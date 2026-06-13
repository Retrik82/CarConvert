import logging
import shutil
from pathlib import Path

from app.config import get_settings
from app.db.models.background import VARIANT_ANGLES

logger = logging.getLogger(__name__)
settings = get_settings()

REPO_ROOT = Path(__file__).resolve().parents[3]
BUNDLED_BACKGROUNDS = REPO_ROOT / "mobile" / "assets" / "backgrounds" / "presets"
PRESET_SLUGS = ("gray-showroom", "auto-workshop")


def backgrounds_root() -> Path:
    path = Path(settings.upload_dir) / "backgrounds"
    path.mkdir(parents=True, exist_ok=True)
    return path


def bundled_preset_path(slug: str, angle: str) -> Path:
    return BUNDLED_BACKGROUNDS / slug / f"{angle}.jpg"


def preset_image_path(slug: str, angle: str) -> Path:
    return backgrounds_root() / "presets" / slug / f"{angle}.jpg"


def seed_preset_backgrounds() -> int:
    """Copy bundled preset JPEGs into upload storage (idempotent)."""
    if not BUNDLED_BACKGROUNDS.is_dir():
        logger.warning("Bundled preset backgrounds not found at %s", BUNDLED_BACKGROUNDS)
        return 0

    copied = 0
    for slug in PRESET_SLUGS:
        for angle in VARIANT_ANGLES:
            src = bundled_preset_path(slug, angle)
            if not src.is_file():
                logger.warning("Missing bundled background %s", src)
                continue
            dst = preset_image_path(slug, angle)
            dst.parent.mkdir(parents=True, exist_ok=True)
            if not dst.exists() or src.stat().st_mtime > dst.stat().st_mtime or src.stat().st_size != dst.stat().st_size:
                shutil.copy2(src, dst)
                copied += 1

    if copied:
        logger.info("Seeded %s preset background image(s) into %s", copied, backgrounds_root() / "presets")
    return copied


def ensure_preset_background(slug: str, angle: str) -> Path:
    """Return server path for a preset angle, copying bundled asset when needed."""
    dst = preset_image_path(slug, angle)
    src = bundled_preset_path(slug, angle)
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

    from app.services.preset_background_renderer import render_preset_background

    render_preset_background(slug, dst)
    return dst
