from pydantic import BaseModel
from typing import Optional, Dict, Any
from datetime import datetime
from uuid import UUID

class AuditLogBase(BaseModel):
    action: str
    entity_type: str
    entity_id: Optional[UUID] = None
    old_values: Optional[Dict[str, Any]] = None
    new_values: Optional[Dict[str, Any]] = None
    ip_address: Optional[str] = None
    user_agent: Optional[str] = None
    session_id: Optional[str] = None

class AuditLogCreate(AuditLogBase):
    user_id: Optional[UUID] = None

class AuditLogResponse(AuditLogBase):
    id: UUID
    user_id: Optional[UUID]
    created_at: datetime
    user_name: Optional[str] = None
    user_email: Optional[str] = None

    class Config:
        from_attributes = True

class AuditLogListResponse(BaseModel):
    logs: list[AuditLogResponse]
    total: int
    page: int
    per_page: int
    total_pages: int

class AuditLogStatsResponse(BaseModel):
    total_logs: int
    today_logs: int
    warning_logs: int
    error_logs: int
    info_logs: int
    success_logs: int
    top_actions: list[Dict[str, Any]]
    top_users: list[Dict[str, Any]]
