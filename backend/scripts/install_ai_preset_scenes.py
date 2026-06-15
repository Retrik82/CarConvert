"""Install AI-generated full-scene JPEGs from Cursor assets into mobile bundle."""

from __future__ import annotations

from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
SRC = ROOT / "assets"
DST = ROOT / "mobile" / "assets" / "backgrounds" / "presets"
TARGET = (1280, 720)

SCENE_FILES: dict[str, dict[str, str]] = {
    "gray-showroom": {
        "three_quarter_left": "gray-showroom-three_quarter_left.png",
        "three_quarter_right": "gray-showroom-three_quarter_right.png",
        "front": "gray-showroom-front.png",
        "left": "gray-showroom-left.png",
        "right": "gray-showroom-right.png",
        "rear": "gray-showroom-rear.png",
        "interior": "gray-showroom-interior.png",
    },
    "auto-workshop": {
        "three_quarter_left": "auto-workshop-three_quarter_left.png",
        "three_quarter_right": "auto-workshop-three_quarter_right.png",
        "front": "auto-workroom-front.png",
        "left": "auto-workshop-left.png",
        "right": "auto-workshop-right.png",
        "rear": "auto-workshop-rear.png",
        "interior": "auto-workshop-interior.png",
    },
}


def main() -> int:
    installed = 0
    for slug, angles in SCENE_FILES.items():
        for angle, filename in angles.items():
            src = SRC / filename
            dst = DST / slug / f"{angle}.jpg"
            if not src.is_file():
                print(f"MISSING {src}")
                continue
            dst.parent.mkdir(parents=True, exist_ok=True)
            image = Image.open(src).convert("RGB")
            image = image.resize(TARGET, Image.Resampling.LANCZOS)
            image.save(dst, format="JPEG", quality=93, optimize=True)
            installed += 1
            print(f"Installed {dst}")

    print(f"Installed {installed} scene(s)")
    return 0 if installed == 14 else 1


if __name__ == "__main__":
    raise SystemExit(main())
