from __future__ import annotations

from datetime import datetime
from typing import Any

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.sql import func

from app.core.database import get_db
from app.models.current_inventory import CurrentInventory
from app.models.movement import Movement
from app.schemas.inventory import (
    InventoryMovementIn,
    InventoryMovementOut,
    MovementItem,
    MovementsListOut,
    MovementType,
)

router = APIRouter(prefix="/api/v1/inventory", tags=["inventory"])

ALLOWED_MOVEMENT_TYPES = {t.value for t in MovementType}


@router.get("/status")
async def inventory_status(db: AsyncSession = Depends(get_db)) -> dict[str, Any]:
    result = await db.execute(
        select(
            CurrentInventory.product_id,
            CurrentInventory.store_id,
            CurrentInventory.quantity,
            CurrentInventory.reserved,
            CurrentInventory.updated_at,
        ).order_by(CurrentInventory.product_id, CurrentInventory.store_id)
    )
    rows = result.all()

    items: list[dict[str, Any]] = []
    for r in rows:
        qty = int(r.quantity)
        res = int(r.reserved)
        items.append(
            {
                "product_id": int(r.product_id),
                "store_id": int(r.store_id),
                "quantity": qty,
                "reserved": res,
                "available": qty - res,
                "updated_at": r.updated_at.isoformat() if r.updated_at else None,
            }
        )

    return {"items": items, "count": len(items)}


@router.post("/movement", response_model=InventoryMovementOut)
async def create_movement(payload: InventoryMovementIn, db: AsyncSession = Depends(get_db)) -> InventoryMovementOut:
    if payload.movement_type not in ALLOWED_MOVEMENT_TYPES:
        raise HTTPException(status_code=400, detail=f"Unsupported movement_type: {payload.movement_type}")

    delta = payload.quantity
    if payload.movement_type in {"sale", "writeoff", "transfer"}:
        delta = -payload.quantity

    async with db.begin():
        inv_res = await db.execute(
            select(CurrentInventory)
            .where(
                CurrentInventory.product_id == payload.product_id,
                CurrentInventory.store_id == payload.store_id,
            )
            .with_for_update()
        )
        inv = inv_res.scalar_one_or_none()

        if inv is None:
            if delta < 0:
                raise HTTPException(status_code=409, detail="No inventory row to decrement")
            inv = CurrentInventory(product_id=payload.product_id, store_id=payload.store_id, quantity=0, reserved=0)
            db.add(inv)
            await db.flush()

        new_qty = int(inv.quantity) + int(delta)

        if new_qty < 0:
            raise HTTPException(status_code=409, detail="Insufficient stock")

        if int(inv.reserved) > new_qty:
            raise HTTPException(status_code=409, detail="Reserved exceeds new stock level")

        inv.quantity = new_qty
        inv.updated_at = func.now()

        mv = Movement(
            product_id=payload.product_id,
            store_id=payload.store_id,
            movement_type=payload.movement_type,
            quantity=payload.quantity,
            related_document=payload.related_document,
        )
        db.add(mv)
        await db.flush()

    return InventoryMovementOut(
        ok=True,
        movement_id=int(mv.id),
        product_id=payload.product_id,
        store_id=payload.store_id,
        movement_type=payload.movement_type,
        quantity=payload.quantity,
        new_quantity=int(new_qty),
    )


@router.get("/movements", response_model=MovementsListOut)
async def list_movements(
    product_id: int | None = Query(default=None, ge=1),
    store_id: int | None = Query(default=None, ge=1),
    movement_type: str | None = Query(default=None, min_length=1, max_length=20),
    date_from: datetime | None = None,
    date_to: datetime | None = None,
    limit: int = Query(default=100, ge=1, le=500),
    db: AsyncSession = Depends(get_db),
) -> MovementsListOut:
    stmt = select(Movement).order_by(Movement.created_at.desc()).limit(limit)

    if product_id is not None:
        stmt = stmt.where(Movement.product_id == product_id)
    if store_id is not None:
        stmt = stmt.where(Movement.store_id == store_id)
    if movement_type is not None:
        stmt = stmt.where(Movement.movement_type == movement_type)
    if date_from is not None:
        stmt = stmt.where(Movement.created_at >= date_from)
    if date_to is not None:
        stmt = stmt.where(Movement.created_at <= date_to)

    res = await db.execute(stmt)
    rows = res.scalars().all()

    items = [
        MovementItem(
            id=int(m.id),
            product_id=int(m.product_id),
            store_id=int(m.store_id),
            movement_type=str(m.movement_type),
            quantity=int(m.quantity),
            related_document=m.related_document,
            created_at=m.created_at,
        )
        for m in rows
    ]
    return MovementsListOut(items=items, count=len(items))


@router.get("/{product_id}")
async def inventory_by_product(product_id: int, db: AsyncSession = Depends(get_db)) -> dict[str, Any]:
    result = await db.execute(
        select(
            CurrentInventory.store_id,
            CurrentInventory.quantity,
            CurrentInventory.reserved,
            CurrentInventory.updated_at,
        )
        .where(CurrentInventory.product_id == product_id)
        .order_by(CurrentInventory.store_id)
    )
    rows = result.all()

    if not rows:
        raise HTTPException(status_code=404, detail="No inventory for product_id")

    stores: list[dict[str, Any]] = []
    total_qty = 0
    total_reserved = 0
    for r in rows:
        qty = int(r.quantity)
        res = int(r.reserved)
        total_qty += qty
        total_reserved += res
        stores.append(
            {
                "store_id": int(r.store_id),
                "quantity": qty,
                "reserved": res,
                "available": qty - res,
                "updated_at": r.updated_at.isoformat() if r.updated_at else None,
            }
        )

    return {
        "product_id": int(product_id),
        "total": {
            "quantity": total_qty,
            "reserved": total_reserved,
            "available": total_qty - total_reserved,
        },
        "stores": stores,
    }
