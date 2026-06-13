import logging
import shutil
from pathlib import Path

from app.config import get_settings
from app.db.models.background import VARIANT_ANGLES

logger = logging.getLogger(__name__)
settings = get_settings()

REPO_ROOT = Path(__file__).resolve().parents[3]
BUNDLED_SCENES = REPO_ROOT / "mobile" / "assets" / "backgrounds" / "presets"
PRESET_SLUGS = ("gray-showroom", "auto-workshop")


def backgrounds_root() -> Path:
    path = Path(settings.upload_dir) / "backgrounds"
    path.mkdir(parents=True, exist_ok=True)
    return path


def bundled_scene_path(slug: str, angle: str) -> Path:
    return BUNDLED_SCENES / slug / f"{angle}.jpg"


def preset_scene_path(slug: str, angle: str) -> Path:
    return backgrounds_root() / "presets" / slug / f"{angle}.jpg"


def seed_preset_scenes() -> int:
    """Copy bundled composed scene JPEGs (room + BMW) into upload storage."""
    if not BUNDLED_SCENES.is_dir():
        logger.warning("Bundled scene assets not found at %s", BUNDLED_SCENES)
        return 0

    copied = 0
    for slug in PRESET_SLUGS:
        for angle in VARIANT_ANGLES:
            src = bundled_scene_path(slug, angle)
            if not src.is_file():
                logger.warning("Missing bundled scene %s", src)
                continue
            dst = preset_scene_path(slug, angle)
            dst.parent.mkdir(parents=True, exist_ok=True)
            if (
                not dst.exists()
                or src.stat().st_mtime > dst.stat().st_mtime
                or src.stat().st_size != dst.stat().st_size
            ):
                shutil.copy2(src, dst)
                copied += 1

    if copied:
        logger.info("Seeded %s composed scene(s) into %s", copied, backgrounds_root() / "presets")
    return copied


def ensure_preset_scene(slug: str, angle: str) -> Path:
    """Return server path to composed scene (room + BMW), building when needed."""
    dst = preset_scene_path(slug, angle)
    src = bundled_scene_path(slug, angle)

    if src.is_file():
        dst.parent.mkdir(parents=True, exist_ok=True)
        if (
            not dst.is_file()
            or dst.stat().st_size < 10_000
            or src.stat().st_mtime > dst.stat().st_mtime
            or src.stat().st_size != dst.stat().st_size
        ):
            shutil.copy2(src, dst)
        return dst

    if dst.is_file() and dst.stat().st_size > 10_000:
        return dst

    logger.warning("No bundled scene for %s/%s — run bundle_preset_backgrounds.py with OpenRouter", slug, angle)
    return dst


# Backward-compatible names used by seed_service
seed_preset_backgrounds = seed_preset_scenes
ensure_preset_background = ensure_preset_scene
bundled_preset_path = bundled_scene_path
preset_image_path = preset_scene_path
