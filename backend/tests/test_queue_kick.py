"""Tests for poll-time job kick and worker health recovery."""

from __future__ import annotations

import asyncio

import pytest

import app.queue as queue_module
from app.config import get_settings
from app.queue import (
    ensure_workers_running,
    kick_queued_job,
    shutdown_queue,
    start_local_queue_workers,
)


@pytest.fixture(autouse=True)
def _reset_settings_cache():
    get_settings.cache_clear()
    yield
    get_settings.cache_clear()


@pytest.mark.asyncio
async def test_kick_queued_job_force_re_enqueues(monkeypatch) -> None:
    monkeypatch.setenv("USE_ARQ_WORKER", "0")
    get_settings.cache_clear()

    processed: asyncio.Queue[str] = asyncio.Queue()

    async def fake_run(job_id: str, user_id: str, api_key: str) -> None:
        await processed.put(job_id)

    monkeypatch.setattr("app.services.job_service.run_photo_job", fake_run)

    await shutdown_queue()
    queue_module._enqueued_job_ids.clear()
    await start_local_queue_workers()

    # Simulate phantom tracking: job marked enqueued but never placed in queue.
    queue_module._enqueued_job_ids.add("stuck-job")

    kicked = await kick_queued_job("stuck-job", "user-1", force=True)

    try:
        assert kicked is True
        job_id = await asyncio.wait_for(processed.get(), timeout=3.0)
        assert job_id == "stuck-job"
    finally:
        await shutdown_queue()


@pytest.mark.asyncio
async def test_ensure_workers_running_restarts_dead_workers(monkeypatch) -> None:
    monkeypatch.setenv("USE_ARQ_WORKER", "0")
    monkeypatch.setenv("PROCESS_MAX_CONCURRENT", "2")
    get_settings.cache_clear()

    await shutdown_queue()
    queue_module._enqueued_job_ids.clear()
    await start_local_queue_workers()

    assert len(queue_module._local_workers) == get_settings().process_max_concurrent
    for task in queue_module._local_workers:
        task.cancel()

    await asyncio.sleep(0.05)
    await ensure_workers_running()

    try:
        expected = get_settings().process_max_concurrent
        assert len(queue_module._local_workers) == expected
        assert all(not task.done() for task in queue_module._local_workers)
    finally:
        await shutdown_queue()
