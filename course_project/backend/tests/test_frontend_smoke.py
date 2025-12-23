import os

import httpx
import pytest


FRONTEND_BASE = os.getenv("FRONTEND_BASE", "http://localhost:5173")


def test_frontend_serves_index():
    try:
        response = httpx.get(FRONTEND_BASE, timeout=10)
    except httpx.HTTPError as exc:  # pragma: no cover - environment dependent
        pytest.skip(f"Frontend not available: {exc}")
    assert response.status_code == 200
    assert "<div id=\"root\"></div>" in response.text
