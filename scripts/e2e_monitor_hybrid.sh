#!/bin/bash
# Гибридный мониторинг: локальные проверки + AlertManager

LOG_FILE="/tmp/e2e_monitor_$(date +%Y%m%d_%H%M%S).log"
TELEGRAM_SCRIPT="/home/oleg/autoshop/scripts/send_telegram_alert.sh"
ALERTMANAGER_SCRIPT="/home/oleg/autoshop/scripts/send_to_alertmanager.sh"

echo "🔍 AVTOSVECHI - ГИБРИДНЫЙ МОНИТОРИНГ" > "$LOG_FILE"
echo "====================================" >> "$LOG_FILE"

ERRORS=()
WARNINGS=()

# Функции проверок
check_service() {
    local name="$1"
    local container="$2"
    local critical="$3"
    
    if docker ps --filter "name=$container" --format "{{.Status}}" | grep -q "Up"; then
        echo "✅ $name: РАБОТАЕТ" >> "$LOG_FILE"
        return 0
    else
        if [ "$critical" = "critical" ]; then
            ERRORS+=("$name")
            echo "❌ $name: НЕ РАБОТАЕТ (КРИТИЧЕСКО)" >> "$LOG_FILE"
        else
            WARNINGS+=("$name")
            echo "⚠️  $name: НЕ РАБОТАЕТ (ПРЕДУПРЕЖДЕНИЕ)" >> "$LOG_FILE"
        fi
        return 1
    fi
}

# Критические сервисы
check_service "Redis" "avtosvechi_redis" "critical"
check_service "Telegram Bot" "telegram-bot-fixed" "critical"
check_service "Prometheus" "autoshop_prometheus" "critical"

# Важные сервисы
check_service "Grafana" "autoshop_grafana" "warning"
check_service "AlertManager" "autoshop_alertmanager" "warning"
check_service "Telegram Proxy" "telegram-proxy-1" "warning"

# Логика уведомлений
TOTAL_ERRORS=${#ERRORS[@]}
TOTAL_WARNINGS=${#WARNINGS[@]}

if [ $TOTAL_ERRORS -gt 0 ]; then
    # Критические ошибки - Telegram + AlertManager
    ERROR_LIST=$(IFS=', '; echo "${ERRORS[*]}")
    
    # Telegram
    "$TELEGRAM_SCRIPT" "🚨 <b>КРИТИЧЕСКИЕ ОШИБКИ AVTOSVECHI</b>

⏰ $(date '+%d.%m.%Y %H:%M:%S')
🔴 Ошибок: $TOTAL_ERRORS
⚠️  Предупреждений: $TOTAL_WARNINGS

<b>Критические:</b>
$ERROR_LIST

<b>Действия:</b>
1. docker-compose logs
2. docker-compose restart
3. Проверить логи: $LOG_FILE"
    
    # AlertManager
    for error in "${ERRORS[@]}"; do
        "$ALERTMANAGER_SCRIPT" "critical" "$error не работает" "Сервис $error остановлен. Требуется немедленное вмешательство."
    done
    
    echo "CRITICAL: $TOTAL_ERRORS errors found" >> "$LOG_FILE"
    exit 1
    
elif [ $TOTAL_WARNINGS -gt 0 ]; then
    # Только предупреждения - только Telegram
    WARNING_LIST=$(IFS=', '; echo "${WARNINGS[*]}")
    
    "$TELEGRAM_SCRIPT" "⚠️  <b>ПРЕДУПРЕЖДЕНИЯ AVTOSVECHI</b>

⏰ $(date '+%d.%m.%Y %H:%M:%S')
⚠️  Предупреждений: $TOTAL_WARNINGS

<b>Сервисы:</b>
$WARNING_LIST

<b>Рекомендации:</b>
Проверить при первой возможности."
    
    echo "WARNING: $TOTAL_WARNINGS warnings found" >> "$LOG_FILE"
    exit 0
    
else
    # Всё ок - daily report
    HOUR=$(date +%H)
    if [ "$HOUR" = "08" ]; then  # В 8 утра
        "$TELEGRAM_SCRIPT" "✅ <b>AVTOSVECHI - ЕЖЕДНЕВНЫЙ ОТЧЕТ</b>

⏰ $(date '+%d.%m.%Y %H:%M:%S')
📊 Все системы работают нормально
🐳 Контейнеров: $(docker ps -q | wc -l)
💾 Память: $(free -m | awk 'NR==2{printf "%dMB/%dMB", $3,$2}')
📈 Нагрузка: $(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}')"
    fi
    
    echo "OK: All systems operational" >> "$LOG_FILE"
    exit 0
fi
