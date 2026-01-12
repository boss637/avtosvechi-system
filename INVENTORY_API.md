# Inventory-service API (черновик)

Базовый префикс: /api/v1/inventory

## 1. Провести движение

POST /api/v1/inventory/movements

Тело запроса (JSON):
{
  "product_id": 123,
  "store_id": 1,
  "movement_type": "in",        // in | sale | return | transfer | writeoff
  "quantity": 5,                // приход: +, продажа: -
  "related_document": "IN-2025-0001"
}

Ответ 201:
{
  "id": 1,
  "product_id": 123,
  "store_id": 1,
  "movement_type": "in",
  "quantity": 5,
  "related_document": "IN-2025-0001",
  "created_at": "2025-12-06T10:00:00Z"
}

## 2. Получить текущие остатки

GET /api/v1/inventory/stock?store_id=1&product_id=123

Параметры:
- store_id (обязателен)
- product_id (опционален; если не указан — вернуть все товары по складу)

Пример ответа:
[
  {
    "product_id": 123,
    "store_id": 1,
    "quantity": 10
  }
]
