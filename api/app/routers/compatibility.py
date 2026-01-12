from fastapi import APIRouter, Depends, HTTPException, Body
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from typing import List, Dict, Any
from app.core.database import get_db
from app.models.product import Product
from app.models import ProductCompatibility

router = APIRouter(prefix="/api/v1/compatibility", tags=["compatibility"])


@router.post("/", status_code=201)
async def add_compatibility(
    compatibility_data: List[Dict[str, Any]] = Body(...),
    db: AsyncSession = Depends(get_db),
):
    """Добавляет совместимость товаров с автомобилями"""
    added = 0
    skipped = []
    
    for item in compatibility_data:
        result = await db.execute(
            select(Product.id).where(Product.sku == item["product_sku"])
        )
        product_id = result.scalar_one_or_none()
        
        if not product_id:
            skipped.append(f"Product {item['product_sku']} not found")
            continue
        
        compat = ProductCompatibility(
            product_id=product_id,
            vehicle_brand=item.get("vehicle_brand"),
            vehicle_model=item.get("vehicle_model"),
            year_from=item.get("year_from"),
            year_to=item.get("year_to"),
            engine_code=item.get("engine_code"),
            engine_volume=item.get("engine_volume"),
            confidence=item.get("confidence", 0.90),
            source=item.get("source", "manual"),
            source_ref=item.get("source_ref"),
        )
        db.add(compat)
        added += 1
    
    await db.commit()
    
    return {
        "added": added,
        "skipped": skipped,
        "total": len(compatibility_data)
    }


@router.get("/test")
async def test_compatibility_search(
    vehicle_brand: str,
    db: AsyncSession = Depends(get_db),
):
    """Тестовый поиск по совместимости"""
    return {
        "vehicle_brand": vehicle_brand,
        "message": "Tables ready, POST data to test"
    }
