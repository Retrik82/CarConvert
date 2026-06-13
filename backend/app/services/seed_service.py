from __future__ import annotations

from decimal import Decimal

from sqlalchemy.ext.asyncio import AsyncSession

from app.core.roles import Role
from app.core.security import hash_password
from app.db.models.app_config import DEFAULT_CUSTOM_BACKGROUND_PRICE, DEFAULT_GENERATION_PRICE
from app.db.models.user import User
from app.repositories.app_config_repository import AppConfigRepository
from app.repositories.user_repository import UserRepository
from app.services.settings_service import CUSTOM_BACKGROUND_PRICE_KEY, GENERATION_PRICE_KEY

ADMIN_EMAIL = "admin@admin.com"
ADMIN_PASSWORD = "admin82"
ADMIN_DISPLAY_NAME = "Administrator"


class SeedService:
    def __init__(self, db: AsyncSession) -> None:
        self._db = db
        self._config = AppConfigRepository(db)
        self._users = UserRepository(db)

    async def seed_defaults(self) -> None:
        await self._config.ensure_default(GENERATION_PRICE_KEY, DEFAULT_GENERATION_PRICE)
        await self._config.ensure_default(CUSTOM_BACKGROUND_PRICE_KEY, DEFAULT_CUSTOM_BACKGROUND_PRICE)

        from app.services.background_service import BackgroundService

        await BackgroundService(self._db).seed_presets()
        await BackgroundService(self._db).sync_preset_images()

        from app.services.background_asset_service import seed_preset_backgrounds
        from app.services.car_asset_service import seed_car_assets

        seed_preset_backgrounds()
        seed_car_assets()

        admin = await self._users.get_by_email(ADMIN_EMAIL)
        if admin is None:
            admin = User(
                email=ADMIN_EMAIL,
                password_hash=hash_password(ADMIN_PASSWORD),
                display_name=ADMIN_DISPLAY_NAME,
                balance=Decimal("0"),
                role=Role.ADMIN.value,
                is_admin=True,
                email_verified=True,
            )
            await self._users.add(admin)
        else:
            admin.role = Role.ADMIN.value
            admin.is_admin = True
            admin.email_verified = True
            await self._users.update(admin)


async def seed_defaults(db: AsyncSession) -> None:
    await SeedService(db).seed_defaults()
