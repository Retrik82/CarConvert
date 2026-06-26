"""Replace the photo background while preserving the user's vehicle and camera angle."""

from __future__ import annotations

import base64
import logging
from dataclasses import dataclass
from pathlib import Path

import httpx

from app.config import get_settings
from app.services.ai.background_processor import (
    generate_empty_room,
    process_into_scene,
    replace_car_background_in_place,
)
from app.services.ai.car_extractor import extract_car_cutout_validated
from app.services.ai.model_router import call_image_completion
from app.services.ai.openrouter_client import _extract_image_reference
from app.services.ai.prompt_blocks import CUTOUT_COMPOSITE_SYSTEM_PROMPT
from app.services.ai.prompt_builder import (
    build_background_environment_prompt,
    build_composite_user_text,
    ensure_prompt_compliance,
)
from app.services.ai.vehicle_descriptor import describe_vehicle
from app.utils.image_utils import sanitize_inplace_background_prompt, to_data_url

logger = logging.getLogger(__name__)
settings = get_settings()

RECOMPOSITE_MARKER = "recomposite.source_job_id"


@dataclass(frozen=True)
class ResolvedBackground:
    prompt: str
    angle: str
    preset_slug: str | None = None
    user_background_id: str | None = None
    scene_image_path: str | None = None


def build_background_replace_prompt(resolved: ResolvedBackground) -> str:
    """Environment description only — never instruct the model to change camera angle."""
    environment = sanitize_inplace_background_prompt(resolved.prompt)
    return build_background_environment_prompt(environment, angle=resolved.angle)


def _build_empty_room_prompt(resolved: ResolvedBackground) -> str:
    """Full studio scene generation for composite fallback."""
    studio = build_background_replace_prompt(resolved)
    if resolved.angle == "interior":
        return f"{studio} Empty environment outside the windows. No vehicle, no people."
    return f"{studio} Empty gray showroom studio with podium. No vehicle, no people."


def mark_job_as_recomposite(job_dir: Path, source_job_id: str) -> None:
    (job_dir / RECOMPOSITE_MARKER).write_text(source_job_id, encoding="utf-8")


def is_recomposite_job(job_dir: Path) -> bool:
    return (job_dir / RECOMPOSITE_MARKER).is_file()


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
    *,
    vehicle_descriptor: dict | None = None,
) -> tuple[str, str]:
    user_text = build_composite_user_text(
        scene_prompt,
        vehicle_descriptor=vehicle_descriptor,
        cutout=True,
    )
    system_prompt, user_text = ensure_prompt_compliance(CUTOUT_COMPOSITE_SYSTEM_PROMPT, user_text)
    content: list[dict] = [
        {"type": "text", "text": user_text},
        {"type": "image_url", "image_url": {"url": scene_data_url}},
        {"type": "image_url", "image_url": {"url": cutout_data_url}},
    ]
    messages = [
        {"role": "system", "content": system_prompt},
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


async def _composite_fallback(
    source_data_url: str,
    resolved: ResolvedBackground,
    api_key: str,
    *,
    vehicle_descriptor: dict | None,
) -> tuple[str, str]:
    cutout_bytes, cutout_mime = await extract_car_cutout_validated(
        source_data_url,
        api_key,
        angle=resolved.angle,
        vehicle_descriptor=vehicle_descriptor,
    )
    cutout_data_url = to_data_url(cutout_bytes, cutout_mime or "image/png")

    scene_prompt = _build_empty_room_prompt(resolved)
    logger.warning("Composite fallback — generating studio scene")
    scene_b64, scene_mime = await generate_empty_room(scene_prompt, api_key)
    scene_data_url = f"data:{scene_mime};base64,{scene_b64}"

    try:
        return await _ai_composite_cutout_on_scene(
            cutout_data_url,
            scene_data_url,
            scene_prompt,
            api_key,
            vehicle_descriptor=vehicle_descriptor,
        )
    except Exception as exc:
        logger.warning("Cutout composite failed (%s), retrying with process_into_scene", exc)
        return await process_into_scene(
            cutout_data_url,
            scene_prompt,
            scene_data_url,
            api_key,
            vehicle_descriptor=vehicle_descriptor,
        )


async def process_user_car_photo(
    source_data_url: str,
    resolved: ResolvedBackground,
    api_key: str,
    *,
    job_dir: Path | None = None,
) -> tuple[str, str]:
    """
    Pipeline:
    1. Describe the source vehicle for identity-preserving prompts.
    2. Replace only the background on the original photo (single attempt).
    3. Fall back to scene compositing only if in-place replacement fails.
    """
    logger.info(
        "Processing user car: angle=%s preset=%s custom=%s",
        resolved.angle,
        resolved.preset_slug,
        resolved.user_background_id,
    )

    vehicle_descriptor = await describe_vehicle(
        source_data_url,
        api_key,
        angle=resolved.angle,
    )
    replace_prompt = build_background_replace_prompt(resolved)

    try:
        return await replace_car_background_in_place(
            source_data_url,
            replace_prompt,
            angle=resolved.angle,
            api_key=api_key,
            vehicle_descriptor=vehicle_descriptor,
        )
    except Exception as exc:
        logger.warning("In-place background replace failed (%s), falling back to composite", exc)
        return await _composite_fallback(
            source_data_url,
            resolved,
            api_key,
            vehicle_descriptor=vehicle_descriptor,
        )


async def process_recomposite_photo(
    source_data_url: str,
    resolved: ResolvedBackground,
    api_key: str,
    *,
    job_dir: Path | None = None,
) -> tuple[str, str]:
    """Extract cutout from source photo and composite onto a new background."""
    vehicle_descriptor = await describe_vehicle(
        source_data_url,
        api_key,
        angle=resolved.angle,
    )
    cutout_bytes, cutout_mime = await extract_car_cutout_validated(
        source_data_url,
        api_key,
        angle=resolved.angle,
        vehicle_descriptor=vehicle_descriptor,
    )
    if job_dir is not None:
        (job_dir / "cutout.png").write_bytes(cutout_bytes)

    cutout_data_url = to_data_url(cutout_bytes, cutout_mime or "image/png")
    scene_prompt = _build_empty_room_prompt(resolved)
    scene_b64, scene_mime = await generate_empty_room(scene_prompt, api_key)
    scene_data_url = f"data:{scene_mime};base64,{scene_b64}"
    return await _ai_composite_cutout_on_scene(
        cutout_data_url,
        scene_data_url,
        scene_prompt,
        api_key,
        vehicle_descriptor=vehicle_descriptor,
    )


async def recomposite_from_cutout(
    cutout_data_url: str,
    resolved: ResolvedBackground,
    api_key: str,
    *,
    vehicle_descriptor: dict | None = None,
) -> tuple[str, str]:
    """Re-run composite only using a saved cutout and new background."""
    scene_prompt = _build_empty_room_prompt(resolved)
    scene_b64, scene_mime = await generate_empty_room(scene_prompt, api_key)
    scene_data_url = f"data:{scene_mime};base64,{scene_b64}"
    return await _ai_composite_cutout_on_scene(
        cutout_data_url,
        scene_data_url,
        scene_prompt,
        api_key,
        vehicle_descriptor=vehicle_descriptor,
    )
