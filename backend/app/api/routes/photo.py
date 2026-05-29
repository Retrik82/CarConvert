import asyncio
import base64
from pathlib import Path

from fastapi import APIRouter, Depends, File, Form, HTTPException, UploadFile
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user
from app.config import get_settings
from app.db.models.user import User
from app.db.session import get_db
from app.models.schemas import HistoryItem, HistoryResponse, PhotoResultResponse, ProcessJobResponse
from app.services.job_service import create_photo_job, get_user_job, list_user_history, run_photo_job
from app.services.session_service import get_active_session
from app.utils.agent_debug_log import agent_log
from app.utils.image_utils import normalize_content_type, read_file_as_base64, validate_image_upload

router = APIRouter(prefix="/photo", tags=["photo"])
history_router = APIRouter(prefix="/photos", tags=["photos"])
settings = get_settings()


@router.post("/process", response_model=ProcessJobResponse)
async def process_photo(
    image: UploadFile = File(...),
    session_id: str | None = Form(default=None),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> ProcessJobResponse:
    if not settings.openrouter_api_key or settings.openrouter_api_key == "your_key_here":
        raise HTTPException(status_code=500, detail="OPENROUTER_API_KEY is not configured.")

    if session_id:
        session = await get_active_session(db, session_id, current_user.id)
        if not session:
            raise HTTPException(status_code=400, detail="Invalid or expired camera session.")

    image_bytes = await image.read()
    filename = image.filename or "photo.jpg"
    content_type_raw = image.content_type
    content_type_used = normalize_content_type(filename, content_type_raw)
    agent_log(
        location="photo.py:process_photo",
        message="upload_received",
        data={
            "filename": filename,
            "content_type_raw": content_type_raw,
            "content_type_used": content_type_used,
            "bytes_len": len(image_bytes),
            "user_id_prefix": current_user.id[:8],
        },
        hypothesis_id="A,B",
        run_id="post-fix",
    )
    try:
        validate_image_upload(filename, content_type_used, image_bytes)
    except ValueError as exc:
        message = str(exc)
        status = 413 if "10MB" in message else 415 if "Unsupported" in message else 400
        raise HTTPException(status_code=status, detail=message) from exc

    job = await create_photo_job(
        db,
        current_user.id,
        image_bytes,
        content_type_used,
        session_id,
    )
    await db.commit()

    asyncio.create_task(run_photo_job(job.id, current_user.id, settings.openrouter_api_key))
    return ProcessJobResponse(job_id=job.id, status=job.status)


@router.get("/result/{job_id}", response_model=PhotoResultResponse)
async def get_result(
    job_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> PhotoResultResponse:
    job = await get_user_job(db, job_id, current_user.id)
    if not job:
        raise HTTPException(status_code=404, detail="Job not found.")

    image_base64 = None
    mime_type = job.result_mime_type
    if job.status == "completed" and job.result_path and Path(job.result_path).exists():
        image_base64, mime_type = read_file_as_base64(job.result_path)

    return PhotoResultResponse(
        job_id=job.id,
        status=job.status,
        image_base64=image_base64,
        mime_type=mime_type,
        error=job.error,
    )


@history_router.get("/history", response_model=HistoryResponse)
async def photo_history(
    limit: int = 50,
    offset: int = 0,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> HistoryResponse:
    jobs, total = await list_user_history(db, current_user.id, limit, offset)
    items = [
        HistoryItem(
            job_id=job.id,
            status=job.status,
            created_at=job.created_at,
            completed_at=job.completed_at,
            has_result=bool(job.result_path),
        )
        for job in jobs
    ]
    return HistoryResponse(items=items, total=total)
