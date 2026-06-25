"""Concurrency and backlog tests for the photo job queue."""

from __future__ import annotations

import asyncio
from datetime import datetime, timedelta, timezone
from unittest.mock import AsyncMock, MagicMock, patch

import pytest

from app.config import get_settings
from app.queue import _enqueued_job_ids, enqueue_photo_job, shutdown_queue, start_local_queue_workers


@pytest.fixture(autouse=True)
def _reset_settings_cache():
    get_settings.cache_clear()
    yield
    get_settings.cache_clear()


@pytest.mark.asyncio
async def test_concurrent_enqueue_processes_all_jobs(monkeypatch) -> None:
    monkeypatch.setenv("USE_ARQ_WORKER", "0")
    monkeypatch.setenv("PROCESS_MAX_CONCURRENT", "3")
    get_settings.cache_clear()

    processed: asyncio.Queue[str] = asyncio.Queue()
    gate = asyncio.Event()

    async def fake_run(job_id: str, user_id: str, api_key: str) -> None:
        await gate.wait()
        await processed.put(job_id)

    monkeypatch.setattr("app.services.job_service.run_photo_job", fake_run)

    await shutdown_queue()
    _enqueued_job_ids.clear()
    await start_local_queue_workers()

    for i in range(6):
        await enqueue_photo_job(f"job-{i}", "user-1")

    gate.set()

    received: list[str] = []
    try:
        for _ in range(6):
            received.append(await asyncio.wait_for(processed.get(), timeout=5.0))
    finally:
        await shutdown_queue()

    assert len(received) == 6
    assert len(set(received)) == 6


@pytest.mark.asyncio
async def test_recently_enqueued_job_not_stale_while_waiting() -> None:
    from app.repositories.photo_job_repository import PhotoJobRepository

    db = AsyncMock()
    repo = PhotoJobRepository(db)
    now = datetime.now(timezone.utc)

    queued_job = MagicMock()
    queued_job.status = "queued"
    queued_job.enqueued_at = now - timedelta(seconds=45)
    queued_job.created_at = now - timedelta(seconds=120)

    captured_query = {}

    async def fake_execute(query):
        captured_query["sql"] = str(query)
        result = MagicMock()
        result.scalars.return_value.all.return_value = []
        return result

    db.execute = fake_execute

    await repo.list_stale_active(
        queued_older_than=now - timedelta(seconds=60),
        processing_older_than=now - timedelta(seconds=300),
    )

    assert "enqueued_at" in captured_query["sql"]
