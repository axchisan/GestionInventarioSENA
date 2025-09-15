from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import date
from uuid import UUID

class LoanBase(BaseModel):
    program: str = Field(..., min_length=1, max_length=100)
    purpose: str = Field(..., min_length=1)
    start_date: date
    end_date: date
    priority: str = Field(default="media", pattern="^(alta|media|baja)$")
    quantity_requested: int = Field(default=1, ge=1)
    
class LoanCreateRegistered(LoanBase):
    """Schema for creating a loan with a registered item"""
    item_id: UUID
    environment_id: UUID
    is_registered_item: bool = True

class LoanCreateCustom(LoanBase):
    """Schema for creating a loan with a custom/non-registered item"""
    item_name: str = Field(..., min_length=1, max_length=200)
    item_description: Optional[str] = None
    environment_id: UUID
    is_registered_item: bool = False

class LoanUpdate(BaseModel):
    status: Optional[str] = Field(None, pattern="^(pending|approved|rejected|active|returned|overdue)$")
    rejection_reason: Optional[str] = None
    actual_return_date: Optional[date] = None
    admin_id: Optional[UUID] = None

class LoanResponse(BaseModel):
    id: UUID
    instructor_id: UUID
    item_id: Optional[UUID]
    admin_id: Optional[UUID]
    environment_id: UUID
    program: str
    purpose: str
    start_date: date
    end_date: date
    actual_return_date: Optional[date]
    status: str
    rejection_reason: Optional[str]
    item_name: Optional[str]
    item_description: Optional[str]
    is_registered_item: bool
    quantity_requested: int
    priority: str
    acta_pdf_path: Optional[str]
    created_at: str
    updated_at: str
    
    # Related data
    instructor_name: Optional[str] = None
    admin_name: Optional[str] = None
    item_details: Optional[dict] = None
    environment_name: Optional[str] = None

    class Config:
        from_attributes = True

class LoanListResponse(BaseModel):
    loans: List[LoanResponse]
    total: int
    page: int
    per_page: int
    total_pages: int

class LoanStatsResponse(BaseModel):
    total_loans: int
    pending_loans: int
    approved_loans: int
    active_loans: int
    overdue_loans: int
    returned_loans: int
    rejected_loans: int