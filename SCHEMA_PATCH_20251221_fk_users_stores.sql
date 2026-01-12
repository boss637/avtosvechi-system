-- users table (created manually)
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    username VARCHAR UNIQUE NOT NULL,
    hashed_password VARCHAR NOT NULL,
    is_active BOOLEAN DEFAULT true
);

-- stores table (created manually)
CREATE TABLE IF NOT EXISTS stores (
  id SERIAL PRIMARY KEY,
  name VARCHAR(100) UNIQUE NOT NULL,
  address VARCHAR,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- seed stores for existing data
INSERT INTO stores (id, name, address)
VALUES
  (1, 'Store #1', 'TBD'),
  (2, 'Store #2', 'TBD')
ON CONFLICT (id) DO NOTHING;

-- FK current_inventory.store_id -> stores.id
ALTER TABLE current_inventory
ADD CONSTRAINT IF NOT EXISTS fk_current_inventory_store_id
FOREIGN KEY (store_id) REFERENCES stores(id)
ON DELETE RESTRICT;

-- FK movements.store_id -> stores.id
ALTER TABLE movements
ADD CONSTRAINT IF NOT EXISTS fk_movements_store_id
FOREIGN KEY (store_id) REFERENCES stores(id)
ON DELETE RESTRICT;

-- FK movements.product_id -> products.id
ALTER TABLE movements
ADD CONSTRAINT IF NOT EXISTS fk_movements_product_id
FOREIGN KEY (product_id) REFERENCES products(id)
ON DELETE RESTRICT;
