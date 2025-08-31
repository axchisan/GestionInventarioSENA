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
from ..models.schedules import Schedule
from ..models.notifications import Notification
from ..routers.auth import get_current_user
from ..schemas.inventory_check import InventoryCheckCreateRequest, InventoryCheckResponse, InventoryCheckInstructorConfirmRequest, InventoryCheckItemRequest

router = APIRouter(tags=["inventory-checks"])

class InventoryCheckItemCreateRequest(BaseModel):
    item_id: UUID
    status: str
    quantity_expected: int
    quantity_found: int
    quantity_damaged: int
    quantity_missing: int
    notes: Optional[str] = None
    environment_id: UUID
    student_id: UUID

@router.post("/inventory-check-items/", status_code=status.HTTP_201_CREATED)
async def create_individual_check_item(
    request: InventoryCheckItemCreateRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    if current_user.role not in ["student", "instructor", "supervisor"]:
        raise HTTPException(status_code=403, detail="Rol no autorizado")

    inventory_item = db.query(InventoryItem).filter(
        InventoryItem.id == request.item_id,
        InventoryItem.environment_id == request.environment_id
    ).first()
    if not inventory_item:
        raise HTTPException(status_code=404, detail="Ítem no encontrado")

    check_item = InventoryCheckItem(
        check_id=None,  # No asociado a check general
        item_id=request.item_id,
        status=request.status,
        quantity_expected=request.quantity_expected,
        quantity_found=request.quantity_found,
        quantity_damaged=request.quantity_damaged,
        quantity_missing=request.quantity_missing,
        notes=request.notes
    )
    db.add(check_item)
    db.commit()
    db.refresh(check_item)

    # Actualizar quantity en InventoryItem
    inventory_item.quantity = request.quantity_found + request.quantity_damaged
    inventory_item.status = request.status if request.status in ['damaged', 'missing'] else inventory_item.status
    db.commit()

    return {"status": "success", "item_id": check_item.item_id}

@router.post("/", status_code=status.HTTP_201_CREATED)
async def create_inventory_check(
    request: InventoryCheckCreateRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    if current_user.role not in ["student", "instructor", "supervisor"]:
        raise HTTPException(status_code=403, detail="Rol no autorizado")

    environment = db.query(Environment).filter(Environment.id == request.environment_id).first()
    if not environment:
        raise HTTPException(status_code=404, detail="Ambiente no encontrado")

    student = db.query(User).filter(User.id == request.student_id, User.role == "student").first()
    if not student:
        raise HTTPException(status_code=404, detail="Estudiante no encontrado")

    schedule = db.query(Schedule).filter(Schedule.id == request.schedule_id).first()
    if not schedule:
        raise HTTPException(status_code=404, detail="Horario no encontrado")

    existing_check = db.query(InventoryCheck).filter(
        InventoryCheck.environment_id == request.environment_id,
        InventoryCheck.schedule_id == request.schedule_id,
        InventoryCheck.check_date == date.today()
    ).first()
    if existing_check:
        raise HTTPException(status_code=400, detail="Ya se realizó verificación hoy para este turno")

    inventory_check = InventoryCheck(
        environment_id=request.environment_id,
        student_id=request.student_id,
        schedule_id=request.schedule_id,
        check_date=date.today(),
        check_time=datetime.utcnow().time(),
        status="pending",
        total_items=len(request.items),
        items_good=0,
        items_damaged=0,
        items_missing=0,
        cleaning_notes=request.cleaning_notes
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
            raise HTTPException(status_code=404, detail=f"Ítem {item_request.item_id} no encontrado")

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
    inventory_check.status = "issues" if items_damaged > 0 or items_missing > 0 else "instructor_review"
    db.commit()

    notification = Notification(
        user_id=schedule.instructor_id,
        type="verification_pending",
        title="Nueva Verificación Pendiente",
        message="Una verificación de inventario ha sido iniciada.",
        is_read=False,
        priority="medium"
    )
    db.add(notification)
    db.commit()

    return {"status": "success", "check_id": inventory_check.id}

@router.put("/{check_id}/confirm", response_model=InventoryCheckResponse)
async def confirm_inventory_check(
    check_id: UUID,
    request: InventoryCheckInstructorConfirmRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    if current_user.role != "instructor":
        raise HTTPException(status_code=403, detail="Solo instructores pueden confirmar verificaciones")

    inventory_check = db.query(InventoryCheck).filter(InventoryCheck.id == check_id).first()
    if not inventory_check:
        raise HTTPException(status_code=404, detail="Verificación no encontrada")

    if inventory_check.instructor_id is not None:
        raise HTTPException(status_code=400, detail="Ya confirmada por instructor")

    inventory_check.instructor_id = current_user.id
    inventory_check.is_clean = request.is_clean
    inventory_check.is_organized = request.is_organized
    inventory_check.inventory_complete = request.inventory_complete
    inventory_check.comments = request.comments
    inventory_check.instructor_confirmed_at = datetime.utcnow()
    if not request.inventory_complete or inventory_check.status == "issues":
        inventory_check.status = "issues"
    else:
        inventory_check.status = "supervisor_review"

    db.commit()
    db.refresh(inventory_check)
    notification = Notification(
        user_id=current_user.id, 
        type="verification_update",
        title="Verificación Confirmada por Instructor",
        message="La verificación ha sido confirmada.",
        is_read=False,
        priority="medium"
    )
    db.add(notification)
    db.commit()

    return inventory_check

@router.get("/", response_model=List[InventoryCheckResponse])
def get_inventory_checks(
    environment_id: Optional[UUID] = None,
    date: Optional[str] = None,  
    shift: Optional[str] = None,  
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user) 
):
    query = db.query(InventoryCheck)
    if environment_id:
        query = query.filter(InventoryCheck.environment_id == environment_id)
    if date:
        try:
            parsed_date = datetime.strptime(date, "%Y-%m-%d").date()
            query = query.filter(InventoryCheck.check_date == parsed_date)
        except ValueError:
            raise HTTPException(status_code=400, detail="Formato de fecha inválido. Se espera YYYY-MM-DD")
    if shift:
        if shift == 'morning':
            query = query.join(Schedule).filter(Schedule.start_time.between('07:00:00', '12:00:00'))
        elif shift == 'afternoon':
            query = query.join(Schedule).filter(Schedule.start_time.between('13:00:00', '18:00:00'))
        elif shift == 'night':
            query = query.join(Schedule).filter(Schedule.start_time.between('18:00:00', '22:00:00'))

    checks = query.all()
    return checks