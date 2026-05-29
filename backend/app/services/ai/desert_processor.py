from app.config import get_settings
from app.services.ai.openrouter_client import OpenRouterClient

settings = get_settings()

DESERT_SYSTEM_PROMPT = (
    "Keep the exact same vehicle. "
    "Do not modify body shape, wheels, headlights, paint, reflections, or proportions. "
    "Only replace the background. "
    "Preserve the exact car. "
    "Photorealistic result."
)

DESERT_USER_PROMPT = (
    "Replace the background with a premium cinematic desert ONLY. "
    "Sand dunes, dry horizon, soft sunlight, atmospheric haze. "
    "Match lighting and natural shadows. No buildings, other cars, text, or artifacts. "
    "The desert must surround the car on all sides."
)


async def process_desert_background(source_data_url: str, api_key: str | None = None) -> tuple[str, str]:
    client = OpenRouterClient(api_key)
    return await client.generate_image(
        model=settings.process_model,
        system_prompt=DESERT_SYSTEM_PROMPT,
        user_text=DESERT_USER_PROMPT,
        source_data_url=source_data_url,
        timeout=float(settings.process_timeout_sec),
    )


async def edit_car_background_custom(
    user_prompt: str, source_data_url: str, api_key: str | None = None
) -> tuple[str, str]:
    client = OpenRouterClient(api_key)
    return await client.generate_image(
        model=settings.process_model,
        system_prompt=DESERT_SYSTEM_PROMPT,
        user_text=f"Background instructions: {user_prompt}",
        source_data_url=source_data_url,
        timeout=float(settings.process_timeout_sec),
    )
