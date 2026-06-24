from decimal import Decimal

from fastapi import APIRouter, Depends

from app.api.deps import get_current_admin, get_settings_service
from app.db.models.user import User
from app.models.schemas import (
    AdminPricingEstimateOut,
    CustomBackgroundPriceOut,
    GenerationPriceOut,
    PricingStepEstimateOut,
    ServicePricingEstimateOut,
    UpdateCustomBackgroundPriceRequest,
    UpdateGenerationPriceRequest,
)
from app.services.pricing_estimate_service import build_pricing_estimate
from app.services.settings_service import SettingsService


def _service_estimate_out(estimate) -> ServicePricingEstimateOut:
    return ServicePricingEstimateOut(
        service_id=estimate.service_id,
        label=estimate.label,
        actual_cost_min_usd=estimate.actual_cost_min_usd,
        actual_cost_max_usd=estimate.actual_cost_max_usd,
        recommended_price_usd=estimate.recommended_price_usd,
        steps=[
            PricingStepEstimateOut(
                step_id=step.step_id,
                label=step.label,
                model=step.model,
                calls=step.calls,
                cost_usd=step.cost_usd,
            )
            for step in estimate.steps
        ],
    )

router = APIRouter(prefix="/admin", tags=["admin"])


@router.get("/settings/price", response_model=GenerationPriceOut)
async def admin_get_price(
    _: User = Depends(get_current_admin),
    settings: SettingsService = Depends(get_settings_service),
) -> GenerationPriceOut:
    price = await settings.get_generation_price()
    return GenerationPriceOut(price_usd=price)


@router.put("/settings/price", response_model=GenerationPriceOut)
async def admin_set_price(
    payload: UpdateGenerationPriceRequest,
    _: User = Depends(get_current_admin),
    settings: SettingsService = Depends(get_settings_service),
) -> GenerationPriceOut:
    price = await settings.set_generation_price(Decimal(str(payload.price_usd)))
    return GenerationPriceOut(price_usd=price)


@router.get("/settings/custom-background-price", response_model=CustomBackgroundPriceOut)
async def admin_get_custom_background_price(
    _: User = Depends(get_current_admin),
    settings: SettingsService = Depends(get_settings_service),
) -> CustomBackgroundPriceOut:
    price = await settings.get_custom_background_price()
    return CustomBackgroundPriceOut(price_usd=price)


@router.put("/settings/custom-background-price", response_model=CustomBackgroundPriceOut)
async def admin_set_custom_background_price(
    payload: UpdateCustomBackgroundPriceRequest,
    _: User = Depends(get_current_admin),
    settings: SettingsService = Depends(get_settings_service),
) -> CustomBackgroundPriceOut:
    price = await settings.set_custom_background_price(Decimal(str(payload.price_usd)))
    return CustomBackgroundPriceOut(price_usd=price)


@router.get("/settings/pricing-estimate", response_model=AdminPricingEstimateOut)
async def admin_get_pricing_estimate(
    _: User = Depends(get_current_admin),
    settings: SettingsService = Depends(get_settings_service),
) -> AdminPricingEstimateOut:
    estimate = build_pricing_estimate()
    charged_generation = await settings.get_generation_price()
    charged_custom = await settings.get_custom_background_price()
    return AdminPricingEstimateOut(
        generation=_service_estimate_out(estimate.generation),
        custom_background=_service_estimate_out(estimate.custom_background),
        charged_generation_price_usd=charged_generation,
        charged_custom_background_price_usd=charged_custom,
    )
