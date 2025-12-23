import os

import httpx


FRONTEND_BASE = os.getenv("FRONTEND_BASE", "http://localhost:5173")


def test_frontend_serves_index():
    response = httpx.get(FRONTEND_BASE, timeout=10)
    assert response.status_code == 200
    assert "<div id=\"root\"></div>" in response.text
