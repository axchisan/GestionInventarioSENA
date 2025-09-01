from pydantic import BaseModel
from uuid import UUID
from datetime import date, datetime
from typing import Optional, List

class MaintenanceRequestCreate(BaseModel):
    item_id: UUID
    title: str
    description: str
    priority: str
    images_urls: Optional[List[str]] = None
    quantity_affected: Optional[int] = 1

class MaintenanceRequestUpdate(BaseModel):
    assigned_technician_id: Optional[UUID] = None
    status: Optional[str] = None
    estimated_completion: Optional[date] = None
    actual_completion: Optional[date] = None
    cost: Optional[float] = None
    notes: Optional[str] = None

class MaintenanceRequestResponse(BaseModel):
    id: UUID
    item_id: UUID
    user_id: UUID
    assigned_technician_id: Optional[UUID]
    title: str
    description: str
    priority: str
    status: str
    estimated_completion: Optional[date]
    actual_completion: Optional[date]
    cost: Optional[float]
    notes: Optional[str]
    images_urls: Optional[List[str]]
    quantity_affected: int
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True