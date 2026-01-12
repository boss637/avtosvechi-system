from __future__ import annotations

from datetime import datetime
from enum import Enum

from pydantic import BaseModel, Field


class MovementType(str, Enum):
    inbound = "inbound"
    sale = "sale"
    transfer = "transfer"
    writeoff = "writeoff"


class InventoryMovementIn(BaseModel):
    product_id: int = Field(..., ge=1)
    store_id: int = Field(..., ge=1)
    movement_type: MovementType
    quantity: int = Field(..., gt=0)
    related_document: str | None = None


class InventoryMovementOut(BaseModel):
    ok: bool
    movement_id: int
    product_id: int
    store_id: int
    movement_type: MovementType
    quantity: int
    new_quantity: int


class MovementItem(BaseModel):
    id: int
    product_id: int
    store_id: int
    movement_type: MovementType
    quantity: int
    related_document: str | None
    created_at: datetime


class MovementsListOut(BaseModel):
    items: list[MovementItem]
    count: int
