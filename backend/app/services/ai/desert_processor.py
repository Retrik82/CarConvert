from app.config import get_settings
from app.services.ai.background_processor import BACKGROUND_REPLACE_SYSTEM_PROMPT
from app.services.ai.model_router import call_generate_image

settings = get_settings()

DESERT_USER_PROMPT = (
    "Replace the background with a premium cinematic desert ONLY. "
    "Sand dunes, dry horizon, soft sunlight, atmospheric haze. "
    "Match lighting and natural shadows. No buildings, other cars, text, or artifacts. "
    "The desert must surround the car on all sides."
)


async def process_desert_background(source_data_url: str, api_key: str | None = None) -> tuple[str, str]:
    return await call_generate_image(
        system_prompt=BACKGROUND_REPLACE_SYSTEM_PROMPT,
        user_text=DESERT_USER_PROMPT,
        source_data_url=source_data_url,
        primary=settings.composite_primary,
        fallback=settings.composite_model_fallback,
        timeout=float(settings.process_timeout_sec),
        api_key=api_key,
    )


async def edit_car_background_custom(
    user_prompt: str, source_data_url: str, api_key: str | None = None
) -> tuple[str, str]:
    return await call_generate_image(
        system_prompt=BACKGROUND_REPLACE_SYSTEM_PROMPT,
        user_text=f"Background instructions: {user_prompt}",
        source_data_url=source_data_url,
        primary=settings.composite_primary,
        fallback=settings.composite_model_fallback,
        timeout=float(settings.process_timeout_sec),
        api_key=api_key,
    )
