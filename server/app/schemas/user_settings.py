from pydantic import BaseModel
from typing import Optional
import uuid
from datetime import datetime

class UserSettingBase(BaseModel):
    language: Optional[str] = "es"
    theme: Optional[str] = "light"
    timezone: Optional[str] = "America/Bogota"
    notifications_enabled: Optional[bool] = True
    email_notifications: Optional[bool] = True
    push_notifications: Optional[bool] = True
    auto_save: Optional[bool] = True

class UserSettingCreate(UserSettingBase):
    user_id: uuid.UUID

class UserSettingUpdate(UserSettingBase):
    pass

class UserSettingResponse(UserSettingBase):
    id: uuid.UUID
    user_id: uuid.UUID
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True
