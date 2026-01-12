from typing import Optional
from pydantic import BaseModel, Field
from datetime import datetime

class VehicleBase(BaseModel):
    vin: str = Field(..., min_length=17, max_length=17, pattern=r'^[A-HJ-NPR-Z0-9]{17}$')
    make: str = Field(..., min_length=2, max_length=100)
    model: str = Field(..., min_length=1, max_length=100)
    year: Optional[int] = None
    engine_code: Optional[str] = None

class VehicleCreate(VehicleBase):
    pass

class VehicleUpdate(BaseModel):
    make: Optional[str] = None
    model: Optional[str] = None
    year: Optional[int] = None
    engine_code: Optional[str] = None

class VehicleInDB(VehicleBase):
    id: int
    created_at: datetime
    
    class Config:
        from_attributes = True

class Vehicle(VehicleInDB):
    pass

class VinDecodeRequest(BaseModel):
    vin: str = Field(..., min_length=17, max_length=17)

class ProductSearchByParams(BaseModel):
    make: Optional[str] = None
    model: Optional[str] = None
    year: Optional[int] = None
    engine_code: Optional[str] = None
