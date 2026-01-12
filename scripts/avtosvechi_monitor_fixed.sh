#!/bin/bash
# ИСПРАВЛЕННЫЙ МОНИТОРИНГ AVTOSVECHI БЕЗ ЛОЖНЫХ СРАБАТЫВАНИЙ

TELEGRAM_BOT_TOKEN="8206084673:AAHNu7tEEm7FTNMXSz63nhVIkzjYYSg2p_w"
TELEGRAM_CHAT_ID="6838202455"
LOG_FILE="/home/oleg/avtosvechi_monitor_$(date +%Y%m%d).log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Функция отправки в Telegram
send_telegram() {
    local message="$1"
    curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
        -d chat_id="${TELEGRAM_CHAT_ID}" \
        -d text="${message}" \
        -d parse_mode="HTML" \
        > /dev/null 2>&1
}

# Начало
echo "[$TIMESTAMP] Запуск мониторинга" >> "$LOG_FILE"

# Реальные проверки (без dummy!)
CRITICAL_ERRORS=()
WARNINGS=()

# 1. ПРОВЕРКА ТОЛЬКО РЕАЛЬНЫХ СЕРВИСОВ
check_service() {
    local name="$1"
    local container="$2"
    local critical="$3"
    
    if docker ps --filter "name=$container" --format "{{.Status}}" | grep -q "Up"; then
        echo "[$TIMESTAMP] ✅ $name работает" >> "$LOG_FILE"
        return 0
    else
        echo "[$TIMESTAMP] ❌ $name не работает" >> "$LOG_FILE"
        if [ "$critical" = "critical" ]; then
            CRITICAL_ERRORS+=("$name")
        else
            WARNINGS+=("$name")
        fi
        return 1
    fi
}

# КРИТИЧЕСКИЕ сервисы (если не работают - немедленный алерт)
check_service "Redis" "avtosvechi_redis" "critical"
check_service "Telegram Bot" "telegram-bot-fixed" "critical"

# ВАЖНЫЕ сервисы (если не работают - только предупреждение)
check_service "Prometheus" "autoshop_prometheus" "warning"
check_service "Grafana" "autoshop_grafana" "warning"
check_service "AlertManager" "autoshop_alertmanager" "warning"

# 2. ФУНКЦИОНАЛЬНЫЕ ПРОВЕРКИ
# Redis ping
if ! docker exec avtosvechi_redis redis-cli ping 2>/dev/null | grep -q PONG; then
    echo "[$TIMESTAMP] ❌ Redis не отвечает на ping" >> "$LOG_FILE"
    CRITICAL_ERRORS+=("Redis ping")
fi

# 3. ИТОГИ
TOTAL_CRITICAL=${#CRITICAL_ERRORS[@]}
TOTAL_WARNINGS=${#WARNINGS[@]}

echo "[$TIMESTAMP] Итого: $TOTAL_CRITICAL критических, $TOTAL_WARNINGS предупреждений" >> "$LOG_FILE"

# 4. УВЕДОМЛЕНИЯ
if [ $TOTAL_CRITICAL -gt 0 ]; then
    # Критические ошибки
    CRITICAL_LIST=$(printf "• %s\n" "${CRITICAL_ERRORS[@]}")
    
    TELEGRAM_MESSAGE="🚨 <b>AVTOSVECHI - КРИТИЧЕСКИЕ ОШИБКИ!</b>

<b>Время:</b> $(date '+%d.%m.%Y %H:%M:%S')

<b>🔴 Критические ошибки ($TOTAL_CRITICAL):</b>
$CRITICAL_LIST

<b>📊 Статистика:</b>
• Контейнеров: $(docker ps -q | wc -l)
• Память: $(free -m | awk 'NR==2{printf "%dMB/%dMB", $3,$2}')
• Нагрузка: $(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | tr -d ',')

<b>🚨 Действия:</b>
1. docker-compose logs
2. docker-compose restart"
    
    send_telegram "$TELEGRAM_MESSAGE"
    echo "[$TIMESTAMP] Отправлено критическое уведомление" >> "$LOG_FILE"
    exit 1
elif [ $TOTAL_WARNINGS -gt 0 ]; then
    # Только предупреждения
    WARNING_LIST=$(printf "• %s\n" "${WARNINGS[@]}")
    
    TELEGRAM_MESSAGE="⚠️  <b>AVTOSVECHI - ПРЕДУПРЕЖДЕНИЯ</b>

<b>Время:</b> $(date '+%d.%m.%Y %H:%M:%S')

<b>🟡 Предупреждения ($TOTAL_WARNINGS):</b>
$WARNING_LIST

<b>✅ Основные системы работают</b>"
    
    send_telegram "$TELEGRAM_MESSAGE"
    echo "[$TIMESTAMP] Отправлено предупреждение" >> "$LOG_FILE"
    exit 0
else
    # Всё ок - только ежедневный отчет в 8 утра
    CURRENT_HOUR=$(date +%H)
    if [ "$CURRENT_HOUR" = "08" ]; then
        TELEGRAM_MESSAGE="✅ <b>AVTOSVECHI - ВСЁ РАБОТАЕТ</b>

<b>Время:</b> $(date '+%d.%m.%Y %H:%M:%S')
<b>Статус:</b> Все системы в норме
<b>Контейнеров:</b> $(docker ps -q | wc -l)"
        
        send_telegram "$TELEGRAM_MESSAGE"
        echo "[$TIMESTAMP] Отправлен ежедневный отчет" >> "$LOG_FILE"
    fi
    
    echo "[$TIMESTAMP] ✅ Все системы работают" >> "$LOG_FILE"
    exit 0
fi
