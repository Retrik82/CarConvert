import asyncio
import logging
from collections.abc import AsyncGenerator
from urllib.parse import urlparse

from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine

from app.config import get_settings
from app.db.base import Base

logger = logging.getLogger(__name__)
settings = get_settings()

_db_ready = asyncio.Event()
_init_lock = asyncio.Lock()


def normalize_database_url(url: str) -> str:
    """Render Postgres URL -> psycopg async driver (keeps sslmode= in query string)."""
    if url.startswith("postgresql://"):
        return url.replace("postgresql://", "postgresql+psycopg://", 1)
    if url.startswith("postgres://"):
        return url.replace("postgres://", "postgresql+psycopg://", 1)
    return url


def _db_target_label(url: str) -> str:
    parsed = urlparse(normalize_database_url(url))
    host = parsed.hostname or "local"
    port = parsed.port or ""
    db = (parsed.path or "/").lstrip("/") or "?"
    port_part = f":{port}" if port else ""
    return f"{host}{port_part}/{db}"


def _engine_kwargs(url: str) -> dict:
    normalized = normalize_database_url(url)
    kwargs: dict = {"echo": False, "pool_pre_ping": True}
    if normalized.startswith("postgresql"):
        kwargs["connect_args"] = {"connect_timeout": 10}
    return kwargs


engine = create_async_engine(normalize_database_url(settings.database_url), **_engine_kwargs(settings.database_url))
AsyncSessionLocal = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)


async def init_db() -> None:
    import app.db.models  # noqa: F401 — register models with Base.metadata

    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
        await conn.run_sync(_migrate_schema)

    async with AsyncSessionLocal() as session:
        from app.services.seed_service import seed_defaults

        await seed_defaults(session)
        await session.commit()


def _migrate_schema(sync_conn) -> None:
    """Add new columns to existing SQLite/Postgres tables without Alembic."""
    from sqlalchemy import inspect, text

    inspector = inspect(sync_conn)
    if "users" in inspector.get_table_names():
        user_cols = {col["name"] for col in inspector.get_columns("users")}
        if "balance" not in user_cols:
            sync_conn.execute(text("ALTER TABLE users ADD COLUMN balance NUMERIC(10, 2) DEFAULT 10.00"))
        if "is_admin" not in user_cols:
            sync_conn.execute(text("ALTER TABLE users ADD COLUMN is_admin BOOLEAN DEFAULT 0"))


async def ensure_db_ready(*, max_attempts: int = 8, delay_sec: float = 2.0) -> None:
    if _db_ready.is_set():
        return

    async with _init_lock:
        if _db_ready.is_set():
            return

        logger.info("Connecting to database %s", _db_target_label(settings.database_url))
        last_error: Exception | None = None
        for attempt in range(1, max_attempts + 1):
            try:
                await init_db()
                _db_ready.set()
                logger.info("Database tables ready")
                return
            except Exception as exc:
                last_error = exc
                logger.warning("Database connect attempt %s/%s failed: %s", attempt, max_attempts, exc)
                if attempt < max_attempts:
                    await asyncio.sleep(delay_sec)

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
