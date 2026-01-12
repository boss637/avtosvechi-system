from __future__ import annotations
from sqlalchemy import Column, Integer, String, Float, Text, Boolean, DateTime, ForeignKey
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from .base import Base

class Product(Base):
    __tablename__ = "products"
    
    id = Column(Integer, primary_key=True, index=True)
    sku = Column(String(100), unique=True, index=True, nullable=False)
    name = Column(String(255), nullable=False)
    description = Column(Text)
    category = Column(String(100))
    brand = Column(String(100))
    
    vehicle_brand = Column(String(50))
    vehicle_model = Column(String(50))
    engine_type = Column(String(50))
    engine_volume = Column(Float)
    year_from = Column(Integer)
    year_to = Column(Integer)
    
    purchase_price = Column(Float, nullable=False)
    selling_price = Column(Float, nullable=False)
    quantity = Column(Integer, default=0)
    min_quantity = Column(Integer, default=5)
    
    vin_codes = Column(Text)
    
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    # Правильное имя relationship для back_populates
    inventory = relationship("Inventory", back_populates="product")
