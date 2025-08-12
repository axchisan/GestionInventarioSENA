from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from sqlalchemy.orm import Session
from typing import Literal
from datetime import datetime
from uuid import UUID
import hashlib
import json
import logging

from ..database import get_db
from ..models.inventory_items import InventoryItem
from ..models.environments import Environment
from ..models.users import User
from ..schemas.user import UserResponse
from ..routers.auth import get_current_user
from ..config import settings

router = APIRouter(tags=["qr"])

# Configurar logging
logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)

def compute_signature(type: str, id: str, code: str, ts: int) -> str:
    raw = f"{type}:{id}:{code}:{ts}:{settings.SECRET_KEY}"
    logger.debug(f"Computing signature with raw string: {raw}")
    signature = hashlib.sha256(raw.encode()).hexdigest()
    logger.debug(f"Generated signature: {signature}")
    return signature

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

class QRScanRequest(BaseModel):
    qr_data: str

def validate_signature(type: str, id: str, code: str, ts: int, sig: str) -> bool:
    raw = f"{type}:{id}:{code}:{ts}:{settings.SECRET_KEY}"
    logger.debug(f"Validating signature with raw string: {raw}")
    expected_sig = hashlib.sha256(raw.encode()).hexdigest()
    logger.debug(f"Expected signature: {expected_sig}, Received signature: {sig}")
    return sig == expected_sig

@router.post("/scan")
async def scan_qr(
    request: QRScanRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    try:
        qr_payload = json.loads(request.qr_data)
        logger.debug(f"QR payload received: {qr_payload}")
        if qr_payload.get("v") != 1:
            raise HTTPException(status_code=400, detail="Versión de QR no soportada")

        qr_type = qr_payload.get("type")
        entity_id = qr_payload.get("id")
        code = qr_payload.get("code")
        ts = qr_payload.get("ts")
        sig = qr_payload.get("sig")

        if not all([qr_type, entity_id, code, ts, sig]):
            raise HTTPException(status_code=400, detail="Datos del QR incompletos")

        if not validate_signature(qr_type, entity_id, code, ts, sig):
            raise HTTPException(status_code=400, detail="Firma del QR inválida")

        if qr_type != "environment":
            raise HTTPException(status_code=400, detail="Solo se soportan QR de ambientes")

        environment = db.query(Environment).filter(
            Environment.id == UUID(entity_id),
            Environment.is_active == True
        ).first()
        if not environment:
            raise HTTPException(status_code=404, detail="Ambiente no encontrado")

        if current_user.role not in ["instructor", "student", "supervisor"]:
            raise HTTPException(
                status_code=403,
                detail="Rol no autorizado para vincular ambientes"
            )

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

    except json.JSONDecodeError:
        raise HTTPException(status_code=400, detail="Formato de QR inválido")
    except ValueError:
        raise HTTPException(status_code=400, detail="ID de ambiente inválido")