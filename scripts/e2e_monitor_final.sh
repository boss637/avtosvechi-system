#!/bin/bash
echo "🔍 AVTOSVECHI - ПОЛНЫЙ E2E МОНИТОРИНГ"
echo "======================================"
echo "Время: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

# Цвета
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "1. ОСНОВНЫЕ СЕРВИСЫ ПРОЕКТА:"
echo "------------------------------"

check() {
    if docker ps --filter "name=$1" --format "{{.Status}}" | grep -q "Up"; then
        echo -e "   ${GREEN}✅ $2: РАБОТАЕТ${NC}"
        return 0
    else
        echo -e "   ${RED}❌ $2: НЕ РАБОТАЕТ${NC}"
        return 1
    fi
}

check "avtosvechi_redis" "Redis"
check "telegram-bot-fixed" "Telegram Bot"
check "telegram-proxy-1" "Telegram Proxy"

echo ""
echo "2. СИСТЕМА МОНИТОРИНГА:"
echo "------------------------------"

check "autoshop_prometheus" "Prometheus"
check "autoshop_grafana" "Grafana"
check "autoshop_alertmanager" "AlertManager"
check "adf2e6e24025_autoshop_node_exporter" "Node Exporter"
check "946eb9702fa1_autoshop_cadvisor" "cAdvisor"

echo ""
echo "3. ПРОВЕРКА ДОСТУПНОСТИ:"
echo "------------------------------"

# Redis
if docker exec avtosvechi_redis redis-cli ping 2>/dev/null | grep -q PONG; then
    echo -e "   ${GREEN}✅ Redis: отвечает${NC}"
else
    echo -e "   ${RED}❌ Redis: не отвечает${NC}"
fi

# Prometheus
if curl -s http://localhost:9091/-/healthy > /dev/null 2>&1; then
    echo -e "   ${GREEN}✅ Prometheus: здоров${NC}"
else
    echo -e "   ${RED}❌ Prometheus: проблемы${NC}"
fi

# Grafana
if curl -s http://localhost:3000/api/health > /dev/null 2>&1; then
    echo -e "   ${GREEN}✅ Grafana: работает${NC}"
else
    echo -e "   ${RED}❌ Grafana: недоступна${NC}"
fi

echo ""
echo "4. СТАТИСТИКА СИСТЕМЫ:"
echo "------------------------------"
TOTAL=$(docker ps -q | wc -l)
RUNNING=$(docker ps --filter "status=running" -q | wc -l)
PROBLEMS=$(docker ps --filter "status=restarting" -q | wc -l)

echo "   Всего контейнеров: $TOTAL"
echo "   Работающих: $RUNNING"
echo "   С проблемами: $PROBLEMS"

echo ""
echo "======================================"
if [ $PROBLEMS -eq 0 ]; then
    echo -e "${GREEN}✅ ВСЕ СИСТЕМЫ РАБОТАЮТ!${NC}"
else
    echo -e "${YELLOW}⚠️  ЕСТЬ ПРОБЛЕМЫ${NC}"
fi
echo ""
echo "🌐 ДОСТУПНЫЕ СЕРВИСЫ:"
echo "   • Grafana:      http://$(hostname -I | awk '{print $1}'):3000"
echo "   • Prometheus:   http://$(hostname -I | awk '{print $1}'):9091"
echo "   • AlertManager: http://$(hostname -I | awk '{print $1}'):9093"
