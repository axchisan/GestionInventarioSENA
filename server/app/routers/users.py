from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from pydantic import BaseModel
from datetime import datetime
from uuid import UUID
import uuid

from ..database import get_db
from ..models.environments import Environment
from ..models.users import User
from ..schemas.user import UserResponse
from ..routers.auth import get_current_user, oauth2_scheme
from ..config import settings
from jose import JWTError, jwt

router = APIRouter(tags=["users"])

class LinkEnvironmentRequest(BaseModel):
    environment_id: UUID

@router.post("/link-environment")
async def link_environment(
    request: LinkEnvironmentRequest,
    db: Session = Depends(get_db),
    token: str = Depends(oauth2_scheme)
):
    # Decodificar el token para obtener el user_id
    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        user_id: str = payload.get("sub")
        if user_id is None:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Token inválido",
                headers={"WWW-Authenticate": "Bearer"},
            )
    except JWTError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token inválido o expirado",
            headers={"WWW-Authenticate": "Bearer"},
        )

    # Obtener el usuario desde la base de datos
    current_user = db.query(User).filter(User.id == uuid.UUID(user_id)).first()
    if not current_user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Usuario no encontrado")

    # Verificar permisos
    if current_user.role not in ["instructor", "student", "supervisor"]:
        raise HTTPException(
            status_code=403,
            detail="Rol no autorizado para vincular ambientes"
        )

    # Verificar el ambiente
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
        "user": UserResponse.from_orm(current_user)
    }