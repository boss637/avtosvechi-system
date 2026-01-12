from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy import update, delete
from app.models.product import Product

async def get_products(db: AsyncSession):
    result = await db.execute(select(Product))
    return result.scalars().all()

async def get_product(db: AsyncSession, product_id: int):
    result = await db.execute(select(Product).where(Product.id == product_id))
    return result.scalar_one_or_none()

async def get_product_by_sku(db: AsyncSession, sku: str):
    result = await db.execute(select(Product).where(Product.sku == sku))
    return result.scalar_one_or_none()

async def create_product(db: AsyncSession, product: Product):
    db.add(product)
    await db.commit()
    await db.refresh(product)
    return product

async def update_product(db: AsyncSession, product_id: int, product: Product):
    stmt = (
        update(Product)
        .where(Product.id == product_id)
        .values(
            name=product.name,
            sku=product.sku,
            price=product.price,
            description=product.description,
        )
    )
    result = await db.execute(stmt)
    await db.commit()
    return result.rowcount > 0

async def delete_product(db: AsyncSession, product_id: int):
    stmt = delete(Product).where(Product.id == product_id)
    result = await db.execute(stmt)
    await db.commit()
    return result.rowcount > 0
