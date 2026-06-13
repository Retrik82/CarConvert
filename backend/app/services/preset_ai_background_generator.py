"""AI full-scene preset generation — delegates to ai_scene_generator."""

from __future__ import annotations

import logging
from pathlib import Path

from app.db.models.background import VARIANT_ANGLES
from app.services.ai_scene_generator import generate_all_preset_scenes, generate_preset_scene_ai
from app.services.background_service import PRESET_DEFINITIONS, backgrounds_root

logger = logging.getLogger(__name__)

PRESET_SLUGS = frozenset(d["slug"] for d in PRESET_DEFINITIONS)


async def generate_preset_scene(slug: str, angle: str, scene_path: Path, api_key: str) -> None:
    await generate_preset_scene_ai(slug, angle, scene_path, api_key)


async def generate_all_preset_backgrounds(api_key: str) -> int:
    return await generate_all_preset_scenes(api_key, backgrounds_root() / "presets")
