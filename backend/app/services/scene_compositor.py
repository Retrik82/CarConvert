"""Compose BMW M4 renders into studio scenes — primary catalog & AI reference assets."""

from __future__ import annotations

import logging
import tempfile
from pathlib import Path

from PIL import Image

from app.services.car_asset_service import BUNDLED_CAR_ASSETS
from app.services.scene_layout import (
    CANVAS_HEIGHT,
    CANVAS_WIDTH,
    car_view_for_angle,
    layout_for_angle,
)

logger = logging.getLogger(__name__)

DEFAULT_SCENE_PAINT = "white"


def room_image_path(scene_path: Path) -> Path:
    """Temporary empty-room file used only while building a scene."""
    return scene_path.with_name(f"{scene_path.stem}_room.jpg")


def car_image_path(angle: str, paint: str = DEFAULT_SCENE_PAINT) -> Path | None:
    view = car_view_for_angle(angle)
    if view is None:
        return None
    path = BUNDLED_CAR_ASSETS / f"{view}_{paint}.png"
    return path if path.is_file() else None


def composite_car_on_room(
    room: Image.Image,
    car: Image.Image,
    angle: str,
) -> Image.Image:
    layout = layout_for_angle(angle)
    if layout is None:
        return room.convert("RGB")

    canvas = room.convert("RGBA").resize((CANVAS_WIDTH, CANVAS_HEIGHT), Image.Resampling.LANCZOS)
    car_rgba = car.convert("RGBA")

    target_width = max(1, int(CANVAS_WIDTH * layout.car_width_ratio))
    scale = target_width / car_rgba.width
    target_height = max(1, int(car_rgba.height * scale))
    car_scaled = car_rgba.resize((target_width, target_height), Image.Resampling.LANCZOS)

    ground_row = int(target_height * layout.car_ground_ratio)
    center_x = int(CANVAS_WIDTH * layout.center_x_ratio)
    x = center_x - target_width // 2
    y = layout.ground_y - ground_row

    composed = canvas.copy()
    composed.paste(car_scaled, (x, y), car_scaled)
    return composed.convert("RGB")


def compose_scene_from_room(
    room_path: Path,
    angle: str,
    scene_path: Path,
    *,
    paint: str = DEFAULT_SCENE_PAINT,
) -> Path:
    """Bake our BMW onto an empty room and save the final scene JPEG."""
    scene_path.parent.mkdir(parents=True, exist_ok=True)

    if angle == "interior" or car_view_for_angle(angle) is None:
        Image.open(room_path).convert("RGB").save(scene_path, format="JPEG", quality=92, optimize=True)
        return scene_path

    car_path = car_image_path(angle, paint)
    if car_path is None:
        raise FileNotFoundError(f"Car asset missing for angle {angle}")

    composed = composite_car_on_room(Image.open(room_path), Image.open(car_path), angle)
    composed.save(scene_path, format="JPEG", quality=92, optimize=True)
    return scene_path


def build_preset_scene(slug: str, angle: str, scene_path: Path) -> Path:
    """Render empty room, attach BMW, persist a single composed scene file."""
    from app.services.preset_background_renderer import render_preset_background

    scene_path.parent.mkdir(parents=True, exist_ok=True)
    room_path = room_image_path(scene_path)

    with tempfile.TemporaryDirectory() as tmp:
        tmp_room = Path(tmp) / "room.jpg"
        render_preset_background(slug, tmp_room, angle)
        compose_scene_from_room(tmp_room, angle, scene_path)

    return scene_path


def build_scene_from_room_bytes(room_bytes: bytes, angle: str, scene_path: Path) -> Path:
    """Compose BMW onto AI-generated room bytes."""
    scene_path.parent.mkdir(parents=True, exist_ok=True)
    room_path = room_image_path(scene_path)
    room_path.write_bytes(room_bytes)
    try:
        return compose_scene_from_room(room_path, angle, scene_path)
    finally:
        if room_path.exists():
            room_path.unlink(missing_ok=True)
