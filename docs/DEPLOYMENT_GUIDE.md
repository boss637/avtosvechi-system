# Руководство по развертыванию

## Быстрый старт:
1. cp .env.example .env
2. Заполните TELEGRAM_TOKEN
3. docker compose up -d --build
4. docker compose ps

## Проверка:
- curl http://localhost:9090/metrics
- curl http://localhost:8080/health
- Команда /start в Telegram боте

## Устранение неполадок:
1. Проверьте .env файл
2. Проверьте логи: docker compose logs
3. Перезапустите: docker compose restart
