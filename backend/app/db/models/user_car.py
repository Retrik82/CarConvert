from __future__ import annotations

import uuid
from datetime import datetime
from decimal import Decimal

from sqlalchemy import DateTime, ForeignKey, Numeric, String, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base


def _uuid() -> str:
    return str(uuid.uuid4())


class UserCar(Base):
    __tablename__ = "user_cars"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_uuid)
    user_id: Mapped[str] = mapped_column(String(36), ForeignKey("users.id"), index=True)
    name: Mapped[str] = mapped_column(String(120))
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())

    user: Mapped[User] = relationship(back_populates="user_cars")
    renders: Mapped[list[SavedRender]] = relationship(
        back_populates="car",
        cascade="all, delete-orphan",
        order_by="SavedRender.created_at",
    )


class SavedRender(Base):
    __tablename__ = "saved_renders"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_uuid)
    car_id: Mapped[str] = mapped_column(String(36), ForeignKey("user_cars.id"), index=True)
    user_id: Mapped[str] = mapped_column(String(36), ForeignKey("users.id"), index=True)
    job_id: Mapped[str | None] = mapped_column(String(36), nullable=True, index=True)
    name: Mapped[str | None] = mapped_column(String(200), nullable=True)
    original_path: Mapped[str | None] = mapped_column(String(512), nullable=True)
    rendered_path: Mapped[str | None] = mapped_column(String(512), nullable=True)
    quality_score: Mapped[Decimal | None] = mapped_column(Numeric(5, 2), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())

    car: Mapped[UserCar] = relationship(back_populates="renders")


from app.db.models.user import User  # noqa: E402
