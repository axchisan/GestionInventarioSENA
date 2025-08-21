from datetime import date, datetime, time
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
    notes: str | None = None

class InventoryCheckRequest(BaseModel):
    environment_id: UUID
    student_id: UUID
    items: List[InventoryCheckItemRequest]

class InventoryCheckResponse(BaseModel):
    id: UUID
    environment_id: UUID
    student_id: UUID
    schedule_id: Optional[UUID]
    check_date: date
    check_time: time
    status: str
    total_items: int
    items_good: int
    items_damaged: int
    items_missing: int
    comments: Optional[str]
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True