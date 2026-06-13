from decimal import Decimal

from fastapi import APIRouter, Depends

from app.api.deps import get_current_admin, get_settings_service
from app.db.models.user import User
from app.models.schemas import CustomBackgroundPriceOut, GenerationPriceOut, UpdateCustomBackgroundPriceRequest, UpdateGenerationPriceRequest
from app.services.settings_service import SettingsService

router = APIRouter(prefix="/admin", tags=["admin"])


@router.get("/settings/price", response_model=GenerationPriceOut)
async def admin_get_price(
    _: User = Depends(get_current_admin),
    settings: SettingsService = Depends(get_settings_service),
) -> GenerationPriceOut:
    price = await settings.get_generation_price()
    return GenerationPriceOut(price_usd=price)


@router.put("/settings/price", response_model=GenerationPriceOut)
async def admin_set_price(
    payload: UpdateGenerationPriceRequest,
    _: User = Depends(get_current_admin),
    settings: SettingsService = Depends(get_settings_service),
) -> GenerationPriceOut:
    price = await settings.set_generation_price(Decimal(str(payload.price_usd)))
    return GenerationPriceOut(price_usd=price)


@router.get("/settings/custom-background-price", response_model=CustomBackgroundPriceOut)
async def admin_get_custom_background_price(
    _: User = Depends(get_current_admin),
    settings: SettingsService = Depends(get_settings_service),
) -> CustomBackgroundPriceOut:
    price = await settings.get_custom_background_price()
    return CustomBackgroundPriceOut(price_usd=price)


@router.put("/settings/custom-background-price", response_model=CustomBackgroundPriceOut)
async def admin_set_custom_background_price(
    payload: UpdateCustomBackgroundPriceRequest,
    _: User = Depends(get_current_admin),
    settings: SettingsService = Depends(get_settings_service),
) -> CustomBackgroundPriceOut:
    price = await settings.set_custom_background_price(Decimal(str(payload.price_usd)))
    return CustomBackgroundPriceOut(price_usd=price)
