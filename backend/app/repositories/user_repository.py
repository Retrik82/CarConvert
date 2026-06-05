from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.roles import Role
from app.db.models.user import User


class UserRepository:
    def __init__(self, db: AsyncSession) -> None:
        self._db = db

    async def get_by_id(self, user_id: str) -> User | None:
        result = await self._db.execute(select(User).where(User.id == user_id))
        return result.scalar_one_or_none()

    async def get_by_email(self, email: str) -> User | None:
        result = await self._db.execute(select(User).where(User.email == email.lower()))
        return result.scalar_one_or_none()

    async def get_admin_user(self) -> User | None:
        result = await self._db.execute(select(User).where(User.role == Role.ADMIN.value))
        admin = result.scalar_one_or_none()
        if admin:
            return admin
        result = await self._db.execute(select(User).where(User.is_admin.is_(True)))
        return result.scalar_one_or_none()

    async def add(self, user: User) -> User:
        self._db.add(user)
        await self._db.flush()
        return user
