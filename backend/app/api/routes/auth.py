from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user
from app.db.models.user import User
from app.db.session import get_db
from app.models.schemas import AuthResponse, LoginRequest, RefreshRequest, RegisterRequest, UserOut
from app.services.auth_service import (
    create_access_token,
    create_refresh_token_value,
    create_user,
    get_user_by_email,
    revoke_refresh_token,
    store_refresh_token,
    validate_refresh_token,
    verify_password,
)

router = APIRouter(prefix="/auth", tags=["auth"])


def _auth_response(user: User, access: str, refresh: str) -> AuthResponse:
    return AuthResponse(
        access_token=access,
        refresh_token=refresh,
        user=UserOut.model_validate(user),
    )


@router.post("/register", response_model=AuthResponse)
async def register(payload: RegisterRequest, db: AsyncSession = Depends(get_db)) -> AuthResponse:
    existing = await get_user_by_email(db, payload.email)
    if existing:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Email already registered.")
    user = await create_user(db, payload.email, payload.password, payload.display_name)
    access = create_access_token(user.id)
    refresh = create_refresh_token_value()
    await store_refresh_token(db, user.id, refresh)
    await db.commit()
    return _auth_response(user, access, refresh)


@router.post("/login", response_model=AuthResponse)
async def login(payload: LoginRequest, db: AsyncSession = Depends(get_db)) -> AuthResponse:
    user = await get_user_by_email(db, payload.email)
    if not user or not verify_password(payload.password, user.password_hash):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid email or password.")
    access = create_access_token(user.id)
    refresh = create_refresh_token_value()
    await store_refresh_token(db, user.id, refresh)
    await db.commit()
    return _auth_response(user, access, refresh)


@router.post("/refresh", response_model=AuthResponse)
async def refresh(payload: RefreshRequest, db: AsyncSession = Depends(get_db)) -> AuthResponse:
    user = await validate_refresh_token(db, payload.refresh_token)
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid refresh token.")
    access = create_access_token(user.id)
    refresh = create_refresh_token_value()
    await store_refresh_token(db, user.id, refresh)
    await db.commit()
    return _auth_response(user, access, refresh)


@router.post("/logout")
async def logout(
    payload: RefreshRequest,
    _: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> dict[str, str]:
    await revoke_refresh_token(db, payload.refresh_token)
    await db.commit()
    return {"status": "ok"}


@router.get("/me", response_model=UserOut)
async def me(current_user: User = Depends(get_current_user)) -> UserOut:
    return UserOut.model_validate(current_user)
