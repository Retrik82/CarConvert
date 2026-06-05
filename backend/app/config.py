from functools import lru_cache
from pathlib import Path

from pydantic_settings import BaseSettings, SettingsConfigDict

BASE_DIR = Path(__file__).resolve().parent.parent


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=str(BASE_DIR / ".env"),
        env_file_encoding="utf-8",
        extra="ignore",
    )

    openrouter_api_key: str = ""
    port: int = 3001
    cors_origins: str = "http://localhost:5173,*"
    database_url: str = f"sqlite+aiosqlite:///{BASE_DIR / 'data' / 'carconvert.db'}"
    jwt_secret: str = "change_me_to_random_32_char_string_minimum"
    jwt_access_expire_min: int = 15
    jwt_refresh_expire_days: int = 30
    auth_rate_limit_login_max: int = 10
    auth_rate_limit_login_window_sec: int = 60
    auth_rate_limit_refresh_max: int = 30
    auth_rate_limit_refresh_window_sec: int = 60
    password_reset_expire_hours: int = 24
    hint_model: str = "rekaai/reka-edge"
    process_model: str = "google/gemini-3.1-flash-image-preview"
    hint_timeout_sec: int = 15
    process_timeout_sec: int = 120
    max_preview_bytes: int = 512_000
    upload_dir: str = str(BASE_DIR / "data" / "uploads")

    @property
    def cors_origin_list(self) -> list[str]:
        return [o.strip() for o in self.cors_origins.split(",") if o.strip()]


@lru_cache
def get_settings() -> Settings:
    return Settings()
