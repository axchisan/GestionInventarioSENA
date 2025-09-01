from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from pydantic import BaseModel
from uuid import UUID
from typing import Optional

from ..database import get_db
from ..models.inventory_check_items import InventoryCheckItem
from ..models.inventory_items import InventoryItem
from ..models.users import User
from ..routers.auth import get_current_user

router = APIRouter(tags=["inventory-check-items"])

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

@router.post("/", status_code=status.HTTP_201_CREATED)
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
