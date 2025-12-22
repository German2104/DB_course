from types import SimpleNamespace

from fastapi.testclient import TestClient

from app import crud
from app.main import app


def test_login_returns_token(monkeypatch):
    def fake_get_user_by_email(_session, _email):
        return SimpleNamespace(email="student@example.com", role="student", password_hash="hashed")

    def fake_verify_password(_password, _hashed):
        return True

    monkeypatch.setattr(crud, "get_user_by_email", fake_get_user_by_email)
    monkeypatch.setattr(crud, "verify_password", fake_verify_password)

    client = TestClient(app)
    response = client.post(
        "/api/auth/login",
        data={"username": "student@example.com", "password": "secret"},
        headers={"Content-Type": "application/x-www-form-urlencoded"},
    )

    assert response.status_code == 200
    payload = response.json()
    assert payload["access_token"]
    assert payload["token_type"] == "bearer"
