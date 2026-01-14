#!/bin/bash
# ФИНАЛЬНАЯ ВЕРСИЯ: Очистка структурированных точек восстановления
# Удаляет старые папки-версии, оставляя 5 последних (настраивается).

set -euo pipefail

# Конфигурация
BACKUP_ROOT="/home/oleg/autoshop/backups"
KEEP_COUNT=5  # Сколько последних папок оставлять

# Функции вывода
info() { echo "[INFO] $1"; }
warning() { echo -e "\033[1;33m[WARNING] $1\033[0m"; }
success() { echo -e "\033[0;32m[SUCCESS] $1\033[0m"; }
error() { echo -e "\033[0;31m[ERROR] $1\033[0m" >&2; }

show_help() {
    cat << EOH
Использование: $0 [--keep N] [--force] [--help]

Аргументы:
  --keep N    Оставить N последних папок (по умолчанию: $KEEP_COUNT)
  --force     Не запрашивать подтверждение
  --help      Показать эту справку

Пример:
  $0                     # Интерактивно, оставить 5 папок
  $0 --keep 3 --force    # Оставить 3 папки без подтверждения
EOH
}

# Обработка аргументов
FORCE=false
while [[ $# -gt 0 ]]; do
    case $1 in
        --keep)
            if [[ $2 =~ ^[0-9]+$ ]] && [ "$2" -ge 1 ]; then
                KEEP_COUNT=$2; shift 2
            else
                error "Аргумент --keep должен быть положительным числом."; exit 1
            fi ;;
        --force) FORCE=true; shift ;;
        --help) show_help; exit 0 ;;
        *) error "Неизвестный аргумент: $1"; show_help; exit 1 ;;
    esac
done

echo "=== Очистка структурированных бэкапов ==="
info "Режим: оставить $KEEP_COUNT последних папок"

# Поиск версионных папок
info "Поиск папок в: $BACKUP_ROOT"
mapfile -t ALL_FOLDERS < <(find "$BACKUP_ROOT" -maxdepth 1 -type d -name "20[0-9][0-9]-[0-9][0-9]-[0-9][0-9]_*" | sort)

if [ ${#ALL_FOLDERS[@]} -le "$KEEP_COUNT" ]; then
    info "Папок найдено: ${#ALL_FOLDERS[@]}. Удалять нечего (оставляем $KEEP_COUNT)."
    exit 0
fi

# Разделение на "оставляемые" и "удаляемые"
TO_KEEP=("${ALL_FOLDERS[@]: -$KEEP_COUNT}")           # Последние KEEP_COUNT
TO_DELETE=("${ALL_FOLDERS[@]:0:${#ALL_FOLDERS[@]}-$KEEP_COUNT}")  # Остальные

echo ""
warning "БУДУТ УДАЛЕНЫ старые папки (${#TO_DELETE[@]} шт.):"
printf '  %s\n' "${TO_DELETE[@]}"
echo ""
info "ОСТАНУТСЯ свежие папки (${#TO_KEEP[@]} шт.):"
printf '  %s\n' "${TO_KEEP[@]}"

# Подтверждение (если не --force)
if [ "$FORCE" = false ]; then
    echo -e "\033[1;33m"
    read -p "Продолжить удаление? (yes/no): " -r CONFIRM
    echo -e "\033[0m"
    [[ "$CONFIRM" =~ ^[Yy][Ee][Ss]$ ]] || { info "Отмена."; exit 0; }
fi

# УДАЛЕНИЕ
DELETED_COUNT=0
for folder in "${TO_DELETE[@]}"; do
    if rm -rf "$folder"; then
        info "Удалено: $(basename "$folder")"
        ((DELETED_COUNT++))
    else
        error "Ошибка удаления: $folder"
    fi
done

success "Удалено папок: $DELETED_COUNT из ${#TO_DELETE[@]}"

# Итог
echo ""
info "Текущее содержимое $BACKUP_ROOT:"
ls -la "$BACKUP_ROOT" | grep -E "^[dl-]" | head -10
