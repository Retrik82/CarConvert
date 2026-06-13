from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.db.models.background import (
    BackgroundPreset,
    BackgroundVariant,
    UserBackground,
    UserBackgroundVariant,
)


class BackgroundRepository:
    def __init__(self, db: AsyncSession) -> None:
        self._db = db

    async def list_active_presets(self) -> list[BackgroundPreset]:
        result = await self._db.execute(
            select(BackgroundPreset)
            .where(BackgroundPreset.is_active.is_(True))
            .options(selectinload(BackgroundPreset.variants))
            .order_by(BackgroundPreset.sort_order, BackgroundPreset.name)
        )
        return list(result.scalars().all())

    async def get_preset(self, preset_id: str) -> BackgroundPreset | None:
        result = await self._db.execute(
            select(BackgroundPreset)
            .where(BackgroundPreset.id == preset_id)
            .options(selectinload(BackgroundPreset.variants))
        )
        return result.scalar_one_or_none()

    async def get_preset_by_slug(self, slug: str) -> BackgroundPreset | None:
        result = await self._db.execute(
            select(BackgroundPreset)
            .where(BackgroundPreset.slug == slug)
            .options(selectinload(BackgroundPreset.variants))
        )
        return result.scalar_one_or_none()

    async def get_variant(self, variant_id: str) -> BackgroundVariant | None:
        return await self._db.get(BackgroundVariant, variant_id)

    async def get_preset_variant(self, preset_id: str, angle: str) -> BackgroundVariant | None:
        result = await self._db.execute(
            select(BackgroundVariant).where(
                BackgroundVariant.preset_id == preset_id,
                BackgroundVariant.angle == angle,
            )
        )
        return result.scalar_one_or_none()

    async def add_preset(self, preset: BackgroundPreset) -> BackgroundPreset:
        self._db.add(preset)
        await self._db.flush()
        return preset

    async def add_variant(self, variant: BackgroundVariant) -> BackgroundVariant:
        self._db.add(variant)
        await self._db.flush()
        return variant

    async def update_preset(self, preset: BackgroundPreset) -> BackgroundPreset:
        await self._db.flush()
        return preset

    async def list_user_backgrounds(self, user_id: str) -> list[UserBackground]:
        result = await self._db.execute(
            select(UserBackground)
            .where(UserBackground.user_id == user_id)
            .options(selectinload(UserBackground.variants))
            .order_by(UserBackground.created_at.desc())
        )
        return list(result.scalars().all())

    async def get_user_background(self, background_id: str, user_id: str) -> UserBackground | None:
        result = await self._db.execute(
            select(UserBackground)
            .where(UserBackground.id == background_id, UserBackground.user_id == user_id)
            .options(selectinload(UserBackground.variants))
        )
        return result.scalar_one_or_none()

    async def get_user_variant(self, variant_id: str) -> UserBackgroundVariant | None:
        return await self._db.get(UserBackgroundVariant, variant_id)

    async def get_user_background_variant(self, background_id: str, angle: str) -> UserBackgroundVariant | None:
        result = await self._db.execute(
            select(UserBackgroundVariant).where(
                UserBackgroundVariant.background_id == background_id,
                UserBackgroundVariant.angle == angle,
            )
        )
        return result.scalar_one_or_none()

    async def add_user_background(self, background: UserBackground) -> UserBackground:
        self._db.add(background)
        await self._db.flush()
        return background

    async def add_user_variant(self, variant: UserBackgroundVariant) -> UserBackgroundVariant:
        self._db.add(variant)
        await self._db.flush()
        return variant
