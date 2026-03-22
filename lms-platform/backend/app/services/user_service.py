import uuid

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.role import Role
from app.models.user import User


async def list_users(
    db: AsyncSession,
    *,
    limit: int,
    offset: int,
) -> list[User]:
    # Листинг пользователей без soft-deleted записей.
    stmt = (
        select(User)
        .where(User.deleted_at.is_(None))
        .order_by(User.created_at.desc())
        .limit(limit)
        .offset(offset)
    )
    result = await db.execute(stmt)
    return list(result.scalars().all())


async def get_user_by_id(db: AsyncSession, user_id: uuid.UUID) -> User | None:
    stmt = select(User).where(User.id == user_id, User.deleted_at.is_(None))
    result = await db.execute(stmt)
    return result.scalar_one_or_none()


async def get_user_by_email(db: AsyncSession, email: str) -> User | None:
    stmt = select(User).where(User.email == email, User.deleted_at.is_(None))
    result = await db.execute(stmt)
    return result.scalar_one_or_none()


async def get_role_name_by_id(db: AsyncSession, role_id: int) -> str | None:
    stmt = select(Role.name).where(Role.id == role_id)
    result = await db.execute(stmt)
    return result.scalar_one_or_none()
