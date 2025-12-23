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


class TestAuth(TestCase):
    def test_login_returns_token(self):
        def fake_get_user_by_email(_session, _email):
            return SimpleNamespace(email="student@example.com", role="student", password_hash="hashed")

        def fake_verify_password(_password, _hashed):
            return True

        with patch("app.crud.get_user_by_email", side_effect=fake_get_user_by_email), patch(
            "app.crud.verify_password", side_effect=fake_verify_password
        ):
            client = TestClient(app)
            response = client.post(
                "/api/auth/login",
                data={"username": "student@example.com", "password": "secret"},
                headers={"Content-Type": "application/x-www-form-urlencoded"},
            )

        self.assertEqual(response.status_code, 200)
        payload = response.json()
        self.assertTrue(payload["access_token"])
        self.assertEqual(payload["token_type"], "bearer")
