import uuid

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.enrollment import Enrollment


async def list_enrollments(
    db: AsyncSession,
    *,
    user_id: uuid.UUID | None,
    course_id: uuid.UUID | None,
    limit: int,
    offset: int,
) -> list[Enrollment]:
    # Универсальный листинг записей на курсы с фильтрами.
    stmt = select(Enrollment).where(Enrollment.deleted_at.is_(None))
    if user_id is not None:
        stmt = stmt.where(Enrollment.user_id == user_id)
    if course_id is not None:
        stmt = stmt.where(Enrollment.course_id == course_id)
    stmt = stmt.order_by(Enrollment.enrolled_at.desc()).limit(limit).offset(offset)
    result = await db.execute(stmt)
    return list(result.scalars().all())
