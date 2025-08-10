from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from uuid import UUID

from ..database import get_db
from ..models.inventory_items import InventoryItem
from ..schemas.inventory_item import InventoryItemResponse  # Necesitaremos crear este esquema

router = APIRouter(prefix="/api/inventory", tags=["inventory"])

@router.get("/", response_model=List[InventoryItemResponse])
def get_inventory_items(db: Session = Depends(get_db), search: str = ""):
    query = db.query(InventoryItem).filter(InventoryItem.status != "lost")
    if search:
        search = search.lower()
        query = query.filter(
            (InventoryItem.name.ilike(f"%{search}%")) |
            (InventoryItem.internal_code.ilike(f"%{search}%")) |
            (InventoryItem.category.ilike(f"%{search}%"))
        )
    items = query.all()
    if not items:
        raise HTTPException(status_code=404, detail="No se encontraron ítems")
    return items

@router.get("/{item_id}", response_model=InventoryItemResponse)
def get_inventory_item(item_id: UUID, db: Session = Depends(get_db)):
    item = db.query(InventoryItem).filter(
        InventoryItem.id == item_id,
        InventoryItem.status != "lost"
    ).first()
    if not item:
        raise HTTPException(status_code=404, detail="Ítem no encontrado")
    return item