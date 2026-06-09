from collections.abc import Callable
from typing import Annotated

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.roles import Role
from app.core.security import decode_access_token
from app.db.models.user import User
from app.db.session import get_db
from app.services.auth_service import AuthService
from app.services.billing_service import BillingService
from app.services.job_service import JobService
from app.services.session_service import SessionService
from app.services.settings_service import SettingsService
from app.services.user_service import UserService

security = HTTPBearer(auto_error=False)


def get_user_service(db: AsyncSession = Depends(get_db)) -> UserService:
    return UserService(db)


def get_auth_service(db: AsyncSession = Depends(get_db)) -> AuthService:
    return AuthService(db)


def get_settings_service(db: AsyncSession = Depends(get_db)) -> SettingsService:
    return SettingsService(db)


def get_session_service(db: AsyncSession = Depends(get_db)) -> SessionService:
    return SessionService(db)


def get_job_service(db: AsyncSession = Depends(get_db)) -> JobService:
    return JobService(db)


def get_billing_service(db: AsyncSession = Depends(get_db)) -> BillingService:
    return BillingService(db)


async def get_current_user(
    credentials: HTTPAuthorizationCredentials | None = Depends(security),
    user_service: UserService = Depends(get_user_service),
) -> User:
    if not credentials or credentials.scheme.lower() != "bearer":
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Not authenticated.")
    decoded = decode_access_token(credentials.credentials)
    if not decoded:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid or expired token.")
    user_id, _role = decoded
    user = await user_service.get_by_id(user_id)
    if not user or not user.is_active:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="User not found or inactive.")
    return user


async def get_current_user_from_token(token: str, db: AsyncSession) -> User | None:
    decoded = decode_access_token(token)
    if not decoded:
        return None
    user_id, _role = decoded
    user = await UserService(db).get_by_id(user_id)
    if not user or not user.is_active:
        return None
    return user


def require_roles(*allowed: Role) -> Callable:
    allowed_set = frozenset(allowed)

    async def _checker(current_user: User = Depends(get_current_user)) -> User:
        if current_user.role_enum not in allowed_set:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Insufficient permissions.")
        return current_user

    return _checker


get_current_admin = require_roles(Role.ADMIN)
get_current_moderator = require_roles(Role.ADMIN, Role.MODERATOR)

CurrentAdmin = Annotated[User, Depends(get_current_admin)]
CurrentModerator = Annotated[User, Depends(get_current_moderator)]
