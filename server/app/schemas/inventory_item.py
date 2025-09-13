from pydantic import BaseModel, validator
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
    quantity: int = 1
    quantity_damaged: int = 0
    quantity_missing: int = 0
    item_type: str = 'individual'
    
    @validator('quantity', 'quantity_damaged', 'quantity_missing')
    def validate_quantities(cls, v):
        if v < 0:
            raise ValueError('Las cantidades no pueden ser negativas')
        return v
    
    @validator('category')
    def validate_category(cls, v):
        valid_categories = ['computer', 'projector', 'keyboard', 'mouse', 'tv', 'camera', 'microphone', 'tablet', 'other']
        if v not in valid_categories:
            raise ValueError(f'Categoría debe ser una de: {", ".join(valid_categories)}')
        return v
    
    @validator('status')
    def validate_status(cls, v):
        valid_statuses = ['available', 'in_use', 'maintenance', 'damaged', 'lost', 'missing', 'good']
        if v not in valid_statuses:
            raise ValueError(f'Estado debe ser uno de: {", ".join(valid_statuses)}')
        return v
    
    @validator('item_type')
    def validate_item_type(cls, v):
        if v not in ['individual', 'group']:
            raise ValueError('Tipo de item debe ser "individual" o "group"')
        return v

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
    quantity_damaged: Optional[int]
    quantity_missing: Optional[int]
    item_type: Optional[str]
    
    @validator('quantity', 'quantity_damaged', 'quantity_missing')
    def validate_quantities(cls, v):
        if v is not None and v < 0:
            raise ValueError('Las cantidades no pueden ser negativas')
        return v
    
    @validator('category')
    def validate_category(cls, v):
        if v is not None:
            valid_categories = ['computer', 'projector', 'keyboard', 'mouse', 'tv', 'camera', 'microphone', 'tablet', 'other']
            if v not in valid_categories:
                raise ValueError(f'Categoría debe ser una de: {", ".join(valid_categories)}')
        return v
    
    @validator('status')
    def validate_status(cls, v):
        if v is not None:
            valid_statuses = ['available', 'in_use', 'maintenance', 'damaged', 'lost', 'missing', 'good']
            if v not in valid_statuses:
                raise ValueError(f'Estado debe ser uno de: {", ".join(valid_statuses)}')
        return v
    
    @validator('item_type')
    def validate_item_type(cls, v):
        if v is not None and v not in ['individual', 'group']:
            raise ValueError('Tipo de item debe ser "individual" o "group"')
        return v

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
    quantity_damaged: int
    quantity_missing: int
    item_type: str
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True

class InventoryItemVerificationUpdate(BaseModel):
    """Schema for updating inventory items during verification process"""
    quantity: Optional[int]
    quantity_damaged: Optional[int] = 0
    quantity_missing: Optional[int] = 0
    status: Optional[str]
    
    @validator('quantity', 'quantity_damaged', 'quantity_missing')
    def validate_quantities(cls, v):
        if v is not None and v < 0:
            raise ValueError('Las cantidades no pueden ser negativas')
        return v
    
    @validator('status')
    def validate_status(cls, v):
        if v is not None:
            valid_statuses = ['available', 'in_use', 'maintenance', 'damaged', 'lost', 'missing', 'good']
            if v not in valid_statuses:
                raise ValueError(f'Estado debe ser uno de: {", ".join(valid_statuses)}')
        return v

class InventoryItemBulkUpdate(BaseModel):
    """Schema for bulk updating multiple inventory items"""
    item_updates: list[dict]
    
    @validator('item_updates')
    def validate_item_updates(cls, v):
        if not v:
            raise ValueError('La lista de actualizaciones no puede estar vacía')
        
        for update in v:
            if 'id' not in update:
                raise ValueError('Cada actualización debe incluir un ID de item')
        
        return v
