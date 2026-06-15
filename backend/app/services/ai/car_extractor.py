"""Extract a user's vehicle from a photo as a transparent PNG cutout."""

from app.config import get_settings
from app.services.ai.openrouter_client import OpenRouterClient

settings = get_settings()

CAR_EXTRACT_SYSTEM_PROMPT = (
    "You are an automotive photo isolation specialist.\n\n"
    "Goal:\n"
    "Extract ONLY the vehicle from the provided photograph.\n\n"
    "Rules:\n"
    "- Output a PNG with a fully transparent background.\n"
    "- Preserve the exact vehicle: body shape, paint, wheels, headlights, grille, "
    "windows, reflections, and proportions.\n"
    "- Remove all background, sky, ground, people, and non-vehicle objects.\n"
    "- Do not alter, enhance, recolor, or regenerate the car.\n"
    "- Do not add floor shadows outside the vehicle silhouette.\n"
    "- Do not add text or watermarks.\n"
    "- If no vehicle is visible, return the closest vehicle region only."
)

CAR_EXTRACT_USER_PROMPT = (
    "Extract the car from this photo. "
    "Return PNG with transparent background. "
    "Keep every vehicle detail exactly as photographed."
)


async def extract_car_cutout(source_data_url: str, api_key: str | None = None) -> tuple[bytes, str]:
    """Return raw PNG bytes and mime type for the isolated vehicle."""
    client = OpenRouterClient(api_key)
    base64_data, mime_type = await client.generate_image(
        model=settings.process_model,
        system_prompt=CAR_EXTRACT_SYSTEM_PROMPT,
        user_text=CAR_EXTRACT_USER_PROMPT,
        source_data_url=source_data_url,
        timeout=float(settings.process_timeout_sec),
    )
    import base64

    image_bytes = base64.b64decode(base64_data)
    return image_bytes, mime_type or "image/png"
