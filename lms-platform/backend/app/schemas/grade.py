import uuid
from datetime import datetime

from pydantic import BaseModel


class GradeOut(BaseModel):
    grade_id: uuid.UUID
    score: int
    feedback: str | None
    graded_at: datetime
    submission_id: uuid.UUID
    assignment_id: uuid.UUID
    assignment_title: str
    student_id: uuid.UUID
    student_email: str
    course_id: uuid.UUID
    course_title: str
