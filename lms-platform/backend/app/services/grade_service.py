import uuid

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.assignment import Assignment
from app.models.course import Course
from app.models.grade import Grade
from app.models.lesson import Lesson
from app.models.submission import Submission
from app.models.user import User


async def list_grades_for_teacher(
    db: AsyncSession,
    *,
    teacher_id: uuid.UUID | None,
    course_id: uuid.UUID | None,
    limit: int,
    offset: int,
) -> list[dict]:
    # Отдаем денормализованный набор для таблицы оценок в UI/API.
    stmt = (
        select(
            Grade.id.label("grade_id"),
            Grade.score,
            Grade.feedback,
            Grade.graded_at,
            Submission.id.label("submission_id"),
            Submission.assignment_id,
            Assignment.title.label("assignment_title"),
            Submission.student_id,
            User.email.label("student_email"),
            Course.id.label("course_id"),
            Course.title.label("course_title"),
        )
        .join(Submission, Submission.id == Grade.submission_id)
        .join(Assignment, Assignment.id == Submission.assignment_id)
        .join(Lesson, Lesson.id == Assignment.lesson_id)
        .join(Course, Course.id == Lesson.course_id)
        .join(User, User.id == Submission.student_id)
        .where(
            Grade.deleted_at.is_(None),
            Submission.deleted_at.is_(None),
            Assignment.deleted_at.is_(None),
            Lesson.deleted_at.is_(None),
            Course.deleted_at.is_(None),
            User.deleted_at.is_(None),
        )
    )
    if teacher_id is not None:
        stmt = stmt.where(Course.teacher_id == teacher_id)
    if course_id is not None:
        stmt = stmt.where(Course.id == course_id)
    stmt = stmt.order_by(Grade.graded_at.desc()).limit(limit).offset(offset)
    result = await db.execute(stmt)
    rows = result.mappings().all()
    return [dict(row) for row in rows]
