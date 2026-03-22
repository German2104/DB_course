import uuid
from datetime import datetime

from pydantic import BaseModel, ConfigDict


class EnrollmentOut(BaseModel):
    id: uuid.UUID
    user_id: uuid.UUID
    course_id: uuid.UUID
    enrolled_at: datetime

    model_config = ConfigDict(from_attributes=True)
