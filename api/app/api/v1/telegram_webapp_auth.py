from __future__ import annotations

import hashlib
import hmac
import os
import time
from typing import Any, Dict, List, Tuple
from urllib.parse import parse_qsl

from fastapi import APIRouter, Body, HTTPException

router = APIRouter(tags=["auth", "telegram"])


def _read_bot_token() -> str:
    token_file = os.getenv("TELEGRAM_BOT_TOKEN_FILE", "/run/secrets/telegram_bot_token")
    try:
        with open(token_file, "r", encoding="utf-8") as f:
            token = f.read().strip()
    except FileNotFoundError:
        raise HTTPException(status_code=500, detail=f"Telegram token file not found: {token_file}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to read Telegram token file: {type(e).__name__}: {e}")

    if not token:
        raise HTTPException(status_code=500, detail="Telegram bot token is empty")
    return token


def _compute_webapp_hash(init_data: str, bot_token: str) -> str:
    pairs: List[Tuple[str, str]] = parse_qsl(init_data, keep_blank_values=True, strict_parsing=False)

    data: Dict[str, str] = {}
    received_hash: str | None = None

    for k, v in pairs:
        if k == "hash":
            received_hash = v
        else:
            data[k] = v

    if not received_hash:
        raise HTTPException(status_code=400, detail="initData missing 'hash'")

    # data_check_string: key=value lines sorted by key
    items = sorted(data.items(), key=lambda x: x[0])
    data_check_string = "\n".join([f"{k}={v}" for (k, v) in items])

    # secret_key = HMAC_SHA256("WebAppData", bot_token)
    secret_key = hmac.new(key=b"WebAppData", msg=bot_token.encode("utf-8"), digestmod=hashlib.sha256).digest()

    # computed_hash = HMAC_SHA256(data_check_string, secret_key) as hex
    computed_hash = hmac.new(
        key=secret_key, msg=data_check_string.encode("utf-8"), digestmod=hashlib.sha256
    ).hexdigest()

    # Return received too for caller checks
    return computed_hash, received_hash, data


@router.post("/auth/telegram/webapp/verify")
def verify_webapp_init_data(
    initData: str = Body(..., embed=True),
    max_age_seconds: int = Body(300, embed=True),
) -> Dict[str, Any]:
    """
    Verify Telegram Mini App initData and return parsed fields.
    This endpoint only verifies; session/JWT выдадим следующим шагом.
    """
    bot_token = _read_bot_token()

    computed_hash, received_hash, data = _compute_webapp_hash(initData, bot_token)

    if computed_hash != received_hash:
        raise HTTPException(status_code=401, detail="initData hash mismatch")

    # Optional freshness check (auth_date is unix seconds)
    auth_date_raw = data.get("auth_date")
    if not auth_date_raw:
        raise HTTPException(status_code=400, detail="initData missing 'auth_date'")

    try:
        auth_date = int(auth_date_raw)
    except ValueError:
        raise HTTPException(status_code=400, detail="initData invalid 'auth_date'")

    now = int(time.time())
    if max_age_seconds > 0 and (now - auth_date) > max_age_seconds:
        raise HTTPException(status_code=401, detail="initData is too old")

    # user приходит как JSON-строка, оставляем как есть на этом шаге
    return {
        "ok": True,
        "auth_date": auth_date,
        "data": data,
    }
