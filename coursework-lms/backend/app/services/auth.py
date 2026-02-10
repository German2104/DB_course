from __future__ import annotations

from fastapi import HTTPException, status

from app.core.security import create_token
from app.repositories.in_memory import repository


def login(email: str, password: str) -> str:
    user = repository.find_user_by_email(email)
    if not user or user.password != password:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid credentials")
    return create_token({"sub": user.id, "role": user.role, "email": user.email})
