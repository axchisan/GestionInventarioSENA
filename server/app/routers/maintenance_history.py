from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List, Optional
from uuid import UUID

from ..database import get_db
from ..models.maintenance_history import MaintenanceHistory
from ..schemas.maintenance_history import MaintenanceHistoryCreate, MaintenanceHistoryResponse, MaintenanceHistoryUpdate
from ..routers.auth import get_current_user
from ..models.users import User
from ..models.inventory_items import InventoryItem

router = APIRouter(tags=["maintenance-history"])

@router.get("/", response_model=List[MaintenanceHistoryResponse])
def get_maintenance_history(
    db: Session = Depends(get_db),
    item_id: Optional[UUID] = None,
    current_user: User = Depends(get_current_user)
):
    if current_user.role not in ["admin", "supervisor"]:
        raise HTTPException(status_code=403, detail="Rol no autorizado")

    query = db.query(MaintenanceHistory)
    if item_id:
        query = query.filter(MaintenanceHistory.item_id == item_id)
    history = query.all()
    return history

@router.post("/", response_model=MaintenanceHistoryResponse, status_code=status.HTTP_201_CREATED)
def create_maintenance_history(
    history_data: MaintenanceHistoryCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    if current_user.role not in ["admin", "supervisor"]:
        raise HTTPException(status_code=403, detail="Rol no autorizado")

    item = db.query(InventoryItem).filter(InventoryItem.id == history_data.item_id).first()
    if not item:
        raise HTTPException(status_code=404, detail="Ítem no encontrado")

    new_history = MaintenanceHistory(**history_data.dict())
    db.add(new_history)
    db.commit()
    db.refresh(new_history)
    return new_history

@router.put("/{history_id}", response_model=MaintenanceHistoryResponse)
def update_maintenance_history(
    history_id: UUID,
    update_data: MaintenanceHistoryUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    if current_user.role not in ["admin", "supervisor"]:
        raise HTTPException(status_code=403, detail="Rol no autorizado")

    history = db.query(MaintenanceHistory).filter(MaintenanceHistory.id == history_id).first()
    if not history:
        raise HTTPException(status_code=404, detail="Historial no encontrado")

    update_dict = update_data.dict(exclude_unset=True)
    for key, value in update_dict.items():
        setattr(history, key, value)

    db.commit()
    db.refresh(history)
    return history