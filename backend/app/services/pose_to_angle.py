"""Map free-form car pose descriptions to catalog background angles."""

from __future__ import annotations

from typing import Any

from app.db.models.background import VARIANT_ANGLES

VALID_ANGLES = frozenset(VARIANT_ANGLES)


def map_pose_to_catalog_angle(pose: dict[str, Any]) -> str:
    """Translate pose classifier output to the nearest catalog angle slug."""
    view_family = _norm(pose.get("view_family"))
    facing = _norm(pose.get("facing"))
    direct_angle = _norm(pose.get("angle"))

    if direct_angle in VALID_ANGLES:
        return direct_angle

    if view_family == "interior" or facing == "interior":
        return "interior"

    if view_family in {"profile", "side"}:
        if facing in {"left", "driver_side", "driver"}:
            return "left"
        if facing in {"right", "passenger_side", "passenger"}:
            return "right"
        return "left"

    if view_family in {"front", "head_on"}:
        return "front"

    if view_family in {"rear", "back"}:
        return "rear"

    if view_family in {"three_quarter", "3_4", "three_quarter_view"}:
        if facing in {"front_right", "right_front", "passenger_front"}:
            return "three_quarter_right"
        return "three_quarter_left"

    if facing in {"front_left", "left_front", "driver_front"}:
        return "three_quarter_left"
    if facing in {"front_right", "right_front", "passenger_front"}:
        return "three_quarter_right"
    if facing == "front":
        return "front"
    if facing == "rear":
        return "rear"
    if facing in {"left", "driver_side"}:
        return "left"
    if facing in {"right", "passenger_side"}:
        return "right"

    return "three_quarter_left"


def _norm(value: Any) -> str:
    if not isinstance(value, str):
        return ""
    return value.strip().lower().replace("-", "_").replace(" ", "_")
