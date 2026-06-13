"""Build prompts and save AI-generated preset background images."""

from __future__ import annotations

import base64
import logging
from io import BytesIO
from pathlib import Path

from PIL import Image

from app.db.models.background import VARIANT_ANGLES
from app.services.ai.background_processor import generate_empty_background
from app.services.background_service import PRESET_DEFINITIONS, backgrounds_root
from app.services.scene_layout import GROUND_Y, layout_for_angle

logger = logging.getLogger(__name__)

PRESET_SLUGS = frozenset(d["slug"] for d in PRESET_DEFINITIONS)
TARGET_SIZE = (1280, 720)

ANGLE_SCENE_HINTS: dict[str, str] = {
    "left": (
        "Camera at driver-side profile height, BMW coupe side view facing right. "
        "Floor horizon at 58% frame height, circular podium centered under wheelbase, "
        "soft top-down studio lighting from above-left."
    ),
    "right": (
        "Camera at passenger-side profile height, BMW coupe side view facing left. "
        "Floor horizon at 58% frame height, circular podium centered under wheelbase, "
        "soft top-down studio lighting from above-right."
    ),
    "front": (
        "Camera straight-on front view at bumper height, symmetrical studio. "
        "Low circular podium centered on floor, head-on perspective, even frontal lighting."
    ),
    "rear": (
        "Camera straight-on rear view at trunk height, symmetrical studio. "
        "Low circular podium centered on floor, head-on perspective, even rear lighting."
    ),
    "three_quarter_left": (
        "Camera at three-quarter front-left angle, BMW coupe nose pointing slightly right. "
        "Perspective floor lines converging to the right, podium slightly left of center, "
        "corner wall visible on the left."
    ),
    "three_quarter_right": (
        "Camera at three-quarter front-right angle, BMW coupe nose pointing slightly left. "
        "Perspective floor lines converging to the left, podium slightly right of center, "
        "corner wall visible on the right."
    ),
    "interior": (
        "Camera inside luxury coupe cabin, dashboard and front seats visible, "
        "ambient soft lighting, no exterior scene."
    ),
}


def build_preset_prompt(slug: str, angle: str) -> str:
    definition = next(item for item in PRESET_DEFINITIONS if item["slug"] == slug)
    layout = layout_for_angle(angle)
    base = definition["prompt_template"]
    scene_hint = ANGLE_SCENE_HINTS.get(angle, "")

    if angle == "interior":
        scene = (
            "Photorealistic empty BMW M4 luxury interior cabin: dashboard, steering wheel, "
            "front seats, ambient lighting, premium leather and carbon trim. "
            "No people, no logos, no text."
        )
    else:
        ground_hint = (
            f"Vehicle standing position: wheels on floor at {GROUND_Y}px in 720px-tall frame. "
            if layout
            else ""
        )
        scene = (
            f"{base} Empty automotive studio scene for a BMW M4 coupe photoshoot. "
            f"{scene_hint} {ground_hint}"
            "Single low circular podium/platform on the floor where the car will stand. "
            "NO car, NO people, NO text, NO watermarks."
        )

    return (
        f"{scene} "
        "Landscape 16:9, photorealistic, professional automotive studio photography, "
        "consistent perspective with BMW CGI render, natural soft shadows, ultra detailed."
    )


def _save_image_bytes(path: Path, image_bytes: bytes, mime: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    if mime == "image/jpeg" or path.suffix.lower() in {".jpg", ".jpeg"}:
        image = Image.open(BytesIO(image_bytes)).convert("RGB")
        image = image.resize(TARGET_SIZE, Image.Resampling.LANCZOS)
        image.save(path, format="JPEG", quality=92, optimize=True)
        return

    image = Image.open(BytesIO(image_bytes)).convert("RGB")
    image = image.resize(TARGET_SIZE, Image.Resampling.LANCZOS)
    jpg_path = path.with_suffix(".jpg")
    image.save(jpg_path, format="JPEG", quality=92, optimize=True)


async def generate_preset_image(slug: str, angle: str, path: Path, api_key: str) -> None:
    prompt = build_preset_prompt(slug, angle)
    logger.info("Generating AI background %s/%s", slug, angle)
    image_b64, mime = await generate_empty_background(prompt, api_key)
    _save_image_bytes(path, base64.b64decode(image_b64), mime)
    logger.info("Saved %s", path)

    from app.services.scene_compositor import compose_scene_preview

    compose_scene_preview(path, angle)


async def generate_all_preset_backgrounds(api_key: str) -> int:
    generated = 0
    for definition in PRESET_DEFINITIONS:
        slug = definition["slug"]
        for angle in VARIANT_ANGLES:
            image_path = backgrounds_root() / "presets" / slug / f"{angle}.jpg"
            try:
                await generate_preset_image(slug, angle, image_path, api_key)
                generated += 1
            except Exception as exc:
                logger.error("Failed to generate %s/%s: %s", slug, angle, exc)
    return generated
