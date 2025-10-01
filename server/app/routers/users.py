from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from sqlalchemy import func, and_, or_
from pydantic import BaseModel, EmailStr
from datetime import datetime
from uuid import UUID
from typing import Optional, List
import uuid
import bcrypt

from ..database import get_db
from ..models.environments import Environment
from ..models.users import User
from ..models.inventory_items import InventoryItem
from ..models.loans import Loan
from ..schemas.user import UserResponse, UserCreate
from ..routers.auth import oauth2_scheme, get_current_user
from ..config import settings
from jose import JWTError, jwt

router = APIRouter(tags=["users"])

class LinkEnvironmentRequest(BaseModel):
    environment_id: UUID

class UserUpdateRequest(BaseModel):
    first_name: Optional[str] = None
    last_name: Optional[str] = None
    phone: Optional[str] = None
    program: Optional[str] = None
    ficha: Optional[str] = None
    role: Optional[str] = None
    is_active: Optional[bool] = None
    environment_id: Optional[UUID] = None

class UserStatsResponse(BaseModel):
    total_users: int
    active_users: int
    inactive_users: int
    users_by_role: dict
    recent_registrations: int

@router.get("/", response_model=List[UserResponse])
async def get_users(
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=1000),
    role: Optional[str] = Query(None),
    is_active: Optional[bool] = Query(None),
    search: Optional[str] = Query(None),
    start_date: Optional[str] = Query(None),
    end_date: Optional[str] = Query(None),
    system_wide: Optional[bool] = Query(None),
    admin_access: Optional[bool] = Query(None),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get all users with filtering and pagination (admin_general only)"""
    if current_user.role != "admin_general":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Solo el administrador general puede acceder a todos los usuarios"
        )
    
    query = db.query(User)
    
    # Apply date filtering for statistics
    if start_date and end_date:
        try:
            start = datetime.fromisoformat(start_date)
            end = datetime.fromisoformat(end_date)
            query = query.filter(User.created_at.between(start, end))
        except ValueError:
            pass
    
    # Apply filters
    if role:
        query = query.filter(User.role == role)
    
    if is_active is not None:
        query = query.filter(User.is_active == is_active)
    
    if search:
        search_filter = or_(
            User.first_name.ilike(f"%{search}%"),
            User.last_name.ilike(f"%{search}%"),
            User.email.ilike(f"%{search}%")
        )
        query = query.filter(search_filter)
    
    # Apply pagination
    users = query.offset(skip).limit(limit).all()
    
    return [UserResponse.from_orm(user) for user in users]

@router.get("/stats", response_model=UserStatsResponse)
async def get_user_stats(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get user statistics (admin_general only)"""
    if current_user.role != "admin_general":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Solo el administrador general puede acceder a las estadísticas"
        )
    
    # Basic counts
    total_users = db.query(User).count()
    active_users = db.query(User).filter(User.is_active == True).count()
    inactive_users = total_users - active_users
    
    # Users by role
    roles = ['student', 'instructor', 'supervisor', 'admin', 'admin_general']
    users_by_role = {}
    for role in roles:
        count = db.query(User).filter(User.role == role).count()
        users_by_role[role] = count
    
    # Recent registrations (last 7 days)
    from datetime import timedelta
    week_ago = datetime.utcnow() - timedelta(days=7)
    recent_registrations = db.query(User).filter(User.created_at >= week_ago).count()
    
    return UserStatsResponse(
        total_users=total_users,
        active_users=active_users,
        inactive_users=inactive_users,
        users_by_role=users_by_role,
        recent_registrations=recent_registrations
    )

@router.get("/{user_id}", response_model=UserResponse)
async def get_user(
    user_id: UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get specific user by ID (admin_general only)"""
    if current_user.role != "admin_general":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Solo el administrador general puede acceder a información de usuarios"
        )
    
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")
    
    return UserResponse.from_orm(user)

@router.post("/", response_model=UserResponse)
async def create_user(
    user_data: UserCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Create new user (admin_general only)"""
    if current_user.role != "admin_general":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Solo el administrador general puede crear usuarios"
        )
    
    # Check if email already exists
    existing_user = db.query(User).filter(User.email == user_data.email).first()
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="El email ya está registrado"
        )
    
    # Hash password
    password_hash = bcrypt.hashpw(user_data.password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')
    
    # Create user
    new_user = User(
        id=uuid.uuid4(),
        email=user_data.email,
        password_hash=password_hash,
        first_name=user_data.first_name,
        last_name=user_data.last_name,
        role=user_data.role,
        phone=user_data.phone,
        program=user_data.program,
        ficha=user_data.ficha,
        avatar_url=user_data.avatar_url,
        is_active=True,
        created_at=datetime.utcnow(),
        updated_at=datetime.utcnow()
    )
    
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    
    return UserResponse.from_orm(new_user)

@router.put("/{user_id}", response_model=UserResponse)
async def update_user(
    user_id: UUID,
    user_data: UserUpdateRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Update user (admin_general only)"""
    if current_user.role != "admin_general":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Solo el administrador general puede actualizar usuarios"
        )
    
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")
    
    # Update fields if provided
    update_data = user_data.dict(exclude_unset=True)
    for field, value in update_data.items():
        setattr(user, field, value)
    
    user.updated_at = datetime.utcnow()
    db.commit()
    db.refresh(user)
    
    return UserResponse.from_orm(user)

@router.delete("/{user_id}")
async def delete_user(
    user_id: UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Soft delete user (deactivate) (admin_general only)"""
    if current_user.role != "admin_general":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Solo el administrador general puede eliminar usuarios"
        )
    
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")
    
    # Soft delete by deactivating
    user.is_active = False
    user.updated_at = datetime.utcnow()
    db.commit()
    
    return {"message": "Usuario desactivado exitosamente"}

@router.post("/{user_id}/activate")
async def activate_user(
    user_id: UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Activate/reactivate user (admin_general only)"""
    if current_user.role != "admin_general":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Solo el administrador general puede activar usuarios"
        )
    
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")
    
    user.is_active = True
    user.updated_at = datetime.utcnow()
    db.commit()
    
    return {"message": "Usuario activado exitosamente"}

@router.post("/link-environment")
async def link_environment(
    request: LinkEnvironmentRequest,
    db: Session = Depends(get_db),
    token: str = Depends(oauth2_scheme)
):
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

    current_user = db.query(User).filter(User.id == uuid.UUID(user_id)).first()
    if not current_user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Usuario no encontrado")

    if current_user.role not in ["instructor", "student", "supervisor"]:
        raise HTTPException(
            status_code=403,
            detail="Rol no autorizado para vincular ambientes"
        )

    environment = db.query(Environment).filter(
        Environment.id == request.environment_id,
        Environment.is_active == True
    ).first()
    if not environment:
        raise HTTPException(status_code=404, detail="Ambiente no encontrado")

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
