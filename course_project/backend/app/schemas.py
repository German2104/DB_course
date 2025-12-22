from datetime import datetime, date
from pydantic import BaseModel, EmailStr, Field


class Token(BaseModel):
    access_token: str
    token_type: str = 'bearer'


class UserBase(BaseModel):
    email: EmailStr
    full_name: str
    role: str
    is_active: bool = True


class UserCreate(UserBase):
    password: str = Field(min_length=6)


class UserOut(UserBase):
    id: int
    created_at: datetime

    class Config:
        from_attributes = True


class CourseBase(BaseModel):
    code: str
    title: str
    description: str
    start_date: date
    end_date: date
    is_active: bool = True


class CourseCreate(CourseBase):
    created_by: int


class CourseOut(CourseBase):
    id: int

    class Config:
        from_attributes = True


class AssignmentBase(BaseModel):
    course_id: int
    title: str
    description: str
    max_score: float
    due_at: datetime
    allow_late: bool = True
    position: int


class AssignmentCreate(AssignmentBase):
    pass


class AssignmentOut(AssignmentBase):
    id: int

    class Config:
        from_attributes = True


class SubmissionBase(BaseModel):
    assignment_id: int
    student_id: int
    attempt_no: int
    submitted_at: datetime
    status: str
    is_late: bool
    content_text: str


class SubmissionCreate(SubmissionBase):
    pass


class SubmissionOut(SubmissionBase):
    id: int

    class Config:
        from_attributes = True


class GradeBase(BaseModel):
    submission_id: int
    reviewer_id: int
    score: float
    feedback: str
    status: str
    graded_at: datetime | None = None


class GradeCreate(GradeBase):
    pass


class GradeOut(GradeBase):
    id: int

    class Config:
        from_attributes = True


class NotificationOut(BaseModel):
    id: int
    user_id: int
    type: str
    message: str
    is_read: bool
    created_at: datetime

    class Config:
        from_attributes = True


class BatchImportResult(BaseModel):
    imported: int
    errors: int
    request_id: str
    details: list[str]
