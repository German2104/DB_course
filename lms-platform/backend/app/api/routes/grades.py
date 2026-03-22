import uuid

from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import CurrentUser, get_db, require_roles
from app.schemas.grade import GradeOut
from app.services import grade_service

router = APIRouter(prefix="/grades", tags=["Grades"])


@router.get("/", response_model=list[GradeOut])
async def list_teacher_grades(
    course_id: uuid.UUID | None = Query(default=None),
    limit: int = Query(default=50, ge=1, le=200),
    offset: int = Query(default=0, ge=0),
    db: AsyncSession = Depends(get_db),
    current_user: CurrentUser = Depends(require_roles("teacher", "admin")),
) -> list[GradeOut]:
    # Teacher видит оценки только своих курсов; admin - всех.
    teacher_id = None if current_user.role == "admin" else current_user.id
    return await grade_service.list_grades_for_teacher(
        db,
        teacher_id=teacher_id,
        course_id=course_id,
        limit=limit,
        offset=offset,
    )
