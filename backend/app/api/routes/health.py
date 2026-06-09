import asyncio

from fastapi import APIRouter
from fastapi.responses import JSONResponse

from app.config import get_settings
from app.db.session import _db_ready, ensure_db_ready
from app.utils.storage import check_upload_dir_writable

settings = get_settings()

router = APIRouter(tags=["health"])


@router.get("/health")
async def health_check() -> dict[str, str]:
    """Render health check — no database required."""
    return {"status": "ok"}


@router.get("/health/db")
async def health_db():
    """Check database; returns quickly on failure (no long hang)."""
    if _db_ready.is_set():
        return {"status": "ok", "database": "connected"}

    try:
        await asyncio.wait_for(ensure_db_ready(max_attempts=3, delay_sec=1.0), timeout=12.0)
        return {"status": "ok", "database": "connected"}
    except asyncio.TimeoutError:
        return JSONResponse(
            status_code=503,
            content={
                "status": "error",
                "database": "timeout",
                "detail": "Database did not respond in 12s. Check DATABASE_URL on Render.",
            },
        )
    except Exception as exc:
        return JSONResponse(
            status_code=503,
            content={"status": "error", "database": "failed", "detail": str(exc)},
        )


@router.get("/health/storage")
async def health_storage():
    """Check that the upload directory exists and is writable."""
    ok, error = check_upload_dir_writable(settings.upload_dir)
    if ok:
        return {"status": "ok", "storage": "writable", "path": settings.upload_dir}
    return JSONResponse(
        status_code=503,
        content={
            "status": "error",
            "storage": "not_writable",
            "path": settings.upload_dir,
            "detail": error,
        },
    )
