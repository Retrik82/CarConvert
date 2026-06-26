import base64

import httpx

from app.config import get_settings
from app.services.ai.model_router import call_image_completion
from app.services.ai.openrouter_client import _extract_image_reference
from app.services.ai.prompt_blocks import (
    BACKGROUND_REPLACE_SYSTEM_PROMPT,
    SCENE_COMPOSITE_SYSTEM_PROMPT,
)
from app.services.ai.prompt_builder import (
    build_composite_user_text,
    build_inplace_edit_user_text,
    ensure_prompt_compliance,
)

settings = get_settings()


async def _image_from_openrouter_body(body: dict) -> tuple[str, str]:
    image_ref = _extract_image_reference(body)
    if image_ref.startswith("data:image"):
        header = image_ref.split(",", 1)[0]
        mime_type = header.replace("data:", "").replace(";base64", "")
        base64_data = image_ref.split(",", 1)[1]
        return base64_data, mime_type

    async with httpx.AsyncClient(timeout=float(settings.process_timeout_sec)) as http_client:
        image_response = await http_client.get(image_ref)
    if image_response.status_code >= 400:
        raise RuntimeError(f"Failed to download generated image ({image_response.status_code}).")
    mime_type = image_response.headers.get("Content-Type", "image/png").split(";")[0].strip()
    encoded = base64.b64encode(image_response.content).decode("utf-8")
    return encoded, mime_type


async def _composite_messages(
    user_photo_data_url: str,
    scene_prompt: str,
    scene_reference_data_url: str,
    *,
    vehicle_descriptor: dict | None = None,
) -> list[dict]:
    user_text = build_composite_user_text(scene_prompt, vehicle_descriptor=vehicle_descriptor)
    content: list[dict] = [
        {"type": "text", "text": user_text},
        {"type": "image_url", "image_url": {"url": scene_reference_data_url}},
        {"type": "image_url", "image_url": {"url": user_photo_data_url}},
    ]
    system_prompt, user_text = ensure_prompt_compliance(
        SCENE_COMPOSITE_SYSTEM_PROMPT,
        user_text,
    )
    content[0] = {"type": "text", "text": user_text}
    return [
        {"role": "system", "content": system_prompt},
        {"role": "user", "content": content},
    ]


async def replace_car_background_in_place(
    source_data_url: str,
    background_prompt: str,
    *,
    angle: str = "three_quarter_left",
    api_key: str | None = None,
    vehicle_descriptor: dict | None = None,
) -> tuple[str, str]:
    """Replace only the background while preserving the vehicle and camera angle."""
    from app.utils.image_utils import aspect_ratio_label_from_data_url

    user_text = build_inplace_edit_user_text(
        background_prompt,
        angle=angle,
        vehicle_descriptor=vehicle_descriptor,
    )
    system_prompt, user_text = ensure_prompt_compliance(
        BACKGROUND_REPLACE_SYSTEM_PROMPT,
        user_text,
    )
    content: list[dict] = [
        {"type": "text", "text": user_text},
        {"type": "image_url", "image_url": {"url": source_data_url}},
    ]

    messages = [
        {"role": "system", "content": system_prompt},
        {"role": "user", "content": content},
    ]
    body = await call_image_completion(
        messages,
        primary=settings.inplace_background_model,
        fallback=settings.inplace_background_model_fallback,
        timeout=float(settings.process_timeout_sec),
        api_key=api_key,
        preserve_source_framing=True,
        aspect_ratio=aspect_ratio_label_from_data_url(source_data_url),
    )
    return await _image_from_openrouter_body(body)


async def process_into_scene(
    user_photo_data_url: str,
    scene_prompt: str,
    scene_reference_data_url: str,
    api_key: str | None = None,
    *,
    vehicle_descriptor: dict | None = None,
) -> tuple[str, str]:
    """Put the user's car into the reference composed scene (room + placeholder BMW)."""
    messages = await _composite_messages(
        user_photo_data_url,
        scene_prompt,
        scene_reference_data_url,
        vehicle_descriptor=vehicle_descriptor,
    )
    body = await call_image_completion(
        messages,
        primary=settings.composite_primary,
        fallback=settings.composite_model_fallback,
        timeout=float(settings.process_timeout_sec),
        api_key=api_key,
    )
    return await _image_from_openrouter_body(body)


async def generate_full_scene(prompt: str, api_key: str | None = None) -> tuple[str, str]:
    """Generate a complete photorealistic scene (environment + BMW on podium) in one pass."""
    messages = [
        {
            "role": "system",
            "content": (
                "Generate a single unified photorealistic automotive photograph. "
                "The car, studio/garage environment, podium platform, lighting, and shadows "
                "must be one coherent realistic image — not a cutout pasted on a background. "
                "No text, watermarks, or people."
            ),
        },
        {"role": "user", "content": prompt},
    ]
    body = await call_image_completion(
        messages,
        primary=settings.composite_primary,
        fallback=settings.composite_model_fallback,
        timeout=float(settings.process_timeout_sec),
        api_key=api_key,
    )
    return await _image_from_openrouter_body(body)


async def generate_empty_room(prompt: str, api_key: str | None = None) -> tuple[str, str]:
    """Generate an empty studio room (no car) for custom background creation."""
    messages = [
        {
            "role": "system",
            "content": (
                "Generate a photorealistic empty automotive studio environment. "
                "No vehicles, no people, no text, no watermarks. "
                "Landscape 16:9, ready for a car photoshoot."
            ),
        },
        {"role": "user", "content": prompt},
    ]
    body = await call_image_completion(
        messages,
        primary=settings.composite_primary,
        fallback=settings.composite_model_fallback,
        timeout=float(settings.process_timeout_sec),
        api_key=api_key,
    )
    return await _image_from_openrouter_body(body)


# Backward-compatible aliases
generate_empty_background = generate_empty_room
