from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from uuid import UUID

from ..database import get_db
from ..models.schedules import Schedule
from ..models.environments import Environment
from ..schemas.schedule import ScheduleResponse
from ..routers.auth import get_current_user
from ..models.users import User

router = APIRouter(tags=["schedules"])

@router.get("/", response_model=List[ScheduleResponse])
async def get_schedules(
    environment_id: UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    # Verificar permisos
    if current_user.role not in ["instructor", "student", "supervisor"]:
        raise HTTPException(
            status_code=403,
            detail="Rol no autorizado para consultar horarios"
        )

    # Verificar que el ambiente existe
    environment = db.query(Environment).filter(
        Environment.id == environment_id,
        Environment.is_active == True
    ).first()
    if not environment:
        raise HTTPException(status_code=404, detail="Ambiente no encontrado")

    # Obtener horarios del ambiente
    schedules = db.query(Schedule).filter(
        Schedule.environment_id == environment_id,
        Schedule.is_active == True
    ).all()

    return schedules