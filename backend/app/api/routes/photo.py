import asyncio
from pathlib import Path

from fastapi import APIRouter, Depends, File, Form, HTTPException, UploadFile

from app.api.deps import get_background_service, get_billing_service, get_current_user, get_job_service, get_session_service
from app.config import get_settings
from app.db.models.user import User
from app.models.schemas import HistoryItem, HistoryResponse, PhotoResultResponse, ProcessJobResponse
from app.services.billing_service import BillingService, InsufficientBalanceError
from app.services.background_service import BackgroundService
from app.services.job_service import JobService, run_photo_job
from app.services.session_service import SessionService
from app.utils.image_utils import normalize_content_type, read_file_as_base64, validate_image_upload

router = APIRouter(prefix="/photo", tags=["photo"])
history_router = APIRouter(prefix="/photos", tags=["photos"])
settings = get_settings()


@router.post("/process", response_model=ProcessJobResponse)
async def process_photo(
    image: UploadFile = File(...),
    session_id: str | None = Form(default=None),
    background_preset_id: str | None = Form(default=None),
    background_preset_slug: str | None = Form(default=None),
    background_variant_id: str | None = Form(default=None),
    user_background_id: str | None = Form(default=None),
    user_background_variant_id: str | None = Form(default=None),
    current_user: User = Depends(get_current_user),
    billing: BillingService = Depends(get_billing_service),
    session_service: SessionService = Depends(get_session_service),
    job_service: JobService = Depends(get_job_service),
    backgrounds: BackgroundService = Depends(get_background_service),
) -> ProcessJobResponse:
    if not settings.openrouter_api_key or settings.openrouter_api_key == "your_key_here":
        raise HTTPException(status_code=500, detail="OPENROUTER_API_KEY is not configured.")

    if session_id:
        session = await session_service.get_active_session(session_id, current_user.id)
        if not session:
            raise HTTPException(status_code=400, detail="Invalid or expired camera session.")

    image_bytes = await image.read()
    filename = image.filename or "photo.jpg"
    content_type_used = normalize_content_type(filename, image.content_type)
    try:
        validate_image_upload(filename, content_type_used, image_bytes)
    except ValueError as exc:
        message = str(exc)
        status = 413 if "10MB" in message else 415 if "Unsupported" in message else 400
        raise HTTPException(status_code=status, detail=message) from exc

    try:
        await billing.charge_for_generation(current_user)
    except InsufficientBalanceError as exc:
        raise HTTPException(
            status_code=402,
            detail=f"Insufficient balance. Required: ${exc.price:.2f}, available: ${exc.balance:.2f}.",
        ) from exc

    resolved_preset_id = background_preset_id
    if not resolved_preset_id and background_preset_slug:
        preset = await backgrounds.get_preset_by_slug(background_preset_slug.strip())
        if preset:
            resolved_preset_id = preset.id

    job = await job_service.create_photo_job(
        current_user.id,
        image_bytes,
        content_type_used,
        session_id,
        background_preset_id=resolved_preset_id,
        background_variant_id=background_variant_id,
        user_background_id=user_background_id,
        user_background_variant_id=user_background_variant_id,
    )

    asyncio.create_task(run_photo_job(job.id, current_user.id, settings.openrouter_api_key))
    return ProcessJobResponse(job_id=job.id, status=job.status)


@router.get("/result/{job_id}", response_model=PhotoResultResponse)
async def get_result(
    job_id: str,
    current_user: User = Depends(get_current_user),
    job_service: JobService = Depends(get_job_service),
) -> PhotoResultResponse:
    job = await job_service.get_user_job(job_id, current_user.id)
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
    job_service: JobService = Depends(get_job_service),
) -> HistoryResponse:
    jobs, total = await job_service.list_user_history(current_user.id, limit, offset)
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
