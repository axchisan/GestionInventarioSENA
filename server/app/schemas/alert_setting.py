from pydantic import BaseModel, validator
from uuid import UUID
from datetime import datetime
from typing import Optional, List

class AlertSettingCreate(BaseModel):
    alert_type: str
    is_enabled: bool = True
    threshold_value: Optional[int] = None
    notification_methods: Optional[List[str]] = None

    @validator('alert_type')
    def validate_alert_type(cls, v):
        valid_types = [
            'stock_bajo', 'mantenimiento_vencido', 'prestamo_vencido', 
            'item_dañado', 'solicitud_mantenimiento', 'revision_inventario'
        ]
        if v not in valid_types:
            raise ValueError(f'Tipo de alerta inválido. Debe ser uno de: {", ".join(valid_types)}')
        return v

    @validator('notification_methods')
    def validate_notification_methods(cls, v):
        if v is not None:
            valid_methods = ['push', 'email', 'sms']
            for method in v:
                if method not in valid_methods:
                    raise ValueError(f'Método de notificación inválido: {method}')
        return v

class AlertSettingUpdate(BaseModel):
    is_enabled: Optional[bool] = None
    threshold_value: Optional[int] = None
    notification_methods: Optional[List[str]] = None

    @validator('notification_methods')
    def validate_notification_methods(cls, v):
        if v is not None:
            valid_methods = ['push', 'email', 'sms']
            for method in v:
                if method not in valid_methods:
                    raise ValueError(f'Método de notificación inválido: {method}')
        return v

class AlertSettingResponse(BaseModel):
    id: UUID
    user_id: UUID
    alert_type: str
    is_enabled: bool
    threshold_value: Optional[int]
    notification_methods: Optional[List[str]]
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True
