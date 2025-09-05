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
    maintenance_type: Optional[str] = None,
    current_user: User = Depends(get_current_user)
):
    query = db.query(MaintenanceRequest)
    
    if current_user.role in ["student", "instructor"]:
        # Users can only see their own requests
        query = query.filter(MaintenanceRequest.user_id == current_user.id)
    elif current_user.role not in ["admin", "supervisor", "admin_general"]:
        raise HTTPException(status_code=403, detail="Rol no autorizado")
    
    if item_id:
        query = query.filter(MaintenanceRequest.item_id == item_id)
    if status:
        query = query.filter(MaintenanceRequest.status == status)
    if maintenance_type:
        query = query.filter(MaintenanceRequest.maintenance_type == maintenance_type)
        
    requests = query.order_by(MaintenanceRequest.created_at.desc()).all()
    return requests

@router.post("/", response_model=MaintenanceRequestResponse, status_code=status.HTTP_201_CREATED)
def create_maintenance_request(
    request_data: MaintenanceRequestCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    if request_data.item_id:
        # Validate item exists if item_id is provided
        item = db.query(InventoryItem).filter(InventoryItem.id == request_data.item_id).first()
        if not item:
            raise HTTPException(status_code=404, detail="Ítem no encontrado")

    title = request_data.title
    if not title:
        if request_data.item_id:
            title = f"Mantenimiento {request_data.maintenance_type} - Item {request_data.item_id}"
        else:
            title = f"Mantenimiento {request_data.maintenance_type} - {request_data.equipment_name or 'Equipo'}"

    new_request = MaintenanceRequest(
        **request_data.dict(),
        title=title,
        user_id=current_user.id
    )
    db.add(new_request)
    db.commit()
    db.refresh(new_request)
    return new_request

@router.get("/my-requests", response_model=List[MaintenanceRequestResponse])
def get_my_maintenance_requests(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get current user's maintenance requests"""
    requests = db.query(MaintenanceRequest).filter(
        MaintenanceRequest.user_id == current_user.id
    ).order_by(MaintenanceRequest.created_at.desc()).all()
    return requests

@router.put("/{request_id}", response_model=MaintenanceRequestResponse)
def update_maintenance_request(
    request_id: UUID,
    update_data: MaintenanceRequestUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    maintenance_request = db.query(MaintenanceRequest).filter(MaintenanceRequest.id == request_id).first()
    if not maintenance_request:
        raise HTTPException(status_code=404, detail="Solicitud no encontrada")

    if current_user.role not in ["admin", "supervisor", "admin_general"]:
        if maintenance_request.user_id != current_user.id:
            raise HTTPException(status_code=403, detail="No autorizado para actualizar esta solicitud")
        if maintenance_request.status != "pending":
            raise HTTPException(status_code=403, detail="No se puede modificar una solicitud en proceso")

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
    maintenance_request = db.query(MaintenanceRequest).filter(MaintenanceRequest.id == request_id).first()
    if not maintenance_request:
        raise HTTPException(status_code=404, detail="Solicitud no encontrada")

    if current_user.role not in ["admin", "supervisor", "admin_general"]:
        if maintenance_request.user_id != current_user.id:
            raise HTTPException(status_code=403, detail="No autorizado para eliminar esta solicitud")
        if maintenance_request.status != "pending":
            raise HTTPException(status_code=403, detail="No se puede eliminar una solicitud en proceso")

    db.delete(maintenance_request)
    db.commit()
    return {"status": "success"}
