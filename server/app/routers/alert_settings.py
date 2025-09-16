from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from uuid import UUID

from ..database import get_db
from ..models.alert_settings import AlertSetting
from ..schemas.alert_setting import AlertSettingCreate, AlertSettingResponse, AlertSettingUpdate
from ..routers.auth import get_current_user
from ..models.users import User

router = APIRouter(tags=["alert-settings"])

@router.get("/user", response_model=List[AlertSettingResponse])
def get_user_alert_settings(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Obtener configuraciones de alertas del usuario actual"""
    settings = db.query(AlertSetting).filter(
        AlertSetting.user_id == current_user.id
    ).all()
    return settings

@router.post("/", response_model=AlertSettingResponse, status_code=status.HTTP_201_CREATED)
def create_alert_setting(
    setting_data: AlertSettingCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Crear nueva configuración de alerta"""
    # Verificar si ya existe una configuración para este tipo de alerta
    existing = db.query(AlertSetting).filter(
        AlertSetting.user_id == current_user.id,
        AlertSetting.alert_type == setting_data.alert_type
    ).first()
    
    if existing:
        raise HTTPException(
            status_code=400, 
            detail=f"Ya existe una configuración para el tipo de alerta: {setting_data.alert_type}"
        )
    
    new_setting = AlertSetting(
        user_id=current_user.id,
        **setting_data.dict()
    )
    db.add(new_setting)
    db.commit()
    db.refresh(new_setting)
    return new_setting

@router.put("/{setting_id}", response_model=AlertSettingResponse)
def update_alert_setting(
    setting_id: UUID,
    update_data: AlertSettingUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Actualizar configuración de alerta"""
    setting = db.query(AlertSetting).filter(
        AlertSetting.id == setting_id,
        AlertSetting.user_id == current_user.id
    ).first()
    
    if not setting:
        raise HTTPException(status_code=404, detail="Configuración no encontrada")
    
    update_dict = update_data.dict(exclude_unset=True)
    for key, value in update_dict.items():
        setattr(setting, key, value)
    
    db.commit()
    db.refresh(setting)
    return setting

@router.delete("/{setting_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_alert_setting(
    setting_id: UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Eliminar configuración de alerta"""
    setting = db.query(AlertSetting).filter(
        AlertSetting.id == setting_id,
        AlertSetting.user_id == current_user.id
    ).first()
    
    if not setting:
        raise HTTPException(status_code=404, detail="Configuración no encontrada")
    
    db.delete(setting)
    db.commit()
