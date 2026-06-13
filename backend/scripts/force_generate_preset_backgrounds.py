#!/usr/bin/env python3
"""Force-regenerate all preset backgrounds via OpenRouter (ignores existing files)."""

from __future__ import annotations

import asyncio
import logging
import sys
from pathlib import Path

# Allow running as: python scripts/force_generate_preset_backgrounds.py
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from app.config import get_settings
from app.db.models.background import VARIANT_ANGLES
from app.db.session import AsyncSessionLocal, ensure_db_ready
from app.repositories.background_repository import BackgroundRepository
from app.services.background_service import PRESET_DEFINITIONS, backgrounds_root
from app.services.preset_ai_background_generator import generate_preset_image

logging.basicConfig(level=logging.INFO, format="%(levelname)s %(message)s")
logger = logging.getLogger(__name__)


async def main() -> int:
    settings = get_settings()
    api_key = settings.openrouter_api_key
    if not api_key or api_key == "your_key_here":
        logger.error("OPENROUTER_API_KEY is not configured in backend/.env")
        return 1

    await ensure_db_ready()
    generated = 0

    for definition in PRESET_DEFINITIONS:
        slug = definition["slug"]
        for angle in VARIANT_ANGLES:
            image_path = backgrounds_root() / "presets" / slug / f"{angle}.jpg"
            try:
                await generate_preset_image(slug, angle, image_path, api_key)
                generated += 1
            except Exception as exc:
                logger.error("Failed %s/%s: %s", slug, angle, exc)

    async with AsyncSessionLocal() as session:
        repo = BackgroundRepository(session)
        for preset in await repo.list_active_presets():
            for variant in preset.variants:
                variant.image_path = str(
                    backgrounds_root() / "presets" / preset.slug / f"{variant.angle}.jpg"
                )
            await repo.update_preset(preset)
        await session.commit()

    logger.info("Done. Generated %s / 14 images.", generated)
    return 0 if generated == 14 else 1


if __name__ == "__main__":
    raise SystemExit(asyncio.run(main()))
