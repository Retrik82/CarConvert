from fastapi import APIRouter

from app.db.session import ensure_db_ready

router = APIRouter(tags=["health"])


@router.get("/health")
async def health_check() -> dict[str, str]:
    """Used by Render health checks — must not require DB."""
    return {"status": "ok"}


@router.get("/health/db")
async def health_db() -> dict[str, str]:
    """Optional: verify Postgres/SQLite is reachable."""
    await ensure_db_ready()
    return {"status": "ok", "database": "connected"}
