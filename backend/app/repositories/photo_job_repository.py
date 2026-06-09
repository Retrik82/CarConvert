from datetime import datetime

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.models.photo_job import PhotoJob


class PhotoJobRepository:
    def __init__(self, db: AsyncSession) -> None:
        self._db = db

    async def create(self, job: PhotoJob) -> PhotoJob:
        self._db.add(job)
        await self._db.flush()
        return job

    async def get_by_id(self, job_id: str) -> PhotoJob | None:
        return await self._db.get(PhotoJob, job_id)

    async def get_for_user(self, job_id: str, user_id: str) -> PhotoJob | None:
        job = await self.get_by_id(job_id)
        if not job or job.user_id != user_id:
            return None
        return job

    async def list_for_user(self, user_id: str, limit: int = 50, offset: int = 0) -> tuple[list[PhotoJob], int]:
        total_result = await self._db.execute(
            select(func.count()).select_from(PhotoJob).where(PhotoJob.user_id == user_id)
        )
        total = int(total_result.scalar_one())
        result = await self._db.execute(
            select(PhotoJob)
            .where(PhotoJob.user_id == user_id)
            .order_by(PhotoJob.created_at.desc())
            .limit(limit)
            .offset(offset)
        )
        return list(result.scalars().all()), total

    async def update(self, job: PhotoJob) -> PhotoJob:
        await self._db.flush()
        return job

    async def update_status(
        self,
        job: PhotoJob,
        *,
        status: str,
        result_path: str | None = None,
        result_mime_type: str | None = None,
        error: str | None = None,
        completed_at: datetime | None = None,
    ) -> PhotoJob:
        job.status = status
        if result_path is not None:
            job.result_path = result_path
        if result_mime_type is not None:
            job.result_mime_type = result_mime_type
        if error is not None:
            job.error = error
        if completed_at is not None:
            job.completed_at = completed_at
        await self._db.flush()
        return job
