import logging
import shutil
from pathlib import Path

from app.config import get_settings

logger = logging.getLogger(__name__)
settings = get_settings()

CAR_MODEL = "bmw_m4_g82"
CAR_VIEWS = (
    "side_left",
    "side_right",
    "front",
    "rear",
    "three_quarter_left",
    "three_quarter_right",
)
CAR_PAINTS = ("white", "black", "neutral")

REPO_ROOT = Path(__file__).resolve().parents[3]
BUNDLED_CAR_ASSETS = REPO_ROOT / "mobile" / "assets" / "cars" / CAR_MODEL


def cars_root() -> Path:
    path = Path(settings.upload_dir) / "cars"
    path.mkdir(parents=True, exist_ok=True)
    return path


def image_url(model: str, view: str, paint: str) -> str:
    return f"/cars/image/{model}/{view}/{paint}"


def get_image_path(model: str, view: str, paint: str) -> Path | None:
    if model != CAR_MODEL or view not in CAR_VIEWS or paint not in CAR_PAINTS:
        return None
    path = cars_root() / model / f"{view}_{paint}.png"
    return path if path.is_file() else None


def seed_car_assets() -> None:
    """Copy bundled PNG renders into upload storage (idempotent)."""
    if not BUNDLED_CAR_ASSETS.is_dir():
        logger.warning("Bundled car assets not found at %s", BUNDLED_CAR_ASSETS)
        return

    dst_dir = cars_root() / CAR_MODEL
    dst_dir.mkdir(parents=True, exist_ok=True)

    copied = 0
    for src in sorted(BUNDLED_CAR_ASSETS.glob("*.png")):
        if "raw" in src.name:
            continue
        stem = src.stem
        if not any(stem.endswith(f"_{paint}") for paint in CAR_PAINTS):
            continue
        target = dst_dir / src.name
        if not target.exists() or src.stat().st_mtime > target.stat().st_mtime:
            shutil.copy2(src, target)
            copied += 1

    if copied:
        logger.info("Seeded %s car asset(s) into %s", copied, dst_dir)
