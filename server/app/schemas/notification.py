from pydantic import BaseModel
from uuid import UUID
from datetime import datetime
from typing import Optional

class NotificationCreate(BaseModel):
    user_id: UUID
    type: str
    title: str
    message: str
    priority: Optional[str] = 'medium'
    action_url: Optional[str] = None
    expires_at: Optional[datetime] = None

class NotificationUpdate(BaseModel):
    is_read: Optional[bool] = None

class NotificationResponse(BaseModel):
    id: UUID
    user_id: UUID
    type: str
    title: str
    message: str
    is_read: bool
    priority: str
    action_url: Optional[str]
    expires_at: Optional[datetime]
    created_at: datetime

    class Config:
        from_attributes = True