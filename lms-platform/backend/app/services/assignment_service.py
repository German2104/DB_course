import uuid

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.assignment import Assignment
from app.models.course import Course
from app.models.enrollment import Enrollment
from app.models.lesson import Lesson


async def list_assignments(
    db: AsyncSession,
    *,
    course_id: uuid.UUID | None,
    limit: int,
    offset: int,
) -> list[Assignment]:
    # Каталог заданий: все активные задания, опционально по курсу.
    stmt = (
        select(Assignment)
        .join(Lesson, Lesson.id == Assignment.lesson_id)
        .join(Course, Course.id == Lesson.course_id)
        .where(
            Assignment.deleted_at.is_(None),
            Lesson.deleted_at.is_(None),
            Course.deleted_at.is_(None),
        )
    )
    if course_id is not None:
        stmt = stmt.where(Course.id == course_id)
    stmt = stmt.order_by(Assignment.created_at.desc()).limit(limit).offset(offset)
    result = await db.execute(stmt)
    return list(result.scalars().all())


async def list_assignments_for_student(
    db: AsyncSession,
    *,
    student_id: uuid.UUID,
    limit: int,
    offset: int,
) -> list[Assignment]:
    # Только задания по курсам, где студент реально записан.
    stmt = (
        select(Assignment)
        .join(Lesson, Lesson.id == Assignment.lesson_id)
        .join(Course, Course.id == Lesson.course_id)
        .join(
            Enrollment,
            (Enrollment.course_id == Course.id) & (Enrollment.user_id == student_id),
        )
        .where(
            Assignment.deleted_at.is_(None),
            Lesson.deleted_at.is_(None),
            Course.deleted_at.is_(None),
            Enrollment.deleted_at.is_(None),
        )
        .order_by(Assignment.created_at.desc())
        .limit(limit)
        .offset(offset)
    )
    result = await db.execute(stmt)
    return list(result.scalars().all())
