from decimal import Decimal

from sqlalchemy.ext.asyncio import AsyncSession

from app.core.roles import Role
from app.core.security import hash_password
from app.db.models.app_config import INITIAL_USER_BALANCE
from app.db.models.user import User
from app.repositories.user_repository import UserRepository


class UserService:
    def __init__(self, db: AsyncSession) -> None:
        self._users = UserRepository(db)

    async def get_by_id(self, user_id: str) -> User | None:
        return await self._users.get_by_id(user_id)

    async def get_by_email(self, email: str) -> User | None:
        return await self._users.get_by_email(email)

    async def get_by_login(self, login: str) -> User | None:
        normalized = login.strip().lower()
        if normalized == "admin":
            return await self._users.get_admin_user()
        return await self._users.get_by_email(normalized)

    async def create_user(
        self,
        email: str,
        password: str,
        display_name: str,
        *,
        role: Role = Role.USER,
    ) -> User:
        user = User(
            email=email.lower(),
            password_hash=hash_password(password),
            display_name=display_name,
            balance=INITIAL_USER_BALANCE,
            role=role.value,
            is_admin=role == Role.ADMIN,
            email_verified=False,
        )
        return await self._users.add(user)

    def to_user_out_fields(self, user: User) -> dict:
        user.sync_legacy_admin_flag()
        return {
            "id": user.id,
            "email": user.email,
            "display_name": user.display_name,
            "balance": user.balance,
            "role": user.role_enum.value,
            "is_admin": user.role_enum == Role.ADMIN,
            "email_verified": user.email_verified,
            "created_at": user.created_at,
        }
