from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List, Optional
from uuid import UUID

from ..database import get_db
from ..models.schedules import Schedule
from ..models.environments import Environment
from ..schemas.schedule import ScheduleResponse, ScheduleCreate, ScheduleUpdate
from ..routers.auth import get_current_user
from ..models.users import User

router = APIRouter(tags=["schedules"])

@router.get("/", response_model=List[ScheduleResponse])
async def get_schedules(
    environment_id: Optional[UUID] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    if current_user.role not in ["instructor", "student", "supervisor", "admin", "admin_general"]:
        raise HTTPException(
            status_code=403,
            detail="Rol no autorizado para consultar horarios"
        )

    if not environment_id and current_user.environment_id:
        environment_id = current_user.environment_id

    if environment_id:
        environment = db.query(Environment).filter(
            Environment.id == environment_id,
            Environment.is_active == True
        ).first()
        if not environment:
            raise HTTPException(status_code=404, detail="Ambiente no encontrado")

        schedules = db.query(Schedule).filter(
            Schedule.environment_id == environment_id,
            Schedule.is_active == True
        ).all()
    else:
        if not current_user.environment_id:
            raise HTTPException(
                status_code=400,
                detail="No se ha vinculado un ambiente al usuario"
            )
        schedules = db.query(Schedule).filter(
            Schedule.environment_id == current_user.environment_id,
            Schedule.is_active == True
        ).all()

    return schedules

@router.post("/", response_model=ScheduleResponse, status_code=status.HTTP_201_CREATED)
async def create_schedule(
    schedule_data: ScheduleCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    if current_user.role not in ["instructor", "supervisor", "admin"]:
        raise HTTPException(status_code=403, detail="Rol no autorizado para crear horarios")

    new_schedule = Schedule(**schedule_data.dict())
    db.add(new_schedule)
    db.commit()
    db.refresh(new_schedule)
    return new_schedule

@router.put("/{schedule_id}", response_model=ScheduleResponse)
async def update_schedule(
    schedule_id: UUID,
    schedule_data: ScheduleUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    if current_user.role not in ["instructor", "supervisor", "admin"]:
        raise HTTPException(status_code=403, detail="Rol no autorizado para editar horarios")

    schedule = db.query(Schedule).filter(Schedule.id == schedule_id).first()
    if not schedule:
        raise HTTPException(status_code=404, detail="Horario no encontrado")

    update_data = schedule_data.dict(exclude_unset=True)
    for key, value in update_data.items():
        setattr(schedule, key, value)

    db.commit()
    db.refresh(schedule)
    return schedule

@router.delete("/{schedule_id}")
async def delete_schedule(
    schedule_id: UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    if current_user.role not in ["instructor", "supervisor", "admin"]:
        raise HTTPException(status_code=403, detail="Rol no autorizado para eliminar horarios")

    schedule = db.query(Schedule).filter(Schedule.id == schedule_id).first()
    if not schedule:
        raise HTTPException(status_code=404, detail="Horario no encontrado")

    db.delete(schedule)
    db.commit()
    return {"status": "success", "detail": "Horario eliminado"}