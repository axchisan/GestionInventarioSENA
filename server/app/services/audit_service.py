from sqlalchemy.orm import Session
from sqlalchemy import desc, func, and_, or_
from typing import List, Optional, Dict, Any, Tuple
from datetime import datetime, date, timedelta
from uuid import UUID

from ..models.audit_logs import AuditLog
from ..models.users import User
from ..schemas.audit_log import AuditLogCreate, AuditLogResponse, AuditLogListResponse, AuditLogStatsResponse

class AuditService:
    """
    Servicio para gestión completa de logs de auditoría
    Proporciona funcionalidades avanzadas de consulta, análisis y reportes
    """
    
    @staticmethod
    def create_audit_log(
        db: Session,
        audit_data: AuditLogCreate,
        ip_address: Optional[str] = None,
        user_agent: Optional[str] = None
    ) -> AuditLog:
        """Crear un nuevo registro de auditoría"""
        audit_log = AuditLog(
            user_id=audit_data.user_id,
            action=audit_data.action,
            entity_type=audit_data.entity_type,
            entity_id=audit_data.entity_id,
            old_values=audit_data.old_values,
            new_values=audit_data.new_values,
            ip_address=ip_address or audit_data.ip_address,
            user_agent=user_agent or audit_data.user_agent,
            session_id=audit_data.session_id
        )
        
        db.add(audit_log)
        db.commit()
        db.refresh(audit_log)
        return audit_log
    
    @staticmethod
    def get_audit_logs_paginated(
        db: Session,
        page: int = 1,
        per_page: int = 20,
        filters: Optional[Dict[str, Any]] = None
    ) -> Tuple[List[AuditLog], int]:
        """Obtener logs de auditoría con paginación y filtros"""
        query = db.query(AuditLog).join(User, AuditLog.user_id == User.id, isouter=True)
        
        # Aplicar filtros
        if filters:
            if filters.get('action'):
                query = query.filter(AuditLog.action.ilike(f"%{filters['action']}%"))
            
            if filters.get('user_id'):
                query = query.filter(AuditLog.user_id == filters['user_id'])
            
            if filters.get('entity_type'):
                query = query.filter(AuditLog.entity_type == filters['entity_type'])
            
            if filters.get('start_date'):
                query = query.filter(AuditLog.created_at >= filters['start_date'])
            
            if filters.get('end_date'):
                end_datetime = datetime.combine(filters['end_date'], datetime.max.time())
                query = query.filter(AuditLog.created_at <= end_datetime)
            
            if filters.get('search'):
                search_term = f"%{filters['search']}%"
                query = query.filter(
                    or_(
                        AuditLog.action.ilike(search_term),
                        AuditLog.entity_type.ilike(search_term),
                        func.concat(User.first_name, ' ', User.last_name).ilike(search_term),
                        User.email.ilike(search_term)
                    )
                )
        
        # Contar total
        total = query.count()
        
        # Aplicar paginación
        logs = query.order_by(desc(AuditLog.created_at)).offset((page - 1) * per_page).limit(per_page).all()
        
        return logs, total
    
    @staticmethod
    def get_audit_statistics(
        db: Session,
        days: int = 30,
        user_id: Optional[UUID] = None
    ) -> Dict[str, Any]:
        """Obtener estadísticas de auditoría"""
        end_date = datetime.now()
        start_date = end_date - timedelta(days=days)
        
        base_query = db.query(AuditLog).filter(AuditLog.created_at >= start_date)
        
        if user_id:
            base_query = base_query.filter(AuditLog.user_id == user_id)
        
        # Estadísticas básicas
        total_logs = base_query.count()
        today_logs = base_query.filter(func.date(AuditLog.created_at) == date.today()).count()
        
        # Clasificación por severidad (basada en tipo de acción)
        warning_actions = ['delete', 'update', 'modify', 'change', 'remove']
        error_actions = ['error', 'fail', 'exception', 'reject']
        success_actions = ['create', 'login', 'approve', 'complete', 'success']
        
        warning_logs = base_query.filter(
            func.lower(AuditLog.action).op('~')(f"({'|'.join(warning_actions)})")
        ).count()
        
        error_logs = base_query.filter(
            func.lower(AuditLog.action).op('~')(f"({'|'.join(error_actions)})")
        ).count()
        
        success_logs = base_query.filter(
            func.lower(AuditLog.action).op('~')(f"({'|'.join(success_actions)})")
        ).count()
        
        info_logs = total_logs - warning_logs - error_logs - success_logs
        
        # Top acciones
        top_actions = db.query(
            AuditLog.action,
            func.count(AuditLog.id).label('count')
        ).filter(
            AuditLog.created_at >= start_date
        ).group_by(AuditLog.action).order_by(desc('count')).limit(10).all()
        
        # Top usuarios
        top_users = db.query(
            User.first_name,
            User.last_name,
            User.email,
            func.count(AuditLog.id).label('count')
        ).join(
            AuditLog, User.id == AuditLog.user_id
        ).filter(
            AuditLog.created_at >= start_date
        ).group_by(
            User.id, User.first_name, User.last_name, User.email
        ).order_by(desc('count')).limit(10).all()
        
        # Actividad por día
        daily_activity = db.query(
            func.date(AuditLog.created_at).label('date'),
            func.count(AuditLog.id).label('count')
        ).filter(
            AuditLog.created_at >= start_date
        ).group_by(func.date(AuditLog.created_at)).order_by('date').all()
        
        # Actividad por hora (últimas 24 horas)
        last_24h = datetime.now() - timedelta(hours=24)
        hourly_activity = db.query(
            func.extract('hour', AuditLog.created_at).label('hour'),
            func.count(AuditLog.id).label('count')
        ).filter(
            AuditLog.created_at >= last_24h
        ).group_by(func.extract('hour', AuditLog.created_at)).order_by('hour').all()
        
        return {
            'total_logs': total_logs,
            'today_logs': today_logs,
            'warning_logs': warning_logs,
            'error_logs': error_logs,
            'info_logs': info_logs,
            'success_logs': success_logs,
            'top_actions': [{'action': action, 'count': count} for action, count in top_actions],
            'top_users': [
                {
                    'name': f"{first_name} {last_name}",
                    'email': email,
                    'count': count
                }
                for first_name, last_name, email, count in top_users
            ],
            'daily_activity': [
                {
                    'date': date_val.isoformat() if date_val else None,
                    'count': count
                }
                for date_val, count in daily_activity
            ],
            'hourly_activity': [
                {
                    'hour': int(hour) if hour else 0,
                    'count': count
                }
                for hour, count in hourly_activity
            ]
        }
    
    @staticmethod
    def get_user_activity(
        db: Session,
        user_id: UUID,
        days: int = 30
    ) -> Dict[str, Any]:
        """Obtener actividad específica de un usuario"""
        end_date = datetime.now()
        start_date = end_date - timedelta(days=days)
        
        user_logs = db.query(AuditLog).filter(
            and_(
                AuditLog.user_id == user_id,
                AuditLog.created_at >= start_date
            )
        ).order_by(desc(AuditLog.created_at)).all()
        
        # Estadísticas del usuario
        total_actions = len(user_logs)
        unique_actions = len(set(log.action for log in user_logs))
        unique_entities = len(set(log.entity_type for log in user_logs))
        
        # Acciones más frecuentes
        action_counts = {}
        for log in user_logs:
            action_counts[log.action] = action_counts.get(log.action, 0) + 1
        
        top_actions = sorted(action_counts.items(), key=lambda x: x[1], reverse=True)[:5]
        
        # Actividad por día
        daily_counts = {}
        for log in user_logs:
            day = log.created_at.date()
            daily_counts[day] = daily_counts.get(day, 0) + 1
        
        return {
            'user_id': str(user_id),
            'total_actions': total_actions,
            'unique_actions': unique_actions,
            'unique_entities': unique_entities,
            'top_actions': [{'action': action, 'count': count} for action, count in top_actions],
            'daily_activity': [
                {'date': day.isoformat(), 'count': count}
                for day, count in sorted(daily_counts.items())
            ],
            'recent_logs': [
                {
                    'id': str(log.id),
                    'action': log.action,
                    'entity_type': log.entity_type,
                    'created_at': log.created_at.isoformat(),
                    'ip_address': log.ip_address
                }
                for log in user_logs[:10]
            ]
        }
    
    @staticmethod
    def get_entity_audit_trail(
        db: Session,
        entity_type: str,
        entity_id: UUID
    ) -> List[AuditLog]:
        """Obtener historial completo de auditoría para una entidad específica"""
        return db.query(AuditLog).filter(
            and_(
                AuditLog.entity_type == entity_type,
                AuditLog.entity_id == entity_id
            )
        ).order_by(desc(AuditLog.created_at)).all()
    
    @staticmethod
    def cleanup_old_logs(
        db: Session,
        days_to_keep: int = 90
    ) -> int:
        """Limpiar logs antiguos para mantener el rendimiento"""
        cutoff_date = datetime.now() - timedelta(days=days_to_keep)
        
        deleted_count = db.query(AuditLog).filter(
            AuditLog.created_at < cutoff_date
        ).delete()
        
        db.commit()
        return deleted_count
    
    @staticmethod
    def export_audit_logs(
        db: Session,
        start_date: date,
        end_date: date,
        format: str = 'json'
    ) -> List[Dict[str, Any]]:
        """Exportar logs de auditoría para reportes externos"""
        logs = db.query(AuditLog).join(
            User, AuditLog.user_id == User.id, isouter=True
        ).filter(
            and_(
                AuditLog.created_at >= start_date,
                AuditLog.created_at <= datetime.combine(end_date, datetime.max.time())
            )
        ).order_by(desc(AuditLog.created_at)).all()
        
        exported_logs = []
        for log in logs:
            log_data = {
                'id': str(log.id),
                'timestamp': log.created_at.isoformat(),
                'user_id': str(log.user_id) if log.user_id else None,
                'user_name': f"{log.user.first_name} {log.user.last_name}" if log.user else None,
                'user_email': log.user.email if log.user else None,
                'action': log.action,
                'entity_type': log.entity_type,
                'entity_id': str(log.entity_id) if log.entity_id else None,
                'old_values': log.old_values,
                'new_values': log.new_values,
                'ip_address': log.ip_address,
                'user_agent': log.user_agent,
                'session_id': log.session_id
            }
            exported_logs.append(log_data)
        
        return exported_logs
