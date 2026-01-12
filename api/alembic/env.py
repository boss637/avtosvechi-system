from __future__ import annotations

import os
import sys

from alembic import context
from sqlalchemy import engine_from_config, pool

# Ensure "app" package is importable when running Alembic from /app
sys.path.append(os.getcwd())

from app.models.base import Base  # noqa: E402

# Import ONLY models that are part of the managed schema (current system)
from app.models.product import Product  # noqa: F401,E402
from app.models.store import Store  # noqa: F401,E402
from app.models.user import User  # noqa: F401,E402
from app.models.movement import Movement  # noqa: F401,E402
from app.models.current_inventory import CurrentInventory  # noqa: F401,E402
from app.models.abc import ProductABC  # noqa: F401,E402

config = context.config

if config.config_file_name:
    try:
        from logging.config import fileConfig

        fileConfig(config.config_file_name, disable_existing_loggers=False)
    except Exception:
        pass

target_metadata = Base.metadata

# Legacy tables that must never be modified by Alembic autogenerate/check
LEGACY_TABLES = {"inventory", "stock_snapshots", "vehicles"}

# Tables where we intentionally ignore FK/index/unique/name noise for now
NOISE_TABLES = {"movements", "current_inventory", "users", "stores", "product_abc_class"}

# For users table: ignore nullable noise on these columns (DB is authoritative for now)
NOISE_NULLABLE_COLUMNS = {
    "users": {"username", "hashed_password"},
}

# For product_abc_class: ignore nullable noise on calculated_at (DB is authoritative for now)
NOISE_NULLABLE_COLUMNS.setdefault("product_abc_class", set()).add("calculated_at")


def include_name(name, type_, parent_names):
    """
    Control which objects participate in autogenerate/check.

    Rule:
    - For tables: include only those present in SQLAlchemy metadata AND not in LEGACY_TABLES.
    """
    if type_ == "table":
        if name in LEGACY_TABLES:
            return False
        return name in target_metadata.tables
    return True


def include_object(object, name, type_, reflected, compare_to):
    """
    Filter out legacy tables and known "noise" diffs (constraint/index/fk naming, etc.)
    so `alembic check` remains meaningful for real schema changes.
    """
    # Block legacy tables entirely
    if type_ == "table" and name in LEGACY_TABLES:
        return False

    # Block objects belonging to legacy tables (secondary safety)
    if hasattr(object, "table") and getattr(object.table, "name", None) in LEGACY_TABLES:
        return False

    # Ignore FK diffs (name/ondelete) on specific tables
    if type_ == "foreign_key_constraint":
        table_name = getattr(object.table, "name", None)
        if table_name in NOISE_TABLES:
            return False

    # Ignore index diffs on specific tables
    if type_ == "index":
        table_name = getattr(object.table, "name", None)
        if table_name in NOISE_TABLES:
            return False

    # Ignore unique constraint diffs on specific tables
    if type_ == "unique_constraint":
        table_name = getattr(object.table, "name", None)
        if table_name in NOISE_TABLES:
            return False

    # Ignore nullable diffs for specific columns
    if type_ == "column" and hasattr(object, "table"):
        table_name = object.table.name
        if table_name in NOISE_NULLABLE_COLUMNS and name in NOISE_NULLABLE_COLUMNS[table_name]:
            return False

    return True


def run_migrations_offline() -> None:
    url = config.get_main_option("sqlalchemy.url")
    context.configure(
        url=url,
        target_metadata=target_metadata,
        literal_binds=True,
        dialect_opts={"paramstyle": "named"},
        compare_type=True,
        compare_server_default=False,
        include_name=include_name,
        include_object=include_object,
    )
    with context.begin_transaction():
        context.run_migrations()


def run_migrations_online() -> None:
    connectable = engine_from_config(
        config.get_section(config.config_ini_section, {}),
        prefix="sqlalchemy.",
        poolclass=pool.NullPool,
    )

    with connectable.connect() as connection:
        context.configure(
            connection=connection,
            target_metadata=target_metadata,
            compare_type=True,
            compare_server_default=False,
            include_name=include_name,
            include_object=include_object,
        )

        with context.begin_transaction():
            context.run_migrations()


if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()
