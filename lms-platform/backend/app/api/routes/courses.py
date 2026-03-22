import uuid
import logging

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import CurrentUser, get_db, require_roles
from app.schemas.course import CourseCreate, CourseOut, CourseUpdate
from app.services import course_service

router = APIRouter(prefix="/courses", tags=["Courses"])
logger = logging.getLogger(__name__)


@router.get("/", response_model=list[CourseOut])
async def list_courses(
    published_only: bool = Query(default=False),
    teacher_id: uuid.UUID | None = Query(default=None),
    limit: int = Query(default=50, ge=1, le=200),
    offset: int = Query(default=0, ge=0),
    db: AsyncSession = Depends(get_db),
) -> list[CourseOut]:
    # Публичный список курсов с фильтрами и пагинацией.
    courses = await course_service.list_courses(
        db,
        published_only=published_only,
        teacher_id=teacher_id,
        limit=limit,
        offset=offset,
    )
    logger.info(
        "courses.list published_only=%s teacher_id=%s limit=%s offset=%s count=%s",
        published_only,
        teacher_id,
        limit,
        offset,
        len(courses),
    )
    return courses


@router.get("/my", response_model=list[CourseOut])
async def list_my_courses(
    limit: int = Query(default=50, ge=1, le=200),
    offset: int = Query(default=0, ge=0),
    db: AsyncSession = Depends(get_db),
    current_user: CurrentUser = Depends(require_roles("student", "teacher", "admin")),
) -> list[CourseOut]:
    # Возвращает курсы относительно роли текущего пользователя.
    courses = await course_service.list_my_courses(
        db,
        user_id=current_user.id,
        role=current_user.role,
        limit=limit,
        offset=offset,
    )
    return courses


@router.post(
    "/",
    response_model=CourseOut,
    status_code=status.HTTP_201_CREATED,
)
async def create_course(
    payload: CourseCreate,
    db: AsyncSession = Depends(get_db),
    current_user: CurrentUser = Depends(require_roles("teacher", "admin")),
) -> CourseOut:
    # Teacher всегда создает курс на себя; admin может указать teacher_id явно.
    teacher_id = payload.teacher_id
    if current_user.role == "teacher":
        if teacher_id is not None and teacher_id != current_user.id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Teacher can create courses only for self",
            )
        teacher_id = current_user.id
    elif teacher_id is None:
        teacher_id = current_user.id

    course = await course_service.create_course(db, payload=payload, teacher_id=teacher_id)
    logger.info(
        "courses.create user_id=%s role=%s course_id=%s",
        current_user.id,
        current_user.role,
        course.id,
    )
    return course


@router.patch("/{course_id}", response_model=CourseOut)
async def update_course(
    course_id: uuid.UUID,
    payload: CourseUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: CurrentUser = Depends(require_roles("teacher", "admin")),
) -> CourseOut:
    # Teacher может редактировать только собственные курсы.
    course = await course_service.get_course_by_id(db, course_id)
    if course is None:
        raise HTTPException(status_code=404, detail="Course not found")

    if current_user.role == "teacher" and course.teacher_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Teacher can update only own courses",
        )

    updated = await course_service.update_course(db, course=course, payload=payload)
    logger.info(
        "courses.update user_id=%s role=%s course_id=%s",
        current_user.id,
        current_user.role,
        updated.id,
    )
    return updated


@router.post("/{course_id}/publish", response_model=CourseOut)
async def publish_course(
    course_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: CurrentUser = Depends(require_roles("teacher", "admin")),
) -> CourseOut:
    # Быстрое переключение курса в опубликованное состояние.
    course = await course_service.get_course_by_id(db, course_id)
    if course is None:
        raise HTTPException(status_code=404, detail="Course not found")
    if current_user.role == "teacher" and course.teacher_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Teacher can publish only own courses",
        )
    return await course_service.publish_course(db, course)
