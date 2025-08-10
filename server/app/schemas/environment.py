from pydantic import BaseModel
from uuid import UUID
from datetime import datetime
from typing import Optional

class EnvironmentResponse(BaseModel):
    id: UUID
    center_id: UUID
    name: str
    location: str
    capacity: int
    qr_code: str
    description: Optional[str]
    is_active: bool
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True