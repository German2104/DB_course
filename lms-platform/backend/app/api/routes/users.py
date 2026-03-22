import uuid
import logging

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_db
from app.schemas.user import UserOut
from app.services import user_service

router = APIRouter(prefix="/users", tags=["Users"])
logger = logging.getLogger(__name__)


@router.get("/", response_model=list[UserOut])
async def list_users(
    limit: int = Query(default=50, ge=1, le=200),
    offset: int = Query(default=0, ge=0),
    db: AsyncSession = Depends(get_db),
) -> list[UserOut]:
    # Админский/сервисный листинг пользователей с пагинацией.
    users = await user_service.list_users(db, limit=limit, offset=offset)
    logger.info("users.list limit=%s offset=%s count=%s", limit, offset, len(users))
    return users


@router.get("/{user_id}", response_model=UserOut)
async def get_user(user_id: uuid.UUID, db: AsyncSession = Depends(get_db)) -> UserOut:
    # Точечный запрос пользователя по UUID.
    user = await user_service.get_user_by_id(db, user_id)
    if user is None:
        logger.warning("users.get.not_found user_id=%s", user_id)
        raise HTTPException(status_code=404, detail="User not found")
    logger.info("users.get.ok user_id=%s", user_id)
    return user
