from app.config import get_settings
from app.services.ai.background_processor import replace_car_background_in_place
from app.utils.image_utils import sanitize_inplace_background_prompt

settings = get_settings()


async def edit_car_background_custom(
    user_prompt: str, source_data_url: str, api_key: str | None = None
) -> tuple[str, str]:
    environment = sanitize_inplace_background_prompt(user_prompt)
    return await replace_car_background_in_place(
        source_data_url,
        environment,
        api_key=api_key,
    )
