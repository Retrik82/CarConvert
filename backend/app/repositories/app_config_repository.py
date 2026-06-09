from decimal import Decimal

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.models.app_config import AppConfig


class AppConfigRepository:
    def __init__(self, db: AsyncSession) -> None:
        self._db = db

    async def get_value(self, key: str, default: Decimal | None = None) -> Decimal | None:
        result = await self._db.execute(select(AppConfig).where(AppConfig.key == key))
        row = result.scalar_one_or_none()
        if row is None:
            return default
        return Decimal(str(row.value))

    async def get_row(self, key: str) -> AppConfig | None:
        result = await self._db.execute(select(AppConfig).where(AppConfig.key == key))
        return result.scalar_one_or_none()

    async def set_value(self, key: str, value: Decimal) -> Decimal:
        row = await self.get_row(key)
        if row is None:
            row = AppConfig(key=key, value=value)
            self._db.add(row)
        else:
            row.value = value
        await self._db.flush()
        return value

    async def ensure_default(self, key: str, default: Decimal) -> None:
        if await self.get_row(key) is None:
            self._db.add(AppConfig(key=key, value=default))
            await self._db.flush()
