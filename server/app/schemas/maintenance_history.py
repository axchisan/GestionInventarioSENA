from pydantic import BaseModel
from uuid import UUID
from datetime import date, datetime
from typing import Optional

class MaintenanceHistoryCreate(BaseModel):
    item_id: UUID
    request_id: Optional[UUID] = None
    technician_id: Optional[UUID] = None
    maintenance_type: str
    description: str
    cost: Optional[float] = None
    parts_replaced: Optional[str] = None
    maintenance_date: date
    next_maintenance_date: Optional[date] = None

class MaintenanceHistoryUpdate(BaseModel):
    maintenance_type: Optional[str] = None
    description: Optional[str] = None
    cost: Optional[float] = None
    parts_replaced: Optional[str] = None
    maintenance_date: Optional[date] = None
    next_maintenance_date: Optional[date] = None

class MaintenanceHistoryResponse(BaseModel):
    id: UUID
    item_id: UUID
    request_id: Optional[UUID]
    technician_id: Optional[UUID]
    maintenance_type: str
    description: str
    cost: Optional[float]
    parts_replaced: Optional[str]
    maintenance_date: date
    next_maintenance_date: Optional[date]
    created_at: datetime

    class Config:
        from_attributes = True