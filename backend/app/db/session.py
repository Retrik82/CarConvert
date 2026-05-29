import asyncio
import logging
import ssl
from collections.abc import AsyncGenerator
from urllib.parse import parse_qsl, urlencode, urlparse, urlunparse

from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine

from app.config import get_settings
from app.db.base import Base

logger = logging.getLogger(__name__)
settings = get_settings()

_SSL_QUERY_KEYS = frozenset({"sslmode", "sslcert", "sslkey", "sslrootcert", "sslcrl"})

_db_ready = asyncio.Event()
_init_lock = asyncio.Lock()


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
    if not normalized.startswith("postgresql"):
        return {}

    # Render Postgres requires TLS
    ctx = ssl.create_default_context()
    ctx.check_hostname = False
    ctx.verify_mode = ssl.CERT_REQUIRED
    return {"ssl": ctx, "timeout": 60}


def _db_target_label(url: str) -> str:
    parsed = urlparse(normalize_database_url(url))
    host = parsed.hostname or "?"
    port = parsed.port or 5432
    db = (parsed.path or "/").lstrip("/") or "?"
    return f"{host}:{port}/{db}"


engine = create_async_engine(
    normalize_database_url(settings.database_url),
    echo=False,
    pool_pre_ping=True,
    connect_args=_connect_args(settings.database_url),
)
AsyncSessionLocal = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)


async def init_db() -> None:
    import app.db.models  # noqa: F401 — register models with Base.metadata

    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)


async def ensure_db_ready() -> None:
    """Create tables on first DB use; retries while Postgres is still starting on Render."""
    if _db_ready.is_set():
        return

    async with _init_lock:
        if _db_ready.is_set():
            return

        logger.info("Connecting to database %s", _db_target_label(settings.database_url))
        last_error: Exception | None = None
        for attempt in range(1, 21):
            try:
                await init_db()
                _db_ready.set()
                logger.info("Database tables ready")
                return
            except Exception as exc:
                last_error = exc
                logger.warning("Database connect attempt %s/20 failed: %s", attempt, exc)
                if attempt < 20:
                    await asyncio.sleep(3)

        assert last_error is not None
        raise last_error


async def get_db() -> AsyncGenerator[AsyncSession, None]:
    await ensure_db_ready()
    async with AsyncSessionLocal() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise
