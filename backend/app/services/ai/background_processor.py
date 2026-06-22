import base64

import httpx

from app.config import get_settings
from app.services.ai.openrouter_client import OpenRouterClient, _extract_image_reference

settings = get_settings()

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


async def process_into_scene(
    user_photo_data_url: str,
    scene_prompt: str,
    scene_reference_data_url: str,
    api_key: str | None = None,
) -> tuple[str, str]:
    """Put the user's car into the reference composed scene (room + placeholder BMW)."""
    client = OpenRouterClient(api_key)
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

    messages = [
        {"role": "system", "content": SCENE_COMPOSITE_SYSTEM_PROMPT},
        {"role": "user", "content": content},
    ]
    body = await client.generate_image_completion(
        settings.process_model,
        messages,
        timeout=float(settings.process_timeout_sec),
    )
    return await _image_from_openrouter_body(body)


async def generate_full_scene(prompt: str, api_key: str | None = None) -> tuple[str, str]:
    """Generate a complete photorealistic scene (environment + BMW on podium) in one pass."""
    client = OpenRouterClient(api_key)
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
    body = await client.generate_image_completion(
        settings.process_model,
        messages,
        timeout=float(settings.process_timeout_sec),
    )
    return await _image_from_openrouter_body(body)


async def generate_outdoor_scene(prompt: str, api_key: str | None = None) -> tuple[str, str]:
    """Generate an empty outdoor environment (no car) for compositing."""
    client = OpenRouterClient(api_key)
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
    body = await client.generate_image_completion(
        settings.process_model,
        messages,
        timeout=float(settings.process_timeout_sec),
    )
    return await _image_from_openrouter_body(body)


async def generate_empty_room(prompt: str, api_key: str | None = None) -> tuple[str, str]:
    """Generate an empty studio room (no car) for custom background creation."""
    client = OpenRouterClient(api_key)
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
    body = await client.generate_image_completion(
        settings.process_model,
        messages,
        timeout=float(settings.process_timeout_sec),
    )
    return await _image_from_openrouter_body(body)


# Backward-compatible aliases
generate_empty_background = generate_empty_room
