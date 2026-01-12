from __future__ import annotations
from sqlalchemy import Column, Integer, String, Float, DateTime
from sqlalchemy.sql import func
from sqlalchemy.orm import Mapped, mapped_column
from app.models.base import Base


class ProductABC(Base):
    __tablename__ = "product_abc_class"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    product_id: Mapped[int] = mapped_column(Integer, unique=True, index=True)
    abc_class: Mapped[str] = mapped_column(String(1), nullable=False)  # 'A', 'B', 'C'
    turnover_3m: Mapped[float] = mapped_column(Float, nullable=False)
    avg_daily_sales: Mapped[float] = mapped_column(Float, nullable=False)
    calculated_at: Mapped[DateTime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
