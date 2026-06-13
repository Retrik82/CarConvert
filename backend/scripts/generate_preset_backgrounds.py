#!/usr/bin/env python3
"""Generate all preset background images via OpenRouter AI."""

from __future__ import annotations

import asyncio
import logging
import sys

from app.config import get_settings
from app.db.session import AsyncSessionLocal, ensure_db_ready
from app.repositories.background_repository import BackgroundRepository
from app.services.background_service import BackgroundService
from app.services.preset_ai_background_generator import generate_all_preset_backgrounds

logging.basicConfig(level=logging.INFO, format="%(levelname)s %(message)s")
logger = logging.getLogger(__name__)


async def main() -> int:
    settings = get_settings()
    api_key = settings.openrouter_api_key
    if not api_key or api_key == "your_key_here":
        logger.error("OPENROUTER_API_KEY is not configured in backend/.env")
        return 1

    await ensure_db_ready()
    generated = await generate_all_preset_backgrounds(api_key)
    logger.info("Generated %s background image(s)", generated)

    async with AsyncSessionLocal() as session:
        repo = BackgroundRepository(session)
        presets = await repo.list_active_presets()
        for preset in presets:
            for variant in preset.variants:
                from app.services.background_service import backgrounds_root

                variant.image_path = str(
                    backgrounds_root() / "presets" / preset.slug / f"{variant.angle}.jpg"
                )
            await repo.update_preset(preset)
        await session.commit()

    logger.info("Database variant paths updated")
    return 0 if generated > 0 else 1


if __name__ == "__main__":
    raise SystemExit(asyncio.run(main()))
