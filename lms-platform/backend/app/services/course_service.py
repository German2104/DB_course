import uuid
from datetime import UTC, datetime

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.course import Course
from app.models.enrollment import Enrollment
from app.schemas.course import CourseCreate, CourseUpdate


async def list_courses(
    db: AsyncSession,
    *,
    published_only: bool,
    teacher_id: uuid.UUID | None,
    limit: int,
    offset: int,
) -> list[Course]:
    # Базовый листинг курсов для публичного каталога.
    stmt = select(Course).where(Course.deleted_at.is_(None))
    if published_only:
        stmt = stmt.where(Course.is_published.is_(True))
    if teacher_id is not None:
        stmt = stmt.where(Course.teacher_id == teacher_id)
    stmt = stmt.order_by(Course.created_at.desc()).limit(limit).offset(offset)
    result = await db.execute(stmt)
    return list(result.scalars().all())


async def get_course_by_id(db: AsyncSession, course_id: uuid.UUID) -> Course | None:
    stmt = select(Course).where(Course.id == course_id, Course.deleted_at.is_(None))
    result = await db.execute(stmt)
    return result.scalar_one_or_none()


async def create_course(
    db: AsyncSession,
    *,
    payload: CourseCreate,
    teacher_id: uuid.UUID,
) -> Course:
    # Явно проставляем audit-времена, т.к. ORM использует полный INSERT.
    now = datetime.now(UTC)
    course = Course(
        title=payload.title.strip(),
        description=payload.description,
        teacher_id=teacher_id,
        is_published=payload.is_published,
        created_at=now,
        updated_at=now,
    )
    db.add(course)
    await db.commit()
    await db.refresh(course)
    return course


async def update_course(
    db: AsyncSession,
    *,
    course: Course,
    payload: CourseUpdate,
) -> Course:
    if payload.title is not None:
        course.title = payload.title.strip()
    if payload.description is not None:
        course.description = payload.description
    if payload.is_published is not None:
        course.is_published = payload.is_published

    await db.commit()
    await db.refresh(course)
    return course


async def list_my_courses(
    db: AsyncSession,
    *,
    user_id: uuid.UUID,
    role: str,
    limit: int,
    offset: int,
) -> list[Course]:
    # Разные правила выборки в зависимости от роли пользователя.
    if role == "student":
        stmt = (
            select(Course)
            .join(Enrollment, Enrollment.course_id == Course.id)
            .where(
                Course.deleted_at.is_(None),
                Enrollment.deleted_at.is_(None),
                Enrollment.user_id == user_id,
            )
        )
    elif role == "teacher":
        stmt = select(Course).where(Course.deleted_at.is_(None), Course.teacher_id == user_id)
    else:
        stmt = select(Course).where(Course.deleted_at.is_(None))

    stmt = stmt.order_by(Course.created_at.desc()).limit(limit).offset(offset)
    result = await db.execute(stmt)
    return list(result.scalars().all())


async def publish_course(db: AsyncSession, course: Course) -> Course:
    # Быстрая операция публикации курса.
    course.is_published = True
    await db.commit()
    await db.refresh(course)
    return course
