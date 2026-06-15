"""Cut out the user's car and composite it onto the selected background."""

from __future__ import annotations

import base64
import io
import logging
import tempfile
from dataclasses import dataclass
from pathlib import Path

from PIL import Image

from app.config import get_settings
from app.db.models.background import ANGLE_PROMPT_SUFFIXES
from app.services.ai.background_processor import generate_empty_room, generate_outdoor_scene
from app.services.ai.car_extractor import extract_car_cutout
from app.services.ai.openrouter_client import OpenRouterClient, _extract_image_reference
from app.services.background_asset_service import PRESET_SLUGS
from app.services.preset_background_renderer import render_preset_background
from app.services.scene_compositor import composite_car_on_room
from app.utils.image_utils import to_data_url

logger = logging.getLogger(__name__)
settings = get_settings()

CUTOUT_COMPOSITE_SYSTEM_PROMPT = (
    "You are an automotive compositing specialist.\n\n"
    "Goal:\n"
    "Place the user's vehicle cutout into the target scene.\n\n"
    "Rules:\n"
    "- Image 1 is the BACKGROUND SCENE — keep walls, floor, podium, lighting, "
    "perspective, and camera angle exactly unchanged.\n"
    "- Image 2 is the USER VEHICLE CUTOUT (transparent PNG) — preserve it exactly.\n"
    "- Replace any placeholder car in the scene with the user's vehicle.\n"
    "- Match scene lighting, scale, and contact shadows for a seamless photorealistic result.\n"
    "- Do not modify the vehicle body, paint, wheels, or proportions.\n"
    "- Do not add text or watermarks."
)


@dataclass(frozen=True)
class ResolvedBackground:
    prompt: str
    angle: str
    preset_slug: str | None = None
    reference_data_url: str | None = None
    is_outdoor: bool = False


def _encode_image(image: Image.Image, mime_type: str = "image/jpeg") -> tuple[str, str]:
    buffer = io.BytesIO()
    if mime_type == "image/png":
        image.save(buffer, format="PNG", optimize=True)
    else:
        image.convert("RGB").save(buffer, format="JPEG", quality=92, optimize=True)
        mime_type = "image/jpeg"
    return base64.b64encode(buffer.getvalue()).decode("utf-8"), mime_type


def _render_preset_room(preset_slug: str, angle: str) -> Image.Image:
    with tempfile.NamedTemporaryFile(suffix=".jpg", delete=False) as tmp:
        tmp_path = Path(tmp.name)
    try:
        render_preset_background(preset_slug, tmp_path, angle)
        return Image.open(tmp_path).convert("RGB")
    finally:
        tmp_path.unlink(missing_ok=True)


async def _ai_composite_cutout_on_scene(
    cutout_data_url: str,
    scene_data_url: str,
    scene_prompt: str,
    api_key: str,
) -> tuple[str, str]:
    client = OpenRouterClient(api_key)
    user_text = (
        "Image 1 — BACKGROUND SCENE: target environment. Keep it exactly as shown.\n"
        "Image 2 — USER VEHICLE: transparent cutout to place into the scene.\n"
        f"Scene description: {scene_prompt}\n"
        "Replace the placeholder car (if any) with the user's vehicle. "
        "Match lighting and scale. Photorealistic composite."
    )
    content: list[dict] = [
        {"type": "text", "text": user_text},
        {"type": "image_url", "image_url": {"url": scene_data_url}},
        {"type": "image_url", "image_url": {"url": cutout_data_url}},
    ]
    messages = [
        {"role": "system", "content": CUTOUT_COMPOSITE_SYSTEM_PROMPT},
        {"role": "user", "content": content},
    ]
    body = await client.chat_completion(
        settings.process_model,
        messages,
        timeout=float(settings.process_timeout_sec),
        max_tokens=1024,
    )
    image_ref = _extract_image_reference(body)
    if image_ref.startswith("data:image"):
        header = image_ref.split(",", 1)[0]
        mime_type = header.replace("data:", "").replace(";base64", "")
        base64_data = image_ref.split(",", 1)[1]
        return base64_data, mime_type

    import httpx

    async with httpx.AsyncClient(timeout=float(settings.process_timeout_sec)) as http_client:
        image_response = await http_client.get(image_ref)
    if image_response.status_code >= 400:
        raise RuntimeError(f"Failed to download composite image ({image_response.status_code}).")
    mime_type = image_response.headers.get("Content-Type", "image/png").split(";")[0].strip()
    encoded = base64.b64encode(image_response.content).decode("utf-8")
    return encoded, mime_type


async def process_user_car_photo(
    source_data_url: str,
    resolved: ResolvedBackground,
    api_key: str,
) -> tuple[str, str]:
    """
    Pipeline:
    1. Extract vehicle cutout from user photo.
    2. Resolve target background (procedural preset room, reference scene, or generated scene).
    3. Composite cutout onto background (programmatic for studio presets, AI for others).
    """
    logger.info(
        "Processing user car: angle=%s preset=%s outdoor=%s",
        resolved.angle,
        resolved.preset_slug,
        resolved.is_outdoor,
    )

    cutout_bytes, cutout_mime = await extract_car_cutout(source_data_url, api_key)
    cutout_data_url = to_data_url(cutout_bytes, cutout_mime or "image/png")
    car_image = Image.open(io.BytesIO(cutout_bytes)).convert("RGBA")

    # Studio preset — procedural empty room + deterministic composite.
    if (
        resolved.preset_slug
        and resolved.preset_slug in PRESET_SLUGS
        and resolved.angle != "interior"
    ):
        room = _render_preset_room(resolved.preset_slug, resolved.angle)
        result = composite_car_on_room(room, car_image, resolved.angle)
        return _encode_image(result)

    # Interior or custom/user backgrounds — AI composite with reference or generated scene.
    if resolved.angle == "interior" or resolved.reference_data_url:
        scene_url = resolved.reference_data_url
        if scene_url is None:
            room_b64, room_mime = await generate_empty_room(
                f"{resolved.prompt} Interior cabin view, no people, no vehicle.",
                api_key,
            )
            scene_url = f"data:{room_mime};base64,{room_b64}"
        return await _ai_composite_cutout_on_scene(
            cutout_data_url,
            scene_url,
            resolved.prompt,
            api_key,
        )

    # Outdoor / default desert — generate scene then AI composite.
    if resolved.is_outdoor:
        from app.services.ai.desert_processor import DESERT_USER_PROMPT

        outdoor_prompt = resolved.prompt or DESERT_USER_PROMPT
        scene_b64, scene_mime = await generate_outdoor_scene(
            f"{outdoor_prompt} Empty environment, no vehicle, no people.",
            api_key,
        )
    else:
        angle_suffix = ANGLE_PROMPT_SUFFIXES.get(resolved.angle, "")
        scene_b64, scene_mime = await generate_empty_room(
            f"{resolved.prompt} {angle_suffix} Empty studio, no vehicle.",
            api_key,
        )

    scene_url = f"data:{scene_mime};base64,{scene_b64}"
    return await _ai_composite_cutout_on_scene(
        cutout_data_url,
        scene_url,
        resolved.prompt,
        api_key,
    )
