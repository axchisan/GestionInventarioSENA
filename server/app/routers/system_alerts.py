from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List, Optional
from uuid import UUID

from ..database import get_db
from ..models.system_alerts import SystemAlert
from ..schemas.system_alert import SystemAlertCreate, SystemAlertResponse, SystemAlertUpdate
from ..routers.auth import get_current_user
from ..models.users import User

router = APIRouter(tags=["system-alerts"])

@router.get("/", response_model=List[SystemAlertResponse])
def get_system_alerts(
    db: Session = Depends(get_db),
    type: Optional[str] = None,
    current_user: User = Depends(get_current_user)
):
    if current_user.role not in ["admin", "supervisor"]:
        raise HTTPException(status_code=403, detail="Rol no autorizado")

    query = db.query(SystemAlert)
    if type:
        query = query.filter(SystemAlert.type == type)
    alerts = query.all()
    return alerts

@router.post("/", response_model=SystemAlertResponse, status_code=status.HTTP_201_CREATED)
def create_system_alert(
    alert_data: SystemAlertCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    if current_user.role not in ["admin", "system"]:
        raise HTTPException(status_code=403, detail="Rol no autorizado")

    new_alert = SystemAlert(**alert_data.dict())
    db.add(new_alert)
    db.commit()
    db.refresh(new_alert)
    return new_alert

@router.put("/{alert_id}", response_model=SystemAlertResponse)
def update_system_alert(
    alert_id: UUID,
    update_data: SystemAlertUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    alert = db.query(SystemAlert).filter(SystemAlert.id == alert_id).first()
    if not alert:
        raise HTTPException(status_code=404, detail="Alerta no encontrada")

    update_dict = update_data.dict(exclude_unset=True)
    for key, value in update_dict.items():
        setattr(alert, key, value)

    if 'is_resolved' in update_dict and update_data.is_resolved:
        alert.resolved_by = current_user.id
        alert.resolved_at = datetime.utcnow()

    db.commit()
    db.refresh(alert)
    return alert