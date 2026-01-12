from datetime import datetime
from sqlalchemy import Column, Integer, String, Numeric, Boolean, DateTime, Index
from sqlalchemy.sql import func
from app.models.base import Base


class ProductAnalog(Base):
    __tablename__ = "product_analogs"

    id = Column(Integer, primary_key=True)
    original_sku = Column(String(50), nullable=False)
    analog_sku = Column(String(50), nullable=False)
    brand_original = Column(String(50), nullable=True)
    brand_analog = Column(String(50), nullable=True)
    compatibility_score = Column(Numeric(3, 2), nullable=True)
    verified = Column(Boolean, nullable=False, server_default="false")
    source = Column(String(50), nullable=False, server_default="'manual'")
    source_ref = Column(String(255), nullable=True)
    created_at = Column(DateTime(timezone=True), nullable=False, server_default=func.now())

    __table_args__ = (
        Index('uq_product_analogs_original_analog', 'original_sku', 'analog_sku', unique=True),
    )
