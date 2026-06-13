import logging
import os
from contextlib import asynccontextmanager
from pathlib import Path

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from app.api.routes import admin, auth, backgrounds, cars, health, legacy, photo, session
from app.api.routes import settings as settings_routes
from app.config import get_settings
from app.models.schemas import EditResponse
from app.utils.logging import setup_logging
from app.utils.storage import check_upload_dir_writable
from app.websocket import camera_stream

logger = logging.getLogger(__name__)
settings = get_settings()


def _ensure_sqlite_parent_dir() -> None:
    url = settings.database_url
    if "sqlite" not in url:
        return
    from sqlalchemy.engine import make_url

    db_path = make_url(url).database
    if db_path:
        Path(db_path).parent.mkdir(parents=True, exist_ok=True)


@asynccontextmanager
async def lifespan(_: FastAPI):
    setup_logging()
    _ensure_sqlite_parent_dir()
    if settings.jwt_secret == "change_me_to_random_32_char_string_minimum":
        logger.warning("JWT_SECRET is using default value — change it in production.")
    db_url = settings.database_url
    if os.getenv("RENDER") and "sqlite" in db_url:
        logger.warning("DATABASE_URL points to SQLite on Render — use Postgres from render.yaml.")
    db_kind = "postgres" if db_url.startswith(("postgres", "postgresql")) else "sqlite"
    storage_ok, storage_error = check_upload_dir_writable(settings.upload_dir)
    if storage_ok:
        logger.info("Upload storage ready at %s", settings.upload_dir)
    else:
        logger.error("Upload storage not writable at %s: %s", settings.upload_dir, storage_error)
    logger.info("API listening (db=%s, tables init on first request)", db_kind)
    yield


app = FastAPI(title="CarConvert API", version="2.0.0", lifespan=lifespan)

_cors_origins = settings.cors_origin_list
_allow_all_origins = "*" in _cors_origins
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"] if _allow_all_origins else _cors_origins,
    allow_credentials=not _allow_all_origins,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(health.router)
app.include_router(auth.router)
app.include_router(settings_routes.router)
app.include_router(admin.router)
app.include_router(backgrounds.router)
app.include_router(cars.router)
app.include_router(session.router)
app.include_router(photo.router)
app.include_router(photo.history_router)
app.include_router(legacy.router)
app.include_router(camera_stream.router)


@app.exception_handler(HTTPException)
async def http_exception_handler(_, exc: HTTPException) -> JSONResponse:
    if exc.status_code == 422:
        return JSONResponse(status_code=exc.status_code, content={"detail": exc.detail})
    return JSONResponse(
        status_code=exc.status_code,
        content=EditResponse(
            success=False,
            error=str(exc.detail) if exc.detail else "Error",
        ).model_dump(),
    )
