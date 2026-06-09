from datetime import datetime, timezone

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import hash_token
from app.db.models.user import PasswordResetToken


class PasswordResetRepository:
    def __init__(self, db: AsyncSession) -> None:
        self._db = db

    async def create(self, user_id: str, raw_token: str, expires_at: datetime) -> PasswordResetToken:
        record = PasswordResetToken(
            user_id=user_id,
            token_hash=hash_token(raw_token),
            expires_at=expires_at,
        )
        self._db.add(record)
        await self._db.flush()
        return record

    async def find_valid_by_raw(self, raw_token: str) -> PasswordResetToken | None:
        target_hash = hash_token(raw_token)
        result = await self._db.execute(
            select(PasswordResetToken).where(
                PasswordResetToken.token_hash == target_hash,
                PasswordResetToken.used.is_(False),
                PasswordResetToken.expires_at > datetime.now(timezone.utc),
            )
        )
        return result.scalar_one_or_none()

    async def mark_used(self, record: PasswordResetToken) -> None:
        record.used = True
        await self._db.flush()
