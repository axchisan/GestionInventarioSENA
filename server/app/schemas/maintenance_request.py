from pydantic import BaseModel, validator
from uuid import UUID
from datetime import date, datetime
from typing import Optional, List

class MaintenanceRequestCreate(BaseModel):
    item_id: Optional[UUID] = None
    environment_id: Optional[UUID] = None
    title: str
    description: str
    priority: str = "medium"
    category: Optional[str] = None
    location: Optional[str] = None
    images_urls: Optional[List[str]] = None
    quantity_affected: Optional[int] = 1

    @validator('environment_id')
    def validate_item_or_environment(cls, v, values):
        if not v and not values.get('item_id'):
            raise ValueError('Either item_id or environment_id must be provided')
        return v

class MaintenanceRequestUpdate(BaseModel):
    assigned_technician_id: Optional[UUID] = None
    status: Optional[str] = None
    estimated_completion: Optional[date] = None
    actual_completion: Optional[date] = None
    cost: Optional[float] = None
    notes: Optional[str] = None
    category: Optional[str] = None
    location: Optional[str] = None

class MaintenanceRequestResponse(BaseModel):
    id: UUID
    item_id: Optional[UUID]
    user_id: UUID
    assigned_technician_id: Optional[UUID]
    environment_id: Optional[UUID]
    title: str
    description: str
    priority: str
    status: str
    category: Optional[str]
    location: Optional[str]
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

class GeneralMaintenanceRequestCreate(BaseModel):
    environment_id: UUID
    title: str
    description: str
    priority: str = "medium"
    category: str
    location: str
    images_urls: Optional[List[str]] = None

class ItemMaintenanceRequestCreate(BaseModel):
    item_id: UUID
    title: str
    description: str
    priority: str = "medium"
    quantity_affected: Optional[int] = 1
    images_urls: Optional[List[str]] = None
