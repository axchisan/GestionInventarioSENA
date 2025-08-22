from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List, Optional
from uuid import UUID

from ..database import get_db
from ..models.inventory_items import InventoryItem
from ..schemas.inventory_item import InventoryItemCreate, InventoryItemResponse, InventoryItemUpdate, InventoryItemUpdate
from ..routers.auth import get_current_user
from ..models.users import User

router = APIRouter(tags=["inventory"])

@router.get("/", response_model=List[InventoryItemResponse])
def get_inventory_items(
    db: Session = Depends(get_db),
    search: str = "",
    environment_id: Optional[UUID] = None,
    current_user: User = Depends(get_current_user)
):
    query = db.query(InventoryItem).filter(InventoryItem.status != "lost")
    if environment_id:
        query = query.filter(InventoryItem.environment_id == environment_id)
    elif current_user.environment_id:
        query = query.filter(InventoryItem.environment_id == current_user.environment_id)
    else:
        raise HTTPException(
            status_code=400,
            detail="No se ha vinculado un ambiente al usuario"
        )

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

@router.post("/", response_model=InventoryItemResponse)
def add_inventory_item(
    item_data: InventoryItemCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    if current_user.role not in ["supervisor", "admin", "admin_general"]:
        raise HTTPException(status_code=403, detail="Rol no autorizado para agregar ítems")

    new_item = InventoryItem(**item_data.dict())
    db.add(new_item)
    db.commit()
    db.refresh(new_item)
    return new_item

@router.put("/{item_id}", response_model=InventoryItemResponse)
def update_inventory_item(
    item_id: UUID,
    item_data: InventoryItemUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    if current_user.role not in ["supervisor", "admin", "admin_general"]:
        raise HTTPException(status_code=403, detail="Rol no autorizado para editar ítems")

    item = db.query(InventoryItem).filter(InventoryItem.id == item_id).first()
    if not item:
        raise HTTPException(status_code=404, detail="Ítem no encontrado")

    update_data = item_data.dict(exclude_unset=True)
    for key, value in update_data.items():
        setattr(item, key, value)

    db.commit()
    db.refresh(item)
    return item

@router.delete("/{item_id}")
def delete_inventory_item(
    item_id: UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    if current_user.role not in ["supervisor", "admin", "admin_general"]:
        raise HTTPException(
            status_code=403,
            detail="Rol no autorizado para eliminar ítems"
        )
    
    item = db.query(InventoryItem).filter(InventoryItem.id == item_id).first()
    if not item:
        raise HTTPException(status_code=404, detail="Ítem no encontrado")
    
    db.delete(item)
    db.commit()
    return {"status": "success", "detail": "Ítem eliminado"}