from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from app.models.vehicle import Vehicle
from sqlalchemy import update, delete

async def get_vehicles(db: AsyncSession):
    result = await db.execute(select(Vehicle))
    return result.scalars().all()

async def get_vehicle(db: AsyncSession, vin: str):
    result = await db.execute(select(Vehicle).where(Vehicle.vin == vin))
    return result.scalar_one_or_none()

async def create_vehicle(db: AsyncSession, vehicle: Vehicle):
    db.add(vehicle)
    await db.commit()
    await db.refresh(vehicle)
    return vehicle

async def update_vehicle(db: AsyncSession, vin: str, vehicle: Vehicle):
    result = await db.execute(update(Vehicle).where(Vehicle.vin == vin).values(**vehicle.dict()))
    await db.commit()
    return result.rowcount > 0

async def delete_vehicle(db: AsyncSession, vin: str):
    result = await db.execute(delete(Vehicle).where(Vehicle.vin == vin))
    await db.commit()
    return result.rowcount > 0
