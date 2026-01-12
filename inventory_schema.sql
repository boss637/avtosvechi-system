-- Таблица движений остатков
CREATE TABLE IF NOT EXISTS movements (
    id              SERIAL PRIMARY KEY,
    product_id      INTEGER NOT NULL REFERENCES products(id),
    store_id        INTEGER NOT NULL,
    movement_type   VARCHAR(20) NOT NULL,  -- in / sale / return / transfer / writeoff
    quantity        INTEGER NOT NULL,
    related_document TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Таблица срезов остатков
CREATE TABLE IF NOT EXISTS stock_snapshots (
    id          SERIAL PRIMARY KEY,
    product_id  INTEGER NOT NULL REFERENCES products(id),
    store_id    INTEGER NOT NULL,
    quantity    INTEGER NOT NULL,
    taken_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);
