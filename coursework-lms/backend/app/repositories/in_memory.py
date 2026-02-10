from __future__ import annotations

from dataclasses import dataclass


@dataclass
class User:
    id: int
    email: str
    password: str
    role: str


class InMemoryRepository:
    def __init__(self) -> None:
        self.users = {
            1: User(1, "admin@lms.local", "admin123", "admin"),
            2: User(2, "teacher1@lms.local", "teacher123", "teacher"),
            3: User(3, "student1@lms.local", "student123", "student"),
        }
        self.courses = {1: {"id": 1, "title": "Database Systems", "teacher_id": 2}}
        self.assignments = {1: {"id": 1, "course_id": 1, "title": "Normalization Task"}}
        self.submissions: dict[int, dict] = {}
        self.grades: dict[int, dict] = {}
        self._submission_seq = 1
        self._grade_seq = 1

    def find_user_by_email(self, email: str) -> User | None:
        for user in self.users.values():
            if user.email == email:
                return user
        return None

    def list_courses(self) -> list[dict]:
        return list(self.courses.values())

    def create_submission(self, assignment_id: int, student_id: int, content: str) -> dict:
        payload = {
            "id": self._submission_seq,
            "assignment_id": assignment_id,
            "student_id": student_id,
            "content": content,
        }
        self.submissions[self._submission_seq] = payload
        self._submission_seq += 1
        return payload

    def create_or_update_grade(self, submission_id: int, teacher_id: int, score: int, feedback: str) -> dict:
        for grade in self.grades.values():
            if grade["submission_id"] == submission_id:
                grade.update({"teacher_id": teacher_id, "score": score, "feedback": feedback})
                return grade
        payload = {
            "id": self._grade_seq,
            "submission_id": submission_id,
            "teacher_id": teacher_id,
            "score": score,
            "feedback": feedback,
        }
        self.grades[self._grade_seq] = payload
        self._grade_seq += 1
        return payload

    def list_grades(self) -> list[dict]:
        return list(self.grades.values())

    def get_submission(self, submission_id: int) -> dict | None:
        return self.submissions.get(submission_id)


repository = InMemoryRepository()
