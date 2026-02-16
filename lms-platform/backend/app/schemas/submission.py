import uuid
from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field


class SubmissionCreate(BaseModel):
    assignment_id: uuid.UUID
    content: str = Field(min_length=1)


class SubmissionOut(BaseModel):
    id: uuid.UUID
    assignment_id: uuid.UUID
    student_id: uuid.UUID
    content: str
    submitted_at: datetime

    model_config = ConfigDict(from_attributes=True)
