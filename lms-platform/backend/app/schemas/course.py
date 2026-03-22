import uuid
from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field


class CourseOut(BaseModel):
    id: uuid.UUID
    title: str
    description: str | None
    teacher_id: uuid.UUID
    is_published: bool
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)


class CourseCreate(BaseModel):
    title: str = Field(min_length=1, max_length=255)
    description: str | None = None
    is_published: bool = False
    teacher_id: uuid.UUID | None = None


class CourseUpdate(BaseModel):
    title: str | None = Field(default=None, min_length=1, max_length=255)
    description: str | None = None
    is_published: bool | None = None
