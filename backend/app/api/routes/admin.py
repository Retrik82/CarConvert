from decimal import Decimal

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_admin, get_current_user
from app.db.models.user import User
from app.db.session import get_db
from app.models.schemas import GenerationPriceOut, UpdateGenerationPriceRequest, UserOut
from app.services.settings_service import get_generation_price, set_generation_price

router = APIRouter(prefix="/admin", tags=["admin"])


@router.get("/settings/price", response_model=GenerationPriceOut)
async def admin_get_price(
    _: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
) -> GenerationPriceOut:
    price = await get_generation_price(db)
    return GenerationPriceOut(price_usd=price)


@router.put("/settings/price", response_model=GenerationPriceOut)
async def admin_set_price(
    payload: UpdateGenerationPriceRequest,
    _: User = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
) -> GenerationPriceOut:
    price = await set_generation_price(db, Decimal(str(payload.price_usd)))
    await db.commit()
    return GenerationPriceOut(price_usd=price)
