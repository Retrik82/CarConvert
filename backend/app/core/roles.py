from enum import StrEnum


class Role(StrEnum):
    USER = "user"
    ADMIN = "admin"
    MODERATOR = "moderator"

    @classmethod
    def from_legacy_admin(cls, is_admin: bool) -> Role:
        return cls.ADMIN if is_admin else cls.USER


ADMIN_ROLES = frozenset({Role.ADMIN})
MODERATOR_ROLES = frozenset({Role.ADMIN, Role.MODERATOR})
