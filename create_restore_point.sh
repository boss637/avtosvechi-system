#!/usr/bin/env bash
# create_restore_point.sh - Создает полную точку восстановления (локально + Git)

set -e # Прерывать выполнение при любой ошибке

# --- Проверка: убедимся, что передано сообщение для коммита ---
if [ -z "$1" ]; then
    echo "ОШИБКА: Пожалуйста, укажите сообщение для коммита."
    echo "Пример: ./create_restore_point.sh \"Исправлена логика в API\""
    exit 1
fi

COMMIT_MESSAGE="$1"
TIMESTAMP=$(date +'%Y-%m-%d_%H-%M-%S')
BACKUP_DIR="backups"
DB_FILE="${BACKUP_DIR}/db_dump_${TIMESTAMP}.sql.gz"
CODE_ARCHIVE="${BACKUP_DIR}/code_snapshot_${TIMESTAMP}.tar.gz"

echo "--- 1. Создание локальной точки восстановления ---"

# --- Дамп Базы Данных ---
echo "Создаем дамп базы данных PostgreSQL в ${DB_FILE}..."
docker compose exec -T postgres pg_dump -U autoshop -d autoshop_db | gzip > "$DB_FILE"
echo "[OK] Дамп базы данных успешно создан."

# --- Архив Кода (с sudo) ---
echo "Создаем архив всего кода проекта в ${CODE_ARCHIVE}..."
# ИСПРАВЛЕНО: Добавлено sudo для доступа ко всем файлам
sudo tar --exclude="$BACKUP_DIR" -czf "$CODE_ARCHIVE" .
echo "[OK] Архив кода успешно создан."

echo ""
echo "--- 2. Создание точки восстановления кода на GitHub ---"

# --- Коммит и Пуш в Git ---
echo "Добавляем все изменения в Git..."
git add .
echo "Создаем коммит с сообщением: '$COMMIT_MESSAGE'..."
git commit -m "$COMMIT_MESSAGE"
echo "Отправляем изменения в репозиторий (git push)..."
git push origin master # Убедитесь, что .master. - это ваша основная ветка
echo "[OK] Изменения успешно отправлены на GitHub."
echo ""

echo "---"
echo "✅ ТОЧКА ВОССТАНОВЛЕНИЯ УСПЕШНО СОЗДАНА! ---"
echo "  - Локальный бэкап БД: ${DB_FILE}"
echo "  - Локальный архив кода: ${CODE_ARCHIVE}"
echo "  - Коммит на GitHub: '$COMMIT_MESSAGE'"
echo "---"

exit 0
