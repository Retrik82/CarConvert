from datetime import datetime, timedelta, timezone

from sqlalchemy import select, update
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import get_settings
from app.core.security import hash_token
from app.db.models.user import RefreshToken, User

settings = get_settings()


class TokenRepository:
    def __init__(self, db: AsyncSession) -> None:
        self._db = db

    async def create_refresh_token(
        self,
        user_id: str,
        raw_token: str,
        *,
        device_id: str | None = None,
        device_name: str | None = None,
        user_agent: str | None = None,
    ) -> RefreshToken:
        expires_at = datetime.now(timezone.utc) + timedelta(days=settings.jwt_refresh_expire_days)
        record = RefreshToken(
            user_id=user_id,
            token_hash=hash_token(raw_token),
            expires_at=expires_at,
            device_id=device_id,
            device_name=device_name,
            user_agent=user_agent,
        )
        self._db.add(record)
        await self._db.flush()
        return record

    async def find_active_by_raw(self, raw_token: str) -> RefreshToken | None:
        target_hash = hash_token(raw_token)
        result = await self._db.execute(
            select(RefreshToken).where(
                RefreshToken.token_hash == target_hash,
                RefreshToken.revoked.is_(False),
                RefreshToken.expires_at > datetime.now(timezone.utc),
            )
        )
        return result.scalar_one_or_none()

    async def find_any_by_raw(self, raw_token: str) -> RefreshToken | None:
        target_hash = hash_token(raw_token)
        result = await self._db.execute(select(RefreshToken).where(RefreshToken.token_hash == target_hash))
        return result.scalar_one_or_none()

    async def revoke(self, record: RefreshToken) -> None:
        record.revoked = True
        record.revoked_at = datetime.now(timezone.utc)
        await self._db.flush()

    async def revoke_by_raw(self, raw_token: str) -> bool:
        record = await self.find_any_by_raw(raw_token)
        if not record or record.revoked:
            return False
        await self.revoke(record)
        return True

    async def revoke_all_for_user(self, user_id: str, *, except_token_id: str | None = None) -> int:
        stmt = (
            update(RefreshToken)
            .where(RefreshToken.user_id == user_id, RefreshToken.revoked.is_(False))
            .values(revoked=True, revoked_at=datetime.now(timezone.utc))
        )
        if except_token_id:
            stmt = stmt.where(RefreshToken.id != except_token_id)
        result = await self._db.execute(stmt)
        await self._db.flush()
        return result.rowcount or 0

    async def touch_last_used(self, record: RefreshToken) -> None:
        record.last_used_at = datetime.now(timezone.utc)
        await self._db.flush()

    async def list_active_sessions(self, user_id: str) -> list[RefreshToken]:
        result = await self._db.execute(
            select(RefreshToken)
            .where(
                RefreshToken.user_id == user_id,
                RefreshToken.revoked.is_(False),
                RefreshToken.expires_at > datetime.now(timezone.utc),
            )
            .order_by(RefreshToken.last_used_at.desc().nullslast(), RefreshToken.created_at.desc())
        )
        return list(result.scalars().all())

    async def get_session_for_user(self, user_id: str, session_id: str) -> RefreshToken | None:
        result = await self._db.execute(
            select(RefreshToken).where(
                RefreshToken.id == session_id,
                RefreshToken.user_id == user_id,
            )
        )
        return result.scalar_one_or_none()
