from __future__ import annotations

from decimal import Decimal

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.roles import Role
from app.core.security import hash_password
from app.db.models.app_config import DEFAULT_GENERATION_PRICE, AppConfig
from app.db.models.user import User
from app.repositories.user_repository import UserRepository
from app.services.settings_service import GENERATION_PRICE_KEY

ADMIN_LOGIN = "admin"
ADMIN_EMAIL = "admin@admin.com"
ADMIN_PASSWORD = "admin82"
ADMIN_DISPLAY_NAME = "Administrator"


async def get_user_by_login(db: AsyncSession, login: str) -> User | None:
    normalized = login.strip().lower()
    if normalized == ADMIN_LOGIN:
        return await UserRepository(db).get_admin_user()
    return await UserRepository(db).get_by_email(normalized)


async def seed_defaults(db: AsyncSession) -> None:
    result = await db.execute(select(AppConfig).where(AppConfig.key == GENERATION_PRICE_KEY))
    if result.scalar_one_or_none() is None:
        db.add(AppConfig(key=GENERATION_PRICE_KEY, value=DEFAULT_GENERATION_PRICE))

    admin = await UserRepository(db).get_by_email(ADMIN_EMAIL)
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
        db.add(admin)
    else:
        admin.role = Role.ADMIN.value
        admin.is_admin = True
        admin.email_verified = True

    await db.flush()
