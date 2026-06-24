"""Pytest fixtures for isolated test runs."""

from __future__ import annotations

import pytest

from app.middleware import rate_limit as rate_limit_module


@pytest.fixture(autouse=True)
def _reset_rate_limiters() -> None:
    """Prevent cross-test pollution from in-memory rate limit buckets."""
    rate_limit_module.login_rate_limiter._events.clear()
    rate_limit_module.refresh_rate_limiter._events.clear()
    rate_limit_module.photo_rate_limiter._events.clear()
    yield
    rate_limit_module.login_rate_limiter._events.clear()
    rate_limit_module.refresh_rate_limiter._events.clear()
    rate_limit_module.photo_rate_limiter._events.clear()
