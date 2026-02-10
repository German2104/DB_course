from __future__ import annotations

from pydantic import BaseModel, EmailStr, Field


class LoginRequest(BaseModel):
    email: EmailStr
    password: str


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"


class CourseOut(BaseModel):
    id: int
    title: str
    teacher_id: int


class SubmissionCreate(BaseModel):
    content: str = Field(min_length=1, max_length=5000)


class SubmissionOut(BaseModel):
    id: int
    assignment_id: int
    student_id: int
    content: str


class GradeCreate(BaseModel):
    score: int = Field(ge=0, le=100)
    feedback: str = Field(min_length=1, max_length=1000)


class GradeOut(BaseModel):
    id: int
    submission_id: int
    teacher_id: int
    score: int
    feedback: str
