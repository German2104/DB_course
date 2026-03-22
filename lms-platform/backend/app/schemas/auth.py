from uuid import UUID

from pydantic import BaseModel


class LoginRequest(BaseModel):
    email: str


class LoginResponse(BaseModel):
    token: str
    user_id: UUID
    role: str
    full_name: str
    email: str


class MeResponse(BaseModel):
    user_id: UUID
    role: str
    full_name: str
    email: str


class DemoAccountsResponse(BaseModel):
    teacher_email: str
    student_email: str
