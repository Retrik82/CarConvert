import time
from collections import defaultdict
from threading import Lock

from fastapi import HTTPException, Request, status

from app.config import get_settings

settings = get_settings()


class SlidingWindowRateLimiter:
    """In-memory rate limiter (per process). Use Redis for multi-instance deployments."""

    def __init__(self, max_requests: int, window_seconds: int) -> None:
        self._max = max_requests
        self._window = window_seconds
        self._events: dict[str, list[float]] = defaultdict(list)
        self._lock = Lock()

    def check(self, key: str) -> None:
        now = time.monotonic()
        cutoff = now - self._window
        with self._lock:
            bucket = [t for t in self._events[key] if t > cutoff]
            if len(bucket) >= self._max:
                raise HTTPException(
                    status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                    detail="Too many requests. Try again later.",
                )
            bucket.append(now)
            self._events[key] = bucket


login_rate_limiter = SlidingWindowRateLimiter(
    settings.auth_rate_limit_login_max,
    settings.auth_rate_limit_login_window_sec,
)
refresh_rate_limiter = SlidingWindowRateLimiter(
    settings.auth_rate_limit_refresh_max,
    settings.auth_rate_limit_refresh_window_sec,
)


def _client_key(request: Request, suffix: str) -> str:
    forwarded = request.headers.get("x-forwarded-for")
    if forwarded:
        ip = forwarded.split(",")[0].strip()
    else:
        ip = request.client.host if request.client else "unknown"
    return f"{suffix}:{ip}"


def enforce_login_rate_limit(request: Request) -> None:
    login_rate_limiter.check(_client_key(request, "login"))


def enforce_refresh_rate_limit(request: Request) -> None:
    refresh_rate_limiter.check(_client_key(request, "refresh"))
