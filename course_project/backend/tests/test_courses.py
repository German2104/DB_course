from types import SimpleNamespace

from fastapi.testclient import TestClient

from app import crud
from app.main import app


def test_list_courses_returns_payload(monkeypatch):
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

    monkeypatch.setattr(crud, "list_courses", fake_list_courses)

    client = TestClient(app)
    response = client.get("/api/courses")

    assert response.status_code == 200
    payload = response.json()
    assert payload[0]["code"] == "DB-01"
