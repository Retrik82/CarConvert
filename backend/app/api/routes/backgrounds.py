from pathlib import Path
import logging

from fastapi import APIRouter, Depends, HTTPException
from fastapi.responses import FileResponse

from app.api.deps import get_background_service, get_billing_service, get_current_user, get_settings_service
from app.config import get_settings
from app.db.models.user import User
from app.models.schemas import (
    BackgroundCatalogResponse,
    BackgroundPresetOut,
    BackgroundVariantOut,
    CreateCustomBackgroundRequest,
    CreateCustomBackgroundResponse,
)
from app.services.background_service import BackgroundService
from app.services.billing_service import BillingService, InsufficientBalanceError
from app.services.settings_service import SettingsService

router = APIRouter(prefix="/backgrounds", tags=["backgrounds"])
settings = get_settings()
logger = logging.getLogger(__name__)


def _variant_preview_url(variant_id: str | None) -> str | None:
    if not variant_id:
        return None
    return f"/backgrounds/image/{variant_id}"


def _preset_to_out(preset, *, is_custom: bool = False) -> BackgroundPresetOut:
    preview_id = preset.preview_variant_id
    if preview_id is None and preset.variants:
        preview_id = preset.variants[0].id
    return BackgroundPresetOut(
        id=preset.id,
        slug=getattr(preset, "slug", preset.id),
        name=preset.name,
        description=getattr(preset, "description", None),
        prompt_template=getattr(preset, "prompt_template", None) or getattr(preset, "prompt", None),
        preview_url=_variant_preview_url(preview_id),
        variants=[
            BackgroundVariantOut(
                id=variant.id,
                angle=variant.angle,
                preview_url=_variant_preview_url(variant.id),
            )
            for variant in preset.variants
        ],
        is_custom=is_custom,
    )


@router.get("", response_model=BackgroundCatalogResponse)
async def list_backgrounds(
    current_user: User = Depends(get_current_user),
    backgrounds: BackgroundService = Depends(get_background_service),
    settings_service: SettingsService = Depends(get_settings_service),
) -> BackgroundCatalogResponse:
    presets, custom = await backgrounds.list_catalog(current_user.id)
    custom_price = await settings_service.get_custom_background_price()
    return BackgroundCatalogResponse(
        presets=[_preset_to_out(preset) for preset in presets],
        custom=[_preset_to_out(item, is_custom=True) for item in custom],
        custom_background_price_usd=custom_price,
    )


@router.get("/image/{variant_id}")
async def get_background_image(
    variant_id: str,
    current_user: User = Depends(get_current_user),
    backgrounds: BackgroundService = Depends(get_background_service),
):
    image_path = await backgrounds.get_variant_image_path(variant_id, current_user.id)
    if image_path is None:
        raise HTTPException(status_code=404, detail="Background image not found.")
    return FileResponse(image_path)


@router.post("/custom", response_model=CreateCustomBackgroundResponse)
async def create_custom_background(
    payload: CreateCustomBackgroundRequest,
    current_user: User = Depends(get_current_user),
    backgrounds: BackgroundService = Depends(get_background_service),
    billing: BillingService = Depends(get_billing_service),
) -> CreateCustomBackgroundResponse:
    if not settings.openrouter_api_key or settings.openrouter_api_key == "your_key_here":
        raise HTTPException(status_code=500, detail="OPENROUTER_API_KEY is not configured.")

    try:
        charged_price = await billing.charge_for_custom_background(current_user)
    except InsufficientBalanceError as exc:
        raise HTTPException(
            status_code=402,
            detail=f"Insufficient balance. Required: ${exc.price:.2f}, available: ${exc.balance:.2f}.",
        ) from exc

    try:
        background = await backgrounds.create_user_background(
            current_user.id,
            payload.name,
            payload.prompt,
            settings.openrouter_api_key,
        )
    except Exception as exc:
        await billing.refund_custom_background(current_user, charged_price)
        logger.exception("Custom background generation failed for user %s", current_user.id)
        detail = str(exc)
        if "OPENROUTER" in detail.upper() or "OpenRouter" in detail:
            detail = (
                "Не удалось сгенерировать фон через AI. "
                "Проверьте OPENROUTER_API_KEY на сервере и доступность модели."
            )
        raise HTTPException(status_code=500, detail=detail) from exc

    return CreateCustomBackgroundResponse(background=_preset_to_out(background, is_custom=True))
