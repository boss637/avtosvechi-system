#!/bin/bash
TELEGRAM_BOT_TOKEN="8206084673:AAHNu7tEEm7FTNMXSz63nhVIkzjYYSg2p_w"
TELEGRAM_CHAT_ID="6838202455"

if ! docker info > /dev/null 2>&1; then
    curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" -d chat_id="${TELEGRAM_CHAT_ID}" -d text="🚨 Docker не работает" > /dev/null
    exit 1
fi

ERRORS=0
for container in avtosvechi_redis telegram-bot-fixed; do
    if ! docker ps --filter "name=$container" --quiet | grep -q .; then
        ERRORS=$((ERRORS + 1))
    fi
done

if [ $ERRORS -gt 0 ]; then
    curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" -d chat_id="${TELEGRAM_CHAT_ID}" -d text="⚠️ Проблемы с $ERRORS контейнерами" > /dev/null
fi
