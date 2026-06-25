"""Photo job queue — in-process workers by default; optional ARQ + Redis for scaling."""

from __future__ import annotations

import asyncio
import logging
from typing import Any

from app.config import get_settings

logger = logging.getLogger(__name__)
settings = get_settings()

_arq_pool: Any = None
_local_queue: asyncio.Queue[tuple[str, str]] | None = None
_local_workers: list[asyncio.Task] = []
_local_started = False
_enqueued_job_ids: set[str] = set()
_enqueue_lock = asyncio.Lock()


async def _get_arq_pool():
    global _arq_pool
    if _arq_pool is not None:
        return _arq_pool
    from arq import create_pool
    from arq.connections import RedisSettings

    _arq_pool = await create_pool(RedisSettings.from_dsn(settings.redis_url))
    return _arq_pool


async def _local_worker_loop(worker_id: int) -> None:
    assert _local_queue is not None
    from app.services.job_service import run_photo_job

    while True:
        job_id, user_id = await _local_queue.get()
        try:
            await run_photo_job(job_id, user_id, settings.openrouter_api_key)
        except Exception as exc:
            logger.exception("Local worker %s failed job %s: %s", worker_id, job_id, exc)
        finally:
            _enqueued_job_ids.discard(job_id)
            _local_queue.task_done()


async def start_local_queue_workers() -> None:
    """Start in-process photo workers inside the API process."""
    global _local_queue, _local_workers, _local_started
    if _local_started:
        return
    _local_queue = asyncio.Queue()
    _local_workers = [
        asyncio.create_task(_local_worker_loop(i)) for i in range(settings.process_max_concurrent)
    ]
    _local_started = True
    logger.info(
        "Photo queue workers started in-process (%s workers)",
        settings.process_max_concurrent,
    )


async def shutdown_queue() -> None:
    global _arq_pool, _local_workers, _local_started, _enqueued_job_ids
    if _local_workers:
        for task in _local_workers:
            task.cancel()
        _local_workers = []
        _local_started = False
    _enqueued_job_ids.clear()
    if _arq_pool is not None:
        await _arq_pool.close()
        _arq_pool = None


async def _enqueue_local(job_id: str, user_id: str) -> None:
    async with _enqueue_lock:
        if job_id in _enqueued_job_ids:
            return
        if not _local_started:
            await start_local_queue_workers()
        assert _local_queue is not None
        _enqueued_job_ids.add(job_id)
        await _local_queue.put((job_id, user_id))


async def enqueue_photo_job(job_id: str, user_id: str) -> None:
    """Schedule photo processing. Always uses in-process workers; ARQ is optional."""
    if settings.redis_enabled and settings.use_arq_worker:
        try:
            pool = await _get_arq_pool()
            await pool.enqueue_job("run_photo_job_task", job_id, user_id)
            logger.info("Enqueued photo job %s via ARQ", job_id)
            return
        except Exception as exc:
            logger.warning("ARQ enqueue failed for job %s, falling back to local queue: %s", job_id, exc)

    await _enqueue_local(job_id, user_id)


async def recover_stuck_queued_jobs() -> int:
    """Re-enqueue DB jobs stuck in 'queued' after restarts or failed ARQ delivery."""
    from app.db.session import AsyncSessionLocal
    from app.repositories.photo_job_repository import PhotoJobRepository

    async with AsyncSessionLocal() as db:
        repo = PhotoJobRepository(db)
        jobs = await repo.list_by_status("queued", limit=settings.max_queue_size)

    recovered = 0
    for job in jobs:
        await _enqueue_local(job.id, job.user_id)
        recovered += 1
    if recovered:
        logger.warning("Recovered %s queued photo job(s) into local workers", recovered)
    return recovered


async def get_queue_depth() -> int | None:
    local_depth = _local_queue.qsize() if _local_queue is not None else 0
    if not settings.redis_enabled or not settings.use_arq_worker:
        return local_depth
    try:
        pool = await _get_arq_pool()
        queued = await pool.zcard(pool.default_queue_name)
        return max(int(queued), local_depth)
    except Exception as exc:
        logger.warning("Failed to read ARQ queue depth: %s", exc)
        return local_depth
