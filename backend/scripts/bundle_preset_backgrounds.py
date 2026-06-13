#!/usr/bin/env python3
"""Pre-render angle-matched preset backgrounds and composed BMW previews."""

from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "backend"))

from app.db.models.background import VARIANT_ANGLES  # noqa: E402
from app.services.background_service import PRESET_DEFINITIONS  # noqa: E402
from app.services.preset_background_renderer import render_preset_background  # noqa: E402
from app.services.scene_compositor import compose_scene_preview  # noqa: E402

BUNDLED_ROOT = ROOT / "mobile" / "assets" / "backgrounds" / "presets"


def main() -> int:
    generated = 0
    for definition in PRESET_DEFINITIONS:
        slug = definition["slug"]
        for angle in VARIANT_ANGLES:
            raw_path = BUNDLED_ROOT / slug / f"{angle}.jpg"
            render_preset_background(slug, raw_path, angle)
            preview_path = compose_scene_preview(raw_path, angle)
            generated += 2
            print(f"OK {raw_path.relative_to(ROOT)} ({raw_path.stat().st_size} bytes)")
            print(f"OK {preview_path.relative_to(ROOT)} ({preview_path.stat().st_size} bytes)")
    print(f"Bundled {generated} background file(s) into {BUNDLED_ROOT}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
