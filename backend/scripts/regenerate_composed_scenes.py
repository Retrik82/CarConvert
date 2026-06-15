"""Regenerate preset scenes: procedural room + transparent BMW composite (consistent layout)."""

from __future__ import annotations

import logging
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "backend"))

from app.db.models.background import VARIANT_ANGLES  # noqa: E402
from app.services.background_service import PRESET_DEFINITIONS  # noqa: E402
from app.services.scene_compositor import build_preset_scene  # noqa: E402

logging.basicConfig(level=logging.INFO, format="%(levelname)s %(message)s")
logger = logging.getLogger(__name__)

BUNDLED_ROOT = ROOT / "mobile" / "assets" / "backgrounds" / "presets"


def main() -> int:
    BUNDLED_ROOT.mkdir(parents=True, exist_ok=True)
    built = 0

    for definition in PRESET_DEFINITIONS:
        slug = definition["slug"]
        for angle in VARIANT_ANGLES:
            scene_path = BUNDLED_ROOT / slug / f"{angle}.jpg"
            try:
                build_preset_scene(slug, angle, scene_path)
                built += 1
                logger.info("Built %s/%s -> %s", slug, angle, scene_path)
            except Exception as exc:
                logger.error("Failed %s/%s: %s", slug, angle, exc)

    logger.info("Regenerated %s / %s composed scene(s)", built, len(PRESET_DEFINITIONS) * len(VARIANT_ANGLES))
    return 0 if built == len(PRESET_DEFINITIONS) * len(VARIANT_ANGLES) else 1


if __name__ == "__main__":
    raise SystemExit(main())
