"""Shared BMW M4 G82 scene layout — matches bundled transparent car renders."""

from __future__ import annotations

from dataclasses import dataclass

CANVAS_WIDTH = 1280
CANVAS_HEIGHT = 720

# Where the car wheels meet the floor in the final composition.
GROUND_Y = int(CANVAS_HEIGHT * 0.682)

# Measured from bundled PNG assets (ground row / image height).
CAR_GROUND_RATIO = 0.884

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
    car_width_ratio: float
    center_x_ratio: float
    car_ground_ratio: float = CAR_GROUND_RATIO
    ground_y: int = GROUND_Y


# Calibrated per bundled car render center-of-mass and aspect ratio.
SCENE_LAYOUTS: dict[str, SceneLayout] = {
    "left": SceneLayout(car_width_ratio=0.86, center_x_ratio=0.484),
    "right": SceneLayout(car_width_ratio=0.86, center_x_ratio=0.511),
    "front": SceneLayout(car_width_ratio=0.52, center_x_ratio=0.499),
    "rear": SceneLayout(car_width_ratio=0.52, center_x_ratio=0.499),
    "three_quarter_left": SceneLayout(car_width_ratio=0.74, center_x_ratio=0.453),
    "three_quarter_right": SceneLayout(car_width_ratio=0.74, center_x_ratio=0.540),
}


def layout_for_angle(angle: str) -> SceneLayout | None:
    return SCENE_LAYOUTS.get(angle)


def car_view_for_angle(angle: str) -> str | None:
    return ANGLE_TO_CAR_VIEW.get(angle)
