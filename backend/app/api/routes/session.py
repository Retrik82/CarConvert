from fastapi import APIRouter, Depends

from app.api.deps import get_current_user, get_session_service
from app.db.models.user import User
from app.models.schemas import SessionStartResponse
from app.services.session_service import SessionService

router = APIRouter(prefix="/session", tags=["session"])


@router.post("/start", response_model=SessionStartResponse)
async def start_session(
    current_user: User = Depends(get_current_user),
    session_service: SessionService = Depends(get_session_service),
) -> SessionStartResponse:
    session = await session_service.create_camera_session(current_user.id)
    return SessionStartResponse(session_id=session.id, expires_at=session.expires_at)
