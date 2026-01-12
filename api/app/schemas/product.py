from typing import Optional, Union, List
import json
from pydantic import ConfigDict, BaseModel, Field, validator
from datetime import datetime

class ProductBase(BaseModel):
    sku: str = Field(..., min_length=3, max_length=100)
    name: str = Field(..., min_length=2, max_length=255)
    description: Optional[str] = None
    category: Optional[str] = None
    brand: Optional[str] = None
    
    # Технические характеристики
    vehicle_brand: Optional[str] = None
    vehicle_model: Optional[str] = None
    engine_type: Optional[str] = None
    engine_volume: Optional[float] = None
    year_from: Optional[int] = None
    year_to: Optional[int] = None
    
    # Цены и остатки
    purchase_price: float = Field(..., gt=0)
    selling_price: float = Field(..., gt=0)
    quantity: int = Field(default=0, ge=0)
    min_quantity: int = Field(default=5, ge=0)
    
    # VIN совместимость - принимаем список или строку, сохраняем как JSON-строку
    vin_codes: Optional[Union[str, List[str]]] = None

    @validator('vin_codes', pre=True, always=True)
    def convert_vin_codes(cls, v):
        if v is None:
            return None
        if isinstance(v, list):
            return json.dumps(v, ensure_ascii=False)
        if isinstance(v, str):
            try:
                json.loads(v)
                return v
            except json.JSONDecodeError:
                return json.dumps([v], ensure_ascii=False)
        return v

    class Config:
        from_attributes = True

class ProductCreate(ProductBase):
    pass

class ProductUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    selling_price: Optional[float] = None
    quantity: Optional[int] = None
    min_quantity: Optional[int] = None
    vin_codes: Optional[Union[str, List[str]]] = None

class ProductInDB(ProductBase):
    id: int
    is_active: bool = True
    created_at: datetime
    updated_at: Optional[datetime] = None

class Product(ProductInDB):
    model_config = ConfigDict(from_attributes=True)

    pass
