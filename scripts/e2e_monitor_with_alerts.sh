#!/bin/bash
# E2E мониторинг с уведомлениями в Telegram

LOG_FILE="/tmp/e2e_monitor_$(date +%Y%m%d_%H%M%S).log"
TELEGRAM_SCRIPT="/home/oleg/autoshop/scripts/send_telegram_alert.sh"

echo "🔍 AVTOSVECHI - МОНИТОРИНГ С АЛЕРТАМИ" > "$LOG_FILE"
echo "======================================" >> "$LOG_FILE"
echo "Время: $(date '+%Y-%m-%d %H:%M:%S')" >> "$LOG_FILE"
echo "" >> "$LOG_FILE"

ERRORS=0
ERROR_MESSAGES=()

# Проверка Redis
if ! docker ps --filter "name=avtosvechi_redis" --format "{{.Status}}" | grep -q "Up"; then
    ERRORS=$((ERRORS + 1))
    ERROR_MESSAGES+=("❌ Redis не работает")
    echo "❌ Redis: НЕ РАБОТАЕТ" >> "$LOG_FILE"
else
    echo "✅ Redis: РАБОТАЕТ" >> "$LOG_FILE"
fi

# Проверка Telegram Bot
if ! docker ps --filter "name=telegram-bot-fixed" --format "{{.Status}}" | grep -q "Up"; then
    ERRORS=$((ERRORS + 1))
    ERROR_MESSAGES+=("❌ Telegram Bot не работает")
    echo "❌ Telegram Bot: НЕ РАБОТАЕТ" >> "$LOG_FILE"
else
    echo "✅ Telegram Bot: РАБОТАЕТ" >> "$LOG_FILE"
fi

# Проверка Prometheus
if ! curl -s http://localhost:9091/-/healthy > /dev/null 2>&1; then
    ERRORS=$((ERRORS + 1))
    ERROR_MESSAGES+=("❌ Prometheus не отвечает")
    echo "❌ Prometheus: проблемы" >> "$LOG_FILE"
else
    echo "✅ Prometheus: здоров" >> "$LOG_FILE"
fi

# Проверка Grafana
if ! curl -s http://localhost:3000/api/health > /dev/null 2>&1; then
    ERRORS=$((ERRORS + 1))
    ERROR_MESSAGES+=("❌ Grafana недоступна")
    echo "❌ Grafana: недоступна" >> "$LOG_FILE"
else
    echo "✅ Grafana: работает" >> "$LOG_FILE"
fi

# Статистика
TOTAL=$(docker ps -q | wc -l)
RUNNING=$(docker ps --filter "status=running" -q | wc -l)
PROBLEMS=$(docker ps --filter "status=restarting" -q | wc -l)

echo "" >> "$LOG_FILE"
echo "📊 СТАТИСТИКА:" >> "$LOG_FILE"
echo "Всего контейнеров: $TOTAL" >> "$LOG_FILE"
echo "Работающих: $RUNNING" >> "$LOG_FILE"
echo "С проблемами: $PROBLEMS" >> "$LOG_FILE"

# Отправка уведомления при ошибках
if [ $ERRORS -gt 0 ]; then
    echo "" >> "$LOG_FILE"
    echo "⚠️  ОБНАРУЖЕНЫ ОШИБКИ: $ERRORS" >> "$LOG_FILE"
    
    # Формируем сообщение для Telegram
    MESSAGE="🚨 <b>AVTOSVECHI - ОБНАРУЖЕНЫ ПРОБЛЕМЫ!</b>
    
⏰ Время: $(date '+%d.%m.%Y %H:%M:%S')
🔧 Ошибок: $ERRORS
📊 Контейнеров: $RUNNING/$TOTAL

<b>Проблемы:</b>"
    
    for error in "${ERROR_MESSAGES[@]}"; do
        MESSAGE="$MESSAGE
• $error"
    done
    
    MESSAGE="$MESSAGE

<b>Действия:</b>
1. Проверить логи: docker-compose logs
2. Перезапустить: docker-compose restart
3. Подробный отчет: $LOG_FILE"
    
    # Отправляем в Telegram
    "$TELEGRAM_SCRIPT" "$MESSAGE"
    
    # Выводим в консоль
    echo "======================================"
    echo "🚨 ОБНАРУЖЕНЫ ОШИБКИ: $ERRORS"
    echo "📱 Уведомление отправлено в Telegram"
    echo "📁 Подробный лог: $LOG_FILE"
    exit 1
else
    echo "" >> "$LOG_FILE"
    echo "✅ ВСЕ СИСТЕМЫ РАБОТАЮТ" >> "$LOG_FILE"
    
    # Отправляем success сообщение раз в сутки (опционально)
    HOUR=$(date +%H)
    if [ "$HOUR" = "09" ]; then  # Только в 9 утра
        MESSAGE="✅ <b>AVTOSVECHI - ВСЕ СИСТЕМЫ В НОРМЕ</b>
        
⏰ Время: $(date '+%d.%m.%Y %H:%M:%S')
📊 Контейнеров: $RUNNING/$TOTAL
💾 Память: $(free -m | awk 'NR==2{printf "%dMB/%dMB (%.1f%%)", $3,$2,$3*100/$2}')
📈 Нагрузка: $(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}')

🌐 Сервисы:
• Grafana: http://192.168.1.100:3000
• Prometheus: http://192.168.1.100:9091"
        
        "$TELEGRAM_SCRIPT" "$MESSAGE"
    fi
    
    echo "======================================"
    echo "✅ ВСЕ СИСТЕМЫ РАБОТАЮТ"
    echo "📁 Лог: $LOG_FILE"
    exit 0
fi
