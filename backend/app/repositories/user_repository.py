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

    async def update(self, user: User) -> User:
        await self._db.flush()
        return user

    async def update_password(self, user: User, password_hash: str) -> User:
        user.password_hash = password_hash
        return await self.update(user)

    async def update_balance(self, user: User, balance) -> User:
        user.balance = balance
        return await self.update(user)

    async def mark_email_verified(self, user: User) -> User:
        user.email_verified = True
        return await self.update(user)
