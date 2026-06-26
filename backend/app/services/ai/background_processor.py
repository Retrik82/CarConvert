import base64

import httpx

from app.config import get_settings
from app.services.ai.model_router import call_image_completion
from app.services.ai.openrouter_client import _extract_image_reference

settings = get_settings()

BACKGROUND_REPLACE_SYSTEM_PROMPT = (
    "You are an automotive photo editor specializing in background replacement.\n\n"
    "Goal:\n"
    "Replace ONLY the background of the photograph. The vehicle must remain identical.\n\n"
    "Rules:\n"
    "- KEEP the exact same vehicle: make, model, color, paint finish, wheels, headlights, "
    "grille, body shape, proportions, reflections, and every visible detail.\n"
    "- KEEP the exact same camera angle, perspective, focal length, framing, and vehicle "
    "position in the frame.\n"
    "- KEEP the exact same vehicle orientation relative to the camera.\n"
    "- Replace ONLY background pixels: sky, ground, walls, buildings, scenery, and environment.\n"
    "- Match new background lighting and shadows to the existing vehicle naturally.\n"
    "- Do not regenerate, restyle, substitute, swap, rotate, reposition, or resize the vehicle.\n"
    "- Do not copy any vehicle from a reference image — use references for environment style only.\n"
    "- Do not add text or watermarks.\n"
    "- Photorealistic seamless result."
)

SCENE_COMPOSITE_SYSTEM_PROMPT = (
    "You place a user's vehicle into a fixed automotive studio photograph. "
    "The reference image shows the target room, lighting, floor, podium, shadows, and camera angle. "
    "Keep the environment in the reference EXACTLY unchanged — same walls, floor, podium, perspective, and light. "
    "Replace ONLY the car in the reference with the user's vehicle from their photo. "
    "Preserve the user's car body shape, paint, wheels, headlights, grille, and proportions exactly. "
    "Seamless photorealistic composite. No text or watermarks."
)


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


def _build_background_replace_user_text(
    background_prompt: str,
    *,
    angle: str,
    style_reference_data_url: str | None = None,
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

    text = (
        f"Background instructions: {background_prompt}\n"
        f"{vehicle_rule} "
        "Do not change the vehicle model, color, or shooting angle."
    )
    if style_reference_data_url:
        text += (
            " A reference scene image is attached for environment style, colors, and lighting only. "
            "Do not copy any vehicle or camera angle from the reference."
        )
    return text


async def replace_car_background_in_place(
    source_data_url: str,
    background_prompt: str,
    *,
    angle: str = "three_quarter_left",
    style_reference_data_url: str | None = None,
    api_key: str | None = None,
) -> tuple[str, str]:
    """Replace only the background while preserving the vehicle and camera angle."""
    user_text = _build_background_replace_user_text(
        background_prompt,
        angle=angle,
        style_reference_data_url=style_reference_data_url,
    )
    content: list[dict] = [{"type": "text", "text": user_text}]
    if style_reference_data_url:
        content.append({"type": "image_url", "image_url": {"url": style_reference_data_url}})
    content.append({"type": "image_url", "image_url": {"url": source_data_url}})

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


async def generate_outdoor_scene(prompt: str, api_key: str | None = None) -> tuple[str, str]:
    """Generate an empty outdoor environment (no car) for compositing."""
    messages = [
        {
            "role": "system",
            "content": (
                "Generate a photorealistic outdoor automotive photography environment. "
                "No vehicles, no people, no text, no watermarks. "
                "Landscape 16:9, natural lighting, ready for a car photoshoot."
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
