from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.database import get_db
from app.crud.product import (
    create_product,
    get_product,
    get_products,
    update_product,
    delete_product,
    get_product_by_sku,
)
from app.api.v1.auth import get_current_user

router = APIRouter()

@router.get("/products/")
async def read_products(
    db: AsyncSession = Depends(get_db),
    current_user = Depends(get_current_user),
):
    return await get_products(db)

@router.post("/products/")
async def create_new_product(
    product_data: dict,
    db: AsyncSession = Depends(get_db),
    current_user = Depends(get_current_user),
):
    from app.models.product import Product as ProductModel
    product = ProductModel(**product_data)
    return await create_product(db, product)

@router.get("/products/{product_id}")
async def read_product(
    product_id: int,
    db: AsyncSession = Depends(get_db),
    current_user = Depends(get_current_user),
):
    product = await get_product(db, product_id)
    if product is None:
        raise HTTPException(status_code=404, detail="Product not found")
    return product

@router.put("/products/{product_id}")
async def update_existing_product(
    product_id: int,
    product_data: dict,
    db: AsyncSession = Depends(get_db),
    current_user = Depends(get_current_user),
):
    from app.models.product import Product as ProductModel
    product = ProductModel(**product_data)
    updated = await update_product(db, product_id, product)
    if not updated:
        raise HTTPException(status_code=404, detail="Product not found")
    return {"message": "Product updated"}

@router.delete("/products/{product_id}")
async def delete_product_endpoint(
    product_id: int,
    db: AsyncSession = Depends(get_db),
    current_user = Depends(get_current_user),
):
    success = await delete_product(db, product_id)
    if not success:
        raise HTTPException(status_code=404, detail="Product not found")
    return {"message": "Product deleted"}

@router.get("/products/sku/{sku}")
async def read_product_by_sku(
    sku: str,
    db: AsyncSession = Depends(get_db),
    current_user = Depends(get_current_user),
):
    product = await get_product_by_sku(db, sku)
    if product is None:
        raise HTTPException(status_code=404, detail="Product not found")
    return product
