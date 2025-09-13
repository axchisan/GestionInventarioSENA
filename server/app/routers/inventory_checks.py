from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from pydantic import BaseModel
from datetime import datetime, date, time
from uuid import UUID
from typing import List, Optional
import pytz # type: ignore

from ..database import get_db
from ..models.inventory_checks import InventoryCheck
from ..models.inventory_check_items import InventoryCheckItem
from ..models.environments import Environment
from ..models.inventory_items import InventoryItem
from ..models.users import User
from ..models.schedules import Schedule
from ..models.notifications import Notification
from ..models.supervisor_reviews import SupervisorReview
from ..routers.auth import get_current_user
from ..schemas.inventory_check import InventoryCheckCreateRequest, InventoryCheckResponse, InventoryCheckInstructorConfirmRequest

router = APIRouter(tags=["inventory-checks"])

COLOMBIA_TZ = pytz.timezone('America/Bogota')

def get_colombia_time():
    """Get current time in Colombian timezone"""
    return datetime.now(COLOMBIA_TZ)

def parse_time_string(time_str: str) -> time:
    """Parse time string and return time object in Colombian timezone"""
    try:
        # Parse the time string (expected format: "HH:MM")
        parsed_time = datetime.strptime(time_str, "%H:%M").time()
        return parsed_time
    except ValueError:
        # Fallback to current Colombian time
        return get_colombia_time().time()

class VerificationByScheduleRequest(BaseModel):
    """Request for creating verification by schedule (for any role)"""
    environment_id: UUID
    schedule_id: UUID
    is_clean: Optional[bool] = None
    is_organized: Optional[bool] = None
    inventory_complete: Optional[bool] = None
    cleaning_notes: Optional[str] = None
    comments: Optional[str] = None

