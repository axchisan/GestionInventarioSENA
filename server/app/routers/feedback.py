from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from typing import List, Optional
from uuid import UUID
from datetime import datetime
import uuid

from ..database import get_db
from ..models.feedback import Feedback
from ..models.users import User
from ..routers.auth import get_current_user
from pydantic import BaseModel

router = APIRouter(tags=["feedback"])

class FeedbackCreate(BaseModel):
    type: str  # 'bug', 'suggestion', 'feature', 'compliment', 'complaint', 'other'
    category: Optional[str] = None
    title: str
    description: str
    steps_to_reproduce: Optional[str] = None
    priority: str = "medium"  # 'low', 'medium', 'high'
    rating: Optional[int] = None
    include_device_info: bool = False
    include_logs: bool = False
    allow_follow_up: bool = True

class FeedbackResponse(BaseModel):
    id: UUID
    user_id: UUID
    type: str
    category: Optional[str]
    title: str
    description: str
    steps_to_reproduce: Optional[str]
    priority: str
    rating: Optional[int]
    status: str
    admin_response: Optional[str]
    include_device_info: bool
    include_logs: bool
    allow_follow_up: bool
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True

class FeedbackUpdateRequest(BaseModel):
    status: Optional[str] = None
    admin_response: Optional[str] = None
    priority: Optional[str] = None

@router.post("/", response_model=FeedbackResponse, status_code=status.HTTP_201_CREATED)
async def create_feedback(
    feedback_data: FeedbackCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Create new feedback submission"""
    
    # Validate type
    valid_types = ['bug', 'suggestion', 'feature', 'compliment', 'complaint', 'other']
    if feedback_data.type not in valid_types:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Tipo inválido. Debe ser uno de: {', '.join(valid_types)}"
        )
    
    # Validate priority
    valid_priorities = ['low', 'medium', 'high']
    if feedback_data.priority not in valid_priorities:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Prioridad inválida. Debe ser uno de: {', '.join(valid_priorities)}"
        )
    
    # Validate rating if provided
    if feedback_data.rating is not None and (feedback_data.rating < 1 or feedback_data.rating > 5):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="La calificación debe estar entre 1 y 5"
        )
    
    new_feedback = Feedback(
        id=uuid.uuid4(),
        user_id=current_user.id,
        type=feedback_data.type,
        category=feedback_data.category,
        title=feedback_data.title,
        description=feedback_data.description,
        steps_to_reproduce=feedback_data.steps_to_reproduce,
        priority=feedback_data.priority,
        rating=feedback_data.rating,
        status="submitted",
        include_device_info=feedback_data.include_device_info,
        include_logs=feedback_data.include_logs,
        allow_follow_up=feedback_data.allow_follow_up,
        created_at=datetime.utcnow(),
        updated_at=datetime.utcnow()
    )
    
    db.add(new_feedback)
    db.commit()
    db.refresh(new_feedback)
    
    return new_feedback

@router.get("/", response_model=List[FeedbackResponse])
async def get_user_feedback(
    skip: int = Query(0, ge=0),
    limit: int = Query(10, ge=1, le=100),
    type: Optional[str] = Query(None),
    status: Optional[str] = Query(None),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get feedback submissions for current user"""
    
    query = db.query(Feedback).filter(Feedback.user_id == current_user.id)
    
    if type:
        query = query.filter(Feedback.type == type)
    
    if status:
        query = query.filter(Feedback.status == status)
    
    # Order by most recent first
    query = query.order_by(Feedback.created_at.desc())
    
    # Apply pagination
    feedbacks = query.offset(skip).limit(limit).all()
    
    return feedbacks

@router.get("/all", response_model=List[FeedbackResponse])
async def get_all_feedback(
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=200),
    type: Optional[str] = Query(None),
    status: Optional[str] = Query(None),
    priority: Optional[str] = Query(None),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get all feedback submissions (admin_general only)"""
    
    if current_user.role != "admin_general":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Solo el administrador general puede ver todos los comentarios"
        )
    
    query = db.query(Feedback)
    
    if type:
        query = query.filter(Feedback.type == type)
    
    if status:
        query = query.filter(Feedback.status == status)
    
    if priority:
        query = query.filter(Feedback.priority == priority)
    
    # Order by priority and date
    query = query.order_by(
        Feedback.priority.desc(),
        Feedback.created_at.desc()
    )
    
    # Apply pagination
    feedbacks = query.offset(skip).limit(limit).all()
    
    return feedbacks

@router.get("/{feedback_id}", response_model=FeedbackResponse)
async def get_feedback(
    feedback_id: UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get specific feedback by ID"""
    
    feedback = db.query(Feedback).filter(Feedback.id == feedback_id).first()
    
    if not feedback:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Comentario no encontrado"
        )
    
    # Users can only see their own feedback, unless they're admin_general
    if feedback.user_id != current_user.id and current_user.role != "admin_general":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="No tienes permiso para ver este comentario"
        )
    
    return feedback

@router.put("/{feedback_id}", response_model=FeedbackResponse)
async def update_feedback(
    feedback_id: UUID,
    update_data: FeedbackUpdateRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Update feedback (admin_general only)"""
    
    if current_user.role != "admin_general":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Solo el administrador general puede actualizar comentarios"
        )
    
    feedback = db.query(Feedback).filter(Feedback.id == feedback_id).first()
    
    if not feedback:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Comentario no encontrado"
        )
    
    # Update fields if provided
    update_dict = update_data.dict(exclude_unset=True)
    for field, value in update_dict.items():
        setattr(feedback, field, value)
    
    feedback.updated_at = datetime.utcnow()
    db.commit()
    db.refresh(feedback)
    
    return feedback

@router.delete("/{feedback_id}")
async def delete_feedback(
    feedback_id: UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Delete feedback"""
    
    feedback = db.query(Feedback).filter(Feedback.id == feedback_id).first()
    
    if not feedback:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Comentario no encontrado"
        )
    
    # Users can delete their own feedback, or admin_general can delete any
    if feedback.user_id != current_user.id and current_user.role != "admin_general":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="No tienes permiso para eliminar este comentario"
        )
    
    db.delete(feedback)
    db.commit()
    
    return {"message": "Comentario eliminado exitosamente"}
