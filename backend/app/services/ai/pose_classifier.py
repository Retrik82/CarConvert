"""Detect car viewpoint as a free-form pose, then map to catalog angle."""

from __future__ import annotations

import logging
from typing import Any

from app.config import get_settings
from app.services.ai.angle_classifier import classify_car_angle
from app.services.ai.model_router import call_vision_json
from app.services.ai.prompt_blocks import CATALOG_ANGLES
from app.services.pose_to_angle import map_pose_to_catalog_angle

logger = logging.getLogger(__name__)
settings = get_settings()

POSE_SYSTEM_PROMPT = f"""You analyze the camera viewpoint of a car in a photograph.

Your description will be mapped to one catalog angle:
{CATALOG_ANGLES}

Respond ONLY with valid JSON (no markdown):
{{
  "view_family": "profile|front|rear|three_quarter|interior",
  "facing": "front_left|front_right|left|right|front|rear|interior",
  "confidence": 0.0-1.0
}}

Describe the actual camera position relative to the vehicle. Be specific about which side or corner is visible."""


async def classify_car_pose_angle(image_data_url: str, api_key: str | None = None) -> str:
    """Return a catalog angle slug after free-form pose analysis."""
    messages = [
        {"role": "system", "content": POSE_SYSTEM_PROMPT},
        {
            "role": "user",
            "content": [
                {
                    "type": "text",
                    "text": "Describe the camera viewpoint of this car photo. Return JSON only.",
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
        angle = map_pose_to_catalog_angle(data)
        logger.info("Pose classified: %s -> %s", data, angle)
        return angle
    except Exception as exc:
        logger.warning("Pose classification failed (%s), falling back to angle_classifier", exc)
        return await classify_car_angle(image_data_url, api_key)
