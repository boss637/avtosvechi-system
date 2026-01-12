from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from pydantic import BaseModel

from app.core.database import get_db
from app.api.v1.auth import get_current_user
from app.models.vehicle import Vehicle


router = APIRouter(prefix="/api/v1/vehicles", tags=["vehicles"])


class VehicleCreate(BaseModel):
    vin: str
    make: str
    model: str
    year: int
    engine_code: str


class VehicleUpdate(BaseModel):
    make: str | None = None
    model: str | None = None
    year: int | None = None
    engine_code: str | None = None


@router.get("/", dependencies=[Depends(get_current_user)])
async def get_vehicles(
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Vehicle))
    return result.scalars().all()


@router.post("/", dependencies=[Depends(get_current_user)])
async def create_vehicle(
    vehicle_data: VehicleCreate,
    db: AsyncSession = Depends(get_db),
):
    vehicle = Vehicle(**vehicle_data.dict())
    db.add(vehicle)
    await db.commit()
    await db.refresh(vehicle)
    return vehicle


@router.get("/{vin}", dependencies=[Depends(get_current_user)])
async def get_vehicle_by_vin(
    vin: str,
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Vehicle).where(Vehicle.vin == vin))
    vehicle = result.scalar_one_or_none()
    if not vehicle:
        raise HTTPException(status_code=404, detail="Vehicle not found")
    return vehicle


@router.put("/{vin}", dependencies=[Depends(get_current_user)])
async def update_vehicle(
    vin: str,
    vehicle_data: VehicleUpdate,
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Vehicle).where(Vehicle.vin == vin))
    vehicle = result.scalar_one_or_none()
    if not vehicle:
        raise HTTPException(status_code=404, detail="Vehicle not found")

    update_data = vehicle_data.dict(exclude_unset=True)
    for field, value in update_data.items():
        setattr(vehicle, field, value)

    await db.commit()
    await db.refresh(vehicle)
    return vehicle


@router.delete("/{vin}", dependencies=[Depends(get_current_user)])
async def delete_vehicle(
    vin: str,
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Vehicle).where(Vehicle.vin == vin))
    vehicle = result.scalar_one_or_none()
    if not vehicle:
        raise HTTPException(status_code=404, detail="Vehicle not found")

    await db.delete(vehicle)
    await db.commit()
    return {"message": "Vehicle deleted successfully"}
