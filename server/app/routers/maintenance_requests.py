from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List, Optional
from uuid import UUID

from ..database import get_db
from ..models.maintenance_requests import MaintenanceRequest
from ..models.notifications import Notification
from ..models.users import User
from ..schemas.maintenance_request import MaintenanceRequestCreate, MaintenanceRequestResponse, MaintenanceRequestUpdate
from ..routers.auth import get_current_user
from ..models.inventory_items import InventoryItem

router = APIRouter(tags=["maintenance-requests"])

@router.get("/", response_model=List[MaintenanceRequestResponse])
def get_maintenance_requests(
    db: Session = Depends(get_db),
    item_id: Optional[UUID] = None,
    status: Optional[str] = None,
    environment_id: Optional[UUID] = None,
    system_wide: Optional[bool] = False,
    admin_access: Optional[bool] = False,
    current_user: User = Depends(get_current_user)
):
    if current_user.role == "admin_general" and (system_wide or admin_access):
        # Admin general can see all maintenance requests
        query = db.query(MaintenanceRequest)
    elif current_user.role in ["admin", "supervisor"]:
        # Admin and supervisor can see all requests or filter by environment
        query = db.query(MaintenanceRequest)
        if environment_id:
            query = query.filter(MaintenanceRequest.environment_id == environment_id)
        elif current_user.environment_id:
            # If supervisor has specific environment, filter by it
            query = query.filter(MaintenanceRequest.environment_id == current_user.environment_id)
    elif current_user.role in ["instructor", "student"]:
        # Instructors and students can only see requests from their environment
        if not current_user.environment_id:
            raise HTTPException(status_code=403, detail="Usuario sin ambiente asignado")
        query = db.query(MaintenanceRequest).filter(MaintenanceRequest.environment_id == current_user.environment_id)
    else:
        raise HTTPException(status_code=403, detail="Rol no autorizado")

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
    if request_data.item_id:
        item = db.query(InventoryItem).filter(InventoryItem.id == request_data.item_id).first()
        if not item:
            raise HTTPException(status_code=404, detail="Ítem no encontrado")

    new_request = MaintenanceRequest(
        item_id=request_data.item_id,
        environment_id=request_data.environment_id,
        title=request_data.title,
        description=request_data.description,
        priority=request_data.priority,
        category=request_data.category,
        location=request_data.location,
        images_urls=request_data.images_urls,
        quantity_affected=request_data.quantity_affected or 1,
        user_id=current_user.id,
        status="pending"
    )
    db.add(new_request)
    db.commit()
    db.refresh(new_request)
    
    # Find all supervisors in the same environment or general supervisors
    supervisors_query = db.query(User).filter(User.role == "supervisor")
    
    # Filter by environment if the request has a specific environment
    if request_data.environment_id:
        supervisors_query = supervisors_query.filter(
            (User.environment_id == request_data.environment_id) | 
            (User.environment_id.is_(None))  # General supervisors
        )
    
    supervisors = supervisors_query.all()
    
    # Create notification for each supervisor
    for supervisor in supervisors:
        notification = Notification(
            user_id=supervisor.id,
            type="maintenance_request",
            title="Nueva Solicitud de Mantenimiento",
            message=f"Se ha creado una nueva solicitud de mantenimiento: {request_data.title}. Prioridad: {request_data.priority}",
            is_read=False,
            priority="high" if request_data.priority == "urgent" else "medium"
        )
        db.add(notification)
    
    db.commit()
    
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

    # Store old status for notification purposes
    old_status = maintenance_request.status
    
    update_dict = update_data.dict(exclude_unset=True)
    for key, value in update_dict.items():
        setattr(maintenance_request, key, value)

    db.commit()
    db.refresh(maintenance_request)
    
    new_status = maintenance_request.status
    if old_status != new_status and maintenance_request.user_id:
        # Notify the original requester about status change
        status_messages = {
            "in_progress": "Su solicitud de mantenimiento está siendo procesada",
            "completed": "Su solicitud de mantenimiento ha sido completada",
            "cancelled": "Su solicitud de mantenimiento ha sido cancelada",
            "on_hold": "Su solicitud de mantenimiento está en espera"
        }
        
        if new_status in status_messages:
            notification = Notification(
                user_id=maintenance_request.user_id,
                type="maintenance_update",
                title="Actualización de Solicitud de Mantenimiento",
                message=f"{status_messages[new_status]}: {maintenance_request.title}",
                is_read=False,
                priority="medium"
            )
            db.add(notification)
            db.commit()
    
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
