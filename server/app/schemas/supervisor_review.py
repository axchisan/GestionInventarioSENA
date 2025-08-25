from pydantic import BaseModel
from uuid import UUID
from datetime import datetime
from typing import Optional

class SupervisorReviewCreate(BaseModel):
    check_id: UUID
    status: str
    comments: Optional[str]

class SupervisorReviewResponse(BaseModel):
    id: UUID
    check_id: UUID
    supervisor_id: UUID
    status: str
    comments: Optional[str]
    reviewed_at: datetime
    created_at: datetime

    class Config:
        from_attributes = True