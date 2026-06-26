from app.config import get_settings
from app.services.ai.background_processor import (
    BACKGROUND_REPLACE_SYSTEM_PROMPT,
    build_inplace_edit_user_text,
)
from app.services.ai.model_router import call_generate_image
from app.utils.image_utils import sanitize_inplace_background_prompt

settings = get_settings()


async def edit_car_background_custom(
    user_prompt: str, source_data_url: str, api_key: str | None = None
) -> tuple[str, str]:
    environment = sanitize_inplace_background_prompt(user_prompt)
    return await call_generate_image(
        system_prompt=BACKGROUND_REPLACE_SYSTEM_PROMPT,
        user_text=build_inplace_edit_user_text(environment),
        source_data_url=source_data_url,
        primary=settings.composite_primary,
        fallback=settings.composite_model_fallback,
        timeout=float(settings.process_timeout_sec),
        api_key=api_key,
    )
