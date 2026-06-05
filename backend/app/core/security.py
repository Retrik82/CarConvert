import hashlib
import secrets
import uuid
from datetime import datetime, timedelta, timezone

import bcrypt
from jose import JWTError, jwt

from app.config import get_settings
from app.core.roles import Role

settings = get_settings()


def hash_password(password: str) -> str:
    return bcrypt.hashpw(password.encode("utf-8"), bcrypt.gensalt()).decode("utf-8")


def verify_password(plain: str, hashed: str) -> bool:
    return bcrypt.checkpw(plain.encode("utf-8"), hashed.encode("utf-8"))


def create_access_token(user_id: str, role: Role) -> str:
    now = datetime.now(timezone.utc)
    expire = now + timedelta(minutes=settings.jwt_access_expire_min)
    payload = {
        "sub": user_id,
        "type": "access",
        "role": role.value,
        "iat": now,
        "jti": str(uuid.uuid4()),
        "exp": expire,
    }
    return jwt.encode(payload, settings.jwt_secret, algorithm="HS256")


def decode_access_token(token: str) -> tuple[str, Role] | None:
    try:
        payload = jwt.decode(token, settings.jwt_secret, algorithms=["HS256"])
        if payload.get("type") != "access":
            return None
        sub = payload.get("sub")
        if not sub:
            return None
        role_raw = payload.get("role", Role.USER.value)
        try:
            role = Role(role_raw)
        except ValueError:
            role = Role.USER
        return str(sub), role
    except JWTError:
        return None


def create_refresh_token_value() -> str:
    return secrets.token_urlsafe(48)


def hash_token(token: str) -> str:
    return hashlib.sha256(token.encode("utf-8")).hexdigest()


def create_password_reset_token() -> str:
    return secrets.token_urlsafe(32)
