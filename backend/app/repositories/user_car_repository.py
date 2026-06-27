from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.db.models.user_car import SavedRender, UserCar


class UserCarRepository:
    def __init__(self, db: AsyncSession) -> None:
        self._db = db

    async def list_for_user(self, user_id: str) -> list[UserCar]:
        result = await self._db.execute(
            select(UserCar)
            .where(UserCar.user_id == user_id)
            .options(selectinload(UserCar.renders))
            .order_by(UserCar.created_at.desc())
        )
        return list(result.scalars().all())

    async def get_for_user(self, car_id: str, user_id: str) -> UserCar | None:
        result = await self._db.execute(
            select(UserCar)
            .where(UserCar.id == car_id, UserCar.user_id == user_id)
            .options(selectinload(UserCar.renders))
        )
        return result.scalar_one_or_none()

    async def get_render_for_user(self, render_id: str, user_id: str) -> SavedRender | None:
        result = await self._db.execute(
            select(SavedRender).where(SavedRender.id == render_id, SavedRender.user_id == user_id)
        )
        return result.scalar_one_or_none()

    async def add_car(self, car: UserCar) -> UserCar:
        self._db.add(car)
        await self._db.flush()
        return car

    async def add_render(self, render: SavedRender) -> SavedRender:
        self._db.add(render)
        await self._db.flush()
        return render

    async def delete_car(self, car: UserCar) -> None:
        await self._db.delete(car)

    async def delete_render(self, render: SavedRender) -> None:
        await self._db.delete(render)

    async def count_for_user(self, user_id: str) -> int:
        result = await self._db.execute(select(UserCar).where(UserCar.user_id == user_id))
        return len(list(result.scalars().all()))
