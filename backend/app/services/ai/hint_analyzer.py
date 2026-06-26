import logging
import re
from typing import Any

from app.config import get_settings
from app.models.schemas import HintOverlay, HintResponse, HintScores, HintType
from app.services.ai.model_router import call_vision_json

logger = logging.getLogger(__name__)
settings = get_settings()

VALID_HINTS: set[str] = {
    "move_left",
    "move_right",
    "move_closer",
    "move_back",
    "raise_phone",
    "lower_phone",
    "align_car",
    "rotate_slightly",
    "perfect_frame",
    "no_car_detected",
}

HINT_TO_ARROW: dict[str, str] = {
    "move_left": "left",
    "move_right": "right",
    "move_closer": "up",
    "move_back": "down",
    "raise_phone": "up",
    "lower_phone": "down",
    "rotate_slightly": "left",
    "align_car": "none",
    "perfect_frame": "none",
    "no_car_detected": "none",
}

HINT_TO_COLOR: dict[str, str] = {
    "perfect_frame": "green",
    "no_car_detected": "red",
}

HINT_SYSTEM_PROMPT = """You are an expert automotive photography coach helping a user position their car inside a live camera guide frame.

The on-screen guide is a rounded rectangle in the CENTER of the image:
- Portrait: roughly 84% width, 48% height
- Landscape: roughly 80% width, 70% height

The user must move the PHONE so the entire car fits inside this rectangle and is well centered.

Your job: give ONE clear next-step instruction to improve framing.

Respond ONLY with valid JSON (no markdown):
{
  "hint": "move_left",
  "message": "short actionable instruction in Russian (max 8 words)",
  "confidence": 0.85,
  "scores": {"centering": 0.0, "distance": 0.0, "angle": 0.0}
}

Allowed hint values:
move_left, move_right, move_closer, move_back, raise_phone, lower_phone,
align_car, rotate_slightly, perfect_frame, no_car_detected

Decision rules (apply in order):
1. No car or only a tiny part visible → no_car_detected
2. Car too small inside guide (< ~55% of guide area) → move_closer
3. Car too large / cropped by guide edges → move_back
4. Car center clearly left of guide center → move_left
5. Car center clearly right of guide center → move_right
6. Car too low in guide / roof cut off → raise_phone
7. Car too high / wheels cut off → lower_phone
8. Car 55-70% of guide and off-center → move_left, move_right, move_closer, or move_back
9. Car roughly centered but yaw/roll off → rotate_slightly or align_car
10. Car fills ~70-90% of guide, centered, fully visible → perfect_frame

Formatting rules:
- confidence and scores MUST be decimals 0.0-1.0 (never 0-100)
- Prefer move_left/move_right/move_closer/move_back over align_car when possible
- message examples: "Сместись левее", "Подойди ближе", "Отойди назад", "Центрируй машину", "Идеально! Снимай"
"""


def _default_hint() -> HintResponse:
    return HintResponse(
        hint="align_car",
        message="Центрируй машину в рамке",
        confidence=0.35,
        scores=HintScores(centering=0.35, distance=0.35, angle=0.35),
        overlay=HintOverlay(arrow="none", color="yellow"),
    )


def _normalize_confidence(value: Any) -> float:
    try:
        confidence = float(value)
    except (TypeError, ValueError):
        return 0.5
    if confidence > 1.0:
        confidence /= 100.0
    return max(0.0, min(1.0, confidence))


def _normalize_score(value: Any, default: float = 0.5) -> float:
    try:
        score = float(value)
    except (TypeError, ValueError):
        return default
    if score > 1.0:
        score /= 100.0
    return max(0.0, min(1.0, score))


def _normalize_hint(raw: Any) -> HintType:
    if not isinstance(raw, str):
        return "align_car"
    hint = raw.strip().lower()
    hint = re.sub(r"[\s\-]+", "_", hint)
    aliases = {
        "left": "move_left",
        "right": "move_right",
        "closer": "move_closer",
        "back": "move_back",
        "forward": "move_closer",
        "away": "move_back",
        "center": "align_car",
        "centre": "align_car",
        "perfect": "perfect_frame",
        "no_car": "no_car_detected",
    }
    hint = aliases.get(hint, hint)
    if hint in VALID_HINTS:
        return hint  # type: ignore[return-value]
    return "align_car"


def _normalize_arrow(raw: Any, hint: str) -> str:
    mapped = HINT_TO_ARROW.get(hint)
    if mapped is not None:
        return mapped
    if isinstance(raw, str):
        arrow = raw.strip().lower()
        if arrow in {"left", "right", "up", "down", "none"}:
            return arrow
    return "none"


def _normalize_color(raw: Any, hint: str) -> str:
    if isinstance(raw, str):
        color = raw.strip().lower()
        if color in {"yellow", "green", "red"}:
            return color
    return HINT_TO_COLOR.get(hint, "yellow")


def _build_hint_response(data: dict[str, Any]) -> HintResponse:
    hint = _normalize_hint(data.get("hint"))
    overlay_raw = data.get("overlay") if isinstance(data.get("overlay"), dict) else {}
    scores_raw = data.get("scores") if isinstance(data.get("scores"), dict) else {}

    arrow = _normalize_arrow(overlay_raw.get("arrow"), hint)
    color = _normalize_color(overlay_raw.get("color"), hint)

    message = data.get("message")
    if not isinstance(message, str) or not message.strip():
        message = {
            "move_left": "Сместись левее",
            "move_right": "Сместись правее",
            "move_closer": "Подойди ближе",
            "move_back": "Отойди назад",
            "raise_phone": "Подними телефон",
            "lower_phone": "Опусти телефон",
            "rotate_slightly": "Поверни камеру",
            "align_car": "Центрируй машину в рамке",
            "perfect_frame": "Идеально! Можно снимать",
            "no_car_detected": "Машина не видна в кадре",
        }.get(hint, "Центрируй машину в рамке")

    return HintResponse(
        hint=hint,
        message=message.strip(),
        confidence=_normalize_confidence(data.get("confidence", 0.5)),
        scores=HintScores(
            centering=_normalize_score(scores_raw.get("centering"), 0.5),
            distance=_normalize_score(scores_raw.get("distance"), 0.5),
            angle=_normalize_score(scores_raw.get("angle"), 0.5),
        ),
        overlay=HintOverlay(arrow=arrow, color=color),  # type: ignore[arg-type]
    )


def _hint_messages(image_data_url: str) -> list[dict[str, Any]]:
    return [
        {"role": "system", "content": HINT_SYSTEM_PROMPT},
        {
            "role": "user",
            "content": [
                {
                    "type": "text",
                    "text": (
                        "Look at the car relative to the central guide frame. "
                        "Tell the user how to move the phone (left/right/closer/back/up/down) "
                        "so the whole car fits inside the frame. Return JSON only."
                    ),
                },
                {"type": "image_url", "image_url": {"url": image_data_url}},
            ],
        },
    ]


async def analyze_frame(image_data_url: str, api_key: str | None = None) -> HintResponse:
    try:
        data = await call_vision_json(
            _hint_messages(image_data_url),
            primary=settings.hint_primary,
            fallback=settings.hint_model_fallback,
            timeout=float(settings.hint_timeout_sec),
            max_tokens=300,
            api_key=api_key,
        )
        return _build_hint_response(data)
    except Exception as exc:
        logger.warning("Hint analysis failed: %s", exc)
        return _default_hint()
