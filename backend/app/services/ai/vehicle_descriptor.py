"""Extract visually identifiable vehicle characteristics from a source photograph."""

from __future__ import annotations

import logging
from typing import Any

from app.config import get_settings
from app.services.ai.model_router import call_vision_json

logger = logging.getLogger(__name__)
settings = get_settings()

VEHICLE_DESCRIPTOR_SYSTEM_PROMPT = """\
You are an expert automotive visual analyst.

Goal:
Extract ONLY visually identifiable characteristics of the vehicle in the photograph.

Rules:
- Extract only information explicitly visible in the image.
- Do not infer make/model/generation unless clearly identifiable from badges, shape, or known design cues.
- If a field is not visible or uncertain, set it to null.
- Do not invent details. Missing data is better than hallucinated data.
- Describe what you see, not what the car might be.

Respond ONLY with valid JSON (no markdown, no code fences)."""

VEHICLE_DESCRIPTOR_SCHEMA = """\
{
  "make": string | null,
  "model": string | null,
  "generation": string | null,
  "body_style": string | null,
  "proportions": string | null,
  "body_geometry": string | null,
  "hood_shape": string | null,
  "roof_shape": string | null,
  "pillars": string | null,
  "door_shape": string | null,
  "window_line": string | null,
  "shoulder_line": string | null,
  "wheel_arches": string | null,
  "front_bumper": string | null,
  "rear_bumper": string | null,
  "grille": string | null,
  "headlight_shape": string | null,
  "taillight_shape": string | null,
  "mirrors": string | null,
  "spoilers": string | null,
  "air_intakes": string | null,
  "side_skirts": string | null,
  "sills": string | null,
  "fender_flares": string | null,
  "wheels": string | null,
  "brakes": string | null,
  "ride_height": string | null,
  "ground_clearance": string | null,
  "body_color": string | null,
  "paint_texture": string | null,
  "carbon_elements": string | null,
  "decorative_trim": string | null,
  "brand_design_cues": string | null
}"""

_FIELD_LABELS: dict[str, str] = {
    "make": "Make",
    "model": "Model",
    "generation": "Generation",
    "body_style": "Body style",
    "proportions": "Proportions",
    "body_geometry": "Body geometry",
    "hood_shape": "Hood shape",
    "roof_shape": "Roof shape",
    "pillars": "Pillars",
    "door_shape": "Door shape",
    "window_line": "Window line",
    "shoulder_line": "Shoulder line",
    "wheel_arches": "Wheel arches",
    "front_bumper": "Front bumper",
    "rear_bumper": "Rear bumper",
    "grille": "Grille",
    "headlight_shape": "Headlight shape",
    "taillight_shape": "Taillight shape",
    "mirrors": "Mirrors",
    "spoilers": "Spoilers",
    "air_intakes": "Air intakes",
    "side_skirts": "Side skirts",
    "sills": "Sills",
    "fender_flares": "Fender flares",
    "wheels": "Wheels",
    "brakes": "Brakes",
    "ride_height": "Ride height",
    "ground_clearance": "Ground clearance",
    "body_color": "Body color",
    "paint_texture": "Paint texture",
    "carbon_elements": "Carbon elements",
    "decorative_trim": "Decorative trim",
    "brand_design_cues": "Brand design cues",
}

INTERIOR_FIELD_LABELS: dict[str, str] = {
    "dashboard": "Dashboard",
    "seats": "Seats",
    "steering_wheel": "Steering wheel",
    "trim": "Interior trim",
    "ambient_lighting": "Ambient lighting",
    "infotainment": "Infotainment screen",
    "gear_selector": "Gear selector",
    "body_color": "Exterior color visible through windows",
}


async def describe_vehicle(
    image_data_url: str,
    api_key: str | None = None,
    *,
    angle: str = "three_quarter_left",
) -> dict[str, Any]:
    """Return a structured vehicle description with nulls for unknown fields."""
    if angle == "interior":
        schema = """\
{
  "dashboard": string | null,
  "seats": string | null,
  "steering_wheel": string | null,
  "trim": string | null,
  "ambient_lighting": string | null,
  "infotainment": string | null,
  "gear_selector": string | null,
  "body_color": string | null
}"""
        user_text = (
            "Analyze the car interior visible in this photograph. "
            f"Return JSON matching this schema:\n{schema}"
        )
    else:
        schema = VEHICLE_DESCRIPTOR_SCHEMA
        user_text = (
            "Analyze the vehicle visible in this photograph. "
            f"Return JSON matching this schema:\n{schema}"
        )

    messages = [
        {"role": "system", "content": VEHICLE_DESCRIPTOR_SYSTEM_PROMPT},
        {
            "role": "user",
            "content": [
                {"type": "text", "text": user_text},
                {"type": "image_url", "image_url": {"url": image_data_url}},
            ],
        },
    ]

    try:
        data = await call_vision_json(
            messages,
            primary=settings.pose_model,
            fallback=settings.pose_model_fallback,
            timeout=float(settings.pose_timeout_sec),
            max_tokens=900,
            api_key=api_key,
        )
        return _normalize_descriptor(data, angle=angle)
    except Exception as exc:
        logger.warning("Vehicle description failed (%s); using empty descriptor", exc)
        return {}


def _normalize_descriptor(raw: Any, *, angle: str) -> dict[str, Any]:
    if not isinstance(raw, dict):
        return {}

    labels = INTERIOR_FIELD_LABELS if angle == "interior" else _FIELD_LABELS
    normalized: dict[str, Any] = {}
    for key in labels:
        value = raw.get(key)
        if isinstance(value, str):
            cleaned = value.strip()
            normalized[key] = cleaned if cleaned else None
        else:
            normalized[key] = None
    return normalized


def format_vehicle_identity(descriptor: dict[str, Any] | None, *, angle: str = "three_quarter_left") -> str:
    """Format non-null descriptor fields into a prompt section. Omits unknowns."""
    if not descriptor:
        return (
            "SOURCE VEHICLE IDENTITY: Use the attached photograph as the exact reference. "
            "Preserve every visible detail; do not invent or substitute features."
        )

    labels = INTERIOR_FIELD_LABELS if angle == "interior" else _FIELD_LABELS
    lines: list[str] = []
    for key, label in labels.items():
        value = descriptor.get(key)
        if isinstance(value, str) and value.strip():
            lines.append(f"- {label}: {value.strip()}")

    if not lines:
        return (
            "SOURCE VEHICLE IDENTITY: Use the attached photograph as the exact reference. "
            "Preserve every visible detail; do not invent or substitute features."
        )

    header = "SOURCE VEHICLE IDENTITY (preserve exactly — do not alter unless explicitly requested):"
    return f"{header}\n" + "\n".join(lines)
