#!/bin/bash
# ============================================================================
# ПОЛНОСТЬЮ АВТОНОМНЫЙ МОНИТОРИГ AVTOSVECHI
# НЕ ТРЕБУЕТ НИКАКИХ ВВОДОВ С КЛАВИАТУРЫ
# ============================================================================

# Конфигурация
TELEGRAM_BOT_TOKEN="8206084673:AAHNu7tEEm7FTNMXSz63nhVIkzjYYSg2p_w"
TELEGRAM_CHAT_ID="6838202455"
LOG_FILE="/home/oleg/autoshop/logs/auto_monitor_$(date +%Y%m%d_%H%M%S).log"

# Создаем директорию логов
mkdir -p /home/oleg/autoshop/logs

# Функция логирования
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Функция отправки в Telegram
send_telegram() {
    local message="$1"
    curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
        -d chat_id="${TELEGRAM_CHAT_ID}" \
        -d text="$message" \
        -d parse_mode="HTML" > /dev/null
}

# ============================================================================
# НАЧАЛО АВТОНОМНОЙ ПРОВЕРКИ
# ============================================================================

log "🚀 ЗАПУСК АВТОНОМНОГО МОНИТОРИНГА AVTOSVECHI"
log "Сервер: $(hostname)"
log "Время: $(date)"

# Проверка 1: Доступность Docker
log "🔍 Проверка Docker..."
if docker info > /dev/null 2>&1; then
    log "✅ Docker работает"
    DOCKER_OK=true
else
    log "❌ CRITICAL: Docker не отвечает!"
    send_telegram "🚨 <b>AVTOSVECHI CRITICAL</b>
    
⚠️ Docker не работает!
Сервер: $(hostname)
Время: $(date)"
    exit 1
fi

# Проверка 2: Список контейнеров
log "🔍 Проверка контейнеров..."
CONTAINERS=("avtosvechi_redis" "telegram-bot-fixed")
ERROR_COUNT=0
RUNNING_CONTAINERS=0

for container in "${CONTAINERS[@]}"; do
    if docker ps --filter "name=$container" --format "table {{.Names}}\t{{.Status}}" | grep -q "$container"; then
        STATUS=$(docker ps --filter "name=$container" --format "{{.Status}}")
        log "✅ $container: $STATUS"
        RUNNING_CONTAINERS=$((RUNNING_CONTAINERS + 1))
    else
        log "❌ $container: НЕ ЗАПУЩЕН"
        ERROR_COUNT=$((ERROR_COUNT + 1))
    fi
done

# Итоговый отчет
log "=========================================="
log "ИТОГ ПРОВЕРКИ:"
log "Всего контейнеров: ${#CONTAINERS[@]}"
log "Запущено: $RUNNING_CONTAINERS"
log "Ошибок: $ERROR_COUNT"
log "=========================================="

# Отправка уведомления при проблемах
if [ $ERROR_COUNT -eq 0 ]; then
    log "🎉 ВСЕ СИСТЕМЫ РАБОТАЮТ НОРМАЛЬНО"
    # Можно отправлять ежедневный отчет о нормальной работе
    HOUR=$(date +%H)
    if [ "$HOUR" = "08" ] || [ "$HOUR" = "20" ]; then
        send_telegram "✅ <b>AVTOSVECHI Status Report</b>
        
Все системы работают нормально!
Контейнеров: ${#CONTAINERS[@]}
Время: $(date)
Сервер: $(hostname)"
    fi
    exit 0
else
    log "⚠️ ОБНАРУЖЕНЫ ПРОБЛЕМЫ: $ERROR_COUNT ошибок"
    
    # Формируем детальное сообщение
    MESSAGE="🚨 <b>AVTOSVECHI ALERT</b>
    
Обнаружены проблемы с контейнерами!
Сервер: $(hostname)
Время: $(date)

Статус контейнеров:"
    
    for container in "${CONTAINERS[@]}"; do
        if docker ps --filter "name=$container" | grep -q "$container"; then
            STATUS=$(docker ps --filter "name=$container" --format "{{.Status}}")
            MESSAGE="$MESSAGE
✅ $container: $STATUS"
        else
            MESSAGE="$MESSAGE
❌ $container: НЕ ЗАПУЩЕН"
        fi
    done
    
    MESSAGE="$MESSAGE

Требуется вмешательство!"
    
    send_telegram "$MESSAGE"
    exit 1
fi

# ============================================================================
# КОНЕЦ СКРИПТА - АВТОМАТИЧЕСКИ ЗАВЕРШАЕТСЯ
# ============================================================================
