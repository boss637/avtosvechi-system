#!/bin/bash

set -e  # Выход при ошибке

# --- Конфигурация ---
BACKUP_DIR="$HOME/autoshop/backups"
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
COMMIT_MESSAGE="${1:-"Automatic restore point created at $TIMESTAMP"}"

# --- Проверка директории бэкапов ---
mkdir -p "$BACKUP_DIR"

echo "--- 1. Создание локальной точки восстановления ---"

# 1.1 Дамп базы данных PostgreSQL
DB_DUMP_FILE="$BACKUP_DIR/db_dump_$TIMESTAMP.sql.gz"
echo "Создаем дамп базы данных PostgreSQL в ${DB_DUMP_FILE##*/}..."
docker compose exec -T postgres pg_dump -U autoshop --clean --if-exists autoshop_db | gzip > "$DB_DUMP_FILE"
echo "[OK] Дамп базы данных успешно создан."

# 1.2 Архив всего кода проекта
CODE_ARCHIVE_FILE="$BACKUP_DIR/code_snapshot_$TIMESTAMP.tar.gz"
echo "Создаем архив всего кода проекта в ${CODE_ARCHIVE_FILE##*/}..."
sudo tar --exclude="$BACKUP_DIR" --exclude=.git -czf "$CODE_ARCHIVE_FILE" "$HOME/autoshop/" 2>/dev/null || {
    echo "[ВНИМАНИЕ] Не удалось создать архив с sudo. Пробуем без него..."
    tar --exclude="$BACKUP_DIR" --exclude=.git -czf "$CODE_ARCHIVE_FILE" "$HOME/autoshop/" 2>/dev/null
}
echo "[OK] Архив кода успешно создан."

echo ""
echo "--- 2. Создание точки восстановления кода на GitHub ---"

# 2.1 Добавление изменений в Git (если они есть)
echo "Добавляем все изменения в Git..."
git add .

# 2.2 Создание коммита (только если есть что коммитить)
if ! git diff-index --quiet HEAD --; then
    echo "Создаем коммит с сообщением: '$COMMIT_MESSAGE'..."
    git commit -m "$COMMIT_MESSAGE"
    COMMIT_CREATED=true
else
    echo "Нет изменений в отслеживаемых файлах для коммита."
    COMMIT_CREATED=false
fi

# 2.3 Отправка на GitHub с автоматическим разрешением конфликтов
if [ "$COMMIT_CREATED" = true ]; then
    echo "Отправляем изменения в репозиторий (git push)..."
    
    # Пытаемся отправить. Если не получилось, синхронизируемся и пробуем снова.
    if ! git push origin master 2>/dev/null; then
        echo "Обнаружены новые изменения на GitHub. Выполняем синхронизацию (git pull --rebase)..."
        git pull --rebase origin master
        echo "Повторная отправка изменений после синхронизации..."
        git push origin master
    fi
    echo "[OK] Изменения успешно отправлены на GitHub."
else
    echo "[OK] Локальные бэкапы созданы. Отправка в GitHub не требовалась (нет новых коммитов)."
fi

echo ""
echo "--- Готово ---"
echo "Точка восстановления создана:"
echo "  • База данных: $DB_DUMP_FILE"
echo "  • Код проекта: $CODE_ARCHIVE_FILE"
if [ "$COMMIT_CREATED" = true ]; then
    echo "  • Коммит Git: создан и отправлен"
fi
