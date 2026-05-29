from datetime import datetime
from typing import Literal

from decimal import Decimal

from pydantic import BaseModel, EmailStr, Field

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
    is_admin: bool
    created_at: datetime

    model_config = {"from_attributes": True}


class GenerationPriceOut(BaseModel):
    price_usd: Decimal


class UpdateGenerationPriceRequest(BaseModel):
    price_usd: Decimal = Field(gt=0, le=1000)


class RegisterRequest(BaseModel):
    email: EmailStr
    password: str = Field(min_length=6, max_length=128)
    display_name: str = Field(min_length=1, max_length=120)


class LoginRequest(BaseModel):
    email: str = Field(min_length=1, max_length=255)
    password: str


class RefreshRequest(BaseModel):
    refresh_token: str


class AuthResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
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


class EditResponse(BaseModel):
    success: bool
    image_base64: str | None = None
    mime_type: str | None = None
    message: str | None = None
    error: str | None = None
