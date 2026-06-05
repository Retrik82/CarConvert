from dataclasses import dataclass
from datetime import datetime, timedelta, timezone

from sqlalchemy.ext.asyncio import AsyncSession

from app.config import get_settings
from app.core.roles import Role
from app.core.security import (
    create_access_token,
    create_password_reset_token,
    create_refresh_token_value,
    decode_access_token,
    hash_password,
    hash_token,
    verify_password,
)
from app.db.models.user import PasswordResetToken, RefreshToken, User
from app.repositories.token_repository import TokenRepository
from app.repositories.user_repository import UserRepository
from app.services.user_service import UserService

settings = get_settings()


@dataclass
class AuthTokens:
    access_token: str
    refresh_token: str
    session_id: str


@dataclass
class DeviceInfo:
    device_id: str | None = None
    device_name: str | None = None
    user_agent: str | None = None


class AuthService:
    def __init__(self, db: AsyncSession) -> None:
        self._db = db
        self._users = UserRepository(db)
        self._tokens = TokenRepository(db)
        self._user_service = UserService(db)

    async def register(
        self,
        email: str,
        password: str,
        display_name: str,
        device: DeviceInfo,
    ) -> tuple[User, AuthTokens]:
        user = await self._user_service.create_user(email, password, display_name)
        return user, await self._issue_tokens(user, device)

    async def login(self, email: str, password: str, device: DeviceInfo) -> tuple[User, AuthTokens] | None:
        user = await self._user_service.get_by_login(email)
        if not user or not verify_password(password, user.password_hash):
            return None
        if not user.is_active:
            return None
        return user, await self._issue_tokens(user, device)

    async def refresh(self, raw_refresh: str, device: DeviceInfo) -> tuple[User, AuthTokens] | None:
        record = await self._tokens.find_active_by_raw(raw_refresh)
        if not record:
            revoked = await self._tokens.find_any_by_raw(raw_refresh)
            if revoked and revoked.revoked:
                await self._tokens.revoke_all_for_user(revoked.user_id)
            return None

        user = await self._users.get_by_id(record.user_id)
        if not user or not user.is_active:
            return None

        await self._tokens.touch_last_used(record)
        await self._tokens.revoke(record)

        merged = DeviceInfo(
            device_id=device.device_id or record.device_id,
            device_name=device.device_name or record.device_name,
            user_agent=device.user_agent or record.user_agent,
        )
        return user, await self._issue_tokens(user, merged)

    async def logout(self, raw_refresh: str) -> bool:
        return await self._tokens.revoke_by_raw(raw_refresh)

    async def logout_all(self, user_id: str, *, keep_session_id: str | None = None) -> int:
        return await self._tokens.revoke_all_for_user(user_id, except_token_id=keep_session_id)

    async def list_sessions(self, user_id: str) -> list[RefreshToken]:
        return await self._tokens.list_active_sessions(user_id)

    async def revoke_session(self, user_id: str, session_id: str) -> bool:
        record = await self._tokens.get_session_for_user(user_id, session_id)
        if not record or record.revoked:
            return False
        await self._tokens.revoke(record)
        return True

    async def forgot_password(self, email: str) -> str | None:
        """Returns raw reset token when user exists (caller must deliver via email)."""
        user = await self._users.get_by_email(email)
        if not user:
            return None
        raw = create_password_reset_token()
        expires = datetime.now(timezone.utc) + timedelta(hours=settings.password_reset_expire_hours)
        self._db.add(
            PasswordResetToken(
                user_id=user.id,
                token_hash=hash_token(raw),
                expires_at=expires,
            )
        )
        await self._db.flush()
        return raw

    async def reset_password(self, raw_token: str, new_password: str) -> bool:
        target_hash = hash_token(raw_token)
        from sqlalchemy import select

        result = await self._db.execute(
            select(PasswordResetToken).where(
                PasswordResetToken.token_hash == target_hash,
                PasswordResetToken.used.is_(False),
                PasswordResetToken.expires_at > datetime.now(timezone.utc),
            )
        )
        record = result.scalar_one_or_none()
        if not record:
            return False
        user = await self._users.get_by_id(record.user_id)
        if not user:
            return False
        user.password_hash = hash_password(new_password)
        record.used = True
        await self._tokens.revoke_all_for_user(user.id)
        await self._db.flush()
        return True

    async def verify_email(self, user_id: str) -> bool:
        user = await self._users.get_by_id(user_id)
        if not user:
            return False
        user.email_verified = True
        await self._db.flush()
        return True

    async def _issue_tokens(self, user: User, device: DeviceInfo) -> AuthTokens:
        raw_refresh = create_refresh_token_value()
        record = await self._tokens.create_refresh_token(
            user.id,
            raw_refresh,
            device_id=device.device_id,
            device_name=device.device_name,
            user_agent=device.user_agent,
        )
        access = create_access_token(user.id, user.role_enum)
        return AuthTokens(
            access_token=access,
            refresh_token=raw_refresh,
            session_id=record.id,
        )


def decode_token_user_id(token: str) -> str | None:
    decoded = decode_access_token(token)
    return decoded[0] if decoded else None


def decode_token_user_and_role(token: str) -> tuple[str, Role] | None:
    return decode_access_token(token)
