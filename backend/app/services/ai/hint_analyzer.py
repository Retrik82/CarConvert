import logging

from app.config import get_settings
from app.models.schemas import HintOverlay, HintResponse, HintScores
from app.services.ai.openrouter_client import OpenRouterClient

logger = logging.getLogger(__name__)
settings = get_settings()

HINT_SYSTEM_PROMPT = """You are an expert automotive photography assistant analyzing a live camera frame.
Evaluate car position, centering, distance, angle, lighting, and composition safety.
Respond ONLY with valid JSON (no markdown) in this exact schema:
{
  "hint": "move_left|move_right|move_closer|move_back|raise_phone|lower_phone|align_car|rotate_slightly|perfect_frame|no_car_detected",
  "message": "short instruction in Russian",
  "confidence": 0.0-1.0,
  "scores": {"centering": 0.0-1.0, "distance": 0.0-1.0, "angle": 0.0-1.0},
  "overlay": {"arrow": "left|right|up|down|none", "color": "yellow|green|red"}
}
Use hint=perfect_frame and overlay.color=green when the frame is ideal for capture.
Use no_car_detected if no vehicle is visible."""


def _default_hint() -> HintResponse:
    return HintResponse(
        hint="align_car",
        message="Наведи камеру на машину",
        confidence=0.4,
        scores=HintScores(centering=0.4, distance=0.4, angle=0.4),
        overlay=HintOverlay(arrow="none", color="yellow"),
    )


async def analyze_frame(image_data_url: str, api_key: str | None = None) -> HintResponse:
    client = OpenRouterClient(api_key)
    try:
        text = await client.chat_text(
            model=settings.hint_model,
            messages=[
                {"role": "system", "content": HINT_SYSTEM_PROMPT},
                {
                    "role": "user",
                    "content": [
                        {
                            "type": "text",
                            "text": "Analyze this camera frame and return JSON hints for the photographer.",
                        },
                        {"type": "image_url", "image_url": {"url": image_data_url}},
                    ],
                },
            ],
            timeout=float(settings.hint_timeout_sec),
            max_tokens=256,
        )
        data = client.parse_json_from_text(text)
        return HintResponse(
            hint=data.get("hint", "align_car"),
            message=data.get("message", "Выровняй машину"),
            confidence=float(data.get("confidence", 0.5)),
            scores=HintScores(**data.get("scores", {})),
            overlay=HintOverlay(**data.get("overlay", {})),
        )
    except Exception as exc:
        logger.warning("Hint analysis failed: %s", exc)
        return _default_hint()
