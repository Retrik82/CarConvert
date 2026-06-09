from datetime import datetime, timedelta, timezone

from sqlalchemy.ext.asyncio import AsyncSession

from app.db.models.camera_session import CameraSession


class CameraSessionRepository:
    def __init__(self, db: AsyncSession) -> None:
        self._db = db

    async def create(self, user_id: str, ttl_hours: int = 2) -> CameraSession:
        session = CameraSession(
            user_id=user_id,
            status="active",
            expires_at=datetime.now(timezone.utc) + timedelta(hours=ttl_hours),
        )
        self._db.add(session)
        await self._db.flush()
        return session

    async def get_by_id(self, session_id: str) -> CameraSession | None:
        return await self._db.get(CameraSession, session_id)

    async def get_active_for_user(self, session_id: str, user_id: str) -> CameraSession | None:
        session = await self.get_by_id(session_id)
        if not session or session.user_id != user_id:
            return None
        if session.status != "active":
            return None
        expires = session.expires_at
        if expires.tzinfo is None:
            expires = expires.replace(tzinfo=timezone.utc)
        if expires < datetime.now(timezone.utc):
            return None
        return session
