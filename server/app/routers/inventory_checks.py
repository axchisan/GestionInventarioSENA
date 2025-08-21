from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from pydantic import BaseModel
from datetime import datetime, date
from uuid import UUID
from typing import List, Optional

from ..database import get_db
from ..models.inventory_checks import InventoryCheck
from ..models.inventory_check_items import InventoryCheckItem
from ..models.environments import Environment
from ..models.inventory_items import InventoryItem
from ..models.users import User
from ..routers.auth import get_current_user
from ..schemas.inventory_check import InventoryCheckRequest, InventoryCheckResponse, InventoryCheckItemRequest

router = APIRouter(tags=["inventory-checks"])

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

@router.post("/")
async def create_inventory_check(
    request: InventoryCheckRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    if current_user.role not in ["instructor", "student", "supervisor"]:
        raise HTTPException(
            status_code=403,
            detail="Rol no autorizado para verificar inventario"
        )

    environment = db.query(Environment).filter(
        Environment.id == request.environment_id,
        Environment.is_active == True
    ).first()
    if not environment:
        raise HTTPException(status_code=404, detail="Ambiente no encontrado")

    student = db.query(User).filter(
        User.id == request.student_id,
        User.role == "student"
    ).first()
    if not student:
        raise HTTPException(status_code=404, detail="Estudiante no encontrado")

    inventory_check = InventoryCheck(
        environment_id=request.environment_id,
        student_id=request.student_id,
        check_date=date.today(),
        check_time=datetime.utcnow().time(),
        status="pending",
        total_items=len(request.items),
        items_good=0,
        items_damaged=0,
        items_missing=0
    )
    db.add(inventory_check)
    db.commit()
    db.refresh(inventory_check)

    items_good = 0
    items_damaged = 0
    items_missing = 0

    for item_request in request.items:
        inventory_item = db.query(InventoryItem).filter(
            InventoryItem.id == item_request.item_id,
            InventoryItem.environment_id == request.environment_id
        ).first()
        if not inventory_item:
            raise HTTPException(
                status_code=404,
                detail=f"Ítem {item_request.item_id} no encontrado en el ambiente"
            )

        check_item = InventoryCheckItem(
            check_id=inventory_check.id,
            item_id=item_request.item_id,
            status=item_request.status,
            quantity_expected=item_request.quantity_expected,
            quantity_found=item_request.quantity_found,
            quantity_damaged=item_request.quantity_damaged,
            quantity_missing=item_request.quantity_missing,
            notes=item_request.notes
        )
        db.add(check_item)

        if item_request.status == "good":
            items_good += item_request.quantity_found
        elif item_request.status == "damaged":
            items_damaged += item_request.quantity_damaged
        elif item_request.status == "missing":
            items_missing += item_request.quantity_missing

    inventory_check.items_good = items_good
    inventory_check.items_damaged = items_damaged
    inventory_check.items_missing = items_missing
    inventory_check.status = "complete" if items_damaged == 0 and items_missing == 0 else "issues"
    db.commit()

    return {
        "status": "success",
        "check_id": str(inventory_check.id),
        "environment_id": str(inventory_check.environment_id),
        "status": inventory_check.status,
        "total_items": inventory_check.total_items,
        "items_good": inventory_check.items_good,
        "items_damaged": inventory_check.items_damaged,
        "items_missing": inventory_check.items_missing
    }

@router.get("/", response_model=List[InventoryCheckResponse])
def get_inventory_checks(
    environment_id: Optional[UUID] = None,
    check_date: Optional[str] = None,  # Formato YYYY-MM-DD
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    if current_user.role not in ["instructor", "student", "supervisor", "admin", "admin_general"]:
        raise HTTPException(
            status_code=403,
            detail="Rol no autorizado para consultar checks"
        )

    query = db.query(InventoryCheck)
    if environment_id:
        query = query.filter(InventoryCheck.environment_id == environment_id)
    if check_date:
        try:
            parsed_date = date.fromisoformat(check_date)
            query = query.filter(InventoryCheck.check_date == parsed_date)
        except ValueError:
            raise HTTPException(status_code=400, detail="Formato de fecha inválido (use YYYY-MM-DD)")

    checks = query.all()
    return checks