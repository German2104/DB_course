from fastapi.testclient import TestClient

from app.main import create_app


def auth_header(token: str) -> dict[str, str]:
    return {"Authorization": f"Bearer {token}"}


def test_login_and_student_submission_flow():
    client = TestClient(create_app())

    login = client.post("/auth/login", json={"email": "student1@lms.local", "password": "student123"})
    assert login.status_code == 200
    student_token = login.json()["access_token"]

    courses = client.get("/courses", headers=auth_header(student_token))
    assert courses.status_code == 200
    assert len(courses.json()) >= 1

    submit = client.post(
        "/assignments/1/submissions",
        headers=auth_header(student_token),
        json={"content": "My homework answer"},
    )
    assert submit.status_code == 201
    payload = submit.json()
    assert payload["assignment_id"] == 1
    assert payload["student_id"] == 3


def test_teacher_can_grade_but_student_cannot():
    client = TestClient(create_app())

    student_login = client.post("/auth/login", json={"email": "student1@lms.local", "password": "student123"})
    teacher_login = client.post("/auth/login", json={"email": "teacher1@lms.local", "password": "teacher123"})
    student_token = student_login.json()["access_token"]
    teacher_token = teacher_login.json()["access_token"]

    submit = client.post(
        "/assignments/1/submissions",
        headers=auth_header(student_token),
        json={"content": "My second homework answer"},
    )
    submission_id = submit.json()["id"]

    student_grade = client.post(
        f"/submissions/{submission_id}/grade",
        headers=auth_header(student_token),
        json={"score": 85, "feedback": "Good"},
    )
    assert student_grade.status_code == 403

    teacher_grade = client.post(
        f"/submissions/{submission_id}/grade",
        headers=auth_header(teacher_token),
        json={"score": 92, "feedback": "Well structured"},
    )
    assert teacher_grade.status_code == 200
    assert teacher_grade.json()["score"] == 92


def test_admin_can_view_all_grades():
    client = TestClient(create_app())

    admin_login = client.post("/auth/login", json={"email": "admin@lms.local", "password": "admin123"})
    admin_token = admin_login.json()["access_token"]

    response = client.get("/grades", headers=auth_header(admin_token))
    assert response.status_code == 200
    assert isinstance(response.json(), list)
