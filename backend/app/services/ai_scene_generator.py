"""AI-generated full scenes: BMW M4 on podium in showroom / garage — no PNG compositing."""

from __future__ import annotations

import base64
import logging
from io import BytesIO
from pathlib import Path

from PIL import Image

from app.db.models.background import ANGLE_PROMPT_SUFFIXES, VARIANT_ANGLES
from app.services.ai.background_processor import generate_full_scene
from app.services.background_service import PRESET_DEFINITIONS

logger = logging.getLogger(__name__)

PRESET_SLUGS = frozenset(d["slug"] for d in PRESET_DEFINITIONS)
TARGET_SIZE = (1280, 720)

CAR_SUBJECT = (
    "White BMW M4 Coupe (G82 generation), glossy white paint, black roof and accents, "
    "realistic wheels and tires standing firmly on the platform with natural contact shadows."
)

PRESET_SCENE_BASE: dict[str, str] = {
    "gray-showroom": (
        "Minimalist luxury gray automotive showroom studio. Smooth concrete walls and floor, "
        "soft diffused ceiling lighting, monochromatic gray palette, premium presentation space. "
        f"A single round light-gray podium/platform in the center. {CAR_SUBJECT}"
    ),
    "auto-workshop": (
        "Modern professional automotive service garage. Clean industrial interior, concrete floor, "
        "bright ceiling workshop lights, tool cabinets and vehicle lift in the background, "
        f"organized workspace. A low circular platform/podium where the car is displayed. {CAR_SUBJECT}"
    ),
}


def build_full_scene_prompt(
    *,
    slug: str | None = None,
    angle: str,
    custom_prompt: str | None = None,
) -> str:
    angle_hint = ANGLE_PROMPT_SUFFIXES.get(angle, "")

    if angle == "interior":
        return (
            "Photorealistic BMW M4 Coupe (G82) luxury interior cabin photograph. "
            "Dashboard, steering wheel, front sport seats, ambient lighting, premium leather "
            "and carbon trim. Driver perspective, no people, no logos, no text. "
            f"{angle_hint} Landscape 16:9, ultra detailed, photorealistic."
        )

    if custom_prompt:
        base = custom_prompt.strip()
    elif slug:
        base = PRESET_SCENE_BASE.get(slug, PRESET_SCENE_BASE["gray-showroom"])
    else:
        base = PRESET_SCENE_BASE["gray-showroom"]

    return (
        f"{base} {angle_hint} "
        "The car is fully visible — not cropped. Wheels touch the podium naturally. "
        "Unified photorealistic photograph, professional automotive studio quality, "
        "natural lighting and soft ground shadows. Landscape 16:9 aspect ratio. "
        "No people, no text, no watermarks, no cutout collage look."
    )


def save_scene_jpeg(path: Path, image_bytes: bytes) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    image = Image.open(BytesIO(image_bytes)).convert("RGB")
    image = image.resize(TARGET_SIZE, Image.Resampling.LANCZOS)
    image.save(path, format="JPEG", quality=93, optimize=True)


async def generate_preset_scene_ai(slug: str, angle: str, scene_path: Path, api_key: str) -> None:
    prompt = build_full_scene_prompt(slug=slug, angle=angle)
    logger.info("AI full scene %s/%s", slug, angle)
    image_b64, _mime = await generate_full_scene(prompt, api_key)
    save_scene_jpeg(scene_path, base64.b64decode(image_b64))
    logger.info("Saved %s (%s bytes)", scene_path, scene_path.stat().st_size)


async def generate_custom_scene_ai(
    user_prompt: str,
    angle: str,
    scene_path: Path,
    api_key: str,
) -> None:
    prompt = build_full_scene_prompt(custom_prompt=user_prompt, angle=angle)
    logger.info("AI custom full scene angle=%s", angle)
    image_b64, _mime = await generate_full_scene(prompt, api_key)
    save_scene_jpeg(scene_path, base64.b64decode(image_b64))


async def generate_all_preset_scenes(api_key: str, output_root: Path) -> int:
    generated = 0
    for definition in PRESET_DEFINITIONS:
        slug = definition["slug"]
        for angle in VARIANT_ANGLES:
            scene_path = output_root / slug / f"{angle}.jpg"
            try:
                await generate_preset_scene_ai(slug, angle, scene_path, api_key)
                generated += 1
            except Exception as exc:
                logger.error("Failed %s/%s: %s", slug, angle, exc)
    return generated
