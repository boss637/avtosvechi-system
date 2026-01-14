#!/bin/bash
# ФИНАЛЬНАЯ РАБОЧАЯ ВЕРСИЯ create_restore_point.sh
set -euo pipefail

# --- КОНФИГУРАЦИЯ ---
BACKUP_ROOT="/home/oleg/autoshop/backups"
DB_NAME="autoshop_db"
DB_CONTAINER="autoshop_db"
DB_USER="autoshop"
# --------------------

echo "=== Создание структурированной точки восстановления ==="

# 1. Запрос описания
read -p "Введите описание точки восстановления: " DESCRIPTION
SAFE_DESCRIPTION=$(echo "$DESCRIPTION" | sed "s/[^а-яА-Яa-zA-Z0-9-]/_/g")
BACKUP_DIR="$BACKUP_ROOT/$(date +%Y-%m-%d)_${SAFE_DESCRIPTION}"

# 2. Создание папки
echo "Создаю папку: $BACKUP_DIR"
mkdir -p "$BACKUP_DIR"

# 3. Дамп базы данных (с явной проверкой)
DB_FILE="$BACKUP_DIR/db_dump.sql.gz"
echo "Создаю дамп БД -> $DB_FILE"
if ! docker exec "$DB_CONTAINER" pg_dump -U "$DB_USER" "$DB_NAME" | gzip > "$DB_FILE"; then
    echo "ОШИБКА: Не удалось создать дамп БД. Проверьте подключение к БД."
    exit 1
fi

# 4. Архив кода (с явной проверкой)
CODE_FILE="$BACKUP_DIR/code_snapshot.tar.gz"
echo "Архивирую код -> $CODE_FILE"
if ! tar -czf "$CODE_FILE" --exclude=backups --exclude=.git --exclude=postgres/data . 2>/dev/null; then
    echo "ОШИБКА: Не удалось создать архив кода."
    exit 1
fi

# 5. Создание README
README_FILE="$BACKUP_DIR/README.md"
cat > "$README_FILE" << README_EOF
# Точка восстановления: ${DESCRIPTION}
**Дата создания:** $(date)
**Папка:** $(basename "$BACKUP_DIR")

## Описание
${DESCRIPTION}

## Содержимое точки
1. \`db_dump.sql.gz\` — дамп базы данных PostgreSQL.
2. \`code_snapshot.tar.gz\` — архив исходного кода проекта.

## Для восстановления
1. Распаковать архив кода: \`tar -xzf code_snapshot.tar.gz -C /target/path\`
2. Восстановить БД: \`gunzip -c db_dump.sql.gz | docker exec -i $DB_CONTAINER psql -U $DB_USER $DB_NAME\`
README_EOF

# 6. Обновление ссылки 'latest'
LINK_PATH="$BACKUP_ROOT/latest"
ln -sfn "$(basename "$BACKUP_DIR")" "$LINK_PATH"
echo "Ссылка 'latest' обновлена -> $(basename "$BACKUP_DIR")"

# 7. Итог
echo "✅ Точка восстановления успешно создана в: $BACKUP_DIR"
echo "   - Дамп БД:   $(basename "$DB_FILE")"
echo "   - Архив кода: $(basename "$CODE_FILE")"
echo "   - README:     $(basename "$README_FILE")"
