import os

import httpx
import pytest


API_BASE = os.getenv("API_BASE", "http://localhost:8000")


def test_courses_endpoint():
    try:
        response = httpx.get(f"{API_BASE}/api/courses", timeout=10)
    except httpx.HTTPError as exc:  # pragma: no cover - environment dependent
        pytest.skip(f"API not available: {exc}")
    assert response.status_code == 200
