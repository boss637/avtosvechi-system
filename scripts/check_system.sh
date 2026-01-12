#!/bin/bash
echo "⚡ БЫСТРАЯ ПРОВЕРКА СИСТЕМЫ"
echo "=========================="
echo "Время: $(date '+%H:%M:%S')"
echo ""

echo "Контейнеры:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.CreatedAt}}" | head -10

echo ""
echo "Проблемные:"
docker ps --filter "status=restarting" --format "{{.Names}} ({{.Status}})"

echo ""
echo "Ресурсы:"
echo "  Память: $(free -m | awk 'NR==2{printf "%sMB/%sMB", $3,$2}')"
echo "  Нагрузка: $(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}')"
