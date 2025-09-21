from fastapi import APIRouter, Depends, HTTPException, Query, Request
from sqlalchemy.orm import Session, joinedload
from sqlalchemy import desc, func, and_, or_
from typing import List, Optional
from datetime import date, datetime, timedelta
from uuid import UUID

from ..database import get_db
from ..models.audit_logs import AuditLog
from ..models.users import User
from ..schemas.audit_log import (
    AuditLogCreate,
    AuditLogResponse, 
    AuditLogListResponse,
    AuditLogStatsResponse
)
from ..services.audit_service import AuditService
from ..routers.auth import get_current_user

router = APIRouter()

@router.get("/", response_model=AuditLogListResponse)
async def get_audit_logs(
    page: int = Query(1, ge=1),
    per_page: int = Query(20, ge=1, le=100),
    action_filter: Optional[str] = Query(None),
    user_id: Optional[UUID] = Query(None),
    entity_type: Optional[str] = Query(None),
    start_date: Optional[date] = Query(None),
    end_date: Optional[date] = Query(None),
    search: Optional[str] = Query(None),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get audit logs with filtering and pagination - Admin General only"""
    
    if current_user.role != "admin_general":
        raise HTTPException(
            status_code=403,
            detail="Only general administrators can access audit logs"
        )
    
    # Preparar filtros
    filters = {}
    if action_filter:
        filters['action'] = action_filter
    if user_id:
        filters['user_id'] = user_id
    if entity_type:
        filters['entity_type'] = entity_type
    if start_date:
        filters['start_date'] = start_date
    if end_date:
        filters['end_date'] = end_date
    if search:
        filters['search'] = search
    
    # Obtener logs usando el servicio
    logs, total = AuditService.get_audit_logs_paginated(
        db=db,
        page=page,
        per_page=per_page,
        filters=filters
    )
    
    # Construir respuesta con información de usuario
    log_responses = []
    for log in logs:
        log_data = AuditLogResponse.from_orm(log)
        if log.user:
            log_data.user_name = f"{log.user.first_name} {log.user.last_name}"
            log_data.user_email = log.user.email
        log_responses.append(log_data)
    
    total_pages = (total + per_page - 1) // per_page
    
    return AuditLogListResponse(
        logs=log_responses,
        total=total,
        page=page,
        per_page=per_page,
        total_pages=total_pages
    )

@router.get("/stats", response_model=AuditLogStatsResponse)
async def get_audit_stats(
    days: int = Query(30, ge=1, le=365),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get audit statistics - Admin General only"""
    
    if current_user.role != "admin_general":
        raise HTTPException(
            status_code=403,
            detail="Only general administrators can access audit statistics"
        )
    
    stats = AuditService.get_audit_statistics(db=db, days=days)
    
    return AuditLogStatsResponse(
        total_logs=stats['total_logs'],
        today_logs=stats['today_logs'],
        warning_logs=stats['warning_logs'],
        error_logs=stats['error_logs'],
        info_logs=stats['info_logs'],
        success_logs=stats['success_logs'],
        top_actions=stats['top_actions'],
        top_users=stats['top_users']
    )

@router.get("/user/{user_id}/activity")
async def get_user_activity(
    user_id: UUID,
    days: int = Query(30, ge=1, le=365),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get specific user activity - Admin General only"""
    
    if current_user.role != "admin_general":
        raise HTTPException(
            status_code=403,
            detail="Only general administrators can access user activity"
        )
    
    activity = AuditService.get_user_activity(db=db, user_id=user_id, days=days)
    return activity

@router.get("/entity/{entity_type}/{entity_id}/trail")
async def get_entity_audit_trail(
    entity_type: str,
    entity_id: UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get complete audit trail for a specific entity - Admin General only"""
    
    if current_user.role != "admin_general":
        raise HTTPException(
            status_code=403,
            detail="Only general administrators can access entity audit trails"
        )
    
    logs = AuditService.get_entity_audit_trail(
        db=db,
        entity_type=entity_type,
        entity_id=entity_id
    )
    
    log_responses = []
    for log in logs:
        log_data = AuditLogResponse.from_orm(log)
        if log.user:
            log_data.user_name = f"{log.user.first_name} {log.user.last_name}"
            log_data.user_email = log.user.email
        log_responses.append(log_data)
    
    return log_responses

@router.get("/{log_id}", response_model=AuditLogResponse)
async def get_audit_log(
    log_id: UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get a specific audit log by ID - Admin General only"""
    
    if current_user.role != "admin_general":
        raise HTTPException(
            status_code=403,
            detail="Only general administrators can access audit logs"
        )
    
    log = db.query(AuditLog).options(joinedload(AuditLog.user)).filter(
        AuditLog.id == log_id
    ).first()
    
    if not log:
        raise HTTPException(
            status_code=404,
            detail="Audit log not found"
        )
    
    log_data = AuditLogResponse.from_orm(log)
    if log.user:
        log_data.user_name = f"{log.user.first_name} {log.user.last_name}"
        log_data.user_email = log.user.email
    
    return log_data

@router.post("/", response_model=AuditLogResponse)
async def create_audit_log(
    audit_data: AuditLogCreate,
    request: Request,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Create a new audit log entry - Internal use"""
    
    # Crear log usando el servicio
    audit_log = AuditService.create_audit_log(
        db=db,
        audit_data=audit_data,
        ip_address=request.client.host,
        user_agent=request.headers.get("user-agent", "")
    )
    
    # Cargar información del usuario para la respuesta
    log_with_user = db.query(AuditLog).options(joinedload(AuditLog.user)).filter(
        AuditLog.id == audit_log.id
    ).first()
    
    log_data = AuditLogResponse.from_orm(log_with_user)
    if log_with_user.user:
        log_data.user_name = f"{log_with_user.user.first_name} {log_with_user.user.last_name}"
        log_data.user_email = log_with_user.user.email
    
    return log_data

@router.delete("/cleanup")
async def cleanup_old_logs(
    days_to_keep: int = Query(90, ge=30, le=365),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Cleanup old audit logs - Admin General only"""
    
    if current_user.role != "admin_general":
        raise HTTPException(
            status_code=403,
            detail="Only general administrators can cleanup audit logs"
        )
    
    deleted_count = AuditService.cleanup_old_logs(db=db, days_to_keep=days_to_keep)
    
    return {
        "message": f"Successfully deleted {deleted_count} old audit logs",
        "deleted_count": deleted_count,
        "days_kept": days_to_keep
    }
