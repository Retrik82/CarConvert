import base64
import logging
from datetime import datetime, timezone
from pathlib import Path

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import get_settings
from app.db.models.photo_job import PhotoJob
from app.services.ai.desert_processor import process_desert_background
from app.utils.image_utils import crop_to_frame_guide, to_data_url

logger = logging.getLogger(__name__)
settings = get_settings()


def _job_dir(user_id: str, job_id: str) -> Path:
    path = Path(settings.upload_dir) / user_id / job_id
    path.mkdir(parents=True, exist_ok=True)
    return path


async def create_photo_job(
    db: AsyncSession,
    user_id: str,
    image_bytes: bytes,
    mime_type: str,
    session_id: str | None = None,
) -> PhotoJob:
    job = PhotoJob(user_id=user_id, session_id=session_id, status="queued")
    db.add(job)
    await db.flush()

    job_dir = _job_dir(user_id, job.id)
    ext = {"image/jpeg": ".jpg", "image/png": ".png", "image/webp": ".webp"}.get(mime_type, ".jpg")
    original_path = job_dir / f"original{ext}"
    original_path.write_bytes(image_bytes)

    job.original_path = str(original_path)
    await db.flush()
    return job


async def get_user_job(db: AsyncSession, job_id: str, user_id: str) -> PhotoJob | None:
    job = await db.get(PhotoJob, job_id)
    if not job or job.user_id != user_id:
        return None
    return job


async def list_user_history(db: AsyncSession, user_id: str, limit: int = 50, offset: int = 0) -> tuple[list[PhotoJob], int]:
    total_result = await db.execute(
        select(func.count()).select_from(PhotoJob).where(PhotoJob.user_id == user_id)
    )
    total = int(total_result.scalar_one())
    result = await db.execute(
        select(PhotoJob)
        .where(PhotoJob.user_id == user_id)
        .order_by(PhotoJob.created_at.desc())
        .limit(limit)
        .offset(offset)
    )
    return list(result.scalars().all()), total


async def run_photo_job(job_id: str, user_id: str, api_key: str) -> None:
    from app.db.session import AsyncSessionLocal

    async with AsyncSessionLocal() as db:
        job = await get_user_job(db, job_id, user_id)
        if not job or not job.original_path:
            return

        job.status = "processing"
        await db.commit()

        try:
            image_bytes = Path(job.original_path).read_bytes()
            mime_type = "image/jpeg"
            if job.original_path.endswith(".png"):
                mime_type = "image/png"
            elif job.original_path.endswith(".webp"):
                mime_type = "image/webp"

            try:
                image_bytes = crop_to_frame_guide(image_bytes)
                mime_type = "image/jpeg"
            except Exception as exc:
                logger.warning("Frame crop skipped for job %s: %s", job_id, exc)

            data_url = to_data_url(image_bytes, mime_type)
            result_b64, result_mime = await process_desert_background(data_url, api_key)

            job_dir = _job_dir(user_id, job_id)
            ext = {"image/jpeg": ".jpg", "image/png": ".png", "image/webp": ".webp"}.get(result_mime, ".jpg")
            result_path = job_dir / f"result{ext}"
            result_path.write_bytes(base64.b64decode(result_b64))

            job.result_path = str(result_path)
            job.result_mime_type = result_mime
            job.status = "completed"
            job.completed_at = datetime.now(timezone.utc)
            job.error = None
        except Exception as exc:
            logger.exception("Photo job %s failed", job_id)
            job.status = "failed"
            job.error = str(exc)
            job.completed_at = datetime.now(timezone.utc)

        await db.commit()
