from __future__ import annotations

import base64
import hashlib
import hmac
import json
from datetime import UTC, datetime, timedelta

SECRET_KEY = "lms-secret-key"


def create_token(payload: dict, expires_minutes: int = 60) -> str:
    data = payload | {"exp": (datetime.now(UTC) + timedelta(minutes=expires_minutes)).timestamp()}
    raw = json.dumps(data, separators=(",", ":"), sort_keys=True).encode()
    signature = hmac.new(SECRET_KEY.encode(), raw, hashlib.sha256).digest()
    return base64.urlsafe_b64encode(raw).decode() + "." + base64.urlsafe_b64encode(signature).decode()


def decode_token(token: str) -> dict | None:
    try:
        raw_part, sign_part = token.split(".")
        raw = base64.urlsafe_b64decode(raw_part.encode())
        provided = base64.urlsafe_b64decode(sign_part.encode())
        expected = hmac.new(SECRET_KEY.encode(), raw, hashlib.sha256).digest()
        if not hmac.compare_digest(expected, provided):
            return None
        payload = json.loads(raw.decode())
        if payload["exp"] < datetime.now(UTC).timestamp():
            return None
        return payload
    except Exception:
        return None
