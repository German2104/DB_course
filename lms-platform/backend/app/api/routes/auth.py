import logging

from fastapi import APIRouter, Depends, HTTPException, Response, status
from fastapi.responses import JSONResponse
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import CurrentUser, get_current_user, get_db
from app.schemas.auth import DemoAccountsResponse, LoginRequest, LoginResponse, MeResponse
from app.services import user_service

router = APIRouter(prefix="/auth", tags=["Auth"])
logger = logging.getLogger(__name__)

# Демо-аккаунты для быстрого старта проверки ролей.
DEMO_TEACHER_EMAIL = "ivan.petrov.teacher@lms.local"
DEMO_STUDENT_EMAIL = "nikita.kuznetsov.student@lms.local"


@router.get("/demo-accounts", response_model=DemoAccountsResponse)
async def demo_accounts() -> DemoAccountsResponse:
    return DemoAccountsResponse(
        teacher_email=DEMO_TEACHER_EMAIL,
        student_email=DEMO_STUDENT_EMAIL,
    )


@router.post("/login", response_model=LoginResponse)
async def login(
    payload: LoginRequest,
    db: AsyncSession = Depends(get_db),
) -> JSONResponse:
    # MVP-логин: аутентификация только по email из seed-данных.
    user = await user_service.get_user_by_email(db, payload.email)
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
    logger.info("auth.login success email=%s user_id=%s role=%s", user.email, user.id, role_name)
    body = LoginResponse(
        token=str(user.id),
        user_id=user.id,
        role=role_name,
        full_name=user.full_name,
        email=user.email,
    )
    response = JSONResponse(content=body.model_dump(mode="json"))
    # Сохраняем токен в cookie, чтобы не передавать header вручную.
    response.set_cookie(
        key="auth_token",
        value=str(user.id),
        httponly=True,
        samesite="lax",
        secure=False,
        max_age=60 * 60 * 8,
    )
    return response


@router.post("/logout", status_code=status.HTTP_204_NO_CONTENT)
async def logout(response: Response) -> None:
    # Выход: удаляем auth_token cookie.
    response.delete_cookie(key="auth_token")


@router.get("/me", response_model=MeResponse)
async def me(current_user: CurrentUser = Depends(get_current_user)) -> MeResponse:
    return MeResponse(
        user_id=current_user.id,
        role=current_user.role,
        email=current_user.email,
        full_name=current_user.full_name,
    )
