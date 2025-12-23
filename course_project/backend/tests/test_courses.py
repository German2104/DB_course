from pathlib import Path
import sys
from types import SimpleNamespace
from unittest import TestCase
from unittest.mock import patch

BACKEND_DIR = Path(__file__).resolve().parents[1]
if str(BACKEND_DIR) not in sys.path:
    sys.path.insert(0, str(BACKEND_DIR))

from fastapi.testclient import TestClient

from app.main import app


class TestCourses(TestCase):
    def test_list_courses_returns_payload(self):
        def fake_list_courses(_session):
            return [
                SimpleNamespace(
                    id=1,
                    code="DB-01",
                    title="Базы данных",
                    description="Описание",
                    start_date="2024-01-01",
                    end_date="2024-06-01",
                    is_active=True,
                )
            ]

        with patch("app.crud.list_courses", side_effect=fake_list_courses):
            client = TestClient(app)
            response = client.get("/api/courses")

        self.assertEqual(response.status_code, 200)
        payload = response.json()
        self.assertEqual(payload[0]["code"], "DB-01")
