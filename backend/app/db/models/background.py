from __future__ import annotations

import uuid
from datetime import datetime

from sqlalchemy import Boolean, DateTime, ForeignKey, Integer, String, Text, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base

VARIANT_ANGLES = (
    "left",
    "right",
    "front",
    "rear",
    "interior",
    "three_quarter_left",
    "three_quarter_right",
)

ANGLE_PROMPT_SUFFIXES: dict[str, str] = {
    "left": (
        "Camera: driver-side profile, BMW coupe facing right. "
        "Floor horizon at 58% height, centered podium under wheelbase."
    ),
    "right": (
        "Camera: passenger-side profile, BMW coupe facing left. "
        "Floor horizon at 58% height, centered podium under wheelbase."
    ),
    "front": "Camera: straight front view at bumper height, symmetrical studio, centered podium.",
    "rear": "Camera: straight rear view at trunk height, symmetrical studio, centered podium.",
    "interior": "Camera: interior cabin view, dashboard and front seats, ambient lighting.",
    "three_quarter_left": (
        "Camera: three-quarter front-left, nose slightly right, perspective floor, podium left of center."
    ),
    "three_quarter_right": (
        "Camera: three-quarter front-right, nose slightly left, perspective floor, podium right of center."
    ),
}


def _uuid() -> str:
    return str(uuid.uuid4())


class BackgroundPreset(Base):
    __tablename__ = "background_presets"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_uuid)
    slug: Mapped[str] = mapped_column(String(64), unique=True, index=True)
    name: Mapped[str] = mapped_column(String(120))
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    prompt_template: Mapped[str] = mapped_column(Text)
    preview_variant_id: Mapped[str | None] = mapped_column(String(36), nullable=True)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    sort_order: Mapped[int] = mapped_column(Integer, default=0)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())

    variants: Mapped[list[BackgroundVariant]] = relationship(
        back_populates="preset",
        cascade="all, delete-orphan",
    )


class BackgroundVariant(Base):
    __tablename__ = "background_variants"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_uuid)
    preset_id: Mapped[str] = mapped_column(String(36), ForeignKey("background_presets.id"), index=True)
    angle: Mapped[str] = mapped_column(String(32), index=True)
    image_path: Mapped[str | None] = mapped_column(String(512), nullable=True)
    prompt_suffix: Mapped[str] = mapped_column(Text, default="")

    preset: Mapped[BackgroundPreset] = relationship(back_populates="variants")


class UserBackground(Base):
    __tablename__ = "user_backgrounds"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_uuid)
    user_id: Mapped[str] = mapped_column(String(36), ForeignKey("users.id"), index=True)
    name: Mapped[str] = mapped_column(String(120))
    prompt: Mapped[str] = mapped_column(Text)
    preview_variant_id: Mapped[str | None] = mapped_column(String(36), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())

    variants: Mapped[list[UserBackgroundVariant]] = relationship(
        back_populates="background",
        cascade="all, delete-orphan",
    )


class UserBackgroundVariant(Base):
    __tablename__ = "user_background_variants"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_uuid)
    background_id: Mapped[str] = mapped_column(String(36), ForeignKey("user_backgrounds.id"), index=True)
    angle: Mapped[str] = mapped_column(String(32), index=True)
    image_path: Mapped[str | None] = mapped_column(String(512), nullable=True)
    prompt_suffix: Mapped[str] = mapped_column(Text, default="")

    background: Mapped[UserBackground] = relationship(back_populates="variants")
