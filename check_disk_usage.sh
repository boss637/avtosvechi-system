#!/bin/bash

# ============================================
# check_disk_usage.sh
# Мониторинг дискового пространства и размера бэкапов
# ============================================

set -euo pipefail

# --- Конфигурация ---
BACKUP_DIR="/home/oleg/autoshop/backups"
LOG_FILE="/home/oleg/autoshop/disk_monitor.log"
# Пороги для предупреждений (в процентах)
WARNING_THRESHOLD=10  # 10% свободного места
CRITICAL_THRESHOLD=5  # 5% свободного места
# Максимальный размер директории бэкапов (в GB)
MAX_BACKUP_SIZE_GB=10
# ============================================

# --- Функции ---
log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" | tee -a "$LOG_FILE"
}

check_disk_space() {
    # Получаем информацию о свободном месте на корневом разделе
    local disk_info=$(df / --output=pcent,target 2>/dev/null | tail -1)
    if [[ -z "$disk_info" ]]; then
        # Альтернативный способ для старых версий df
        disk_info=$(df / | tail -1)
        local used_percent=$(echo "$disk_info" | awk '{print $5}' | sed 's/%//')
    else
        local used_percent=$(echo "$disk_info" | awk '{print $1}' | sed 's/%//')
    fi
    
    local free_percent=$((100 - used_percent))
    
    log_message "INFO" "Свободно на диске: ${free_percent}%"
    
    if [[ $free_percent -le $CRITICAL_THRESHOLD ]]; then
        log_message "CRITICAL" "КРИТИЧЕСКИ МАЛО СВОБОДНОГО МЕСТА: ${free_percent}%!"
        return 2
    elif [[ $free_percent -le $WARNING_THRESHOLD ]]; then
        log_message "WARNING" "Мало свободного места: ${free_percent}%"
        return 1
    else
        log_message "INFO" "Свободного места достаточно: ${free_percent}%"
        return 0
    fi
}

check_backup_size() {
    # Проверяем размер директории с бэкапами
    if [[ ! -d "$BACKUP_DIR" ]]; then
        log_message "WARNING" "Директория с бэкапами не найдена: $BACKUP_DIR"
        return 0
    fi
    
    local size_kb=$(du -sk "$BACKUP_DIR" 2>/dev/null | cut -f1)
    local size_gb=$(echo "scale=2; $size_kb / 1024 / 1024" | bc 2>/dev/null || echo "0")
    local file_count=$(find "$BACKUP_DIR" -type f 2>/dev/null | wc -l)
    
    log_message "INFO" "Директория бэкапов: ${size_gb} GB, файлов: ${file_count}"
    
    # Сравниваем с порогом (используем bc для сравнения дробных чисел)
    if command -v bc >/dev/null 2>&1; then
        if (( $(echo "$size_gb > $MAX_BACKUP_SIZE_GB" | bc -l 2>/dev/null) )); then
            log_message "WARNING" "Размер бэкапов превысил ${MAX_BACKUP_SIZE_GB} GB: ${size_gb} GB"
            
            # Дополнительная информация: список самых больших файлов
            log_message "INFO" "Топ-5 самых больших файлов:"
            find "$BACKUP_DIR" -type f -exec du -h {} \; 2>/dev/null | sort -rh | head -5 | while read line; do
                log_message "INFO" "  $line"
            done
            return 1
        else
            log_message "INFO" "Размер бэкапов в норме: ${size_gb} GB"
            return 0
        fi
    else
        log_message "WARNING" "Утилита 'bc' не установлена, проверка размера пропущена"
        return 0
    fi
}

show_help() {
    cat << EOH
Использование: $0 [--check-all] [--check-disk] [--check-backups] [--help]

Аргументы:
  --check-all     Проверить всё (по умолчанию)
  --check-disk    Проверить только свободное место на диске
  --check-backups Проверить только размер директории бэкапов
  --help          Показать эту справку

Пороги:
  - Предупреждение при свободном месте < ${WARNING_THRESHOLD}%
  - Критично при свободном месте < ${CRITICAL_THRESHOLD}%
  - Предупреждение при размере бэкапов > ${MAX_BACKUP_SIZE_GB} GB

Лог файл: $LOG_FILE
EOH
}

# --- Основная логика ---
main() {
    local check_disk=true
    local check_backups=true
    
    # Обработка аргументов
    case "${1:-}" in
        --check-disk)
            check_backups=false
            ;;
        --check-backups)
            check_disk=false
            ;;
        --help)
            show_help
            exit 0
            ;;
        --check-all|"")
            # Проверять всё (значение по умолчанию)
            ;;
        *)
            echo "Неизвестный аргумент: $1"
            show_help
            exit 1
            ;;
    esac
    
    log_message "INFO" "=== Запуск проверки дискового пространства ==="
    
    local exit_code=0
    
    # Проверка дискового пространства
    if [[ "$check_disk" = true ]]; then
        if ! check_disk_space; then
            [[ $? -ge 1 ]] && exit_code=1
        fi
    fi
    
    # Проверка размера бэкапов
    if [[ "$check_backups" = true ]]; then
        if ! check_backup_size; then
            [[ $? -ge 1 ]] && exit_code=1
        fi
    fi
    
    log_message "INFO" "=== Проверка завершена ==="
    
    # Сводка по лог-файлу
    echo -e "\nПоследние 10 записей из лога:"
    tail -10 "$LOG_FILE" 2>/dev/null || echo "Лог файл ещё не создан"
    
    exit $exit_code
}

# --- Запуск ---
main "$@"
