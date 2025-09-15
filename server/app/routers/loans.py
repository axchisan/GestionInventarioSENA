from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session, joinedload
from sqlalchemy import and_, or_, func, desc
from typing import List, Optional
from datetime import date, datetime
from uuid import UUID

from ..database import get_db
from ..models.loans import Loan
from ..models.inventory_items import InventoryItem
from ..models.environments import Environment
from ..models.users import User
from ..schemas.loan import (
    LoanCreateRegistered, 
    LoanCreateCustom, 
    LoanUpdate, 
    LoanResponse, 
    LoanListResponse,
    LoanStatsResponse
)
from ..routers.auth import get_current_user


router = APIRouter()

@router.post("/", response_model=LoanResponse, status_code=status.HTTP_201_CREATED)
async def create_loan(
    loan_data: LoanCreateRegistered | LoanCreateCustom,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Create a new loan request"""
    
    # Verify user is instructor
    if current_user.role not in ["instructor", "admin"]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only instructors and admins can create loan requests"
        )
    
    # Verify environment exists
    environment = db.query(Environment).filter(Environment.id == loan_data.environment_id).first()
    if not environment:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Environment not found"
        )
    
    # If registered item, verify it exists and is available
    if isinstance(loan_data, LoanCreateRegistered):
        item = db.query(InventoryItem).filter(InventoryItem.id == loan_data.item_id).first()
        if not item:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Item not found"
            )
        
        # Check if item has enough quantity available
        available_quantity = item.quantity - item.quantity_damaged - item.quantity_missing
        if available_quantity < loan_data.quantity_requested:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Not enough quantity available. Available: {available_quantity}, Requested: {loan_data.quantity_requested}"
            )
    
    # Create loan
    loan_dict = loan_data.model_dump()
    loan_dict["instructor_id"] = current_user.id
    
    loan = Loan(**loan_dict)
    db.add(loan)
    db.commit()
    db.refresh(loan)
    
    return await _get_loan_with_details(loan.id, db)

@router.get("/", response_model=LoanListResponse)
async def get_loans(
    page: int = Query(1, ge=1),
    per_page: int = Query(10, ge=1, le=100),
    status_filter: Optional[str] = Query(None),
    environment_id: Optional[UUID] = Query(None),
    instructor_id: Optional[UUID] = Query(None),
    priority: Optional[str] = Query(None),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get loans with filtering and pagination"""
    
    query = db.query(Loan)
    
    # Apply role-based filtering
    if current_user.role == "instructor":
        query = query.filter(Loan.instructor_id == current_user.id)
    elif current_user.role == "admin":
        # Admin can see loans for their environment or warehouse
        if current_user.environment_id:
            warehouse_env = db.query(Environment).filter(
                and_(Environment.center_id == current_user.center_id, Environment.is_warehouse == True)
            ).first()
            if warehouse_env:
                query = query.filter(
                    or_(
                        Loan.environment_id == current_user.environment_id,
                        Loan.environment_id == warehouse_env.id
                    )
                )
    
    # Apply filters
    if status_filter:
        query = query.filter(Loan.status == status_filter)
    if environment_id:
        query = query.filter(Loan.environment_id == environment_id)
    if instructor_id:
        query = query.filter(Loan.instructor_id == instructor_id)
    if priority:
        query = query.filter(Loan.priority == priority)
    
    # Get total count
    total = query.count()
    
    # Apply pagination
    loans = query.order_by(desc(Loan.created_at)).offset((page - 1) * per_page).limit(per_page).all()
    
    # Get detailed loan data
    loan_responses = []
    for loan in loans:
        loan_detail = await _get_loan_with_details(loan.id, db)
        loan_responses.append(loan_detail)
    
    total_pages = (total + per_page - 1) // per_page
    
    return LoanListResponse(
        loans=loan_responses,
        total=total,
        page=page,
        per_page=per_page,
        total_pages=total_pages
    )

@router.get("/stats", response_model=LoanStatsResponse)
async def get_loan_stats(
    environment_id: Optional[UUID] = Query(None),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get loan statistics"""
    
    query = db.query(Loan)
    
    # Apply role-based filtering
    if current_user.role == "instructor":
        query = query.filter(Loan.instructor_id == current_user.id)
    elif current_user.role == "admin" and environment_id:
        query = query.filter(Loan.environment_id == environment_id)
    
    total_loans = query.count()
    pending_loans = query.filter(Loan.status == "pending").count()
    approved_loans = query.filter(Loan.status == "approved").count()
    active_loans = query.filter(Loan.status == "active").count()
    overdue_loans = query.filter(Loan.status == "overdue").count()
    returned_loans = query.filter(Loan.status == "returned").count()
    rejected_loans = query.filter(Loan.status == "rejected").count()
    
    return LoanStatsResponse(
        total_loans=total_loans,
        pending_loans=pending_loans,
        approved_loans=approved_loans,
        active_loans=active_loans,
        overdue_loans=overdue_loans,
        returned_loans=returned_loans,
        rejected_loans=rejected_loans
    )

@router.get("/{loan_id}", response_model=LoanResponse)
async def get_loan(
    loan_id: UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get a specific loan by ID"""
    
    loan = db.query(Loan).filter(Loan.id == loan_id).first()
    if not loan:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Loan not found"
        )
    
    # Check permissions
    if current_user.role == "instructor" and loan.instructor_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You can only view your own loans"
        )
    
    return await _get_loan_with_details(loan_id, db)

