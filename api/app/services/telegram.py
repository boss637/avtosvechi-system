import os
import requests


def _read_token() -> str:
    token_path = os.getenv("TELEGRAM_BOT_TOKEN_FILE", "/run/secrets/telegram_bot_token")
    with open(token_path, "r", encoding="utf-8") as f:
        return f.read().strip()


def send_telegram_message(text: str) -> dict:
    chat_id = os.getenv("TELEGRAM_CHAT_ID")
    if not chat_id:
        raise RuntimeError("TELEGRAM_CHAT_ID is not set")

    token = _read_token()
    if not token:
        raise RuntimeError("Telegram token is empty")

    url = f"https://api.telegram.org/bot{token}/sendMessage"
    payload = {
        "chat_id": chat_id,
        "text": text,
        "disable_web_page_preview": True,
    }

    r = requests.post(url, data=payload, timeout=10)
    r.raise_for_status()
    return r.json()
