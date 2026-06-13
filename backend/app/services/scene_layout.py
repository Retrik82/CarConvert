"""Shared BMW M4 G82 scene layout — matches bundled transparent car renders."""

from __future__ import annotations

from dataclasses import dataclass

CANVAS_WIDTH = 1280
CANVAS_HEIGHT = 720

# Vertical safe zone for the full car silhouette.
MARGIN_TOP_RATIO = 0.07
MARGIN_SIDE_RATIO = 0.05

# Where the car wheels meet the floor in the final composition.
GROUND_Y = int(CANVAS_HEIGHT * 0.70)

ANGLE_TO_CAR_VIEW: dict[str, str] = {
    "left": "side_left",
    "right": "side_right",
    "front": "front",
    "rear": "rear",
    "three_quarter_left": "three_quarter_left",
    "three_quarter_right": "three_quarter_right",
}


@dataclass(frozen=True)
class SceneLayout:
    center_x_ratio: float
    max_width_ratio: float
    ground_y: int = GROUND_Y


# Center of mass per angle; max width is an upper bound — compositor scales down to fit height.
SCENE_LAYOUTS: dict[str, SceneLayout] = {
    "left": SceneLayout(center_x_ratio=0.50, max_width_ratio=0.88),
    "right": SceneLayout(center_x_ratio=0.50, max_width_ratio=0.88),
    "front": SceneLayout(center_x_ratio=0.50, max_width_ratio=0.56),
    "rear": SceneLayout(center_x_ratio=0.50, max_width_ratio=0.56),
    "three_quarter_left": SceneLayout(center_x_ratio=0.48, max_width_ratio=0.78),
    "three_quarter_right": SceneLayout(center_x_ratio=0.52, max_width_ratio=0.78),
}


def layout_for_angle(angle: str) -> SceneLayout | None:
    return SCENE_LAYOUTS.get(angle)


def car_view_for_angle(angle: str) -> str | None:
    return ANGLE_TO_CAR_VIEW.get(angle)
