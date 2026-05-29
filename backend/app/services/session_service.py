from datetime import datetime, timedelta, timezone

from sqlalchemy.ext.asyncio import AsyncSession

from app.db.models.camera_session import CameraSession


async def create_camera_session(db: AsyncSession, user_id: str, ttl_hours: int = 2) -> CameraSession:
    session = CameraSession(
        user_id=user_id,
        status="active",
        expires_at=datetime.now(timezone.utc) + timedelta(hours=ttl_hours),
    )
    db.add(session)
    await db.flush()
    return session


async def get_active_session(db: AsyncSession, session_id: str, user_id: str) -> CameraSession | None:
    session = await db.get(CameraSession, session_id)
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
