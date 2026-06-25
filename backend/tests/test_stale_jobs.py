"""Tests for photo job stale detection after queue/load changes."""

from __future__ import annotations

from datetime import datetime, timedelta, timezone

import pytest

from app.config import get_settings


@pytest.fixture(autouse=True)
def _reset_settings_cache():
    get_settings.cache_clear()
    yield
    get_settings.cache_clear()


def test_queued_max_wait_scales_with_backlog(monkeypatch) -> None:
    monkeypatch.setenv("QUEUED_JOB_DEADLINE_SEC", "0")
    monkeypatch.setenv("MAX_QUEUE_SIZE", "50")
    monkeypatch.setenv("PROCESS_MAX_CONCURRENT", "3")
    monkeypatch.setenv("PROCESS_JOB_DEADLINE_SEC", "300")
    get_settings.cache_clear()

    settings = get_settings()
    # 50 / 3 * 300 + 120 = 5120
    assert settings.queued_max_wait_sec == 5120


def test_queued_max_wait_explicit_override(monkeypatch) -> None:
    monkeypatch.setenv("QUEUED_JOB_DEADLINE_SEC", "600")
    get_settings.cache_clear()

    assert get_settings().queued_max_wait_sec == 600


@pytest.mark.asyncio
async def test_list_stale_queued_uses_enqueued_at_not_created_at() -> None:
    from unittest.mock import AsyncMock, MagicMock

    from app.repositories.photo_job_repository import PhotoJobRepository

    db = AsyncMock()
    repo = PhotoJobRepository(db)

    now = datetime.now(timezone.utc)
    recent_enqueue = now - timedelta(seconds=10)
    old_processing_start = now - timedelta(seconds=400)

    queued_job = MagicMock()
    queued_job.status = "queued"
    queued_job.enqueued_at = recent_enqueue
    queued_job.created_at = now - timedelta(seconds=120)

    processing_job = MagicMock()
    processing_job.status = "processing"
    processing_job.processing_started_at = old_processing_start
    processing_job.created_at = now - timedelta(seconds=30)

    async def fake_execute(_query):
        result = MagicMock()

        class _Scalars:
            def all(self_nonlocal):
                return [processing_job]

        result.scalars.return_value = _Scalars()
        return result

    db.execute = fake_execute

    stale = await repo.list_stale_active(
        queued_older_than=now - timedelta(seconds=60),
        processing_older_than=now - timedelta(seconds=300),
    )

    assert stale == [processing_job]
