import base64
import logging
from datetime import datetime, timezone
from pathlib import Path

from sqlalchemy.ext.asyncio import AsyncSession

from app.config import get_settings
from app.db.models.photo_job import PhotoJob
from app.repositories.photo_job_repository import PhotoJobRepository
from app.services.background_service import BackgroundService, process_photo_with_background
from app.utils.image_utils import crop_to_frame_guide, to_data_url

logger = logging.getLogger(__name__)
settings = get_settings()


def _job_dir(user_id: str, job_id: str) -> Path:
    path = Path(settings.upload_dir) / user_id / job_id
    path.mkdir(parents=True, exist_ok=True)
    return path


class JobService:
    def __init__(self, db: AsyncSession) -> None:
        self._jobs = PhotoJobRepository(db)
        self._db = db

    async def create_photo_job(
        self,
        user_id: str,
        image_bytes: bytes,
        mime_type: str,
        session_id: str | None = None,
        *,
        background_preset_id: str | None = None,
        background_variant_id: str | None = None,
        user_background_id: str | None = None,
        user_background_variant_id: str | None = None,
    ) -> PhotoJob:
        job = PhotoJob(
            user_id=user_id,
            session_id=session_id,
            status="queued",
            background_preset_id=background_preset_id,
            background_variant_id=background_variant_id,
            user_background_id=user_background_id,
            user_background_variant_id=user_background_variant_id,
        )
        await self._jobs.create(job)

        job_dir = _job_dir(user_id, job.id)
        ext = {"image/jpeg": ".jpg", "image/png": ".png", "image/webp": ".webp"}.get(mime_type, ".jpg")
        original_path = job_dir / f"original{ext}"
        original_path.write_bytes(image_bytes)

        job.original_path = str(original_path)
        await self._jobs.update(job)
        return job

    async def get_user_job(self, job_id: str, user_id: str) -> PhotoJob | None:
        return await self._jobs.get_for_user(job_id, user_id)

    async def list_user_history(self, user_id: str, limit: int = 50, offset: int = 0) -> tuple[list[PhotoJob], int]:
        return await self._jobs.list_for_user(user_id, limit=limit, offset=offset)


async def create_photo_job(
    db: AsyncSession,
    user_id: str,
    image_bytes: bytes,
    mime_type: str,
    session_id: str | None = None,
) -> PhotoJob:
    return await JobService(db).create_photo_job(user_id, image_bytes, mime_type, session_id)


async def get_user_job(db: AsyncSession, job_id: str, user_id: str) -> PhotoJob | None:
    return await JobService(db).get_user_job(job_id, user_id)


async def list_user_history(db: AsyncSession, user_id: str, limit: int = 50, offset: int = 0) -> tuple[list[PhotoJob], int]:
    return await JobService(db).list_user_history(user_id, limit=limit, offset=offset)


async def run_photo_job(job_id: str, user_id: str, api_key: str) -> None:
    from app.db.session import AsyncSessionLocal
    from app.services.ai.concurrency import process_slot

    async with process_slot():
        async with AsyncSessionLocal() as db:
            service = JobService(db)
            job = await service.get_user_job(job_id, user_id)
            if not job or not job.original_path:
                return

            await service._jobs.update_status(job, status="processing")
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
                background_service = BackgroundService(db)

                from app.services.ai.pose_classifier import classify_car_pose_angle

                detected_angle = await classify_car_pose_angle(data_url, api_key)
                resolved = await background_service.resolve_variant_for_job(
                    preset_id=job.background_preset_id,
                    preset_variant_id=job.background_variant_id,
                    user_background_id=job.user_background_id,
                    user_variant_id=job.user_background_variant_id,
                    user_id=user_id,
                    angle=detected_angle,
                )
                job_dir = _job_dir(user_id, job_id)
                result_b64, result_mime = await process_photo_with_background(
                    data_url,
                    resolved,
                    api_key,
                    job_dir=job_dir,
                )

                ext = {"image/jpeg": ".jpg", "image/png": ".png", "image/webp": ".webp"}.get(result_mime, ".jpg")
                result_path = job_dir / f"result{ext}"
                result_path.write_bytes(base64.b64decode(result_b64))

                await service._jobs.update_status(
                    job,
                    status="completed",
                    result_path=str(result_path),
                    result_mime_type=result_mime,
                    error=None,
                    completed_at=datetime.now(timezone.utc),
                )
            except Exception as exc:
                logger.exception("Photo job %s failed", job_id)
                await service._jobs.update_status(
                    job,
                    status="failed",
                    error=str(exc),
                    completed_at=datetime.now(timezone.utc),
                )

            await db.commit()
