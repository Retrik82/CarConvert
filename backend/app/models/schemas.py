from datetime import datetime
from typing import Literal

from decimal import Decimal

from pydantic import BaseModel, EmailStr, Field, field_validator

HintType = Literal[
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
]

ArrowType = Literal["left", "right", "up", "down", "none"]
OverlayColor = Literal["yellow", "green", "red"]


class UserOut(BaseModel):
    id: str
    email: str
    display_name: str
    balance: Decimal
    role: str = "user"
    is_admin: bool
    email_verified: bool = False
    created_at: datetime

    model_config = {"from_attributes": True}


class DeviceMeta(BaseModel):
    device_id: str | None = Field(default=None, max_length=128)
    device_name: str | None = Field(default=None, max_length=255)


class SessionOut(BaseModel):
    id: str
    device_id: str | None
    device_name: str | None
    user_agent: str | None
    created_at: datetime
    last_used_at: datetime | None
    expires_at: datetime
    is_current: bool = False


class SessionsResponse(BaseModel):
    sessions: list[SessionOut]


class GenerationPriceOut(BaseModel):
    price_usd: Decimal


def _validate_price_usd(value: Decimal) -> Decimal:
    quantized = value.quantize(Decimal("0.01"))
    if quantized != value:
        raise ValueError("Maximum 2 decimal places")
    return value


class UpdateGenerationPriceRequest(BaseModel):
    price_usd: Decimal = Field(gt=Decimal("0"), le=Decimal("999.99"))

    @field_validator("price_usd")
    @classmethod
    def validate_price_usd(cls, value: Decimal) -> Decimal:
        return _validate_price_usd(value)


class CustomBackgroundPriceOut(BaseModel):
    price_usd: Decimal


class UpdateCustomBackgroundPriceRequest(BaseModel):
    price_usd: Decimal = Field(gt=Decimal("0"), le=Decimal("999.99"))

    @field_validator("price_usd")
    @classmethod
    def validate_price_usd(cls, value: Decimal) -> Decimal:
        return _validate_price_usd(value)


class PricingStepEstimateOut(BaseModel):
    step_id: str
    label: str
    model: str
    calls: int
    cost_usd: Decimal


class ServicePricingEstimateOut(BaseModel):
    service_id: str
    label: str
    actual_cost_min_usd: Decimal
    actual_cost_max_usd: Decimal
    recommended_price_usd: Decimal
    steps: list[PricingStepEstimateOut]


class AdminPricingEstimateOut(BaseModel):
    generation: ServicePricingEstimateOut
    custom_background: ServicePricingEstimateOut
    charged_generation_price_usd: Decimal
    charged_custom_background_price_usd: Decimal


class BackgroundVariantOut(BaseModel):
    id: str
    angle: str
    preview_url: str | None = None

    model_config = {"from_attributes": True}


class BackgroundPresetOut(BaseModel):
    id: str
    slug: str
    name: str
    description: str | None = None
    prompt_template: str | None = None
    preview_url: str | None = None
    variants: list[BackgroundVariantOut] = Field(default_factory=list)
    is_custom: bool = False

    model_config = {"from_attributes": True}


class BackgroundCatalogResponse(BaseModel):
    presets: list[BackgroundPresetOut]
    custom: list[BackgroundPresetOut]
    custom_background_price_usd: Decimal


class CarModelOut(BaseModel):
    id: str
    name: str
    views: list[str]
    paints: list[str]
    default_view: str
    preview_url: str


class CarCatalogResponse(BaseModel):
    models: list[CarModelOut]


class RegisterRequest(DeviceMeta):
    email: EmailStr
    password: str = Field(min_length=6, max_length=128)
    display_name: str = Field(min_length=1, max_length=120)


class LoginRequest(DeviceMeta):
    email: str = Field(min_length=1, max_length=255)
    password: str


class ForgotPasswordRequest(BaseModel):
    email: EmailStr


class ResetPasswordRequest(BaseModel):
    token: str = Field(min_length=20)
    new_password: str = Field(min_length=6, max_length=128)


class LogoutAllRequest(BaseModel):
    keep_current_session: bool = True


class RefreshRequest(BaseModel):
    refresh_token: str


class AuthResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    session_id: str | None = None
    user: UserOut


class SessionStartResponse(BaseModel):
    session_id: str
    expires_at: datetime


class HintScores(BaseModel):
    centering: float = 0.0
    distance: float = 0.0
    angle: float = 0.0


class HintOverlay(BaseModel):
    arrow: ArrowType = "none"
    color: OverlayColor = "yellow"


class HintResponse(BaseModel):
    type: str = "hint"
    hint: HintType = "align_car"
    message: str = "Выровняй машину"
    confidence: float = 0.5
    scores: HintScores = Field(default_factory=HintScores)
    overlay: HintOverlay = Field(default_factory=HintOverlay)


class ProcessJobResponse(BaseModel):
    job_id: str
    status: str


class PhotoResultResponse(BaseModel):
    job_id: str
    status: str
    image_base64: str | None = None
    mime_type: str | None = None
    error: str | None = None


class HistoryItem(BaseModel):
    job_id: str
    status: str
    created_at: datetime
    completed_at: datetime | None = None
    has_result: bool = False


class HistoryResponse(BaseModel):
    items: list[HistoryItem]
    total: int


class SavedRenderOut(BaseModel):
    id: str
    job_id: str | None = None
    name: str | None = None
    created_at: datetime
    quality_score: float | None = None
    has_original: bool = False
    has_rendered: bool = False
    original_url: str | None = None
    rendered_url: str | None = None


class UserCarOut(BaseModel):
    id: str
    name: str
    created_at: datetime
    renders: list[SavedRenderOut] = Field(default_factory=list)


class MyCarsResponse(BaseModel):
    cars: list[UserCarOut]


class CreateUserCarRequest(BaseModel):
    name: str = Field(default="My Car", max_length=120)


class UpdateUserCarRequest(BaseModel):
    name: str = Field(min_length=1, max_length=120)


class UpdateUserRenderRequest(BaseModel):
    name: str = Field(min_length=1, max_length=200)


class EditResponse(BaseModel):
    success: bool
    image_base64: str | None = None
    mime_type: str | None = None
    message: str | None = None
    error: str | None = None
