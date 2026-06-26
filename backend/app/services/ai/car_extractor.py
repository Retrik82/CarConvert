"""Extract a user's vehicle from a photo as a transparent PNG cutout."""

import base64
import logging

from app.config import get_settings
from app.services.ai.cutout_validator import validate_cutout
from app.services.ai.model_router import call_generate_image
from app.utils.debug_log import agent_log

logger = logging.getLogger(__name__)
settings = get_settings()

CAR_EXTRACT_SYSTEM_PROMPT = (
    "You are an automotive photo isolation specialist.\n\n"
    "Goal:\n"
    "Extract ONLY the vehicle from the provided photograph.\n\n"
    "Rules:\n"
    "- Output a PNG with a fully transparent background.\n"
    "- Preserve the exact vehicle: body shape, paint, wheels, headlights, grille, "
    "windows, reflections, proportions, license plates, badges, and all text on the car.\n"
    "- Remove all background, sky, ground, people, and non-vehicle objects.\n"
    "- Do not alter, enhance, recolor, blur, or regenerate any car pixel.\n"
    "- Keep license plate numbers and letters exactly as photographed.\n"
    "- Do not add floor shadows outside the vehicle silhouette.\n"
    "- Do not add text or watermarks.\n"
    "- If no vehicle is visible, return the closest vehicle region only."
)

CAR_EXTRACT_USER_PROMPT = (
    "Extract the car from this photo. "
    "Return PNG with transparent background. "
    "Keep every vehicle detail exactly as photographed, including license plate text and badges."
)

INTERIOR_EXTRACT_USER_PROMPT = (
    "Extract the car interior cabin visible in this photo. "
    "Return PNG with transparent background outside the cabin glass and body. "
    "Preserve dashboard, seats, steering wheel, and trim exactly as photographed."
)


async def extract_car_cutout(
    source_data_url: str,
    api_key: str | None = None,
    *,
    angle: str = "three_quarter_left",
    force_fallback: bool = False,
) -> tuple[bytes, str]:
    """Return raw PNG bytes and mime type for the isolated vehicle or cabin."""
    user_prompt = INTERIOR_EXTRACT_USER_PROMPT if angle == "interior" else CAR_EXTRACT_USER_PROMPT
    primary = settings.cutout_model_fallback if force_fallback else settings.cutout_model
    fallback = settings.cutout_model if force_fallback else settings.cutout_model_fallback

    base64_data, mime_type = await call_generate_image(
        system_prompt=CAR_EXTRACT_SYSTEM_PROMPT,
        user_text=user_prompt,
        source_data_url=source_data_url,
        primary=primary,
        fallback=fallback,
        timeout=float(settings.process_timeout_sec),
        api_key=api_key,
    )
    image_bytes = base64.b64decode(base64_data)
    return image_bytes, mime_type or "image/png"


async def extract_car_cutout_validated(
    source_data_url: str,
    api_key: str | None = None,
    *,
    angle: str = "three_quarter_left",
) -> tuple[bytes, str]:
    """Extract cutout and retry once with fallback model if validation fails."""
    image_bytes, mime_type = await extract_car_cutout(
        source_data_url, api_key, angle=angle, force_fallback=False
    )
    ok, reason = validate_cutout(image_bytes)
    if ok:
        return image_bytes, mime_type

    image_bytes, mime_type = await extract_car_cutout(
        source_data_url, api_key, angle=angle, force_fallback=True
    )
    ok, reason = validate_cutout(image_bytes)
    if ok:
        return image_bytes, mime_type

    # region agent log
    agent_log(
        hypothesis_id="F",
        location="car_extractor.py:extract_car_cutout_validated",
        message="cutout_validation_bypassed",
        data={"angle": angle, "reason": reason, "bytes": len(image_bytes)},
    )
    # endregion
    logger.warning("Cutout validation failed (%s); continuing with model output", reason)
    return image_bytes, mime_type
