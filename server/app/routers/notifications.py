from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from uuid import UUID

from ..database import get_db
from ..models.notifications import Notification
from ..schemas.notification import NotificationCreate, NotificationResponse, NotificationUpdate
from ..routers.auth import get_current_user
from ..models.users import User

router = APIRouter(tags=["notifications"])

@router.get("/", response_model=List[NotificationResponse])
def get_notifications(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    notifications = db.query(Notification).filter(Notification.user_id == current_user.id).all()
    return notifications

@router.post("/", response_model=NotificationResponse, status_code=status.HTTP_201_CREATED)
def create_notification(
    notif_data: NotificationCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    if current_user.role not in ["admin", "system"]:  # Asumir 'system' para automatizaciones
        raise HTTPException(status_code=403, detail="Rol no autorizado")

    new_notif = Notification(**notif_data.dict())
    db.add(new_notif)
    db.commit()
    db.refresh(new_notif)
    return new_notif

@router.put("/{notif_id}", response_model=NotificationResponse)
def update_notification(
    notif_id: UUID,
    update_data: NotificationUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    notif = db.query(Notification).filter(Notification.id == notif_id, Notification.user_id == current_user.id).first()
    if not notif:
        raise HTTPException(status_code=404, detail="Notificación no encontrada")

    update_dict = update_data.dict(exclude_unset=True)
    for key, value in update_dict.items():
        setattr(notif, key, value)

    db.commit()
    db.refresh(notif)
    return notif