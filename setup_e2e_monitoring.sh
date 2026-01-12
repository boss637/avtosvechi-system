#!/bin/bash
echo "🚀 НАСТРОЙКА E2E МОНИТОРИНГА AVTOSVECHI"
echo "========================================"

# 1. СОЗДАЕМ СТРУКТУРУ ПАПОК
echo "1. Создаем структуру папок..."
mkdir -p scripts prometheus/alerts .github/workflows
echo "   ✅ Готово"

# 2. СОЗДАЕМ ОСНОВНОЙ СКРИПТ E2E МОНИТОРИНГА
echo "2. Создаем скрипт E2E мониторинга..."
cat > scripts/e2e_monitor.sh << 'SCRIPT'
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
SCRIPT

# Делаем скрипт исполняемым
chmod +x scripts/e2e_monitor.sh
echo "   ✅ Скрипт создан и сделан исполняемым"

# 3. СОЗДАЕМ СКРИПТ БЫСТРОЙ ПРОВЕРКИ
echo "3. Создаем скрипт быстрой проверки..."
cat > scripts/quick_check.sh << 'QUICK'
#!/bin/bash
echo "⚡ БЫСТРАЯ ПРОВЕРКА - \$(date '+%H:%M:%S')"
echo "========================================"
echo "Контейнеры:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | head -10
echo ""
echo "Проблемные:"
docker ps --filter "status=restarting" --format "{{.Names}} ({{.Status}})"
QUICK

chmod +x scripts/quick_check.sh
echo "   ✅ Скрипт быстрой проверки создан"

# 4. СОЗДАЕМ КОНФИГУРАЦИЮ PROMETHEUS
echo "4. Создаем конфигурацию Prometheus..."
cat > prometheus/prometheus.yml << 'PROMETHEUS'
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'docker'
    static_configs:
      - targets: ['docker-exporter:9323']

  - job_name: 'node'
    static_configs:
      - targets: ['node-exporter:9100']
PROMETHEUS
echo "   ✅ Конфигурация Prometheus создана"

# 5. СОЗДАЕМ CRON ЗАДАЧУ
echo "5. Настраиваем автоматическую проверку..."
CRON_JOB="0 * * * * /home/oleg/autoshop/scripts/e2e_monitor.sh >> /home/oleg/e2e_monitor.log 2>&1"
(crontab -l 2>/dev/null | grep -v "e2e_monitor.sh"; echo "$CRON_JOB") | crontab -
echo "   ✅ Cron задача добавлена: проверка каждый час"

# 6. СОЗДАЕМ ИНСТРУКЦИЮ
echo "6. Создаем инструкцию..."
cat > INSTRUCTIONS.txt << 'INSTRUCTIONS'
🎯 E2E МОНИТОРИНГ AVTOSVECHI - ИНСТРУКЦИЯ
=========================================

📋 ЧТО БЫЛО СОЗДАНО:
1. ✅ scripts/e2e_monitor.sh     - Полная проверка системы
2. ✅ scripts/quick_check.sh     - Быстрая проверка (5 сек)
3. ✅ prometheus/prometheus.yml  - Конфигурация мониторинга
4. ✅ Cron задача               - Автопроверка каждый час

🚀 КАК ИСПОЛЬЗОВАТЬ:

1. ЗАПУСТИТЬ ПОЛНУЮ ПРОВЕРКУ:
   ./scripts/e2e_monitor.sh

2. ЗАПУСТИТЬ БЫСТРУЮ ПРОВЕРКУ:
   ./scripts/quick_check.sh

3. ПРОВЕРИТЬ LOGS CRON:
   cat /home/oleg/e2e_monitor.log

4. ПРОВЕРИТЬ CRON ЗАДАЧИ:
   crontab -l

🔧 РЕШЕНИЕ ПРОБЛЕМ:

1. Если Telegram бот перезагружается:
   docker logs telegram-bot-1 --tail 50

2. Если сервисы не запущены:
   docker-compose up -d

3. Проверить доступность:
   - Grafana:      http://ваш-ip:3000 (admin/admin123)
   - Prometheus:   http://ваш-ip:9091
   - AlertManager: http://ваш-ip:9093

📊 ДАЛЬНЕЙШИЕ ШАГИ:
1. Добавить PostgreSQL в docker-compose.yml
2. Добавить API сервис (порт 8000)
3. Настроить алерты в AlertManager
4. Создать дашборд в Grafana

📞 ЕСЛИ ВОЗНИКЛИ ПРОБЛЕМЫ:
Запустите команды и покажите вывод:
1. ./scripts/e2e_monitor.sh
2. docker logs telegram-bot-1 --tail 50
INSTRUCTIONS

echo ""
echo "========================================"
echo "✅ ВСЁ ГОТОВО!"
echo ""
echo "📋 ИНСТРУКЦИЯ СОХРАНЕНА В ФАЙЛЕ: INSTRUCTIONS.txt"
echo ""
echo "🚀 ЗАПУСТИТЕ ПРОВЕРКУ:"
echo "   ./scripts/e2e_monitor.sh"
echo ""
echo "⚡ БЫСТРАЯ ПРОВЕРКА:"
echo "   ./scripts/quick_check.sh"
