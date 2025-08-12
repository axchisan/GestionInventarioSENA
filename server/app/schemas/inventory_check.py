from pydantic import BaseModel
from uuid import UUID
from typing import List

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