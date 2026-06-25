from datetime import datetime

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.models.photo_job import PhotoJob

_ACTIVE_STATUSES = ("queued", "processing")


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

    async def count_active(self) -> int:
        result = await self._db.execute(
            select(func.count())
            .select_from(PhotoJob)
            .where(PhotoJob.status.in_(_ACTIVE_STATUSES))
        )
        return int(result.scalar_one())

    async def count_active_for_user(self, user_id: str) -> int:
        result = await self._db.execute(
            select(func.count())
            .select_from(PhotoJob)
            .where(PhotoJob.user_id == user_id, PhotoJob.status.in_(_ACTIVE_STATUSES))
        )
        return int(result.scalar_one())

    async def list_stale_active(
        self,
        *,
        queued_older_than: datetime,
        processing_older_than: datetime,
        user_id: str | None = None,
    ) -> list[PhotoJob]:
        from sqlalchemy import and_, or_

        query = (
            select(PhotoJob)
            .where(
                or_(
                    and_(PhotoJob.status == "queued", PhotoJob.created_at < queued_older_than),
                    and_(PhotoJob.status == "processing", PhotoJob.created_at < processing_older_than),
                )
            )
            .order_by(PhotoJob.created_at.asc())
        )
        if user_id is not None:
            query = query.where(PhotoJob.user_id == user_id)
        result = await self._db.execute(query)
        return list(result.scalars().all())

    async def list_by_status(self, status: str, *, limit: int = 100) -> list[PhotoJob]:
        result = await self._db.execute(
            select(PhotoJob)
            .where(PhotoJob.status == status)
            .order_by(PhotoJob.created_at.asc())
            .limit(limit)
        )
        return list(result.scalars().all())