@router.post("/", status_code=status.HTTP_201_CREATED)
async def create_inventory_check(
    request: InventoryCheckCreateRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    if current_user.role not in ["student", "instructor", "supervisor"]:
        raise HTTPException(status_code=403, detail="Rol no autorizado")

    environment = db.query(Environment).filter(Environment.id == request.environment_id).first()
    if not environment:
        raise HTTPException(status_code=404, detail="Ambiente no encontrado")

    student = db.query(User).filter(User.id == request.student_id, User.role == "student").first()
    if not student:
        raise HTTPException(status_code=404, detail="Estudiante no encontrado")

    schedule = db.query(Schedule).filter(Schedule.id == request.schedule_id).first()
    if not schedule:
        raise HTTPException(status_code=404, detail="Horario no encontrado")

    existing_check = db.query(InventoryCheck).filter(
        InventoryCheck.environment_id == request.environment_id,
        InventoryCheck.schedule_id == request.schedule_id,
        InventoryCheck.check_date == date.today()
    ).first()
    if existing_check:
        raise HTTPException(status_code=400, detail="Ya se realizó verificación hoy para este turno")

    # Calcular estadísticas basadas en InventoryCheckItem existentes
    check_items = db.query(InventoryCheckItem).filter(
        InventoryCheckItem.environment_id == request.environment_id,
        InventoryCheckItem.created_at >= datetime.combine(date.today(), datetime.min.time()),
        InventoryCheckItem.created_at <= datetime.combine(date.today(), datetime.max.time())
    ).all()

    items_good = sum(item.quantity_found for item in check_items if item.status == "good")
    items_damaged = sum(item.quantity_damaged for item in check_items if item.status == "damaged")
    items_missing = sum(item.quantity_missing for item in check_items if item.status == "missing")
    total_items = len(check_items)

    colombia_now = get_colombia_time()
    
    inventory_check = InventoryCheck(
        environment_id=request.environment_id,
        student_id=request.student_id,
        schedule_id=request.schedule_id,
        check_date=date.today(),
        check_time=colombia_now.time(),
        status="student_pending",
        total_items=total_items,
        items_good=items_good,
        items_damaged=items_damaged,
        items_missing=items_missing,
        cleaning_notes=request.cleaning_notes,
        student_confirmed_at=colombia_now
    )
    db.add(inventory_check)
    db.commit()
    db.refresh(inventory_check)

    # Actualizar el estado según los ítems verificados
    if items_damaged > 0 or items_missing > 0:
        inventory_check.status = "issues"
    else:
        inventory_check.status = "instructor_review"
    db.commit()

    # Notificar al instructor
    notification = Notification(
        user_id=schedule.instructor_id,
        type="verification_pending",
        title="Nueva Verificación Pendiente",
        message="Una verificación de inventario ha sido iniciada por un estudiante.",
        is_read=False,
        priority="medium"
    )
    db.add(notification)
    db.commit()

    return {"status": "success", "check_id": inventory_check.id}

@router.post("/by-schedule", status_code=status.HTTP_201_CREATED)
async def create_verification_by_schedule(
    request: VerificationByScheduleRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Create or update verification by schedule - allows any role to complete verification steps"""
    if current_user.role not in ["student", "instructor", "supervisor"]:
        raise HTTPException(status_code=403, detail="Rol no autorizado")

    environment = db.query(Environment).filter(Environment.id == request.environment_id).first()
    if not environment:
        raise HTTPException(status_code=404, detail="Ambiente no encontrado")

    schedule = db.query(Schedule).filter(Schedule.id == request.schedule_id).first()
    if not schedule:
        raise HTTPException(status_code=404, detail="Horario no encontrado")

    colombia_now = get_colombia_time()

    # Check if verification already exists for today
    existing_check = db.query(InventoryCheck).filter(
        InventoryCheck.environment_id == request.environment_id,
        InventoryCheck.schedule_id == request.schedule_id,
        InventoryCheck.check_date == date.today()
    ).first()

    if existing_check:
        # Update existing verification based on user role
        if current_user.role == "student":
            if existing_check.status not in ["student_pending"]:
                existing_check.student_confirmed_at = colombia_now
                existing_check.cleaning_notes = request.cleaning_notes or existing_check.cleaning_notes
        
        elif current_user.role == "instructor":
            if existing_check.status in ["student_pending", "instructor_review"]:
                existing_check.instructor_id = current_user.id
                existing_check.is_clean = request.is_clean
                existing_check.is_organized = request.is_organized
                existing_check.inventory_complete = request.inventory_complete
                existing_check.instructor_comments = request.comments
                existing_check.instructor_confirmed_at = colombia_now
                
                # Update status based on verification results
                if not request.inventory_complete or existing_check.items_damaged > 0 or existing_check.items_missing > 0:
                    existing_check.status = "issues"
                else:
                    existing_check.status = "supervisor_review"
        
        elif current_user.role == "supervisor":
            # Supervisor can complete all steps if needed
            if not existing_check.instructor_id:
                existing_check.instructor_id = current_user.id
                existing_check.is_clean = request.is_clean
                existing_check.is_organized = request.is_organized
                existing_check.inventory_complete = request.inventory_complete
                existing_check.instructor_confirmed_at = colombia_now
            
            existing_check.supervisor_id = current_user.id
            existing_check.supervisor_comments = request.comments
            existing_check.supervisor_confirmed_at = colombia_now
            
            # Final status determination
            if request.inventory_complete and existing_check.items_damaged == 0 and existing_check.items_missing == 0:
                existing_check.status = "complete"
            else:
                existing_check.status = "issues"
        
        db.commit()
        db.refresh(existing_check)
        return {"status": "success", "check_id": existing_check.id, "action": "updated"}
    
    else:
        # Create new verification
        # Calculate statistics from check items
        check_items = db.query(InventoryCheckItem).filter(
            InventoryCheckItem.environment_id == request.environment_id,
            InventoryCheckItem.created_at >= datetime.combine(date.today(), datetime.min.time()),
            InventoryCheckItem.created_at <= datetime.combine(date.today(), datetime.max.time())
        ).all()

        items_good = sum(item.quantity_found for item in check_items if item.status == "good")
        items_damaged = sum(item.quantity_damaged for item in check_items)
        items_missing = sum(item.quantity_missing for item in check_items)
        total_items = len(check_items)

        # Determine initial status and fields based on user role
        initial_status = "student_pending"
        student_id = current_user.id if current_user.role == "student" else None
        instructor_id = current_user.id if current_user.role == "instructor" else None
        supervisor_id = current_user.id if current_user.role == "supervisor" else None

        if current_user.role == "instructor":
            initial_status = "instructor_review"
        elif current_user.role == "supervisor":
            initial_status = "supervisor_review"
            instructor_id = current_user.id  # Supervisor can act as instructor too

        inventory_check = InventoryCheck(
            environment_id=request.environment_id,
            student_id=student_id or schedule.instructor_id,  # Fallback to instructor if no student
            instructor_id=instructor_id,
            supervisor_id=supervisor_id,
            schedule_id=request.schedule_id,
            check_date=date.today(),
            check_time=colombia_now.time(),
            status=initial_status,
            total_items=total_items,
            items_good=items_good,
            items_damaged=items_damaged,
            items_missing=items_missing,
            is_clean=request.is_clean,
            is_organized=request.is_organized,
            inventory_complete=request.inventory_complete,
            cleaning_notes=request.cleaning_notes,
            comments=request.comments
        )

        # Set confirmation timestamps based on role
        if current_user.role == "student":
            inventory_check.student_confirmed_at = colombia_now
        elif current_user.role == "instructor":
            inventory_check.instructor_confirmed_at = colombia_now
            inventory_check.student_confirmed_at = colombia_now  # Assume student step completed
        elif current_user.role == "supervisor":
            inventory_check.supervisor_confirmed_at = colombia_now
            inventory_check.instructor_confirmed_at = colombia_now
            inventory_check.student_confirmed_at = colombia_now

        db.add(inventory_check)
        db.commit()
        db.refresh(inventory_check)

        # Update final status based on results
        if current_user.role == "supervisor":
            if request.inventory_complete and items_damaged == 0 and items_missing == 0:
                inventory_check.status = "complete"
            else:
                inventory_check.status = "issues"
        elif current_user.role == "instructor":
            if not request.inventory_complete or items_damaged > 0 or items_missing > 0:
                inventory_check.status = "issues"
            else:
                inventory_check.status = "supervisor_review"
        else:  # student
            if items_damaged > 0 or items_missing > 0:
                inventory_check.status = "issues"
            else:
                inventory_check.status = "instructor_review"

        db.commit()

        # Create appropriate notifications
        if current_user.role == "student" and schedule.instructor_id:
            notification = Notification(
                user_id=schedule.instructor_id,
                type="verification_pending",
                title="Nueva Verificación Pendiente",
                message="Una verificación de inventario ha sido iniciada por un estudiante.",
                is_read=False,
                priority="medium"
            )
            db.add(notification)
        elif current_user.role == "instructor":
            # Notify supervisor if available
            supervisors = db.query(User).filter(User.role == "supervisor", User.environment_id == request.environment_id).all()
            for supervisor in supervisors:
                notification = Notification(
                    user_id=supervisor.id,
                    type="verification_pending",
                    title="Verificación Lista para Supervisión",
                    message="Una verificación de inventario está lista para revisión de supervisor.",
                    is_read=False,
                    priority="medium"
                )
                db.add(notification)

        db.commit()
        return {"status": "success", "check_id": inventory_check.id, "action": "created"}

@router.put("/{check_id}/confirm", response_model=InventoryCheckResponse)
async def confirm_inventory_check(
    check_id: UUID,
    request: InventoryCheckInstructorConfirmRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    if current_user.role not in ["instructor", "supervisor"]:
        raise HTTPException(status_code=403, detail="Solo instructores y supervisores pueden confirmar verificaciones")

    inventory_check = db.query(InventoryCheck).filter(InventoryCheck.id == check_id).first()
    if not inventory_check:
        raise HTTPException(status_code=404, detail="Verificación no encontrada")

    colombia_now = get_colombia_time()

    if current_user.role == "instructor":
        if inventory_check.instructor_id is not None and inventory_check.instructor_id != current_user.id:
            raise HTTPException(status_code=400, detail="Ya confirmada por otro instructor")
        
        inventory_check.instructor_id = current_user.id
        inventory_check.is_clean = request.is_clean
        inventory_check.is_organized = request.is_organized
        inventory_check.inventory_complete = request.inventory_complete
        inventory_check.instructor_comments = request.comments
        inventory_check.instructor_confirmed_at = colombia_now
        
        # Update status
        if not request.inventory_complete or inventory_check.items_damaged > 0 or inventory_check.items_missing > 0:
            inventory_check.status = "issues"
        else:
            inventory_check.status = "supervisor_review"
    
    elif current_user.role == "supervisor":
        # Supervisor can complete instructor step if not done
        if not inventory_check.instructor_id:
            inventory_check.instructor_id = current_user.id
            inventory_check.instructor_confirmed_at = colombia_now
        
        inventory_check.supervisor_id = current_user.id
        inventory_check.is_clean = request.is_clean
        inventory_check.is_organized = request.is_organized
        inventory_check.inventory_complete = request.inventory_complete
        inventory_check.supervisor_comments = request.comments
        inventory_check.supervisor_confirmed_at = colombia_now
        
        # Final status
        if request.inventory_complete and inventory_check.items_damaged == 0 and inventory_check.items_missing == 0:
            inventory_check.status = "complete"
        else:
            inventory_check.status = "issues"

    db.commit()
    db.refresh(inventory_check)
    
    # Create notifications
    notification_type = "verification_update"
    if current_user.role == "instructor":
        # Notify supervisors
        supervisors = db.query(User).filter(User.role == "supervisor", User.environment_id == inventory_check.environment_id).all()
        for supervisor in supervisors:
            notification = Notification(
                user_id=supervisor.id,
                type=notification_type,
                title="Verificación Lista para Supervisión",
                message="Una verificación de inventario está lista para revisión de supervisor.",
                is_read=False,
                priority="medium"
            )
            db.add(notification)
    else:  # supervisor
        # Notify student and instructor
        if inventory_check.student_id:
            notification = Notification(
                user_id=inventory_check.student_id,
                type=notification_type,
                title="Verificación Completada",
                message=f"Tu verificación ha sido {'completada' if inventory_check.status == 'complete' else 'marcada con observaciones'}.",
                is_read=False,
                priority="medium"
            )
            db.add(notification)
        
        if inventory_check.instructor_id and inventory_check.instructor_id != current_user.id:
            notification = Notification(
                user_id=inventory_check.instructor_id,
                type=notification_type,
                title="Verificación Revisada",
                message=f"La verificación ha sido {'completada' if inventory_check.status == 'complete' else 'marcada con observaciones'} por el supervisor.",
                is_read=False,
                priority="medium"
            )
            db.add(notification)
    
    db.commit()
    return inventory_check

@router.put("/{check_id}/assign-role")
async def assign_verification_role(
    check_id: UUID,
    role_assignment: dict,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Allow supervisors to assign verification to instructors or take over verification"""
    if current_user.role not in ["supervisor", "admin"]:
        raise HTTPException(status_code=403, detail="Solo supervisores pueden asignar verificaciones")

    inventory_check = db.query(InventoryCheck).filter(InventoryCheck.id == check_id).first()
    if not inventory_check:
        raise HTTPException(status_code=404, detail="Verificación no encontrada")

    target_role = role_assignment.get("target_role")
    if target_role == "supervisor_takeover":
        inventory_check.status = "supervisor_review"
    elif target_role == "instructor_assign":
        inventory_check.status = "instructor_review"

    db.commit()
    return {"status": "success", "message": f"Verificación asignada a {target_role}"}

@router.get("/", response_model=List[InventoryCheckResponse])
def get_inventory_checks(
    environment_id: Optional[UUID] = None,
    date: Optional[str] = None,  
    shift: Optional[str] = None,
    status: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user) 
):
    query = db.query(InventoryCheck)
    
    # Filter by environment
    if environment_id:
        query = query.filter(InventoryCheck.environment_id == environment_id)
    elif current_user.environment_id:
        query = query.filter(InventoryCheck.environment_id == current_user.environment_id)
    
    # Filter by date
    if date:
        try:
            parsed_date = datetime.strptime(date, "%Y-%m-%d").date()
            query = query.filter(InventoryCheck.check_date == parsed_date)
        except ValueError:
            raise HTTPException(status_code=400, detail="Formato de fecha inválido. Se espera YYYY-MM-DD")
    
    # Filter by shift
    if shift:
        if shift == 'morning':
            query = query.join(Schedule).filter(Schedule.start_time.between('07:00:00', '12:00:00'))
        elif shift == 'afternoon':
            query = query.join(Schedule).filter(Schedule.start_time.between('13:00:00', '18:00:00'))
        elif shift == 'night':
            query = query.join(Schedule).filter(Schedule.start_time.between('18:00:00', '22:00:00'))
    
    # Filter by status
    if status:
        query = query.filter(InventoryCheck.status == status)
    
    # Role-based filtering
    if current_user.role == "student":
        query = query.filter(InventoryCheck.student_id == current_user.id)
    elif current_user.role == "instructor":
        query = query.filter(
            (InventoryCheck.instructor_id == current_user.id) |
            (InventoryCheck.status == "instructor_review")
        )
    elif current_user.role == "supervisor":
        query = query.filter(
            (InventoryCheck.supervisor_id == current_user.id) |
            (InventoryCheck.status.in_(["supervisor_review", "issues"]))
        )

    checks = query.order_by(InventoryCheck.created_at.desc()).all()
    return checks

@router.get("/by-schedule", response_model=List[InventoryCheckResponse])
def get_inventory_checks_by_schedule(
    environment_id: UUID,
    schedule_id: UUID,
    date: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get inventory checks by schedule for a specific date"""
    try:
        parsed_date = datetime.strptime(date, "%Y-%m-%d").date()
    except ValueError:
        raise HTTPException(status_code=400, detail="Formato de fecha inválido. Se espera YYYY-MM-DD")
    
    checks = db.query(InventoryCheck).filter(
        InventoryCheck.environment_id == environment_id,
        InventoryCheck.schedule_id == schedule_id,
        InventoryCheck.check_date == parsed_date
    ).all()
    
    return checks

@router.get("/schedule-stats")
def get_schedule_stats(
    environment_id: UUID,
    schedule_id: UUID,
    date: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get statistics for a specific schedule and date"""
    try:
        parsed_date = datetime.strptime(date, "%Y-%m-%d").date()
    except ValueError:
        raise HTTPException(status_code=400, detail="Formato de fecha inválido. Se espera YYYY-MM-DD")
    
    # Get inventory check for this schedule and date
    check = db.query(InventoryCheck).filter(
        InventoryCheck.environment_id == environment_id,
        InventoryCheck.schedule_id == schedule_id,
        InventoryCheck.check_date == parsed_date
    ).first()
    
    if not check:
        return {
            "total_items": 0,
            "items_good": 0,
            "items_damaged": 0,
            "items_missing": 0,
            "status": "not_started",
            "completion_percentage": 0
        }
    
    completion_percentage = 0
    if check.total_items > 0:
        completion_percentage = ((check.items_good + check.items_damaged + check.items_missing) / check.total_items) * 100
    
    return {
        "total_items": check.total_items or 0,
        "items_good": check.items_good or 0,
        "items_damaged": check.items_damaged or 0,
        "items_missing": check.items_missing or 0,
        "status": check.status,
        "completion_percentage": round(completion_percentage, 2)
    }

@router.put("/{check_id}/supervisor-approve")
async def supervisor_approve_check(
    check_id: UUID,
    approval_data: dict,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Supervisor approval endpoint for inventory checks"""
    if current_user.role != "supervisor":
        raise HTTPException(status_code=403, detail="Solo supervisores pueden aprobar verificaciones")
    
    inventory_check = db.query(InventoryCheck).filter(InventoryCheck.id == check_id).first()
    if not inventory_check:
        raise HTTPException(status_code=404, detail="Verificación no encontrada")
    
    # Update check status based on approval
    approved = approval_data.get("approved", False)
    comments = approval_data.get("comments", "")
    
    colombia_now = get_colombia_time()
    
    inventory_check.supervisor_id = current_user.id
    inventory_check.supervisor_comments = comments
    inventory_check.supervisor_confirmed_at = colombia_now
    
    if approved:
        inventory_check.status = "complete"
    else:
        inventory_check.status = "rejected"
    
    # Create supervisor review record
    supervisor_review = SupervisorReview(
        check_id=check_id,
        supervisor_id=current_user.id,
        status="approved" if approved else "rejected",
        comments=comments
    )
    db.add(supervisor_review)
    
    # Create notifications
    if inventory_check.student_id:
        notification_student = Notification(
            user_id=inventory_check.student_id,
            type="verification_update",
            title="Verificación Revisada por Supervisor",
            message=f"Tu verificación ha sido {'aprobada' if approved else 'rechazada'} por el supervisor.",
            is_read=False,
            priority="medium"
        )
        db.add(notification_student)
    
    if inventory_check.instructor_id and inventory_check.instructor_id != current_user.id:
        notification_instructor = Notification(
            user_id=inventory_check.instructor_id,
            type="verification_update",
            title="Verificación Revisada por Supervisor",
            message=f"La verificación ha sido {'aprobada' if approved else 'rechazada'} por el supervisor.",
            is_read=False,
            priority="medium"
        )
        db.add(notification_instructor)
    
    db.commit()
    db.refresh(inventory_check)
    
    return {
        "status": "success",
        "message": f"Verificación {'aprobada' if approved else 'rechazada'} exitosamente",
        "check_status": inventory_check.status
    }
