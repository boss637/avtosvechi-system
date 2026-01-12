from datetime import datetime
from sqlalchemy import Column, Integer, String, Numeric, DateTime, ForeignKey, Index
from sqlalchemy.sql import func
from app.models.base import Base


class ProductCompatibility(Base):
    __tablename__ = "product_compatibility"

    id = Column(Integer, primary_key=True)
    product_id = Column(Integer, ForeignKey("products.id", ondelete="CASCADE"), nullable=False)
    vehicle_brand = Column(String(100), nullable=False)
    vehicle_model = Column(String(100), nullable=True)
    year_from = Column(Integer, nullable=True)
    year_to = Column(Integer, nullable=True)
    engine_code = Column(String(64), nullable=True)
    engine_volume = Column(Numeric(4, 1), nullable=True)
    confidence = Column(Numeric(3, 2), nullable=False, server_default="0.90")
    source = Column(String(50), nullable=False, server_default="'manual'")
    source_ref = Column(String(255), nullable=True)
    last_verified_at = Column(DateTime(timezone=True), nullable=True)
    created_at = Column(DateTime(timezone=True), nullable=False, server_default=func.now())
    updated_at = Column(DateTime(timezone=True), nullable=False, server_default=func.now(), onupdate=func.now())

    __table_args__ = (
        Index('idx_pc_vehicle_search', 'vehicle_brand', 'vehicle_model', 'year_from', 'year_to'),
        Index('idx_pc_product_id', 'product_id'),
    )
