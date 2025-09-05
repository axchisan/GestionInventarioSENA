from pydantic import BaseModel, validator
from uuid import UUID
from datetime import date, datetime
from typing import Optional, List

class MaintenanceRequestCreate(BaseModel):
    item_id: Optional[UUID] = None
    equipment_name: Optional[str] = None
    equipment_location: Optional[str] = None
    equipment_category: Optional[str] = None
    title: str
    description: str
    priority: str
    maintenance_type: str = "corrective"
    images_urls: Optional[List[str]] = None
    quantity_affected: Optional[int] = 1

    @validator('equipment_name')
    def validate_equipment_info(cls, v, values):
        if not values.get('item_id') and not v:
            raise ValueError('Either item_id or equipment_name must be provided')
        return v

class MaintenanceRequestUpdate(BaseModel):
    assigned_technician_id: Optional[UUID] = None
    status: Optional[str] = None
    maintenance_type: Optional[str] = None
    estimated_completion: Optional[date] = None
    actual_completion: Optional[date] = None
    cost: Optional[float] = None
    notes: Optional[str] = None

class MaintenanceRequestResponse(BaseModel):
    id: UUID
    item_id: Optional[UUID]
    user_id: UUID
    assigned_technician_id: Optional[UUID]
    equipment_name: Optional[str]
    equipment_location: Optional[str]
    equipment_category: Optional[str]
    title: str
    description: str
    priority: str
    status: str
    maintenance_type: str
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
