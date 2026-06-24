"""Photo job queue — ARQ + Redis in production, in-process fallback for local dev."""

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
            _local_queue.task_done()


async def start_local_queue_workers() -> None:
    global _local_queue, _local_workers, _local_started
    if _local_started or settings.redis_enabled:
        return
    _local_queue = asyncio.Queue()
    _local_workers = [
        asyncio.create_task(_local_worker_loop(i)) for i in range(settings.process_max_concurrent)
    ]
    _local_started = True
    logger.warning(
        "REDIS_URL not set — using in-process photo queue (%s workers). "
        "Jobs will not survive API restarts.",
        settings.process_max_concurrent,
    )


async def shutdown_queue() -> None:
    global _arq_pool, _local_workers, _local_started
    if _local_workers:
        for task in _local_workers:
            task.cancel()
        _local_workers = []
        _local_started = False
    if _arq_pool is not None:
        await _arq_pool.close()
        _arq_pool = None


async def enqueue_photo_job(job_id: str, user_id: str) -> None:
    if settings.redis_enabled:
        pool = await _get_arq_pool()
        await pool.enqueue_job("run_photo_job_task", job_id, user_id)
        return

    if not _local_started:
        await start_local_queue_workers()
    assert _local_queue is not None
    await _local_queue.put((job_id, user_id))


async def get_queue_depth() -> int | None:
    if not settings.redis_enabled:
        return _local_queue.qsize() if _local_queue is not None else 0
    try:
        pool = await _get_arq_pool()
        queued = await pool.zcard(pool.default_queue_name)
        return int(queued)
    except Exception as exc:
        logger.warning("Failed to read queue depth: %s", exc)
        return None
