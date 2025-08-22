from pydantic import BaseModel
from uuid import UUID
from datetime import datetime, date
from typing import Optional

class InventoryItemCreate(BaseModel):
    environment_id: Optional[UUID]
    name: str
    serial_number: Optional[str]
    internal_code: str
    category: str
    brand: Optional[str]
    model: Optional[str]
    status: str
    purchase_date: Optional[date]
    warranty_expiry: Optional[date]
    last_maintenance: Optional[date]
    next_maintenance: Optional[date]
    image_url: Optional[str]
    notes: Optional[str]
    quantity: int
    item_type: str

class InventoryItemUpdate(BaseModel):
    name: Optional[str]
    serial_number: Optional[str]
    internal_code: Optional[str]
    category: Optional[str]
    brand: Optional[str]
    model: Optional[str]
    status: Optional[str]
    purchase_date: Optional[date]
    warranty_expiry: Optional[date]
    last_maintenance: Optional[date]
    next_maintenance: Optional[date]
    image_url: Optional[str]
    notes: Optional[str]
    quantity: Optional[int]
    item_type: Optional[str]
class InventoryItemResponse(BaseModel):
    id: UUID
    environment_id: Optional[UUID]
    name: str
    serial_number: Optional[str]
    internal_code: str
    category: str
    brand: Optional[str]
    model: Optional[str]
    status: str
    purchase_date: Optional[date]
    warranty_expiry: Optional[date]
    last_maintenance: Optional[date]
    next_maintenance: Optional[date]
    image_url: Optional[str]
    notes: Optional[str]
    quantity: int
    item_type: str
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True