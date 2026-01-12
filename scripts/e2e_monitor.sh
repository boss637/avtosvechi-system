#!/bin/bash
echo "🔍 E2E МОНИТОРИНГ AVTOSVECHI - \$(date '+%Y-%m-%d %H:%M:%S')"
echo "========================================"

echo "1. Проверяем Docker сервисы:"
echo "------------------------------"

# Проверяем Redis
if docker ps --format "{{.Names}}" | grep -q "avtosvechi_redis"; then
    echo "   ✅ Redis: запущен"
else
    echo "   ❌ Redis: не запущен"
fi

# Проверяем Telegram Proxy
if docker ps --format "{{.Names}}" | grep -q "telegram-proxy-1"; then
    echo "   ✅ Telegram Proxy: запущен"
else
    echo "   ❌ Telegram Proxy: не запущен"
fi

# Проверяем Telegram Bot
if docker ps --format "{{.Names}}" | grep -q "telegram-bot-1"; then
    STATUS=\$(docker ps --format "{{.Names}}\t{{.Status}}" | grep "telegram-bot-1" | awk '{print \$2}')
    if echo "\$STATUS" | grep -q "Up"; then
        echo "   ✅ Telegram Bot: работает"
    else
        echo "   ⚠️  Telegram Bot: \$STATUS"
    fi
else
    echo "   ❌ Telegram Bot: не запущен"
fi

# Проверяем мониторинг
echo ""
echo "2. Проверяем систему мониторинга:"
echo "------------------------------"

if docker ps --format "{{.Names}}" | grep -q "autoshop_prometheus"; then
    echo "   ✅ Prometheus: запущен"
else
    echo "   ❌ Prometheus: не запущен"
fi

if docker ps --format "{{.Names}}" | grep -q "autoshop_grafana"; then
    echo "   ✅ Grafana: запущен"
else
    echo "   ❌ Grafana: не запущен"
fi

if docker ps --format "{{.Names}}" | grep -q "autoshop_alertmanager"; then
    echo "   ✅ AlertManager: запущен"
else
    echo "   ❌ AlertManager: не запущен"
fi

# Проверяем доступность
echo ""
echo "3. Проверяем доступность сервисов:"
echo "------------------------------"

# Проверка Redis
if docker exec avtosvechi_redis redis-cli ping 2>/dev/null | grep -q PONG; then
    echo "   ✅ Redis: отвечает"
else
    echo "   ❌ Redis: не отвечает"
fi

# Проверка Prometheus
if curl -s -f --connect-timeout 3 http://localhost:9091/-/healthy > /dev/null 2>&1; then
    echo "   ✅ Prometheus: работает"
else
    echo "   ❌ Prometheus: не отвечает"
fi

# Проверка Grafana
if curl -s -f --connect-timeout 3 http://localhost:3000/api/health > /dev/null 2>&1; then
    echo "   ✅ Grafana: работает"
else
    echo "   ❌ Grafana: не отвечает"
fi

# Статистика
echo ""
echo "4. Статистика системы:"
echo "------------------------------"
TOTAL=\$(docker ps -q | wc -l)
RUNNING=\$(docker ps --filter "status=running" -q | wc -l)
RESTARTING=\$(docker ps --filter "status=restarting" -q | wc -l)
echo "   Всего контейнеров: \$TOTAL"
echo "   Работающих: \$RUNNING"
echo "   Перезагружающихся: \$RESTARTING"

echo ""
echo "========================================"
echo "✅ Проверка завершена!"
