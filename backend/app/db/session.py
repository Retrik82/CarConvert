import asyncio
import logging
from collections.abc import AsyncGenerator
from urllib.parse import parse_qsl, urlencode, urlparse, urlunparse

from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine

from app.config import get_settings
from app.db.base import Base

logger = logging.getLogger(__name__)
settings = get_settings()

_SSL_QUERY_KEYS = frozenset({"sslmode", "sslcert", "sslkey", "sslrootcert", "sslcrl"})


def normalize_database_url(url: str) -> str:
    """Render Postgres gives postgresql:// — use async driver for SQLAlchemy."""
    if url.startswith("postgresql://"):
        url = url.replace("postgresql://", "postgresql+asyncpg://", 1)
    elif url.startswith("postgres://"):
        url = url.replace("postgres://", "postgresql+asyncpg://", 1)

    parsed = urlparse(url)
    if not parsed.scheme.startswith("postgresql"):
        return url

    # asyncpg via SQLAlchemy breaks on sslmode= in the query string
    query = [(k, v) for k, v in parse_qsl(parsed.query, keep_blank_values=True) if k not in _SSL_QUERY_KEYS]
    return urlunparse(parsed._replace(query=urlencode(query)))


def _connect_args(url: str) -> dict:
    normalized = normalize_database_url(url)
    if normalized.startswith("postgresql"):
        # Render Postgres requires SSL
        return {"ssl": True}
    return {}


engine = create_async_engine(
    normalize_database_url(settings.database_url),
    echo=False,
    connect_args=_connect_args(settings.database_url),
)
AsyncSessionLocal = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)


async def init_db() -> None:
    import app.db.models  # noqa: F401 — register models with Base.metadata

    last_error: Exception | None = None
    for attempt in range(1, 6):
        try:
            async with engine.begin() as conn:
                await conn.run_sync(Base.metadata.create_all)
            logger.info("Database tables ready")
            return
        except Exception as exc:
            last_error = exc
            logger.warning("Database init attempt %s/5 failed: %s", attempt, exc)
            if attempt < 5:
                await asyncio.sleep(3)

    assert last_error is not None
    raise last_error


async def get_db() -> AsyncGenerator[AsyncSession, None]:
    async with AsyncSessionLocal() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise
