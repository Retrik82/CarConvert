"""Generate AI rooms and bake BMW M4 into composed preset scenes."""

from __future__ import annotations

import base64
import logging
from pathlib import Path

from app.db.models.background import VARIANT_ANGLES
from app.services.ai.background_processor import generate_empty_room
from app.services.background_service import PRESET_DEFINITIONS, backgrounds_root
from app.services.scene_layout import GROUND_Y, layout_for_angle

logger = logging.getLogger(__name__)

PRESET_SLUGS = frozenset(d["slug"] for d in PRESET_DEFINITIONS)

ANGLE_SCENE_HINTS: dict[str, str] = {
    "left": (
        "Camera at driver-side profile height, BMW coupe side view facing right. "
        "Floor horizon at 58% frame height, circular podium centered under wheelbase."
    ),
    "right": (
        "Camera at passenger-side profile height, BMW coupe side view facing left. "
        "Floor horizon at 58% frame height, circular podium centered under wheelbase."
    ),
    "front": "Camera straight-on front view at bumper height, symmetrical studio, centered podium.",
    "rear": "Camera straight-on rear view at trunk height, symmetrical studio, centered podium.",
    "three_quarter_left": (
        "Camera at three-quarter front-left, nose slightly right, perspective floor, podium left of center."
    ),
    "three_quarter_right": (
        "Camera at three-quarter front-right, nose slightly left, perspective floor, podium right of center."
    ),
    "interior": "Camera inside luxury coupe cabin, dashboard and front seats, ambient lighting.",
}


def build_preset_prompt(slug: str, angle: str) -> str:
    definition = next(item for item in PRESET_DEFINITIONS if item["slug"] == slug)
    layout = layout_for_angle(angle)
    base = definition["prompt_template"]
    scene_hint = ANGLE_SCENE_HINTS.get(angle, "")

    if angle == "interior":
        scene = (
            "Photorealistic empty BMW M4 luxury interior cabin: dashboard, steering wheel, "
            "front seats, ambient lighting, premium materials. No people, no logos, no text."
        )
    else:
        ground_hint = (
            f"Empty podium at {GROUND_Y}px in a 720px-tall frame. "
            if layout
            else ""
        )
        scene = (
            f"{base} Empty automotive studio for a BMW M4 coupe. {scene_hint} {ground_hint}"
            "NO car, NO people, NO text, NO watermarks."
        )

    return (
        f"{scene} Landscape 16:9, photorealistic automotive studio, "
        "consistent perspective with BMW CGI render, ultra detailed."
    )


async def generate_preset_scene(slug: str, angle: str, scene_path: Path, api_key: str) -> None:
    from app.services.scene_compositor import build_scene_from_room_bytes

    prompt = build_preset_prompt(slug, angle)
    logger.info("Generating AI room %s/%s", slug, angle)
    room_b64, _mime = await generate_empty_room(prompt, api_key)
    build_scene_from_room_bytes(base64.b64decode(room_b64), angle, scene_path)
    logger.info("Saved composed scene %s", scene_path)


async def generate_all_preset_backgrounds(api_key: str) -> int:
    generated = 0
    for definition in PRESET_DEFINITIONS:
        slug = definition["slug"]
        for angle in VARIANT_ANGLES:
            scene_path = backgrounds_root() / "presets" / slug / f"{angle}.jpg"
            try:
                await generate_preset_scene(slug, angle, scene_path, api_key)
                generated += 1
            except Exception as exc:
                logger.error("Failed to generate %s/%s: %s", slug, angle, exc)
    return generated
