from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user
from app.db.models.user import User
from app.db.session import get_db
from app.models.schemas import SessionStartResponse
from app.services.session_service import create_camera_session

router = APIRouter(prefix="/session", tags=["session"])


@router.post("/start", response_model=SessionStartResponse)
async def start_session(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> SessionStartResponse:
    session = await create_camera_session(db, current_user.id)
    await db.commit()
    return SessionStartResponse(session_id=session.id, expires_at=session.expires_at)
