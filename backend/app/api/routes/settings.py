from fastapi import APIRouter, Depends

from app.api.deps import get_current_user, get_settings_service
from app.db.models.user import User
from app.models.schemas import GenerationPriceOut
from app.services.settings_service import SettingsService

router = APIRouter(prefix="/settings", tags=["settings"])


@router.get("/generation-price", response_model=GenerationPriceOut)
async def get_public_generation_price(
    _: User = Depends(get_current_user),
    settings: SettingsService = Depends(get_settings_service),
) -> GenerationPriceOut:
    price = await settings.get_generation_price()
    return GenerationPriceOut(price_usd=price)
