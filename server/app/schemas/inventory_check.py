from datetime import date, time, datetime
from pydantic import BaseModel
from uuid import UUID
from typing import List, Optional

class InventoryCheckItemRequest(BaseModel):
    item_id: UUID
    status: str
    quantity_expected: int
    quantity_found: int
    quantity_damaged: int
    quantity_missing: int
    notes: Optional[str] = None

class InventoryCheckCreateRequest(BaseModel):
    environment_id: UUID
    schedule_id: UUID
    student_id: UUID
    cleaning_notes: Optional[str] = None

class InventoryCheckInstructorConfirmRequest(BaseModel):
    is_clean: bool
    is_organized: bool
    inventory_complete: bool
    comments: Optional[str] = None

class InventoryCheckResponse(BaseModel):
    id: UUID
    environment_id: UUID
    student_id: UUID
    instructor_id: Optional[UUID]
    schedule_id: Optional[UUID]
    check_date: date
    check_time: time
    status: str
    total_items: int
    items_good: int
    items_damaged: int
    items_missing: int
    is_clean: Optional[bool]
    is_organized: Optional[bool]
    inventory_complete: Optional[bool]
    cleaning_notes: Optional[str]
    comments: Optional[str]
    instructor_confirmed_at: Optional[datetime]
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True