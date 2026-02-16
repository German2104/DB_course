import uuid

from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import CurrentUser, get_db, require_roles
from app.schemas.assignment import AssignmentOut
from app.services import assignment_service

router = APIRouter(prefix="/assignments", tags=["Assignments"])


@router.get("/", response_model=list[AssignmentOut])
async def list_assignments(
    course_id: uuid.UUID | None = Query(default=None),
    limit: int = Query(default=50, ge=1, le=200),
    offset: int = Query(default=0, ge=0),
    db: AsyncSession = Depends(get_db),
) -> list[AssignmentOut]:
    # Общий каталог заданий, при необходимости фильтруется по course_id.
    return await assignment_service.list_assignments(
        db,
        course_id=course_id,
        limit=limit,
        offset=offset,
    )


@router.get("/my", response_model=list[AssignmentOut])
async def list_my_assignments(
    limit: int = Query(default=50, ge=1, le=200),
    offset: int = Query(default=0, ge=0),
    db: AsyncSession = Depends(get_db),
    current_user: CurrentUser = Depends(require_roles("student")),
) -> list[AssignmentOut]:
    # Задания только из курсов, на которые записан текущий студент.
    return await assignment_service.list_assignments_for_student(
        db,
        student_id=current_user.id,
        limit=limit,
        offset=offset,
    )
