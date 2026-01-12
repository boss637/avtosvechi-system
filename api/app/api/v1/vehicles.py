from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.database import get_db
from app.api.v1.auth import get_current_user
from app.crud.vehicle import create_vehicle, get_vehicle, get_vehicles, update_vehicle, delete_vehicle
from app.models.vehicle import Vehicle as VehicleModel

router = APIRouter()

class VehicleCreate(BaseModel):
    vin: str
    make: str
    model: str
    year: int | None = None
    engine_code: str | None = None

@router.get("/")
async def read_vehicles(
    db: AsyncSession = Depends(get_db),
    current_user = Depends(get_current_user),
):
    return await get_vehicles(db)

@router.post("/")
async def create_new_vehicle(
    vehicle_data: VehicleCreate,
    db: AsyncSession = Depends(get_db),
    current_user = Depends(get_current_user),
):
    vehicle = VehicleModel(**vehicle_data.dict())
    return await create_vehicle(db, vehicle)

@router.get("/{vin}")
async def read_vehicle(
    vin: str,
    db: AsyncSession = Depends(get_db),
    current_user = Depends(get_current_user),
):
    vehicle = await get_vehicle(db, vin)
    if vehicle is None:
        raise HTTPException(status_code=404, detail="Vehicle not found")
    return vehicle

@router.put("/{vin}")
async def update_existing_vehicle(
    vin: str,
    vehicle_data: VehicleCreate,
    db: AsyncSession = Depends(get_db),
    current_user = Depends(get_current_user),
):
    vehicle = VehicleModel(**vehicle_data.dict())
    updated = await update_vehicle(db, vin, vehicle)
    if not updated:
        raise HTTPException(status_code=404, detail="Vehicle not found")
    return {"message": "Vehicle updated"}

@router.delete("/{vin}")
async def delete_vehicle_endpoint(
    vin: str,
    db: AsyncSession = Depends(get_db),
    current_user = Depends(get_current_user),
):
    success = await delete_vehicle(db, vin)
    if not success:
        raise HTTPException(status_code=404, detail="Vehicle not found")
    return {"message": "Vehicle deleted successfully"}
