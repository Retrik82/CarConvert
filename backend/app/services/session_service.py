from sqlalchemy.ext.asyncio import AsyncSession

from app.db.models.camera_session import CameraSession
from app.repositories.camera_session_repository import CameraSessionRepository


class SessionService:
    def __init__(self, db: AsyncSession) -> None:
        self._sessions = CameraSessionRepository(db)

    async def create_camera_session(self, user_id: str, ttl_hours: int = 2) -> CameraSession:
        return await self._sessions.create(user_id, ttl_hours=ttl_hours)

    async def get_active_session(self, session_id: str, user_id: str) -> CameraSession | None:
        return await self._sessions.get_active_for_user(session_id, user_id)


async def create_camera_session(db: AsyncSession, user_id: str, ttl_hours: int = 2) -> CameraSession:
    return await SessionService(db).create_camera_session(user_id, ttl_hours=ttl_hours)


async def get_active_session(db: AsyncSession, session_id: str, user_id: str) -> CameraSession | None:
    return await SessionService(db).get_active_session(session_id, user_id)
