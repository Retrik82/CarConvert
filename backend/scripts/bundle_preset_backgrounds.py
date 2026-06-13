#!/usr/bin/env python3
"""Bundle composed preset scenes (room + BMW M4) for each camera angle."""

from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "backend"))

from app.db.models.background import VARIANT_ANGLES  # noqa: E402
from app.services.background_service import PRESET_DEFINITIONS  # noqa: E402
from app.services.scene_compositor import build_preset_scene  # noqa: E402

BUNDLED_ROOT = ROOT / "mobile" / "assets" / "backgrounds" / "presets"


def main() -> int:
    generated = 0
    for definition in PRESET_DEFINITIONS:
        slug = definition["slug"]
        for angle in VARIANT_ANGLES:
            scene_path = BUNDLED_ROOT / slug / f"{angle}.jpg"
            build_preset_scene(slug, angle, scene_path)
            # Remove legacy raw/preview files from the old two-file layout.
            for legacy in (scene_path.with_name(f"{angle}_preview.jpg"), scene_path.with_name(f"{angle}_room.jpg")):
                if legacy.is_file():
                    legacy.unlink()
            generated += 1
            print(f"OK {scene_path.relative_to(ROOT)} ({scene_path.stat().st_size} bytes)")
    print(f"Bundled {generated} composed scene(s) into {BUNDLED_ROOT}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
