from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import CurrentUser, get_db, require_roles
from app.schemas.submission import SubmissionCreate, SubmissionOut
from app.services import submission_service

router = APIRouter(prefix="/submissions", tags=["Submissions"])


@router.post("/", response_model=SubmissionOut, status_code=status.HTTP_201_CREATED)
async def create_submission(
    payload: SubmissionCreate,
    db: AsyncSession = Depends(get_db),
    current_user: CurrentUser = Depends(require_roles("student")),
) -> SubmissionOut:
    # Student может отправлять решения только в рамках своих курсов.
    try:
        return await submission_service.create_submission_for_student(
            db,
            student_id=current_user.id,
            payload=payload,
        )
    except PermissionError as exc:
        raise HTTPException(status_code=403, detail=str(exc)) from exc
    except ValueError as exc:
        raise HTTPException(status_code=409, detail=str(exc)) from exc
