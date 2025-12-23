import os

import httpx


API_BASE = os.getenv("API_BASE", "http://localhost:8000")


def test_courses_endpoint():
    response = httpx.get(f"{API_BASE}/api/courses", timeout=10)
    assert response.status_code == 200
