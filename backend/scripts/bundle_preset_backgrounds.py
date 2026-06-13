"""Generate all preset scenes via OpenRouter AI (full photograph, no compositing)."""

from __future__ import annotations

import asyncio
import logging
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "backend"))

from app.config import get_settings  # noqa: E402
from app.services.ai_scene_generator import generate_all_preset_scenes  # noqa: E402

logging.basicConfig(level=logging.INFO, format="%(levelname)s %(message)s")
logger = logging.getLogger(__name__)

BUNDLED_ROOT = ROOT / "mobile" / "assets" / "backgrounds" / "presets"


async def main() -> int:
    settings = get_settings()
    api_key = settings.openrouter_api_key
    if not api_key or api_key == "your_key_here":
        logger.error("OPENROUTER_API_KEY is not configured in backend/.env")
        return 1

    BUNDLED_ROOT.mkdir(parents=True, exist_ok=True)
    generated = await generate_all_preset_scenes(api_key, BUNDLED_ROOT)
    logger.info("Generated %s / 14 AI scene(s) into %s", generated, BUNDLED_ROOT)
    return 0 if generated == 14 else 1


if __name__ == "__main__":
    raise SystemExit(asyncio.run(main()))
