from pydantic import BaseModel
from uuid import UUID
from datetime import datetime
from typing import Optional

class SystemAlertCreate(BaseModel):
    type: str
    title: str
    message: str
    severity: str
    entity_type: Optional[str] = None
    entity_id: Optional[UUID] = None

class SystemAlertUpdate(BaseModel):
    is_resolved: Optional[bool] = None

class SystemAlertResponse(BaseModel):
    id: UUID
    type: str
    title: str
    message: str
    severity: str
    entity_type: Optional[str]
    entity_id: Optional[UUID]
    is_resolved: bool
    resolved_by: Optional[UUID]
    resolved_at: Optional[datetime]
    created_at: datetime

    class Config:
        from_attributes = True