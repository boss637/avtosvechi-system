#!/bin/bash

# ============================================
# clean_old_backups.sh
# Удаляет старые файлы резервных копий.
# КРИТИЧЕСКОЕ ПРАВИЛО: Всегда сохраняются 3 последних файла каждого типа.
# ============================================

set -euo pipefail

# --- Конфигурация ---
BACKUP_DIR="/home/oleg/autoshop/backups"
# Шаблоны имен файлов для удаления
FILE_PATTERNS=("db_dump_*.sql.gz" "code_snapshot_*.tar.gz")
# Дней хранения по умолчанию
DEFAULT_RETENTION_DAYS=30
# МИНИМАЛЬНОЕ количество файлов каждого типа, которые должны остаться ВСЕГДА
MIN_KEEP_COUNT=3
# ============================================

# --- Цвета для вывода (опционально) ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color
# ============================================

# --- Функции ---
print_header() {
    echo -e "\n${BLUE}=== Очистка старых резервных копий ===${NC}"
    echo -e "${BLUE}Правило: Всегда сохраняется минимум $MIN_KEEP_COUNT последних файлов каждого типа${NC}"
}

print_info() {
    echo -e "[INFO] $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS] $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

print_error() {
    echo -e "${RED}[ERROR] $1${NC}" >&2
}

# Функция для проверки возраста файла в днях (упрощенная и надежная)
file_older_than_days() {
    local file="$1"
    local days="$2"
    
    # Простая проверка с помощью find
    # find возвращает имя файла если он старше указанных дней
    if find "$file" -mtime "+$days" 2>/dev/null | grep -q .; then
        return 0  # файл старше указанного количества дней
    else
        return 1  # файл младше или не найден
    fi
}

show_help() {
    cat << EOH
Использование: $0 [--days N] [--force] [--help]

Аргументы:
  --days N   Удалить файлы старше N дней (по умолчанию: $DEFAULT_RETENTION_DAYS)
  --force    Удалить без подтверждения
  --help     Показать эту справку

ВАЖНО: Независимо от срока, всегда сохраняются $MIN_KEEP_COUNT последних файлов каждого типа.

Примеры:
  $0                     # Интерактивный режим, период 30 дней
  $0 --days 7 --force    # Удалить файлы старше 7 дней (кроме 3 самых свежих)
EOH
}

# --- Обработка аргументов командной строки ---
RETENTION_DAYS=$DEFAULT_RETENTION_DAYS
FORCE_MODE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --days)
            if [[ $2 =~ ^[0-9]+$ ]]; then
                RETENTION_DAYS=$2
                shift 2
            else
                print_error "Аргумент для --days должен быть числом."
                exit 1
            fi
            ;;
        --force)
            FORCE_MODE=true
            shift
            ;;
        --help)
            show_help
            exit 0
            ;;
        *)
            print_error "Неизвестный аргумент: $1"
            show_help
            exit 1
            ;;
    esac
done

