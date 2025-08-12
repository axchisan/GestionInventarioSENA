from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from pydantic import BaseModel
from datetime import datetime
from uuid import UUID

from ..database import get_db
from ..models.environments import Environment
from ..models.users import User
from ..routers.auth import get_current_user

router = APIRouter(tags=["users"])

class LinkEnvironmentRequest(BaseModel):
    environment_id: UUID

@router.post("/link-environment")
async def link_environment(
    request: LinkEnvironmentRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    # Verificar permisos según el rol
    if current_user.role not in ["instructor", "student", "supervisor"]:
        raise HTTPException(
            status_code=403,
            detail="Rol no autorizado para vincular ambientes"
        )

    # Buscar el ambiente
    environment = db.query(Environment).filter(
        Environment.id == request.environment_id,
        Environment.is_active == True
    ).first()
    if not environment:
        raise HTTPException(status_code=404, detail="Ambiente no encontrado")

    # Actualizar el environment_id del usuario
    current_user.environment_id = environment.id
    current_user.updated_at = datetime.utcnow()
    db.commit()
    db.refresh(current_user)

    return {
        "status": "success",
        "environment": {
            "id": str(environment.id),
            "name": environment.name,
            "location": environment.location,
            "qr_code": environment.qr_code
        },
        "user": {
            "id": str(current_user.id),
            "role": current_user.role,
            "first_name": current_user.first_name,
            "last_name": current_user.last_name
        }
    }