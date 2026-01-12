#!/bin/bash
# Скрипт отправки уведомлений в Telegram

TELEGRAM_BOT_TOKEN="8206084673:AAHNu7tEEm7FTNMXSz63nhVIkzjYYSg2p_w"
TELEGRAM_CHAT_ID="6838202455"

# Функция отправки сообщения
send_message() {
    local message="$1"
    curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
        -d chat_id="${TELEGRAM_CHAT_ID}" \
        -d text="${message}" \
        -d parse_mode="HTML" \
        > /dev/null 2>&1
}

# Основная логика
if [ $# -eq 0 ]; then
    echo "Использование: $0 'Текст сообщения'"
    exit 1
fi

# Отправляем сообщение
send_message "$1"
echo "Сообщение отправлено в Telegram"
