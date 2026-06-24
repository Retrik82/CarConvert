"""Unit tests for OpenRouter cost estimates shown in admin panel."""

from decimal import Decimal

from app.config import Settings
from app.services.pricing_estimate_service import (
    build_pricing_estimate,
    estimate_custom_background_cost,
    estimate_generation_cost,
)


def _settings(**overrides: object) -> Settings:
    return Settings(**overrides)


def test_generation_estimate_uses_configured_models() -> None:
    estimate = estimate_generation_cost(
        _settings(
            pose_model="google/gemini-2.5-flash-lite",
            cutout_model="google/gemini-2.5-flash-image",
            composite_model="google/gemini-3.1-flash-image-preview",
            cutout_model_fallback="google/gemini-3.1-flash-image-preview",
            composite_model_fallback="google/gemini-2.5-flash-image",
        )
    )
    assert estimate.service_id == "generation"
    assert len(estimate.steps) == 3
    assert estimate.steps[0].model == "google/gemini-2.5-flash-lite"
    assert estimate.steps[1].model == "google/gemini-2.5-flash-image"
    assert estimate.actual_cost_min_usd == Decimal("0.11")
    assert estimate.actual_cost_max_usd == Decimal("0.21")
    assert estimate.recommended_price_usd == Decimal("0.22")


def test_custom_background_estimate_scales_by_angle_count() -> None:
    estimate = estimate_custom_background_cost(
        _settings(composite_model="google/gemini-3.1-flash-image-preview")
    )
    assert estimate.steps[0].calls == 7
    assert estimate.actual_cost_min_usd == Decimal("0.46")
    assert estimate.recommended_price_usd == Decimal("0.50")


def test_build_pricing_estimate_returns_both_services() -> None:
    bundle = build_pricing_estimate()
    assert bundle.generation.service_id == "generation"
    assert bundle.custom_background.service_id == "custom_background"
