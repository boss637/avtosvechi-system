# Solver Agent - Агент-решатель

## Назначение
Solver Agent - это интеллектуальный компонент Триады, предназначенный для автоматического анализа инцидентов и предложения решений. В будущем будет интегрирован с ML-моделями для полной автоматизации.

## Архитектура

### Основные компоненты
1. **Rules Engine** - движок правил для анализа инцидентов
2. **Health Server** - HTTP сервер для health checks (порт 8080)
3. **Analysis Cycle** - цикл периодического анализа новых инцидентов

### Поддерживаемые типы действий
- `restart_service` - перезапуск сервиса
- `execute_command` - выполнение shell команды
- `send_notification` - отправка уведомления

## Конфигурация правил

### Формат rules.yaml
Правила описываются в YAML формате с полями:
```yaml
- id: "уникальный_идентификатор"
  name: "Название правила"
  condition:  # Условие срабатывания
    service: "имя_сервиса"
    error_type: "тип_ошибки"
    count_threshold: 3
    time_window_minutes: 5
  action:     # Действие при срабатывании
    type: "restart_service"
    service: "имя_сервиса"
    command: "docker restart контейнер"
  priority: "high|medium|low"
  enabled: true|false
  requires_confirmation: true|false
  confidence_threshold: 0.0-1.0
