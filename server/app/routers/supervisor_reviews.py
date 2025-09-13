from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from uuid import UUID
from typing import List

from ..database import get_db
from ..models.supervisor_reviews import SupervisorReview
from ..models.inventory_checks import InventoryCheck
from ..models.notifications import Notification
from ..routers.auth import get_current_user
from ..models.users import User
from ..schemas.supervisor_review import SupervisorReviewCreate, SupervisorReviewResponse

router = APIRouter(tags=["supervisor-reviews"])

@router.post("/", response_model=SupervisorReviewResponse)
def create_supervisor_review(
    review_data: SupervisorReviewCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    if current_user.role != "supervisor":
        raise HTTPException(status_code=403, detail="Solo supervisores pueden revisar verificaciones")

    check = db.query(InventoryCheck).filter(InventoryCheck.id == review_data.check_id).first()
    if not check:
        raise HTTPException(status_code=404, detail="Verificación no encontrada")

    new_review = SupervisorReview(
        check_id=review_data.check_id,
        supervisor_id=current_user.id,
        status=review_data.status,
        comments=review_data.comments
    )
    db.add(new_review)
    db.commit()
    db.refresh(new_review)

    # Actualizar status del check si approved
    if review_data.status == "approved":
        check.status = "complete"
    elif review_data.status == "rejected":
        check.status = "issues"
    db.commit()

    # Create notifications for student and instructor about supervisor review
    notification_student = Notification(
        user_id=check.student_id,
        type="verification_update",
        title="Verificación Revisada por Supervisor",
        message=f"Tu verificación ha sido {'aprobada' if review_data.status == 'approved' else 'rechazada'} por el supervisor.",
        is_read=False,
        priority="medium"
    )
    db.add(notification_student)
    
    if check.instructor_id:
        notification_instructor = Notification(
            user_id=check.instructor_id,
            type="verification_update",
            title="Verificación Revisada por Supervisor",
            message=f"La verificación ha sido {'aprobada' if review_data.status == 'approved' else 'rechazada'} por el supervisor.",
            is_read=False,
            priority="medium"
        )
        db.add(notification_instructor)
    
    db.commit()

    return new_review

@router.get("/pending", response_model=List[dict])
def get_pending_reviews(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get all inventory checks pending supervisor review"""
    if current_user.role != "supervisor":
        raise HTTPException(status_code=403, detail="Solo supervisores pueden ver verificaciones pendientes")
    
    # Get checks that are in supervisor_review status or issues status
    pending_checks = db.query(InventoryCheck).filter(
        InventoryCheck.status.in_(["supervisor_review", "issues"])
    ).all()
    
    result = []
    for check in pending_checks:
        result.append({
            "check_id": check.id,
            "environment_id": check.environment_id,
            "student_id": check.student_id,
            "instructor_id": check.instructor_id,
            "check_date": check.check_date,
            "status": check.status,
            "total_items": check.total_items,
            "items_good": check.items_good,
            "items_damaged": check.items_damaged,
            "items_missing": check.items_missing,
            "is_clean": check.is_clean,
            "is_organized": check.is_organized,
            "inventory_complete": check.inventory_complete,
            "comments": check.comments
        })
    
    return result

@router.get("/{check_id}", response_model=dict)
def get_supervisor_review(
    check_id: UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get supervisor review for a specific check"""
    if current_user.role not in ["supervisor", "admin"]:
        raise HTTPException(status_code=403, detail="No autorizado para ver esta revisión")
    
    review = db.query(SupervisorReview).filter(SupervisorReview.check_id == check_id).first()
    if not review:
        raise HTTPException(status_code=404, detail="Revisión no encontrada")
    
    check = db.query(InventoryCheck).filter(InventoryCheck.id == check_id).first()
    
    return {
        "review_id": review.id,
        "check_id": review.check_id,
        "supervisor_id": review.supervisor_id,
        "status": review.status,
        "comments": review.comments,
        "created_at": review.created_at,
        "check_details": {
            "environment_id": check.environment_id,
            "student_id": check.student_id,
            "instructor_id": check.instructor_id,
            "check_date": check.check_date,
            "total_items": check.total_items,
            "items_good": check.items_good,
            "items_damaged": check.items_damaged,
            "items_missing": check.items_missing
        } if check else None
    }
