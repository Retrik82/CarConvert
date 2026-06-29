from datetime import datetime
from decimal import Decimal

from pathlib import Path

from fastapi import APIRouter, Depends, File, Form, HTTPException, UploadFile
from fastapi.responses import FileResponse
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user
from app.db.models.user import User
from app.db.session import get_db
from app.models.schemas import (
    CreateUserCarRequest,
    MyCarsResponse,
    SavedRenderOut,
    UpdateUserCarRequest,
    UpdateUserRenderRequest,
    UserCarOut,
)
from app.services.user_car_service import UserCarService

router = APIRouter(prefix="/my-cars", tags=["my-cars"])


def get_user_car_service(db: AsyncSession = Depends(get_db)) -> UserCarService:
    return UserCarService(db)


def _render_image_url(car_id: str, render_id: str, kind: str) -> str:
    return f"/my-cars/{car_id}/renders/{render_id}/image/{kind}"


def _media_type_for(path: Path) -> str:
    ext = path.suffix.lower()
    return {
        ".jpg": "image/jpeg",
        ".jpeg": "image/jpeg",
        ".png": "image/png",
        ".webp": "image/webp",
    }.get(ext, "application/octet-stream")


def _render_to_out(car_id: str, render) -> SavedRenderOut:
    return SavedRenderOut(
        id=render.id,
        job_id=render.job_id,
        name=render.name,
        created_at=render.created_at,
        quality_score=float(render.quality_score) if render.quality_score is not None else None,
        has_original=bool(render.original_path),
        has_rendered=bool(render.rendered_path),
        original_url=_render_image_url(car_id, render.id, "original") if render.original_path else None,
        rendered_url=_render_image_url(car_id, render.id, "rendered") if render.rendered_path else None,
    )


def _car_to_out(car) -> UserCarOut:
    return UserCarOut(
        id=car.id,
        name=car.name,
        created_at=car.created_at,
        renders=[_render_to_out(car.id, render) for render in car.renders],
    )


@router.get("", response_model=MyCarsResponse)
async def list_my_cars(
    current_user: User = Depends(get_current_user),
    service: UserCarService = Depends(get_user_car_service),
) -> MyCarsResponse:
    cars = await service.list_cars(current_user.id)
    return MyCarsResponse(cars=[_car_to_out(car) for car in cars])


@router.post("", response_model=UserCarOut)
async def create_my_car(
    payload: CreateUserCarRequest,
    current_user: User = Depends(get_current_user),
    service: UserCarService = Depends(get_user_car_service),
) -> UserCarOut:
    car = await service.create_car(current_user.id, payload.name)
    return _car_to_out(car)


@router.patch("/{car_id}", response_model=UserCarOut)
async def update_my_car(
    car_id: str,
    payload: UpdateUserCarRequest,
    current_user: User = Depends(get_current_user),
    service: UserCarService = Depends(get_user_car_service),
) -> UserCarOut:
    car = await service.update_car_name(car_id, current_user.id, payload.name)
    if car is None:
        raise HTTPException(status_code=404, detail="Car not found.")
    return _car_to_out(car)


@router.delete("/{car_id}")
async def delete_my_car(
    car_id: str,
    current_user: User = Depends(get_current_user),
    service: UserCarService = Depends(get_user_car_service),
):
    deleted = await service.delete_car(car_id, current_user.id)
    if not deleted:
        raise HTTPException(status_code=404, detail="Car not found.")
    return {"ok": True}


@router.post("/{car_id}/renders", response_model=SavedRenderOut)
async def save_render(
    car_id: str,
    current_user: User = Depends(get_current_user),
    service: UserCarService = Depends(get_user_car_service),
    job_id: str | None = Form(default=None),
    name: str | None = Form(default=None),
    rendered_ext: str = Form(default="png"),
    quality_score: float | None = Form(default=None),
    original: UploadFile | None = File(default=None),
    rendered: UploadFile | None = File(default=None),
) -> SavedRenderOut:
    original_bytes = await original.read() if original is not None else None
    rendered_bytes = await rendered.read() if rendered is not None else None

    if not job_id and not original_bytes and not rendered_bytes:
        raise HTTPException(status_code=400, detail="Provide job_id or image files.")

    render = await service.add_render(
        car_id,
        current_user.id,
        job_id=job_id,
        name=name,
        original_bytes=original_bytes if original_bytes else None,
        rendered_bytes=rendered_bytes if rendered_bytes else None,
        rendered_ext=rendered_ext,
        quality_score=quality_score,
    )
    if render is None:
        raise HTTPException(status_code=404, detail="Car not found.")
    return _render_to_out(car_id, render)


@router.patch("/{car_id}/renders/{render_id}", response_model=SavedRenderOut)
async def update_render(
    car_id: str,
    render_id: str,
    payload: UpdateUserRenderRequest,
    current_user: User = Depends(get_current_user),
    service: UserCarService = Depends(get_user_car_service),
) -> SavedRenderOut:
    render = await service.update_render_name(car_id, render_id, current_user.id, payload.name)
    if render is None:
        raise HTTPException(status_code=404, detail="Render not found.")
    return _render_to_out(car_id, render)


@router.delete("/{car_id}/renders/{render_id}")
async def delete_render(
    car_id: str,
    render_id: str,
    current_user: User = Depends(get_current_user),
    service: UserCarService = Depends(get_user_car_service),
):
    deleted = await service.delete_render(car_id, render_id, current_user.id)
    if not deleted:
        raise HTTPException(status_code=404, detail="Render not found.")
    return {"ok": True}


@router.get("/{car_id}/renders/{render_id}/image/{kind}")
async def get_render_image(
    car_id: str,
    render_id: str,
    kind: str,
    current_user: User = Depends(get_current_user),
    service: UserCarService = Depends(get_user_car_service),
):
    car = await service._cars.get_for_user(car_id, current_user.id)
    if car is None:
        raise HTTPException(status_code=404, detail="Car not found.")
    render = await service.get_render(car_id, render_id, current_user.id)
    if render is None:
        raise HTTPException(status_code=404, detail="Render not found.")
    path = service.get_render_image_path(render, kind)
    if path is None:
        path = await service.repair_render_image(render, car_id, current_user.id, kind)
    if path is None:
        raise HTTPException(status_code=404, detail="Image not found.")
    return FileResponse(path, media_type=_media_type_for(path))
