from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import Optional
import uuid

from ..database import get_db
from ..models.user_settings import UserSetting
from ..models.users import User
from ..schemas.user_settings import UserSettingCreate, UserSettingUpdate, UserSettingResponse
from .auth import get_current_user

router = APIRouter(prefix="/api/settings", tags=["settings"])

@router.get("/{user_id}", response_model=UserSettingResponse)
async def get_user_settings(
    user_id: uuid.UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get user settings by user ID"""
    # Check if user can access these settings (own settings or admin)
    if current_user.id != user_id and current_user.role not in ['admin', 'admin_general', 'supervisor']:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to access these settings"
        )
    
    settings = db.query(UserSetting).filter(UserSetting.user_id == user_id).first()
    
    if not settings:
        # Create default settings if they don't exist
        settings = UserSetting(user_id=user_id)
        db.add(settings)
        db.commit()
        db.refresh(settings)
    
    return settings

@router.get("/", response_model=UserSettingResponse)
async def get_current_user_settings(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get current user's settings"""
    return await get_user_settings(current_user.id, db, current_user)

@router.put("/{user_id}", response_model=UserSettingResponse)
async def update_user_settings(
    user_id: uuid.UUID,
    settings_update: UserSettingUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Update user settings"""
    # Check if user can update these settings
    if current_user.id != user_id and current_user.role not in ['admin', 'admin_general']:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to update these settings"
        )
    
    settings = db.query(UserSetting).filter(UserSetting.user_id == user_id).first()
    
    if not settings:
        # Create new settings if they don't exist
        settings_data = settings_update.dict(exclude_unset=True)
        settings_data['user_id'] = user_id
        settings = UserSetting(**settings_data)
        db.add(settings)
    else:
        # Update existing settings
        for field, value in settings_update.dict(exclude_unset=True).items():
            setattr(settings, field, value)
    
    db.commit()
    db.refresh(settings)
    return settings

@router.put("/", response_model=UserSettingResponse)
async def update_current_user_settings(
    settings_update: UserSettingUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Update current user's settings"""
    return await update_user_settings(current_user.id, settings_update, db, current_user)

@router.post("/", response_model=UserSettingResponse)
async def create_user_settings(
    settings_create: UserSettingCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Create new user settings"""
    # Check if settings already exist
    existing_settings = db.query(UserSetting).filter(
        UserSetting.user_id == settings_create.user_id
    ).first()
    
    if existing_settings:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Settings already exist for this user"
        )
    
    # Check authorization
    if current_user.id != settings_create.user_id and current_user.role not in ['admin', 'admin_general']:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to create settings for this user"
        )
    
    settings = UserSetting(**settings_create.dict())
    db.add(settings)
    db.commit()
    db.refresh(settings)
    return settings

@router.delete("/{user_id}")
async def delete_user_settings(
    user_id: uuid.UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Delete user settings (admin only)"""
    if current_user.role not in ['admin', 'admin_general']:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to delete settings"
        )
    
    settings = db.query(UserSetting).filter(UserSetting.user_id == user_id).first()
    
    if not settings:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Settings not found"
        )
    
    db.delete(settings)
    db.commit()
    return {"message": "Settings deleted successfully"}
