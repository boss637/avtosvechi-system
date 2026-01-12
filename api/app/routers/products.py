from fastapi.responses import JSONResponse

from fastapi.encoders import jsonable_encoder

import logging
from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app import schemas
from app.api.v1.auth import get_current_user
from app.core.database import get_db
from app.models.current_inventory import CurrentInventory
from app.models.product import Product

router = APIRouter(prefix="/api/v1/products", tags=["products"])
logger = logging.getLogger(__name__)


class ProductSearchQuery(BaseModel):
    sku: str | None = None
    brand: str | None = None
    category: str | None = None
    vehicle_brand: str | None = None
    price_from: float | None = None
    price_to: float | None = None
    available: bool | None = None
    limit: int = 100
    offset: int = 0


class ProductSearchResponse(BaseModel):
    items: List[schemas.Product]
    count: int
    filters: ProductSearchQuery


# ВАЖНО: статические пути должны быть ДО динамического /{product_id}
@router.get("/search", response_model=None, response_class=JSONResponse)
async def search_products(
    q: ProductSearchQuery = Depends(),
    db: AsyncSession = Depends(get_db),
):
    stmt = select(Product)

    if q.sku:
        stmt = stmt.where(Product.sku.ilike(f"%{q.sku}%"))
    if q.brand:
        stmt = stmt.where(Product.brand.ilike(f"%{q.brand}%"))
    if q.category:
        stmt = stmt.where(Product.category.ilike(f"%{q.category}%"))
    if q.vehicle_brand:
        stmt = stmt.where(Product.vehicle_brand.ilike(f"%{q.vehicle_brand}%"))
    if q.price_from is not None:
        stmt = stmt.where(Product.selling_price >= q.price_from)
    if q.price_to is not None:
        stmt = stmt.where(Product.selling_price <= q.price_to)

    if q.available is not None:
        stmt = stmt.join(
            CurrentInventory,
            CurrentInventory.product_id == Product.id,
            isouter=True,
        )
        available_expr = (CurrentInventory.quantity - CurrentInventory.reserved)

        if q.available:
            stmt = stmt.where(available_expr > 0)
        else:
            stmt = stmt.where(
                (available_expr <= 0) | (CurrentInventory.product_id.is_(None))
            )

        stmt = stmt.distinct()

    stmt = stmt.order_by(Product.name).offset(int(q.offset)).limit(min(int(q.limit), 1000))

    res = await db.execute(stmt)
    orm_items = res.scalars().all()

    # Ключевой фикс: конвертируем ORM -> Pydantic
    items = [schemas.Product.model_validate(obj) for obj in orm_items]

    return JSONResponse(content=jsonable_encoder(ProductSearchResponse(items=items, count=len(items), filters=q)))


@router.get("/sku/{sku}", response_model=Optional[schemas.Product])
async def read_product_by_sku(
    sku: str,
    db: AsyncSession = Depends(get_db),
    current_user=Depends(get_current_user),
):
    result = await db.execute(select(Product).where(Product.sku == sku))
    db_product = result.scalar_one_or_none()
    if db_product is None:
        raise HTTPException(status_code=404, detail="Product not found")
    return schemas.Product.model_validate(db_product)


@router.get("/", response_model=List[schemas.Product])
async def read_products(
    skip: int = 0,
    limit: int = 100,
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Product).offset(skip).limit(limit))
    items = result.scalars().all()
    return [schemas.Product.model_validate(obj) for obj in items]


@router.get("/{product_id}", response_model=Optional[schemas.Product])
async def read_product(
    product_id: int,
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Product).where(Product.id == product_id))
    db_product = result.scalar_one_or_none()
    if db_product is None:
        raise HTTPException(status_code=404, detail="Product not found")
    return schemas.Product.model_validate(db_product)


@router.post("/", response_model=schemas.Product)
async def create_product(
    product: schemas.ProductCreate,
    db: AsyncSession = Depends(get_db),
    current_user=Depends(get_current_user),
):
    db_product = Product(**product.model_dump())
    db.add(db_product)
    await db.commit()
    await db.refresh(db_product)
    return schemas.Product.model_validate(db_product)


@router.put("/{product_id}", response_model=schemas.Product)
async def update_product(
    product_id: int,
    product: schemas.ProductUpdate,
    db: AsyncSession = Depends(get_db),
    current_user=Depends(get_current_user),
):
    result = await db.execute(select(Product).where(Product.id == product_id))
    db_product = result.scalar_one_or_none()
    if db_product is None:
        raise HTTPException(status_code=404, detail="Product not found")

    update_data = product.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(db_product, field, value)

    await db.commit()
    await db.refresh(db_product)
    return schemas.Product.model_validate(db_product)


@router.delete("/{product_id}")
async def delete_product(
    product_id: int,
    db: AsyncSession = Depends(get_db),
    current_user=Depends(get_current_user),
):
    result = await db.execute(select(Product).where(Product.id == product_id))
    db_product = result.scalar_one_or_none()
    if db_product is None:
        raise HTTPException(status_code=404, detail="Product not found")

    await db.delete(db_product)
    await db.commit()
    return {"message": "Product deleted successfully"}
