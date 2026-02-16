from collections.abc import AsyncGenerator
from uuid import UUID

from fastapi import Cookie, Depends, Header, HTTPException, status
from pydantic import BaseModel
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.db import AsyncSessionLocal
from app.services import user_service


async def get_db() -> AsyncGenerator[AsyncSession, None]:
    # Единая точка выдачи DB-сессии для всех роутов.
    async with AsyncSessionLocal() as session:
        yield session


class CurrentUser(BaseModel):
    id: UUID
    email: str
    full_name: str
    role_id: int
    role: str
    is_active: bool


async def get_current_user(
    x_user_id: str | None = Header(default=None, alias="X-User-Id"),
    auth_token: str | None = Cookie(default=None, alias="auth_token"),
    db: AsyncSession = Depends(get_db),
) -> CurrentUser:
    # Приоритет токена: явный header -> cookie после /auth/login.
    token = x_user_id or auth_token
    if not token:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing authentication token",
        )
    try:
        user_id = UUID(token)
    except ValueError as exc:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token format",
        ) from exc

    user = await user_service.get_user_by_id(db, user_id)
    if user is None or not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid credentials",
        )
    role_name = await user_service.get_role_name_by_id(db, user.role_id)
    if role_name is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Role not found",
        )
    return CurrentUser(
        id=user.id,
        email=user.email,
        full_name=user.full_name,
        role_id=user.role_id,
        role=role_name,
        is_active=user.is_active,
    )


def require_roles(*allowed_roles: str):
    # Универсальный RBAC-checker для роутов.
    async def _checker(current_user: CurrentUser = Depends(get_current_user)) -> CurrentUser:
        if current_user.role not in allowed_roles:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Insufficient permissions",
            )
        return current_user

    return _checker
