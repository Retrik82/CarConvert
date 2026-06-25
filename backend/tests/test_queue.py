import asyncio

import pytest

from app.config import get_settings
from app.queue import _enqueued_job_ids, enqueue_photo_job, shutdown_queue, start_local_queue_workers


@pytest.fixture(autouse=True)
def _reset_settings_cache():
    get_settings.cache_clear()
    yield
    get_settings.cache_clear()


@pytest.mark.asyncio
async def test_enqueue_uses_local_workers_when_arq_disabled(monkeypatch) -> None:
    monkeypatch.setenv("REDIS_URL", "redis://localhost:6379")
    monkeypatch.setenv("USE_ARQ_WORKER", "0")
    get_settings.cache_clear()

    processed: asyncio.Queue[tuple[str, str]] = asyncio.Queue()

    async def fake_run(job_id: str, user_id: str, api_key: str) -> None:
        await processed.put((job_id, user_id))

    monkeypatch.setattr("app.services.job_service.run_photo_job", fake_run)

    await shutdown_queue()
    _enqueued_job_ids.clear()
    await start_local_queue_workers()
    await enqueue_photo_job("job-1", "user-1")

    try:
        job_id, user_id = await asyncio.wait_for(processed.get(), timeout=2.0)
    finally:
        await shutdown_queue()

    assert job_id == "job-1"
    assert user_id == "user-1"
