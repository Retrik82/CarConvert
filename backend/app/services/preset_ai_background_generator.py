"""Build prompts and save AI-generated preset background images."""

from __future__ import annotations

import base64
import logging
from io import BytesIO
from pathlib import Path

from PIL import Image

from app.db.models.background import ANGLE_PROMPT_SUFFIXES, VARIANT_ANGLES
from app.services.ai.background_processor import generate_empty_background
from app.services.background_service import PRESET_DEFINITIONS, backgrounds_root

logger = logging.getLogger(__name__)

PRESET_SLUGS = frozenset(d["slug"] for d in PRESET_DEFINITIONS)
TARGET_SIZE = (1280, 720)


def build_preset_prompt(slug: str, angle: str) -> str:
    definition = next(item for item in PRESET_DEFINITIONS if item["slug"] == slug)
    angle_hint = ANGLE_PROMPT_SUFFIXES.get(angle, "")
    base = definition["prompt_template"]

    if angle == "interior":
        scene = (
            "Photorealistic empty luxury car interior cabin background: dashboard, steering wheel, "
            "front seats, ambient lighting, premium materials. No people, no logos, no text."
        )
    else:
        scene = (
            f"{base} Empty scene ready for a car photoshoot. "
            "A single low circular podium/platform centered on the floor where a vehicle will stand. "
            "NO car, NO people, NO text, NO watermarks."
        )

    return (
        f"{scene} {angle_hint} "
        "Landscape 16:9 composition, photorealistic, professional automotive studio photography, "
        "natural perspective and lighting, ultra detailed, 8k quality."
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
