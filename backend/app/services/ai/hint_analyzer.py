import logging
import re
from typing import Any

from app.config import get_settings
from app.models.schemas import HintOverlay, HintResponse, HintScores, HintType
from app.services.ai.openrouter_client import OpenRouterClient

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

HINT_SYSTEM_PROMPT = """You are an expert automotive photography assistant analyzing a live camera frame.
Evaluate car position, centering, distance, angle, lighting, and composition inside the guide frame.
Respond ONLY with valid JSON (no markdown) in this exact schema:
{
  "hint": "move_left|move_right|move_closer|move_back|raise_phone|lower_phone|align_car|rotate_slightly|perfect_frame|no_car_detected",
  "message": "short instruction in Russian",
  "confidence": 0.85,
  "scores": {"centering": 0.0-1.0, "distance": 0.0-1.0, "angle": 0.0-1.0},
  "overlay": {"arrow": "left|right|up|down|none", "color": "yellow|green|red"}
}
Rules:
- confidence and scores MUST be decimals between 0.0 and 1.0 (never 0-100).
- move_left => overlay.arrow must be "left"; move_right => "right"; move_closer/raise_phone => "up"; move_back/lower_phone => "down".
- hint=perfect_frame => overlay.color=green, arrow=none.
- no_car_detected => overlay.color=red."""


def _default_hint() -> HintResponse:
    return HintResponse(
        hint="align_car",
        message="Наведи камеру на машину",
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
            "perfect_frame": "Идеально! Можно снимать",
            "no_car_detected": "Машина не видна в кадре",
        }.get(hint, "Выровняй машину в рамке")

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


async def _request_hint_text(client: OpenRouterClient, image_data_url: str, use_json_mode: bool) -> str:
    messages = [
        {"role": "system", "content": HINT_SYSTEM_PROMPT},
        {
            "role": "user",
            "content": [
                {
                    "type": "text",
                    "text": (
                        "Analyze this camera frame. The car should fill the central guide frame. "
                        "Return JSON only."
                    ),
                },
                {"type": "image_url", "image_url": {"url": image_data_url}},
            ],
        },
    ]
    kwargs: dict[str, Any] = {
        "model": settings.hint_model,
        "messages": messages,
        "timeout": float(settings.hint_timeout_sec),
        "max_tokens": 300,
    }
    if use_json_mode:
        kwargs["response_format"] = {"type": "json_object"}
    return await client.chat_text(**kwargs)


async def analyze_frame(image_data_url: str, api_key: str | None = None) -> HintResponse:
    client = OpenRouterClient(api_key)
    last_error: Exception | None = None
    for use_json_mode in (True, False):
        try:
            text = await _request_hint_text(client, image_data_url, use_json_mode=use_json_mode)
            data = client.parse_json_from_text(text)
            return _build_hint_response(data)
        except Exception as exc:
            last_error = exc
            if use_json_mode:
                logger.info("Hint JSON mode failed, retrying without response_format: %s", exc)
                continue
    logger.warning("Hint analysis failed: %s", last_error)
    return _default_hint()
