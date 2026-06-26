"""Extract a user's vehicle from a photo as a transparent PNG cutout."""

import base64
import logging

from app.config import get_settings
from app.services.ai.cutout_validator import validate_cutout
from app.services.ai.model_router import call_generate_image
from app.services.ai.prompt_blocks import CAR_EXTRACT_SYSTEM_PROMPT
from app.services.ai.prompt_builder import build_extract_user_text, ensure_prompt_compliance
from app.services.ai.vehicle_descriptor import describe_vehicle
from app.utils.debug_log import agent_log

logger = logging.getLogger(__name__)
settings = get_settings()


async def extract_car_cutout(
    source_data_url: str,
    api_key: str | None = None,
    *,
    angle: str = "three_quarter_left",
    force_fallback: bool = False,
    vehicle_descriptor: dict | None = None,
) -> tuple[bytes, str]:
    """Return raw PNG bytes and mime type for the isolated vehicle or cabin."""
    descriptor = vehicle_descriptor
    if descriptor is None:
        descriptor = await describe_vehicle(source_data_url, api_key, angle=angle)

    user_prompt = build_extract_user_text(angle=angle, vehicle_descriptor=descriptor)
    system_prompt, user_prompt = ensure_prompt_compliance(CAR_EXTRACT_SYSTEM_PROMPT, user_prompt)

    primary = settings.cutout_model_fallback if force_fallback else settings.cutout_model
    fallback = settings.cutout_model if force_fallback else settings.cutout_model_fallback

    base64_data, mime_type = await call_generate_image(
        system_prompt=system_prompt,
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
    vehicle_descriptor: dict | None = None,
) -> tuple[bytes, str]:
    """Extract cutout and retry once with fallback model if validation fails."""
    image_bytes, mime_type = await extract_car_cutout(
        source_data_url,
        api_key,
        angle=angle,
        force_fallback=False,
        vehicle_descriptor=vehicle_descriptor,
    )
    ok, reason = validate_cutout(image_bytes)
    if ok:
        return image_bytes, mime_type

    image_bytes, mime_type = await extract_car_cutout(
        source_data_url,
        api_key,
        angle=angle,
        force_fallback=True,
        vehicle_descriptor=vehicle_descriptor,
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