@router.put("/{loan_id}", response_model=LoanResponse)
async def update_loan(
    loan_id: UUID,
    loan_update: LoanUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Update a loan (approve, reject, return, etc.)"""
    
    loan = db.query(Loan).filter(Loan.id == loan_id).first()
    if not loan:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Loan not found"
        )
    
    # Check permissions based on status change
    if loan_update.status in ["approved", "rejected"]:
        if current_user.role != "admin":
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Only admins can approve or reject loans"
            )
        loan.admin_id = current_user.id
    
    # Update loan fields
    for field, value in loan_update.model_dump(exclude_unset=True).items():
        setattr(loan, field, value)
    
    loan.updated_at = func.current_timestamp()
    db.commit()
    db.refresh(loan)
    
    return await _get_loan_with_details(loan_id, db)

@router.delete("/{loan_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_loan(
    loan_id: UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Delete a loan (only if pending and by instructor)"""
    
    loan = db.query(Loan).filter(Loan.id == loan_id).first()
    if not loan:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Loan not found"
        )
    
    # Only instructor can delete their own pending loans
    if loan.instructor_id != current_user.id or loan.status != "pending":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You can only delete your own pending loans"
        )
    
    db.delete(loan)
    db.commit()

async def _get_loan_with_details(loan_id: UUID, db: Session) -> LoanResponse:
    """Helper function to get loan with all related details"""
    
    loan = db.query(Loan).options(
        joinedload(Loan.instructor),
        joinedload(Loan.admin),
        joinedload(Loan.item),
        joinedload(Loan.environment)
    ).filter(Loan.id == loan_id).first()
    
    if not loan:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Loan not found"
        )
    
    # Build response with related data
    response_data = {
        "id": loan.id,
        "instructor_id": loan.instructor_id,
        "item_id": loan.item_id,
        "admin_id": loan.admin_id,
        "environment_id": loan.environment_id,
        "program": loan.program,
        "purpose": loan.purpose,
        "start_date": loan.start_date,
        "end_date": loan.end_date,
        "actual_return_date": loan.actual_return_date,
        "status": loan.status,
        "rejection_reason": loan.rejection_reason,
        "item_name": loan.item_name,
        "item_description": loan.item_description,
        "is_registered_item": loan.is_registered_item,
        "quantity_requested": loan.quantity_requested,
        "priority": loan.priority,
        "acta_pdf_path": loan.acta_pdf_path,
        "created_at": loan.created_at.isoformat() if loan.created_at else None,
        "updated_at": loan.updated_at.isoformat() if loan.updated_at else None,
        "instructor_name": f"{loan.instructor.first_name} {loan.instructor.last_name}" if loan.instructor else None,
        "admin_name": f"{loan.admin.first_name} {loan.admin.last_name}" if loan.admin else None,
        "environment_name": loan.environment.name if loan.environment else None,
    }
    
    if loan.item:
        response_data["item_details"] = {
            "name": loan.item.name,
            "internal_code": loan.item.internal_code,
            "category": loan.item.category,
            "brand": loan.item.brand,
            "model": loan.item.model,
            "status": loan.item.status
        }
    
    return LoanResponse(**response_data)
