from pydantic import BaseModel
from typing import Optional, Dict, Any
from datetime import datetime
from uuid import UUID

class GeneratedReportBase(BaseModel):
    report_type: str
    title: str
    file_format: str
    parameters: Optional[Dict[str, Any]] = None

class GeneratedReportCreate(GeneratedReportBase):
    pass

class GeneratedReportResponse(GeneratedReportBase):
    id: UUID
    user_id: UUID
    file_path: Optional[str] = None
    file_size: Optional[int] = None
    status: str
    generated_at: Optional[datetime] = None
    expires_at: Optional[datetime] = None
    download_count: int = 0
    created_at: datetime

    class Config:
        from_attributes = True