# --- Основная логика ---
main() {
    print_header

    # Проверка существования директории
    if [[ ! -d "$BACKUP_DIR" ]]; then
        print_error "Директория с бэкапами не найдена: $BACKUP_DIR"
        exit 1
    fi

    print_info "Директория для очистки: $BACKUP_DIR"
    print_info "Период хранения: $RETENTION_DAYS дней."
    print_info "Гарантированно сохраняем: $MIN_KEEP_COUNT последних файлов каждого типа."

    # Массив для хранения путей к файлам, которые будут удалены
    declare -a files_to_delete=()

    # Обрабатываем каждый шаблон отдельно
    for pattern in "${FILE_PATTERNS[@]}"; do
        print_info "Обработка файлов по шаблону: $pattern"
        
        # 1. Находим ВСЕ файлы по шаблону, сортируем по времени изменения (сначала новые)
        # Используем простой подход без сложных строк с метками времени
        all_files=()
        while IFS= read -r file; do
            all_files+=("$file")
        done < <(find "$BACKUP_DIR" -maxdepth 1 -type f -name "$pattern" -printf "%T@ %p\n" 2>/dev/null | sort -rn 2>/dev/null | cut -d' ' -f2- 2>/dev/null)
        
        # Альтернативный способ если выше не сработал
        if [[ ${#all_files[@]} -eq 0 ]]; then
            all_files=($(find "$BACKUP_DIR" -maxdepth 1 -type f -name "$pattern" 2>/dev/null | xargs -I{} sh -c 'echo $(stat -c %Y "{}") {}' 2>/dev/null | sort -rn | cut -d' ' -f2-))
        fi
        
        if [[ ${#all_files[@]} -eq 0 ]]; then
            print_info "  Файлы не найдены."
            continue
        fi
        
        print_info "  Всего найдено: ${#all_files[@]} файл(ов)."
        
        # 2. Определяем файлы, которые гарантированно сохраняем (последние MIN_KEEP_COUNT)
        keep_count=$(( ${#all_files[@]} < MIN_KEEP_COUNT ? ${#all_files[@]} : MIN_KEEP_COUNT ))
        
        # Выводим имена сохраняемых файлов
        if [[ $keep_count -gt 0 ]]; then
            print_info "  Гарантированно сохраняем $keep_count самых свежих файл(ов):"
            for ((k=0; k<keep_count; k++)); do
                file="${all_files[$k]}"
                file_date=$(stat -c %y "$file" 2>/dev/null | cut -d' ' -f1,2 | cut -d'.' -f1 || echo "unknown")
                print_info "    - $(basename "$file") (изменен: $file_date)"
            done
        fi
        
        # 3. Фильтруем оставшиеся файлы по сроку хранения
        for ((i=keep_count; i<${#all_files[@]}; i++)); do
            file="${all_files[$i]}"
            
            # Проверяем, старше ли файл указанного количества дней
            if file_older_than_days "$file" "$RETENTION_DAYS"; then
                files_to_delete+=("$file")
                file_date=$(stat -c %y "$file" 2>/dev/null | cut -d' ' -f1,2 | cut -d'.' -f1 || echo "unknown")
                file_age=$(($(($(date +%s) - $(stat -c %Y "$file" 2>/dev/null || echo $(date +%s)))) / 86400))
                print_info "  Помечен для удаления (возраст: ${file_age} дней): $(basename "$file")"
            else
                file_age=$(($(($(date +%s) - $(stat -c %Y "$file" 2>/dev/null || echo $(date +%s)))) / 86400))
                print_info "  Сохраняем (возраст: ${file_age} дней): $(basename "$file")"
            fi
        done
    done

    # Проверяем, есть ли что удалять
    if [[ ${#files_to_delete[@]} -eq 0 ]]; then
        print_success "Файлы для удаления не найдены (старше $RETENTION_DAYS дней, кроме $MIN_KEEP_COUNT последних каждого типа)."
        exit 0
    fi

    # Вывод списка файлов для удаления
    echo -e "\n${YELLOW}Найдены следующие файлы для удаления (старше $RETENTION_DAYS дней):${NC}"
    for file in "${files_to_delete[@]}"; do
        file_age=$(($(($(date +%s) - $(stat -c %Y "$file" 2>/dev/null || echo $(date +%s)))) / 86400))
        echo "$(basename "$file") (возраст: ${file_age} дней)"
    done
    echo ""

    # Подсчет и вывод сводки
    file_count=${#files_to_delete[@]}
    total_size=$(printf '%s\0' "${files_to_delete[@]}" | xargs -0 du -ch 2>/dev/null | tail -1 | cut -f1)
    print_warning "ИТОГО: $file_count файл(ов) общим размером ~$total_size."

    # Запрос подтверждения (если не режим --force)
    if [[ "$FORCE_MODE" = false ]]; then
        echo -e "${YELLOW}Вы уверены, что хотите удалить эти файлы?${NC}"
        read -p "Введите 'yes' для подтверждения: " -r user_confirmation
        if [[ ! "$user_confirmation" =~ ^[Yy][Ee][Ss]$ ]]; then
            print_info "Удаление отменено пользователем."
            exit 0
        fi
    else
        print_info "Режим --force активен, подтверждение не требуется."
    fi

    # УДАЛЕНИЕ ФАЙЛОВ
    echo ""
    deleted_count=0
    for file in "${files_to_delete[@]}"; do
        if rm -v "$file"; then
            ((deleted_count++))
        else
            print_error "Не удалось удалить файл: $file"
        fi
    done

    # Итоговое сообщение
    if [[ $deleted_count -eq $file_count ]]; then
        print_success "Очистка завершена. Удалено $deleted_count файл(ов)."
    else
        print_warning "Очистка завершена с замечаниями. Удалено $deleted_count из $file_count файл(ов)."
    fi
}

# --- Запуск основной функции ---
main "$@"
