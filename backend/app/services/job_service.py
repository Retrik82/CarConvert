import asyncio
import base64
import logging
from datetime import datetime, timedelta, timezone
from decimal import Decimal
from pathlib import Path

from sqlalchemy.ext.asyncio import AsyncSession

from app.config import get_settings
from app.db.models.photo_job import PhotoJob
from app.repositories.photo_job_repository import PhotoJobRepository
from app.repositories.user_repository import UserRepository
from app.services.background_service import BackgroundService, process_photo_with_background
from app.services.billing_service import BillingService
from app.utils.image_utils import crop_to_frame_guide, to_data_url
from app.utils.debug_log import agent_log

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
        charged_amount: Decimal | None = None,
    ) -> PhotoJob:
        job = PhotoJob(
            user_id=user_id,
            session_id=session_id,
            status="queued",
            background_preset_id=background_preset_id,
            background_variant_id=background_variant_id,
            user_background_id=user_background_id,
            user_background_variant_id=user_background_variant_id,
            charged_amount=charged_amount,
        )
        await self._jobs.create(job)

        job_dir = _job_dir(user_id, job.id)
        ext = {"image/jpeg": ".jpg", "image/png": ".png", "image/webp": ".webp"}.get(mime_type, ".jpg")
        original_path = job_dir / f"original{ext}"
        original_path.write_bytes(image_bytes)

        job.original_path = str(original_path)
        await self._jobs.update(job)
        return job

    async def fail_stale_active_jobs(self, user_id: str | None = None) -> int:
        """Mark long-running queued/processing jobs as failed and refund charges."""
        now = datetime.now(timezone.utc)
        queued_cutoff = now - timedelta(seconds=settings.queued_max_wait_sec)
        processing_cutoff = now - timedelta(seconds=settings.process_job_deadline_sec)
        never_enqueued_cutoff = now - timedelta(seconds=60)
        stale_jobs = await self._jobs.list_stale_active(
            queued_older_than=queued_cutoff,
            processing_older_than=processing_cutoff,
            never_enqueued_older_than=never_enqueued_cutoff,
            user_id=user_id,
        )
        if not stale_jobs:
            return 0

        for job in stale_jobs:
            age_sec = (now - job.created_at).total_seconds()
            stale_reason = (
                "queued_deadline"
                if job.status == "queued"
                else "processing_deadline"
            )
            # region agent log
            agent_log(
                hypothesis_id="A" if job.status == "queued" else "C",
                location="job_service.py:fail_stale_active_jobs",
                message="marking_stale_job",
                data={
                    "job_id": job.id,
                    "user_id": job.user_id,
                    "status": job.status,
                    "age_sec": round(age_sec, 1),
                    "stale_reason": stale_reason,
                    "queued_deadline_sec": settings.queued_max_wait_sec,
                    "process_deadline_sec": settings.process_job_deadline_sec,
                    "original_path": job.original_path,
                },
            )
            # endregion

        billing = BillingService(self._db)
        users = UserRepository(self._db)
        failed = 0
        for job in stale_jobs:
            await self._jobs.update_status(
                job,
                status="failed",
                error="Job timed out. Please try again.",
                completed_at=datetime.now(timezone.utc),
            )
            if job.charged_amount:
                user = await users.get_by_id(job.user_id)
                if user:
                    await billing.refund_for_generation(user, Decimal(str(job.charged_amount)))
            failed += 1
        return failed

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


async def _refund_job_charge(db: AsyncSession, job: PhotoJob) -> None:
    if not job.charged_amount:
        return
    user = await UserRepository(db).get_by_id(job.user_id)
    if not user:
        return
    await BillingService(db).refund_for_generation(user, Decimal(str(job.charged_amount)))


async def _fail_job(
    db: AsyncSession,
    job: PhotoJob,
    *,
    error: str,
    refund: bool = True,
) -> None:
    service = JobService(db)
    await service._jobs.update_status(
        job,
        status="failed",
        error=error,
        completed_at=datetime.now(timezone.utc),
    )
    if refund:
        await _refund_job_charge(db, job)


async def run_photo_job(job_id: str, user_id: str, api_key: str) -> None:
    from app.db.session import AsyncSessionLocal

    # region agent log
    agent_log(
        hypothesis_id="B",
        location="job_service.py:run_photo_job",
        message="worker_started",
        data={
            "job_id": job_id,
            "user_id": user_id,
            "api_key_len": len(api_key or ""),
            "api_key_set": bool(api_key and api_key != "your_key_here"),
        },
    )
    # endregion

    async with AsyncSessionLocal() as db:
        service = JobService(db)
        job = None
        for attempt in range(10):
            job = await service.get_user_job(job_id, user_id)
            if job:
                break
            await asyncio.sleep(0.1 * (attempt + 1))

        if not job:
            # region agent log
            agent_log(
                hypothesis_id="B",
                location="job_service.py:run_photo_job",
                message="job_not_found_after_retries",
                data={"job_id": job_id, "user_id": user_id},
            )
            # endregion
            logger.error(
                "Photo job %s not found for user %s after retries — scheduling re-enqueue",
                job_id,
                user_id,
            )
            from app.queue import schedule_reenqueue

            await schedule_reenqueue(job_id, user_id)
            return

        if job.status != "queued":
            logger.info("Photo job %s already %s — skipping duplicate worker run", job_id, job.status)
            return

        if not job.original_path or not Path(job.original_path).is_file():
            # region agent log
            agent_log(
                hypothesis_id="C",
                location="job_service.py:run_photo_job",
                message="missing_original_file",
                data={"job_id": job_id, "original_path": job.original_path},
            )
            # endregion
            logger.error("Photo job %s is missing original image", job_id)
            await _fail_job(db, job, error="Original image is missing. Please upload again.")
            await db.commit()
            return

        await service._jobs.mark_processing(job, started_at=datetime.now(timezone.utc))
        await db.commit()
        # region agent log
        agent_log(
            hypothesis_id="B",
            location="job_service.py:run_photo_job",
            message="status_processing",
            data={"job_id": job_id},
        )
        # endregion

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

            # region agent log
            agent_log(
                hypothesis_id="D",
                location="job_service.py:run_photo_job",
                message="before_openrouter_pose",
                data={"job_id": job_id, "image_bytes": len(image_bytes)},
            )
            # endregion
            detected_angle = await classify_car_pose_angle(data_url, api_key)
            # region agent log
            agent_log(
                hypothesis_id="D",
                location="job_service.py:run_photo_job",
                message="after_openrouter_pose",
                data={"job_id": job_id, "angle": detected_angle},
            )
            # endregion
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
            # region agent log
            agent_log(
                hypothesis_id="D",
                location="job_service.py:run_photo_job",
                message="job_completed",
                data={"job_id": job_id, "result_path": str(result_path)},
            )
            # endregion
        except Exception as exc:
            # region agent log
            agent_log(
                hypothesis_id="D",
                location="job_service.py:run_photo_job",
                message="job_failed",
                data={"job_id": job_id, "error": str(exc)[:500]},
            )
            # endregion
            logger.exception("Photo job %s failed", job_id)
            await _fail_job(db, job, error=str(exc))

        await db.commit()
