from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List, Optional
from uuid import UUID

from ..database import get_db
from ..models.maintenance_requests import MaintenanceRequest
from ..schemas.maintenance_request import MaintenanceRequestCreate, MaintenanceRequestResponse, MaintenanceRequestUpdate
from ..routers.auth import get_current_user
from ..models.users import User
from ..models.inventory_items import InventoryItem

router = APIRouter(tags=["maintenance-requests"])

@router.get("/", response_model=List[MaintenanceRequestResponse])
def get_maintenance_requests(
    db: Session = Depends(get_db),
    item_id: Optional[UUID] = None,
    status: Optional[str] = None,
    current_user: User = Depends(get_current_user)
):
    if current_user.role not in ["admin", "supervisor"]:
        raise HTTPException(status_code=403, detail="Rol no autorizado")

    query = db.query(MaintenanceRequest)
    if item_id:
        query = query.filter(MaintenanceRequest.item_id == item_id)
    if status:
        query = query.filter(MaintenanceRequest.status == status)
    requests = query.all()
    return requests

@router.post("/", response_model=MaintenanceRequestResponse, status_code=status.HTTP_201_CREATED)
def create_maintenance_request(
    request_data: MaintenanceRequestCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    item = db.query(InventoryItem).filter(InventoryItem.id == request_data.item_id).first()
    if not item:
        raise HTTPException(status_code=404, detail="Ítem no encontrado")

    new_request = MaintenanceRequest(
        **request_data.dict(),
        user_id=current_user.id
    )
    db.add(new_request)
    db.commit()
    db.refresh(new_request)
    return new_request

@router.put("/{request_id}", response_model=MaintenanceRequestResponse)
def update_maintenance_request(
    request_id: UUID,
    update_data: MaintenanceRequestUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    if current_user.role not in ["admin", "supervisor"]:
        raise HTTPException(status_code=403, detail="Rol no autorizado")

    maintenance_request = db.query(MaintenanceRequest).filter(MaintenanceRequest.id == request_id).first()
    if not maintenance_request:
        raise HTTPException(status_code=404, detail="Solicitud no encontrada")

    update_dict = update_data.dict(exclude_unset=True)
    for key, value in update_dict.items():
        setattr(maintenance_request, key, value)

    db.commit()
    db.refresh(maintenance_request)
    return maintenance_request

@router.delete("/{request_id}")
def delete_maintenance_request(
    request_id: UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    if current_user.role not in ["admin", "supervisor"]:
        raise HTTPException(status_code=403, detail="Rol no autorizado")

    maintenance_request = db.query(MaintenanceRequest).filter(MaintenanceRequest.id == request_id).first()
    if not maintenance_request:
        raise HTTPException(status_code=404, detail="Solicitud no encontrada")

    db.delete(maintenance_request)
    db.commit()
    return {"status": "success"}