import uuid
from datetime import datetime

from pydantic import BaseModel, ConfigDict


class AssignmentOut(BaseModel):
    id: uuid.UUID
    lesson_id: uuid.UUID
    title: str
    description: str | None
    max_score: int
    due_date: datetime | None

    model_config = ConfigDict(from_attributes=True)
