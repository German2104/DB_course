import uuid
from datetime import UTC, datetime

from sqlalchemy import exists, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.assignment import Assignment
from app.models.enrollment import Enrollment
from app.models.lesson import Lesson
from app.models.submission import Submission
from app.schemas.submission import SubmissionCreate


async def create_submission_for_student(
    db: AsyncSession,
    *,
    student_id: uuid.UUID,
    payload: SubmissionCreate,
) -> Submission:
    # Студент может отправлять решения только по курсам своей записи.
    enrollment_exists = exists(
        select(1)
        .select_from(Enrollment)
        .join(Lesson, Lesson.course_id == Enrollment.course_id)
        .join(Assignment, Assignment.lesson_id == Lesson.id)
        .where(
            Enrollment.user_id == student_id,
            Enrollment.deleted_at.is_(None),
            Lesson.deleted_at.is_(None),
            Assignment.deleted_at.is_(None),
            Assignment.id == payload.assignment_id,
        )
    )
    allowed_stmt = select(enrollment_exists)
    allowed_result = await db.execute(allowed_stmt)
    is_allowed = bool(allowed_result.scalar())
    if not is_allowed:
        raise PermissionError("Student is not enrolled for this assignment")

    now = datetime.now(UTC)
    submission = Submission(
        assignment_id=payload.assignment_id,
        student_id=student_id,
        content=payload.content.strip(),
        submitted_at=now,
        created_at=now,
        updated_at=now,
    )
    db.add(submission)
    try:
        await db.commit()
    except IntegrityError as exc:
        await db.rollback()
        # Если ответ уже существует, считаем это переотправкой и обновляем запись.
        existing_stmt = select(Submission).where(
            Submission.assignment_id == payload.assignment_id,
            Submission.student_id == student_id,
            Submission.deleted_at.is_(None),
        )
        existing_result = await db.execute(existing_stmt)
        existing = existing_result.scalar_one_or_none()
        if existing is None:
            raise ValueError("Failed to submit solution") from exc
        existing.content = payload.content.strip()
        existing.submitted_at = now
        existing.updated_at = now
        db.add(existing)
        await db.commit()
        await db.refresh(existing)
        return existing
    await db.refresh(submission)
    return submission
