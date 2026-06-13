from __future__ import annotations

from decimal import Decimal

from sqlalchemy.ext.asyncio import AsyncSession

from app.db.models.app_config import DEFAULT_CUSTOM_BACKGROUND_PRICE, DEFAULT_GENERATION_PRICE
from app.repositories.app_config_repository import AppConfigRepository

GENERATION_PRICE_KEY = "generation_price_usd"
CUSTOM_BACKGROUND_PRICE_KEY = "custom_background_price_usd"


class SettingsService:
    def __init__(self, db: AsyncSession) -> None:
        self._config = AppConfigRepository(db)

    async def get_generation_price(self) -> Decimal:
        value = await self._config.get_value(GENERATION_PRICE_KEY, DEFAULT_GENERATION_PRICE)
        return value if value is not None else DEFAULT_GENERATION_PRICE

    async def set_generation_price(self, price: Decimal) -> Decimal:
        return await self._config.set_value(GENERATION_PRICE_KEY, price)

    async def get_custom_background_price(self) -> Decimal:
        value = await self._config.get_value(CUSTOM_BACKGROUND_PRICE_KEY, DEFAULT_CUSTOM_BACKGROUND_PRICE)
        return value if value is not None else DEFAULT_CUSTOM_BACKGROUND_PRICE

    async def set_custom_background_price(self, price: Decimal) -> Decimal:
        return await self._config.set_value(CUSTOM_BACKGROUND_PRICE_KEY, price)


async def get_generation_price(db: AsyncSession) -> Decimal:
    return await SettingsService(db).get_generation_price()


async def set_generation_price(db: AsyncSession, price: Decimal) -> Decimal:
    return await SettingsService(db).set_generation_price(price)
