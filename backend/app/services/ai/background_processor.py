import base64

import httpx

from app.config import get_settings
from app.services.ai.model_router import call_image_completion
from app.services.ai.openrouter_client import _extract_image_reference
from app.services.ai.prompt_blocks import (
    BACKGROUND_REPLACE_SYSTEM_PROMPT,
    SCENE_COMPOSITE_SYSTEM_PROMPT,
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
) -> list[dict]:
    user_text = (
        "Image 1 — REFERENCE SCENE: fixed studio room with a placeholder car. "
        "Keep this room, camera angle, lighting, floor, podium, and shadows exactly as shown. "
        "Image 2 — USER VEHICLE: the car to place into the reference scene. "
        f"Scene description: {scene_prompt} "
        "Replace only the car in the reference with the user's vehicle. "
        "Do not change the room or perspective. Photorealistic result."
    )
    content: list[dict] = [
        {"type": "text", "text": user_text},
        {"type": "image_url", "image_url": {"url": scene_reference_data_url}},
        {"type": "image_url", "image_url": {"url": user_photo_data_url}},
    ]
    return [
        {"role": "system", "content": SCENE_COMPOSITE_SYSTEM_PROMPT},
        {"role": "user", "content": content},
    ]


def build_inplace_edit_user_text(
    background_prompt: str,
    *,
    angle: str = "three_quarter_left",
) -> str:
    if angle == "interior":
        vehicle_rule = (
            "Keep the cabin interior, dashboard, seats, steering wheel, and trim exactly as photographed. "
            "Replace only the environment visible outside the windows."
        )
    else:
        vehicle_rule = (
            "Keep the vehicle and original camera viewpoint exactly as photographed. "
            "Replace only the environment behind and around the car."
        )

    return (
        "SOURCE PHOTO (attached below): edit this photograph in place.\n"
        f"New background environment: {background_prompt}\n"
        f"{vehicle_rule} "
        "Do not change the vehicle model, color, body, wheels, or shooting angle. "
        "Do not generate a new car or a new camera angle."
    )


async def replace_car_background_in_place(
    source_data_url: str,
    background_prompt: str,
    *,
    angle: str = "three_quarter_left",
    api_key: str | None = None,
) -> tuple[str, str]:
    """Replace only the background while preserving the vehicle and camera angle."""
    from app.utils.image_utils import aspect_ratio_label_from_data_url

    user_text = build_inplace_edit_user_text(
        background_prompt,
        angle=angle,
    )
    content: list[dict] = [
        {"type": "text", "text": user_text},
        {"type": "image_url", "image_url": {"url": source_data_url}},
    ]

    messages = [
        {"role": "system", "content": BACKGROUND_REPLACE_SYSTEM_PROMPT},
        {"role": "user", "content": content},
    ]
    body = await call_image_completion(
        messages,
        primary=settings.composite_primary,
        fallback=settings.composite_model_fallback,
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
) -> tuple[str, str]:
    """Put the user's car into the reference composed scene (room + placeholder BMW)."""
    messages = await _composite_messages(user_photo_data_url, scene_prompt, scene_reference_data_url)
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
