#!/bin/bash
# Отправка алертов в AlertManager

ALERTMANAGER_URL="http://localhost:9093"

send_alert() {
    local severity="$1"
    local summary="$2"
    local description="$3"
    
    ALERT_JSON=$(cat << JSON
[
  {
    "labels": {
      "alertname": "E2ECheckFailed",
      "service": "avtosvechi",
      "severity": "${severity}",
      "instance": "$(hostname)"
    },
    "annotations": {
      "summary": "${summary}",
      "description": "${description}",
      "timestamp": "$(date -Iseconds)"
    }
  }
]
JSON
)
    
    curl -X POST "${ALERTMANAGER_URL}/api/v1/alerts" \
         -H "Content-Type: application/json" \
         -d "${ALERT_JSON}" \
         > /dev/null 2>&1
}

# Пример использования
# send_alert "critical" "Redis не работает" "Контейнер Redis остановлен"
