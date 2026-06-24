from functools import lru_cache
from pathlib import Path

from pydantic import field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict

BASE_DIR = Path(__file__).resolve().parent.parent
DEFAULT_SQLITE_URL = f"sqlite+aiosqlite:///{BASE_DIR / 'data' / 'carconvert.db'}"


def _default_database_url() -> str:
    return DEFAULT_SQLITE_URL


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=str(BASE_DIR / ".env"),
        env_file_encoding="utf-8",
        extra="ignore",
    )

    openrouter_api_key: str = ""
    port: int = 3001
    cors_origins: str = "http://localhost:5173,*"
    database_url: str = _default_database_url()
    redis_url: str = ""

    @field_validator("database_url", mode="before")
    @classmethod
    def normalize_database_url(cls, value: object) -> str:
        if value is None:
            return _default_database_url()
        url = str(value).strip()
        if not url:
            return _default_database_url()
        return url

    jwt_secret: str = "change_me_to_random_32_char_string_minimum"
    jwt_access_expire_min: int = 15
    jwt_refresh_expire_days: int = 30
    auth_rate_limit_login_max: int = 10
    auth_rate_limit_login_window_sec: int = 60
    auth_rate_limit_refresh_max: int = 30
    auth_rate_limit_refresh_window_sec: int = 60
    password_reset_expire_hours: int = 24

    # Legacy aliases (backward compatible)
    hint_model: str = "rekaai/reka-edge"
    process_model: str = "google/gemini-3.1-flash-image-preview"

    # Hints (camera)
    hint_model_primary: str = ""
    hint_model_fallback: str = "google/gemini-2.5-flash-lite"

    # Pose / angle
    pose_model: str = "google/gemini-2.5-flash-lite"
    pose_model_fallback: str = "rekaai/reka-edge"
    pose_timeout_sec: int = 10

    # Cutout
    cutout_model: str = "google/gemini-2.5-flash-image"
    cutout_model_fallback: str = "google/gemini-3.1-flash-image-preview"

    # Composite
    composite_model: str = ""
    composite_model_fallback: str = "google/gemini-2.5-flash-image"
    composite_model_premium: str = "google/gemini-3-pro-image-preview"

    hint_timeout_sec: int = 15
    process_timeout_sec: int = 120
    max_preview_bytes: int = 512_000
    upload_dir: str = str(BASE_DIR / "data" / "uploads")

    # Load / queue
    hint_max_concurrent: int = 8
    process_max_concurrent: int = 3
    openrouter_max_retries: int = 2
    process_job_deadline_sec: int = 300
    max_queue_size: int = 50
    max_active_jobs_per_user: int = 2
    photo_rate_limit_max: int = 10
    photo_rate_limit_window_sec: int = 60

    @property
    def cors_origin_list(self) -> list[str]:
        return [o.strip() for o in self.cors_origins.split(",") if o.strip()]

    @property
    def hint_primary(self) -> str:
        return self.hint_model_primary or self.hint_model

    @property
    def composite_primary(self) -> str:
        return self.composite_model or self.process_model

    @property
    def redis_enabled(self) -> bool:
        return bool(self.redis_url.strip())


@lru_cache
def get_settings() -> Settings:
    return Settings()
