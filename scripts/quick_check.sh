#!/bin/bash
echo "⚡ БЫСТРАЯ ПРОВЕРКА - \$(date '+%H:%M:%S')"
echo "========================================"
echo "Контейнеры:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | head -10
echo ""
echo "Проблемные:"
docker ps --filter "status=restarting" --format "{{.Names}} ({{.Status}})"
