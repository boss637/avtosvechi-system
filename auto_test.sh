#!/bin/bash
echo "🧪 АВТОТЕСТ СИСТЕМЫ AVTOSVECHI"
echo "=============================="
echo "Время старта: $(date)"
echo ""

# 1. ТЕСТ СЕРВИСОВ
echo "1. ПРОВЕРКА СЕРВИСОВ:"
echo "-------------------"

services=("avtosvechi_redis:Redis" "telegram-bot-fixed:Telegram Bot" "autoshop_prometheus:Prometheus")

all_ok=true
for service in "${services[@]}"; do
    container="${service%%:*}"
    name="${service##*:}"
    
    if docker ps --filter "name=$container" --format "{{.Status}}" | grep -q "Up"; then
        echo "  ✅ $name: работает"
    else
        echo "  ❌ $name: НЕ РАБОТАЕТ"
        all_ok=false
    fi
done

echo ""
echo "2. ТЕСТ МОНИТОРИНГА:"
echo "-------------------"
./scripts/avtosvechi_monitor_fixed.sh 2>&1 | tail -3
monitor_exit=$?

echo ""
echo "3. ТЕСТ CRON:"
echo "------------"
crontab -l | grep -c avtosvechi | while read count; do
    echo "  Найдено задач: $count"
done

echo ""
echo "📊 ИТОГИ ТЕСТА:"
echo "-------------"
if $all_ok && [ $monitor_exit -eq 0 ]; then
    echo "  ✅ ВСЕ ТЕСТЫ ПРОЙДЕНЫ"
    echo "  🚀 СИСТЕМА ГОТОВА К РАБОТЕ"
    exit 0
else
    echo "  ❌ ЕСТЬ ПРОБЛЕМЫ"
    echo "  🔧 ТРЕБУЕТСЯ НАСТРОЙКА"
    exit 1
fi
