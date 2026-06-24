"""Cut out the user's vehicle from a photo and composite onto the selected background scene."""

from __future__ import annotations

import base64
import logging
from dataclasses import dataclass
from pathlib import Path

import httpx

from app.config import get_settings
from app.db.models.background import ANGLE_PROMPT_SUFFIXES
from app.services.ai.background_processor import generate_empty_room, process_into_scene
from app.services.ai.car_extractor import extract_car_cutout_validated
from app.services.ai.model_router import call_image_completion
from app.services.ai.openrouter_client import _extract_image_reference
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
    user_background_id: str | None = None
    scene_image_path: str | None = None


async def _image_ref_to_base64(image_ref: str) -> tuple[str, str]:
    if image_ref.startswith("data:image"):
        header = image_ref.split(",", 1)[0]
        mime_type = header.replace("data:", "").replace(";base64", "")
        base64_data = image_ref.split(",", 1)[1]
        return base64_data, mime_type

    async with httpx.AsyncClient(timeout=float(settings.process_timeout_sec)) as http_client:
        image_response = await http_client.get(image_ref)
    if image_response.status_code >= 400:
        raise RuntimeError(f"Failed to download composite image ({image_response.status_code}).")
    mime_type = image_response.headers.get("Content-Type", "image/png").split(";")[0].strip()
    encoded = base64.b64encode(image_response.content).decode("utf-8")
    return encoded, mime_type


async def _ai_composite_cutout_on_scene(
    cutout_data_url: str,
    scene_data_url: str,
    scene_prompt: str,
    api_key: str,
) -> tuple[str, str]:
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
    body = await call_image_completion(
        messages,
        primary=settings.composite_primary,
        fallback=settings.composite_model_fallback,
        timeout=float(settings.process_timeout_sec),
        max_tokens=1024,
        api_key=api_key,
    )
    image_ref = _extract_image_reference(body)
    return await _image_ref_to_base64(image_ref)


def _build_scene_generation_prompt(resolved: ResolvedBackground) -> str:
    angle_suffix = ANGLE_PROMPT_SUFFIXES.get(resolved.angle, "")
    if resolved.angle == "interior":
        return f"{resolved.prompt} {angle_suffix} Interior cabin view, no people, no vehicle."
    return f"{resolved.prompt} {angle_suffix} Empty studio environment, no vehicle, no people."


def _load_scene_data_url(resolved: ResolvedBackground) -> str | None:
    if not resolved.scene_image_path:
        return None
    path = Path(resolved.scene_image_path)
    if not path.is_file() or path.stat().st_size < 1000:
        return None
    suffix = path.suffix.lower()
    mime = "image/jpeg" if suffix in {".jpg", ".jpeg"} else "image/png"
    return to_data_url(path.read_bytes(), mime)


async def process_user_car_photo(
    source_data_url: str,
    resolved: ResolvedBackground,
    api_key: str,
    *,
    job_dir: Path | None = None,
) -> tuple[str, str]:
    """
    Pipeline:
    1. Extract vehicle (or interior cabin) cutout from user photo.
    2. Composite onto the selected background reference scene for the detected angle.
    3. Fall back to generating an empty room only when no reference scene exists.
    """
    logger.info(
        "Processing user car: angle=%s preset=%s custom=%s",
        resolved.angle,
        resolved.preset_slug,
        resolved.user_background_id,
    )

    cutout_bytes, cutout_mime = await extract_car_cutout_validated(
        source_data_url,
        api_key,
        angle=resolved.angle,
    )
    if job_dir is not None:
        cutout_path = job_dir / "cutout.png"
        cutout_path.write_bytes(cutout_bytes)

    cutout_data_url = to_data_url(cutout_bytes, cutout_mime or "image/png")

    scene_data_url = _load_scene_data_url(resolved)
    if scene_data_url is None:
        logger.warning("No reference scene for %s — generating empty room", resolved.angle)
        scene_prompt = _build_scene_generation_prompt(resolved)
        scene_b64, scene_mime = await generate_empty_room(scene_prompt, api_key)
        scene_data_url = f"data:{scene_mime};base64,{scene_b64}"

    try:
        return await _ai_composite_cutout_on_scene(
            cutout_data_url,
            scene_data_url,
            resolved.prompt,
            api_key,
        )
    except Exception as exc:
        logger.warning("Cutout composite failed (%s), retrying with process_into_scene", exc)
        return await process_into_scene(
            cutout_data_url,
            resolved.prompt,
            scene_data_url,
            api_key,
        )


async def recomposite_from_cutout(
    cutout_data_url: str,
    resolved: ResolvedBackground,
    api_key: str,
) -> tuple[str, str]:
    """Re-run composite only using a saved cutout and new background."""
    scene_data_url = _load_scene_data_url(resolved)
    if scene_data_url is None:
        scene_prompt = _build_scene_generation_prompt(resolved)
        scene_b64, scene_mime = await generate_empty_room(scene_prompt, api_key)
        scene_data_url = f"data:{scene_mime};base64,{scene_b64}"
    return await _ai_composite_cutout_on_scene(
        cutout_data_url,
        scene_data_url,
        resolved.prompt,
        api_key,
    )
