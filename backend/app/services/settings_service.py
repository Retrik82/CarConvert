from __future__ import annotations

from decimal import Decimal

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.models.app_config import DEFAULT_GENERATION_PRICE, AppConfig

GENERATION_PRICE_KEY = "generation_price_usd"


async def get_generation_price(db: AsyncSession) -> Decimal:
    result = await db.execute(select(AppConfig).where(AppConfig.key == GENERATION_PRICE_KEY))
    row = result.scalar_one_or_none()
    if row is None:
        return DEFAULT_GENERATION_PRICE
    return Decimal(str(row.value))


async def set_generation_price(db: AsyncSession, price: Decimal) -> Decimal:
    result = await db.execute(select(AppConfig).where(AppConfig.key == GENERATION_PRICE_KEY))
    row = result.scalar_one_or_none()
    if row is None:
        row = AppConfig(key=GENERATION_PRICE_KEY, value=price)
        db.add(row)
    else:
        row.value = price
    await db.flush()
    return price
