"""Estimate OpenRouter AI cost and recommended user-facing prices for admin."""

from __future__ import annotations

from dataclasses import dataclass
from decimal import Decimal, ROUND_HALF_UP

from app.config import Settings, get_settings
from app.db.models.background import VARIANT_ANGLES

# Reference OpenRouter list-price estimates per typical call (USD), June 2026.
MODEL_CALL_COST_USD: dict[str, Decimal] = {
    "rekaai/reka-edge": Decimal("0.0005"),
    "google/gemini-2.5-flash-lite": Decimal("0.0003"),
    "google/gemini-2.5-flash": Decimal("0.0008"),
    "google/gemini-2.5-flash-image": Decimal("0.04"),
    "google/gemini-3.1-flash-image-preview": Decimal("0.065"),
    "google/gemini-3-pro-image-preview": Decimal("0.15"),
}

DEFAULT_MODEL_COST_USD = Decimal("0.05")
FALLBACK_BUFFER = Decimal("1.25")
RECOMMENDED_MULTIPLIER_GENERATION = Decimal("2.0")
RECOMMENDED_MULTIPLIER_CUSTOM_BACKGROUND = Decimal("1.10")


def _model_cost(model: str) -> Decimal:
    return MODEL_CALL_COST_USD.get(model, DEFAULT_MODEL_COST_USD)


def _quantize_usd(value: Decimal) -> Decimal:
    return value.quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)


@dataclass(frozen=True)
class StepEstimate:
    step_id: str
    label: str
    model: str
    calls: int
    cost_usd: Decimal


@dataclass(frozen=True)
class ServiceEstimate:
    service_id: str
    label: str
    actual_cost_min_usd: Decimal
    actual_cost_max_usd: Decimal
    recommended_price_usd: Decimal
    steps: tuple[StepEstimate, ...]


@dataclass(frozen=True)
class PricingEstimate:
    generation: ServiceEstimate
    custom_background: ServiceEstimate


def _step(step_id: str, label: str, model: str, *, calls: int = 1) -> StepEstimate:
    return StepEstimate(
        step_id=step_id,
        label=label,
        model=model,
        calls=calls,
        cost_usd=_model_cost(model) * calls,
    )


def estimate_generation_cost(settings: Settings | None = None) -> ServiceEstimate:
    cfg = settings or get_settings()
    steps = (
        _step("pose", "Ракурс (pose → angle)", cfg.pose_model),
        _step("describe", "Анализ машины (vision)", cfg.pose_model),
        _step("inplace", "Замена фона in-place", cfg.inplace_background_model),
    )
    min_cost = sum((step.cost_usd for step in steps), Decimal("0"))
    retry_extra = _model_cost(cfg.inplace_background_model_fallback)
    max_cost = min_cost + retry_extra
    recommended = _quantize_usd(_quantize_usd(min_cost) * RECOMMENDED_MULTIPLIER_GENERATION)
    return ServiceEstimate(
        service_id="generation",
        label="Генерация фото",
        actual_cost_min_usd=_quantize_usd(min_cost),
        actual_cost_max_usd=_quantize_usd(max_cost),
        recommended_price_usd=recommended,
        steps=steps,
    )


def estimate_custom_background_cost(settings: Settings | None = None) -> ServiceEstimate:
    cfg = settings or get_settings()
    angle_count = len(VARIANT_ANGLES)
    model = cfg.composite_primary
    step = _step(
        "scene_generation",
        f"AI-сцены ({angle_count} ракурсов)",
        model,
        calls=angle_count,
    )
    min_cost = step.cost_usd
    max_cost = min_cost * FALLBACK_BUFFER
    recommended = _quantize_usd(min_cost * RECOMMENDED_MULTIPLIER_CUSTOM_BACKGROUND)
    return ServiceEstimate(
        service_id="custom_background",
        label="Кастомный фон",
        actual_cost_min_usd=_quantize_usd(min_cost),
        actual_cost_max_usd=_quantize_usd(max_cost),
        recommended_price_usd=recommended,
        steps=(step,),
    )


def build_pricing_estimate(settings: Settings | None = None) -> PricingEstimate:
    cfg = settings or get_settings()
    return PricingEstimate(
        generation=estimate_generation_cost(cfg),
        custom_background=estimate_custom_background_cost(cfg),
    )
