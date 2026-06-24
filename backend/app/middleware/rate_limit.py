import time
from collections import defaultdict
from threading import Lock

from fastapi import HTTPException, Request, status

from app.config import get_settings

settings = get_settings()

_redis_client = None


async def _get_redis():
    global _redis_client
    if _redis_client is not None:
        return _redis_client
    if not settings.redis_enabled:
        return None
    try:
        import redis.asyncio as aioredis

        _redis_client = aioredis.from_url(settings.redis_url, decode_responses=True)
        return _redis_client
    except Exception:
        return None


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
photo_rate_limiter = SlidingWindowRateLimiter(
    settings.photo_rate_limit_max,
    settings.photo_rate_limit_window_sec,
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


async def enforce_photo_rate_limit(user_id: str) -> None:
    key = f"user:{user_id}"
    redis = await _get_redis()
    if redis is not None:
        redis_key = f"rl:photo:{key}"
        count = await redis.incr(redis_key)
        if count == 1:
            await redis.expire(redis_key, settings.photo_rate_limit_window_sec)
        if count > settings.photo_rate_limit_max:
            raise HTTPException(
                status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                detail="Too many photo requests. Try again later.",
            )
        return
    photo_rate_limiter.check(key)
