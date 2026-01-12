#!/bin/bash
echo "🔔 НАСТРОЙКА ПРОСТЫХ АЛЕРТОВ"
echo "============================"

# Создаем директорию для алертов
mkdir -p ~/autoshop/prometheus/alerts

# Создаем файл с алертами
cat > ~/autoshop/prometheus/alerts/avtosvechi_alerts.yml << 'ALERTS'
groups:
  - name: avtosvechi_alerts
    rules:
      - alert: ContainerRestarting
        expr: time() - container_last_seen{name=~".*"} > 60
        for: 2m
        labels:
          severity: warning
        annotations:
          summary: "Контейнер {{ $labels.name }} перезагружается"
          description: "Контейнер {{ $labels.name }} перезагружается более 2 минут"
          
      - alert: HighMemoryUsage
        expr: (container_memory_usage_bytes / container_spec_memory_limit_bytes) * 100 > 80
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "Высокое использование памяти {{ $labels.name }}"
          description: "Контейнер {{ $labels.name }} использует {{ $value }}% памяти"
          
      - alert: ServiceDown
        expr: up == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "Сервис {{ $labels.job }} недоступен"
          description: "Сервис {{ $labels.job }} на {{ $labels.instance }} недоступен"
ALERTS

echo "✅ Файл алертов создан: ~/autoshop/prometheus/alerts/avtosvechi_alerts.yml"
echo ""
echo "📋 ДЛЯ АКТИВАЦИИ АЛЕРТОВ:"
echo "1. Добавьте в prometheus.yml:"
echo "   rule_files:"
echo "     - '/etc/prometheus/alerts/avtosvechi_alerts.yml'"
echo ""
echo "2. Перезапустите Prometheus:"
echo "   docker restart autoshop_prometheus"
echo ""
echo "3. Настройте уведомления в AlertManager:"
echo "   http://$(hostname -I | awk '{print $1}'):9093"
