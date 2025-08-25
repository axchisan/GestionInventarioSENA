from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from uuid import UUID

from ..database import get_db
from ..models.supervisor_reviews import SupervisorReview
from ..models.inventory_checks import InventoryCheck
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

    return new_review