import uuid
import logging

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import CurrentUser, get_current_user, get_db
from app.schemas.enrollment import EnrollmentOut
from app.services import enrollment_service

router = APIRouter(prefix="/enrollments", tags=["Enrollments"])
logger = logging.getLogger(__name__)


@router.get("/", response_model=list[EnrollmentOut])
async def list_enrollments(
    user_id: uuid.UUID | None = Query(default=None),
    course_id: uuid.UUID | None = Query(default=None),
    limit: int = Query(default=100, ge=1, le=300),
    offset: int = Query(default=0, ge=0),
    db: AsyncSession = Depends(get_db),
    current_user: CurrentUser = Depends(get_current_user),
) -> list[EnrollmentOut]:
    # Ограничение для student: только собственные записи на курсы.
    if current_user.role == "student":
        if user_id is not None and user_id != current_user.id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Student can access only own enrollments",
            )
        user_id = current_user.id

    enrollments = await enrollment_service.list_enrollments(
        db,
        user_id=user_id,
        course_id=course_id,
        limit=limit,
        offset=offset,
    )
    logger.info(
        "enrollments.list user_id=%s course_id=%s limit=%s offset=%s count=%s",
        user_id,
        course_id,
        limit,
        offset,
        len(enrollments),
    )
    return enrollments
