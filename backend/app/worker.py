"""ARQ worker for photo processing jobs."""

from __future__ import annotations

import logging

from arq.connections import RedisSettings

from app.config import get_settings
from app.services.job_service import run_photo_job

logger = logging.getLogger(__name__)
settings = get_settings()


async def run_photo_job_task(ctx, job_id: str, user_id: str) -> None:
    logger.info("Worker starting job %s for user %s", job_id, user_id)
    await run_photo_job(job_id, user_id, settings.openrouter_api_key)


async def startup(ctx) -> None:
    logger.info("ARQ worker started (max_jobs=%s)", settings.process_max_concurrent)


async def shutdown(ctx) -> None:
    logger.info("ARQ worker shutting down")


class WorkerSettings:
    functions = [run_photo_job_task]
    on_startup = startup
    on_shutdown = shutdown
    max_jobs = settings.process_max_concurrent
    job_timeout = settings.process_job_deadline_sec
    redis_settings = RedisSettings.from_dsn(settings.redis_url or "redis://localhost:6379")
