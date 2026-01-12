# Inventory-сервис: модель движений

## Таблицы

- products (уже есть)
- vehicles (уже есть)
- inventory (уже есть, остатки по складам)
- movements (НОВАЯ)
- stock_snapshots (НОВАЯ)

## Таблица movements (движения)

Поля (черновик):
- id (serial, PK)
- product_id (FK -> products.id)
- store_id (int, склад/магазин)
- movement_type (приход / продажа / возврат / перемещение / списание)
- quantity (int, со знаком + или -)
- related_document (text, номер накладной/чека)
- created_at (timestamp with time zone, now())

## Таблица stock_snapshots (срезы остатков)

Поля (черновик):
- id (serial, PK)
- product_id (FK -> products.id)
- store_id (int)
- quantity (int)
- taken_at (timestamp with time zone)
