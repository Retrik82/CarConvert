from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user
from app.db.models.user import User
from app.db.session import get_db
from app.models.schemas import GenerationPriceOut
from app.services.settings_service import get_generation_price

router = APIRouter(prefix="/settings", tags=["settings"])


@router.get("/generation-price", response_model=GenerationPriceOut)
async def get_public_generation_price(
    _: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> GenerationPriceOut:
    price = await get_generation_price(db)
    return GenerationPriceOut(price_usd=price)
