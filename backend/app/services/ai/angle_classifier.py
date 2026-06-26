"""Detect which of the 7 catalog angles best matches a user photo."""

import logging
import re
from typing import Any

from app.config import get_settings
from app.db.models.background import VARIANT_ANGLES
from app.services.ai.model_router import call_vision_json
from app.services.ai.prompt_blocks import CATALOG_ANGLES

logger = logging.getLogger(__name__)
settings = get_settings()

VALID_ANGLES = frozenset(VARIANT_ANGLES)

ANGLE_SYSTEM_PROMPT = f"""You classify the camera viewpoint of a car in a photograph.
Respond ONLY with valid JSON (no markdown):
{{"angle": "<one of {CATALOG_ANGLES}>", "confidence": 0.0-1.0}}

Angle definitions:
- left: side profile, car faces right
- right: side profile, car faces left
- front: straight-on front bumper view
- rear: straight-on rear view
- interior: cabin/dashboard/seats visible, no exterior body profile
- three_quarter_left: front-left three-quarter view
- three_quarter_right: front-right three-quarter view

Pick the closest match even if the photo is imperfect."""


async def classify_car_angle(image_data_url: str, api_key: str | None = None) -> str:
    messages = [
        {"role": "system", "content": ANGLE_SYSTEM_PROMPT},
        {
            "role": "user",
            "content": [
                {
                    "type": "text",
                    "text": "Which catalog camera angle best matches this car photo? Return JSON only.",
                },
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
            max_tokens=120,
            api_key=api_key,
        )
        angle = _normalize_angle(data.get("angle"))
        if angle:
            return angle
    except Exception as exc:
        logger.warning("Angle classification failed (%s), defaulting to three_quarter_left", exc)

    return "three_quarter_left"


def _normalize_angle(raw: Any) -> str | None:
    if not isinstance(raw, str):
        return None
    angle = raw.strip().lower()
    angle = re.sub(r"[\s\-]+", "_", angle)
    aliases = {
        "3_4_left": "three_quarter_left",
        "3_4_right": "three_quarter_right",
        "three_quarter": "three_quarter_left",
        "side_left": "left",
        "side_right": "right",
        "inside": "interior",
    }
    angle = aliases.get(angle, angle)
    if angle in VALID_ANGLES:
        return angle
    return None
