from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import Literal
from datetime import datetime
from uuid import UUID
import hashlib
import json

from ..database import get_db
from ..models.environments import Environment
from ..models.inventory_items import InventoryItem
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