from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from uuid import UUID

from ..database import get_db
from ..models.environments import Environment
from ..schemas.environment import EnvironmentResponse

router = APIRouter(tags=["environments"])

@router.get("/", response_model=List[EnvironmentResponse])
def get_environments(db: Session = Depends(get_db), search: str = ""):
    query = db.query(Environment).filter(Environment.is_active == True)
    if search:
        search = search.lower()
        query = query.filter(
            (Environment.name.ilike(f"%{search}%")) |
            (Environment.location.ilike(f"%{search}%")) |
            (Environment.qr_code.ilike(f"%{search}%"))
        )
    environments = query.all()
    if not environments:
        raise HTTPException(status_code=404, detail="No se encontraron ambientes")
    return environments

@router.get("/{environment_id}", response_model=EnvironmentResponse)
def get_environment(environment_id: UUID, db: Session = Depends(get_db)):
    environment = db.query(Environment).filter(
        Environment.id == environment_id,
        Environment.is_active == True
    ).first()
    if not environment:
        raise HTTPException(status_code=404, detail="Ambiente no encontrado")
    return environment