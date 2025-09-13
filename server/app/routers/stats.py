from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import func, and_
from uuid import UUID
from datetime import datetime, date, timedelta
from typing import Optional

from ..database import get_db
from ..models.inventory_checks import InventoryCheck
from ..models.inventory_items import InventoryItem
from ..models.maintenance_requests import MaintenanceRequest
from ..models.environments import Environment
from ..models.users import User
from ..routers.auth import get_current_user

router = APIRouter(tags=["stats"])

@router.get("/dashboard")
def get_dashboard_stats(
    environment_id: Optional[UUID] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get general dashboard statistics"""
    
    # Base query filters
    inventory_query = db.query(InventoryItem)
    checks_query = db.query(InventoryCheck)
    maintenance_query = db.query(MaintenanceRequest)
    
    if environment_id:
        inventory_query = inventory_query.filter(InventoryItem.environment_id == environment_id)
        checks_query = checks_query.filter(InventoryCheck.environment_id == environment_id)
        maintenance_query = maintenance_query.filter(MaintenanceRequest.environment_id == environment_id)
    elif current_user.environment_id:
        inventory_query = inventory_query.filter(InventoryItem.environment_id == current_user.environment_id)
        checks_query = checks_query.filter(InventoryCheck.environment_id == current_user.environment_id)
        maintenance_query = maintenance_query.filter(MaintenanceRequest.environment_id == current_user.environment_id)
    
    # Inventory statistics
    total_items = inventory_query.count()
    available_items = inventory_query.filter(InventoryItem.status == 'available').count()
    in_use_items = inventory_query.filter(InventoryItem.status == 'in_use').count()
    maintenance_items = inventory_query.filter(InventoryItem.status == 'maintenance').count()
    damaged_items = inventory_query.filter(InventoryItem.status == 'damaged').count()
    
    # Total quantities including group items
    total_quantity = db.query(func.sum(InventoryItem.quantity)).filter(
        InventoryItem.environment_id == (environment_id or current_user.environment_id)
    ).scalar() or 0
    
    damaged_quantity = db.query(func.sum(InventoryItem.quantity_damaged)).filter(
        InventoryItem.environment_id == (environment_id or current_user.environment_id)
    ).scalar() or 0
    
    missing_quantity = db.query(func.sum(InventoryItem.quantity_missing)).filter(
        InventoryItem.environment_id == (environment_id or current_user.environment_id)
    ).scalar() or 0
    
    # Verification statistics (last 30 days)
    thirty_days_ago = date.today() - timedelta(days=30)
    recent_checks = checks_query.filter(InventoryCheck.check_date >= thirty_days_ago).count()
    completed_checks = checks_query.filter(
        and_(InventoryCheck.check_date >= thirty_days_ago, InventoryCheck.status == 'complete')
    ).count()
    
    # Maintenance statistics
    pending_maintenance = maintenance_query.filter(MaintenanceRequest.status == 'pending').count()
    in_progress_maintenance = maintenance_query.filter(MaintenanceRequest.status == 'in_progress').count()
    
    return {
        "inventory": {
            "total_items": total_items,
            "total_quantity": total_quantity,
            "available_items": available_items,
            "in_use_items": in_use_items,
            "maintenance_items": maintenance_items,
            "damaged_items": damaged_items,
            "damaged_quantity": damaged_quantity,
            "missing_quantity": missing_quantity
        },
        "verifications": {
            "recent_checks": recent_checks,
            "completed_checks": completed_checks,
            "completion_rate": round((completed_checks / recent_checks * 100) if recent_checks > 0 else 0, 2)
        },
        "maintenance": {
            "pending_requests": pending_maintenance,
            "in_progress_requests": in_progress_maintenance,
            "total_active": pending_maintenance + in_progress_maintenance
        }
    }

@router.get("/inventory-checks")
def get_inventory_check_stats(
    environment_id: Optional[UUID] = None,
    start_date: Optional[str] = None,
    end_date: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get detailed inventory check statistics"""
    
    query = db.query(InventoryCheck)
    
    if environment_id:
        query = query.filter(InventoryCheck.environment_id == environment_id)
    elif current_user.environment_id:
        query = query.filter(InventoryCheck.environment_id == current_user.environment_id)
    
    if start_date:
        try:
            start = datetime.strptime(start_date, "%Y-%m-%d").date()
            query = query.filter(InventoryCheck.check_date >= start)
        except ValueError:
            raise HTTPException(status_code=400, detail="Formato de fecha inválido para start_date")
    
    if end_date:
        try:
            end = datetime.strptime(end_date, "%Y-%m-%d").date()
            query = query.filter(InventoryCheck.check_date <= end)
        except ValueError:
            raise HTTPException(status_code=400, detail="Formato de fecha inválido para end_date")
    
    # Status distribution
    status_stats = {}
    for status in ['pending', 'instructor_review', 'supervisor_review', 'complete', 'issues']:
        count = query.filter(InventoryCheck.status == status).count()
        status_stats[status] = count
    
    # Items statistics
    total_items_checked = query.with_entities(func.sum(InventoryCheck.total_items)).scalar() or 0
    total_good_items = query.with_entities(func.sum(InventoryCheck.items_good)).scalar() or 0
    total_damaged_items = query.with_entities(func.sum(InventoryCheck.items_damaged)).scalar() or 0
    total_missing_items = query.with_entities(func.sum(InventoryCheck.items_missing)).scalar() or 0
    
    return {
        "status_distribution": status_stats,
        "items_summary": {
            "total_checked": total_items_checked,
            "good_items": total_good_items,
            "damaged_items": total_damaged_items,
            "missing_items": total_missing_items,
            "good_percentage": round((total_good_items / total_items_checked * 100) if total_items_checked > 0 else 0, 2)
        },
        "total_verifications": query.count()
    }

@router.get("/environment/{environment_id}")
def get_environment_stats(
    environment_id: UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get statistics for a specific environment"""
    
    # Verify environment exists
    environment = db.query(Environment).filter(Environment.id == environment_id).first()
    if not environment:
        raise HTTPException(status_code=404, detail="Ambiente no encontrado")
    
    # Inventory by category
    categories = ['computer', 'projector', 'keyboard', 'mouse', 'tv', 'camera', 'microphone', 'tablet', 'other']
    category_stats = {}
    
    for category in categories:
        count = db.query(InventoryItem).filter(
            and_(InventoryItem.environment_id == environment_id, InventoryItem.category == category)
        ).count()
        
        quantity = db.query(func.sum(InventoryItem.quantity)).filter(
            and_(InventoryItem.environment_id == environment_id, InventoryItem.category == category)
        ).scalar() or 0
        
        category_stats[category] = {
            "count": count,
            "quantity": quantity
        }
    
    # Recent activity (last 7 days)
    week_ago = date.today() - timedelta(days=7)
    recent_checks = db.query(InventoryCheck).filter(
        and_(InventoryCheck.environment_id == environment_id, InventoryCheck.check_date >= week_ago)
    ).count()
    
    recent_maintenance = db.query(MaintenanceRequest).filter(
        and_(MaintenanceRequest.environment_id == environment_id, MaintenanceRequest.created_at >= datetime.combine(week_ago, datetime.min.time()))
    ).count()
    
    return {
        "environment": {
            "id": environment.id,
            "name": environment.name,
            "location": environment.location
        },
        "category_distribution": category_stats,
        "recent_activity": {
            "checks_last_week": recent_checks,
            "maintenance_requests_last_week": recent_maintenance
        }
    }

@router.get("/trends")
def get_trends_stats(
    environment_id: Optional[UUID] = None,
    days: int = 30,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get trend statistics over time"""
    
    if days > 365:
        raise HTTPException(status_code=400, detail="Máximo 365 días permitidos")
    
    start_date = date.today() - timedelta(days=days)
    
    query = db.query(InventoryCheck)
    if environment_id:
        query = query.filter(InventoryCheck.environment_id == environment_id)
    elif current_user.environment_id:
        query = query.filter(InventoryCheck.environment_id == current_user.environment_id)
    
    # Daily verification counts
    daily_stats = []
    for i in range(days):
        current_date = start_date + timedelta(days=i)
        daily_count = query.filter(InventoryCheck.check_date == current_date).count()
        daily_stats.append({
            "date": current_date.isoformat(),
            "verifications": daily_count
        })
    
    # Weekly averages
    weekly_avg = sum(stat["verifications"] for stat in daily_stats) / (days / 7) if days >= 7 else 0
    
    return {
        "period_days": days,
        "daily_verifications": daily_stats,
        "weekly_average": round(weekly_avg, 2),
        "total_period_verifications": sum(stat["verifications"] for stat in daily_stats)
    }
