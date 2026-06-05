from fastapi import APIRouter, Depends, HTTPException, Request, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user
from app.db.models.user import User
from app.db.session import get_db
from app.middleware.rate_limit import enforce_login_rate_limit, enforce_refresh_rate_limit
from app.models.schemas import (
    AuthResponse,
    ForgotPasswordRequest,
    LoginRequest,
    LogoutAllRequest,
    RefreshRequest,
    RegisterRequest,
    ResetPasswordRequest,
    SessionOut,
    SessionsResponse,
    UserOut,
)
from app.services.auth_service import AuthService, DeviceInfo
from app.services.user_service import UserService

router = APIRouter(prefix="/auth", tags=["auth"])


def _device_from_request(request: Request, payload: LoginRequest | RegisterRequest) -> DeviceInfo:
    return DeviceInfo(
        device_id=payload.device_id or request.headers.get("x-device-id"),
        device_name=payload.device_name or request.headers.get("x-device-name"),
        user_agent=request.headers.get("user-agent"),
    )


async def _build_user_out(db: AsyncSession, user: User) -> UserOut:
    return UserOut(**UserService(db).to_user_out_fields(user))


async def _build_auth_response(db: AsyncSession, user: User, tokens) -> AuthResponse:
    return AuthResponse(
        access_token=tokens.access_token,
        refresh_token=tokens.refresh_token,
        session_id=tokens.session_id,
        user=await _build_user_out(db, user),
    )


@router.post("/register", response_model=AuthResponse)
async def register(
    request: Request,
    payload: RegisterRequest,
    db: AsyncSession = Depends(get_db),
) -> AuthResponse:
    enforce_login_rate_limit(request)
    email = payload.email.lower()
    if email in {"admin", "admin@admin.com"}:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="This email is reserved.")
    user_service = UserService(db)
    if await user_service.get_by_email(email):
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Email already registered.")
    auth = AuthService(db)
    user, tokens = await auth.register(
        payload.email,
        payload.password,
        payload.display_name,
        _device_from_request(request, payload),
    )
    return await _build_auth_response(db, user, tokens)


@router.post("/login", response_model=AuthResponse)
async def login(
    request: Request,
    payload: LoginRequest,
    db: AsyncSession = Depends(get_db),
) -> AuthResponse:
    enforce_login_rate_limit(request)
    auth = AuthService(db)
    result = await auth.login(payload.email, payload.password, _device_from_request(request, payload))
    if not result:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid email or password.")
    user, tokens = result
    return await _build_auth_response(db, user, tokens)


@router.post("/refresh", response_model=AuthResponse)
async def refresh(
    request: Request,
    payload: RefreshRequest,
    db: AsyncSession = Depends(get_db),
) -> AuthResponse:
    enforce_refresh_rate_limit(request)
    auth = AuthService(db)
    device = DeviceInfo(
        device_id=request.headers.get("x-device-id"),
        device_name=request.headers.get("x-device-name"),
        user_agent=request.headers.get("user-agent"),
    )
    result = await auth.refresh(payload.refresh_token, device)
    if not result:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid or expired refresh token.")
    user, tokens = result
    return await _build_auth_response(db, user, tokens)


@router.post("/logout")
async def logout(payload: RefreshRequest, db: AsyncSession = Depends(get_db)) -> dict[str, str]:
    await AuthService(db).logout(payload.refresh_token)
    return {"status": "ok"}


@router.post("/logout-all")
async def logout_all(
    request: Request,
    payload: LogoutAllRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> dict[str, str | int]:
    keep_id: str | None = None
    if payload.keep_current_session:
        keep_id = request.headers.get("x-session-id")
        if not keep_id:
            sessions = await AuthService(db).list_sessions(current_user.id)
            if sessions:
                keep_id = sessions[0].id
    count = await AuthService(db).logout_all(current_user.id, keep_session_id=keep_id)
    return {"status": "ok", "revoked_sessions": count}


@router.get("/me", response_model=UserOut)
async def me(current_user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)) -> UserOut:
    return await _build_user_out(db, current_user)


@router.get("/sessions", response_model=SessionsResponse)
async def list_sessions(
    request: Request,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> SessionsResponse:
    sessions = await AuthService(db).list_sessions(current_user.id)
    current_id = request.headers.get("x-session-id")
    items = [
        SessionOut(
            id=s.id,
            device_id=s.device_id,
            device_name=s.device_name,
            user_agent=s.user_agent,
            created_at=s.created_at,
            last_used_at=s.last_used_at,
            expires_at=s.expires_at,
            is_current=current_id == s.id if current_id else False,
        )
        for s in sessions
    ]
    return SessionsResponse(sessions=items)


@router.delete("/sessions/{session_id}")
async def revoke_session(
    session_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> dict[str, str]:
    ok = await AuthService(db).revoke_session(current_user.id, session_id)
    if not ok:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Session not found.")
    return {"status": "ok"}


@router.post("/forgot-password")
async def forgot_password(
    request: Request,
    payload: ForgotPasswordRequest,
    db: AsyncSession = Depends(get_db),
) -> dict[str, str]:
    enforce_login_rate_limit(request)
    await AuthService(db).forgot_password(payload.email.lower())
    return {"status": "ok", "message": "If the email exists, a reset link has been sent."}


@router.post("/reset-password")
async def reset_password(payload: ResetPasswordRequest, db: AsyncSession = Depends(get_db)) -> dict[str, str]:
    ok = await AuthService(db).reset_password(payload.token, payload.new_password)
    if not ok:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid or expired reset token.")
    return {"status": "ok"}


@router.post("/verify-email")
async def verify_email(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> dict[str, str]:
    await AuthService(db).verify_email(current_user.id)
    return {"status": "ok"}
