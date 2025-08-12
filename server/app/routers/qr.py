from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from sqlalchemy.orm import Session
from typing import Literal
from datetime import datetime
from uuid import UUID
import hashlib
import json

from ..database import get_db
from ..models.inventory_items import InventoryItem
from ..models.environments import Environment
from ..models.users import User
from ..schemas.user import UserResponse  # Importar UserResponse
from ..routers.auth import get_current_user
from ..config import settings

router = APIRouter(tags=["qr"])

def compute_signature(type: str, id: str, code: str, ts: int) -> str:
    raw = f"{type}:{id}:{code}:{ts}:{settings.SECRET_KEY}"
    return hashlib.sha256(raw.encode()).hexdigest()

@router.get("/generate/{entity_type}/{entity_id}")
def generate_qr(
    entity_type: Literal["environment", "item"],
    entity_id: UUID,
    db: Session = Depends(get_db)
):
    ts = int(datetime.now().timestamp())
    payload = {"v": 1, "type": entity_type, "id": str(entity_id), "ts": ts}

    if entity_type == "environment":
        entity = db.query(Environment).filter(
            Environment.id == entity_id,
            Environment.is_active == True
        ).first()
        if not entity:
            raise HTTPException(status_code=404, detail="Ambiente no encontrado")
        payload["code"] = entity.qr_code
        payload["name"] = entity.name
        payload["location"] = entity.location
    else:  # item
        entity = db.query(InventoryItem).filter(
            InventoryItem.id == entity_id,
            InventoryItem.status != "lost"
        ).first()
        if not entity:
            raise HTTPException(status_code=404, detail="Ítem no encontrado")
        payload["code"] = entity.internal_code
        payload["name"] = entity.name
        payload["category"] = entity.category

    payload["sig"] = compute_signature(
        type=entity_type,
        id=str(entity_id),
        code=payload["code"],
        ts=ts
    )

    return {"qr_data": json.dumps(payload)}

# Esquema para el payload del QR
class QRScanRequest(BaseModel):
    qr_data: str

# Función para validar la firma del QR
def validate_signature(type: str, id: str, code: str, ts: int, sig: str) -> bool:
    expected_sig = hashlib.sha256(
        f"{type}:{id}:{code}:{ts}:{settings.SECRET_KEY}".encode()
    ).hexdigest()
    return sig == expected_sig

@router.post("/scan")
async def scan_qr(
    request: QRScanRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    try:
        # Decodificar el JSON del QR
        qr_payload = json.loads(request.qr_data)
        if qr_payload.get("v") != 1:
            raise HTTPException(status_code=400, detail="Versión de QR no soportada")

        # Extraer datos del payload
        qr_type = qr_payload.get("type")
        entity_id = qr_payload.get("id")
        code = qr_payload.get("code")
        ts = qr_payload.get("ts")
        sig = qr_payload.get("sig")

        if not all([qr_type, entity_id, code, ts, sig]):
            raise HTTPException(status_code=400, detail="Datos del QR incompletos")

        # Validar la firma
        if not validate_signature(qr_type, entity_id, code, ts, sig):
            raise HTTPException(status_code=400, detail="Firma del QR inválida")

        # Verificar tipo de QR
        if qr_type != "environment":
            raise HTTPException(status_code=400, detail="Solo se soportan QR de ambientes")

        # Buscar el ambiente en la base de datos
        environment = db.query(Environment).filter(
            Environment.id == UUID(entity_id),
            Environment.is_active == True
        ).first()
        if not environment:
            raise HTTPException(status_code=404, detail="Ambiente no encontrado")

        # Verificar permisos según el rol del usuario
        if current_user.role not in ["instructor", "student", "supervisor"]:
            raise HTTPException(
                status_code=403,
                detail="Rol no autorizado para vincular ambientes"
            )

        # Actualizar el environment_id del usuario
        current_user.environment_id = environment.id
        current_user.updated_at = datetime.utcnow()
        db.commit()
        db.refresh(current_user)  # Ahora funciona porque current_user es un modelo User

        # Devolver información del ambiente
        return {
            "status": "success",
            "environment": {
                "id": str(environment.id),
                "name": environment.name,
                "location": environment.location,
                "qr_code": environment.qr_code
            },
            "user": UserResponse.from_orm(current_user)  # Convertir a Pydantic para la respuesta
        }

    except json.JSONDecodeError:
        raise HTTPException(status_code=400, detail="Formato de QR inválido")
    except ValueError:
        raise HTTPException(status_code=400, detail="ID de ambiente inválido")