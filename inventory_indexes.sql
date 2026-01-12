-- Индексы для ускорения выборок по движениям и срезам

-- Частые фильтры: по товару и складу
CREATE INDEX IF NOT EXISTS ix_movements_product_store
    ON movements (product_id, store_id);

-- Фильтр по типу движения и дате (отчёты)
CREATE INDEX IF NOT EXISTS ix_movements_type_created
    ON movements (movement_type, created_at);

-- Срезы остатков: по товару и складу
CREATE INDEX IF NOT EXISTS ix_stock_snapshots_product_store
    ON stock_snapshots (product_id, store_id);

-- По дате среза (история остатков)
CREATE INDEX IF NOT EXISTS ix_stock_snapshots_taken_at
    ON stock_snapshots (taken_at);
