# DB schema (PostgreSQL)

Источник истины по схеме БД — schema-only дамп:
- `project/schema/autoshop_schema.sql` (pg_dump `--schema-only -n public`) [web:9]

## Актуальная версия

- Alembic revision (current/head): `036250e434c4` [web:176]
- Git commit (schema dump): `bff1ba0f1ce7ff680d4fa0a64bbfecac13d4c12b`

## Как обновлять

1) Применить миграции: `alembic upgrade head` [web:38]  
2) Снять schema-only дамп и обновить `project/schema/autoshop_schema.sql` [web:9]  
3) Обновить этот файл: revision + git commit.

## Примечания

- Таблица `alembic_version` хранит текущий идентификатор ревизии миграций Alembic в колонке `version_num`. [web:176]
