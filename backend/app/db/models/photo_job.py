from __future__ import annotations

import uuid
from datetime import datetime
from decimal import Decimal

from sqlalchemy import DateTime, ForeignKey, Numeric, String, Text, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base


def _uuid() -> str:
    return str(uuid.uuid4())


class PhotoJob(Base):
    __tablename__ = "photo_jobs"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_uuid)
    user_id: Mapped[str] = mapped_column(String(36), ForeignKey("users.id"), index=True)
    session_id: Mapped[str | None] = mapped_column(String(36), ForeignKey("camera_sessions.id"), nullable=True)
    status: Mapped[str] = mapped_column(String(32), default="queued", index=True)
    original_path: Mapped[str | None] = mapped_column(String(512), nullable=True)
    result_path: Mapped[str | None] = mapped_column(String(512), nullable=True)
    result_mime_type: Mapped[str | None] = mapped_column(String(64), nullable=True)
    background_preset_id: Mapped[str | None] = mapped_column(String(36), nullable=True)
    background_variant_id: Mapped[str | None] = mapped_column(String(36), nullable=True)
    user_background_id: Mapped[str | None] = mapped_column(String(36), nullable=True)
    user_background_variant_id: Mapped[str | None] = mapped_column(String(36), nullable=True)
    error: Mapped[str | None] = mapped_column(Text, nullable=True)
    charged_amount: Mapped[Decimal | None] = mapped_column(Numeric(10, 2), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    enqueued_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    processing_started_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    completed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)

    user: Mapped[User] = relationship(back_populates="photo_jobs")
    session: Mapped[CameraSession | None] = relationship(back_populates="photo_jobs")
