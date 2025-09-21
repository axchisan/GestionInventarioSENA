from fastapi import Request, Response
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.responses import StreamingResponse
from sqlalchemy.orm import Session
from typing import Callable, Dict, Any, Optional
import json
import time
import uuid
from datetime import datetime

from ..database import get_db
from ..models.audit_logs import AuditLog
from ..models.users import User
from ..utils.security import decode_token

class AuditMiddleware(BaseHTTPMiddleware):
    """
    Middleware para capturar automáticamente todas las operaciones del sistema
    y generar logs de auditoría para trazabilidad completa.
    """
    
    # Métodos HTTP que requieren auditoría
    AUDIT_METHODS = {"POST", "PUT", "DELETE", "PATCH"}
    
    # Endpoints que NO requieren auditoría (por rendimiento o privacidad)
    EXCLUDE_ENDPOINTS = {
        "/api/audit-logs",  # Evitar recursión
        "/docs",
        "/openapi.json",
        "/favicon.ico",
        "/",
        "/api/stats"  # Evitar spam de logs por estadísticas
    }

    async def dispatch(self, request: Request, call_next: Callable) -> Response:
        print(f"[AUDIT MIDDLEWARE] Processing request: {request.method} {request.url.path}")
        
        # Verificar si el endpoint requiere auditoría
        should_audit = self._should_audit(request)
        print(f"[AUDIT MIDDLEWARE] Should audit: {should_audit}")
        
        if not should_audit:
            return await call_next(request)
        
        start_time = time.time()
        request_data = await self._capture_request_data(request)
        
        body = await request.body()
        
        async def receive():
            return {"type": "http.request", "body": body}
        
        request._receive = receive
        
        # Ejecutar la request
        response = await call_next(request)
        
        try:
            print(f"[AUDIT MIDDLEWARE] Creating audit log for {request.method} {request.url.path}")
            await self._create_audit_log_async(
                request=request,
                response=response,
                request_data=request_data,
                duration=time.time() - start_time
            )
        except Exception as e:
            print(f"[AUDIT ERROR] Failed to create audit log: {str(e)}")
        
        return response

    def _should_audit(self, request: Request) -> bool:
        """Determina si una request debe ser auditada"""
        path = request.url.path
        method = request.method
        
        print(f"[AUDIT CHECK] Path: {path}, Method: {method}")
        
        # Excluir endpoints específicos
        if path == "/":  # Exact match for root
            print(f"[AUDIT CHECK] Excluded root path")
            return False
            
        for exclude_path in self.EXCLUDE_ENDPOINTS:
            if exclude_path != "/" and path.startswith(exclude_path):
                print(f"[AUDIT CHECK] Excluded by path: {exclude_path}")
                return False
        
        if path.startswith("/api/") and method in self.AUDIT_METHODS:
            print(f"[AUDIT CHECK] Will audit API endpoint with method {method}")
            return True
        
        if "/api/auth/login" in path:
            print(f"[AUDIT CHECK] Will audit login endpoint")
            return True
        
        print(f"[AUDIT CHECK] Will not audit")
        return False

    async def _capture_request_data(self, request: Request) -> Dict[str, Any]:
        """Captura datos relevantes de la request"""
        try:
            body = await request.body()
            request_body = None
            
            if body:
                try:
                    request_body = json.loads(body.decode())
                    # Filtrar datos sensibles
                    request_body = self._filter_sensitive_data(request_body)
                except (json.JSONDecodeError, UnicodeDecodeError):
                    request_body = {"raw_body": body.decode(errors='ignore')[:500]}
            
            return {
                "method": request.method,
                "path": request.url.path,
                "query_params": dict(request.query_params),
                "body": request_body,
                "client_ip": request.client.host if request.client else "unknown",
                "user_agent": request.headers.get("user-agent", "")
            }
        except Exception as e:
            return {
                "error": f"Failed to capture request data: {str(e)}",
                "method": request.method,
                "path": request.url.path
            }

    def _filter_sensitive_data(self, data: Any) -> Any:
        """Filtra datos sensibles de los logs"""
        if isinstance(data, dict):
            filtered = {}
            for key, value in data.items():
                if key.lower() in ['password', 'password_hash', 'token', 'secret', 'key', 'authorization']:
                    filtered[key] = "[FILTERED]"
                else:
                    filtered[key] = self._filter_sensitive_data(value)
            return filtered
        elif isinstance(data, list):
            return [self._filter_sensitive_data(item) for item in data]
        else:
            return data

    async def _create_audit_log_async(
        self,
        request: Request,
        response: Response,
        request_data: Dict[str, Any],
        duration: float
    ):
        """Crea un registro de auditoría en la base de datos de forma asíncrona"""
        try:
            print(f"[AUDIT DB] Starting database operation")
            db_gen = get_db()
            db = next(db_gen)
            
            try:
                # Obtener información del usuario autenticado
                user_id = None
                user_info = await self._get_user_from_request(request)
                if user_info:
                    user_id = user_info.get("user_id")
                    print(f"[AUDIT DB] Found user_id: {user_id}")
                else:
                    print(f"[AUDIT DB] No user found in request")
                
                # Determinar la acción basada en el endpoint y método
                action = self._determine_action(request.url.path, request.method)
                print(f"[AUDIT DB] Action: {action}")
                
                # Determinar el tipo de entidad
                entity_type = self._determine_entity_type(request.url.path)
                print(f"[AUDIT DB] Entity type: {entity_type}")
                
                # Extraer ID de entidad si está en la URL
                entity_id = self._extract_entity_id(request.url.path)
                print(f"[AUDIT DB] Entity ID: {entity_id}")
                
                audit_log = AuditLog(
                    user_id=user_id,
                    action=action,
                    entity_type=entity_type,
                    entity_id=entity_id,
                    old_values=None,
                    new_values={
                        "request": request_data,
                        "response": {
                            "status_code": response.status_code,
                            "headers": dict(response.headers)
                        },
                        "duration_seconds": round(duration, 3),
                        "timestamp": datetime.utcnow().isoformat()
                    },
                    ip_address=request.client.host if request.client else "unknown",
                    user_agent=request.headers.get("user-agent", ""),
                    session_id=request.headers.get("x-session-id")
                )
                
                db.add(audit_log)
                db.commit()
                print(f"[AUDIT SUCCESS] Created log for {action} on {entity_type}")
                
            except Exception as e:
                db.rollback()
                print(f"[AUDIT DB ERROR] Database error: {str(e)}")
                raise
            finally:
                db.close()
                
        except Exception as e:
            print(f"[AUDIT ERROR] Failed to create audit log: {str(e)}")

    async def _get_user_from_request(self, request: Request) -> Optional[Dict[str, Any]]:
        """Extrae información del usuario de la request"""
        try:
            # Buscar token en headers
            auth_header = request.headers.get("authorization")
            if auth_header and auth_header.startswith("Bearer "):
                token = auth_header.split(" ")[1]
                user_data = decode_token(token)
                return user_data
        except Exception as e:
            print(f"[AUDIT] Could not decode user token: {str(e)}")
        
        return None

    def _determine_action(self, path: str, method: str) -> str:
        """Determina la acción basada en el path y método HTTP"""
        if "/auth/login" in path:
            return "LOGIN"
        elif "/auth/register" in path:
            return "REGISTER"
        elif "/auth/logout" in path:
            return "LOGOUT"
        
        # Acción genérica basada en método HTTP y entidad
        action_map = {
            "GET": "VIEW",
            "POST": "CREATE",
            "PUT": "UPDATE",
            "PATCH": "UPDATE",
            "DELETE": "DELETE"
        }
        
        entity = self._determine_entity_type(path).upper()
        return f"{action_map.get(method, method)}_{entity}"

    def _determine_entity_type(self, path: str) -> str:
        """Determina el tipo de entidad basado en el path"""
        if "/inventory-checks" in path:
            return "inventory_check"
        elif "/inventory" in path:
            return "inventory_item"
        elif "/loans" in path:
            return "loan"
        elif "/users" in path:
            return "user"
        elif "/maintenance-requests" in path:
            return "maintenance_request"
        elif "/maintenance-history" in path:
            return "maintenance_history"
        elif "/environments" in path:
            return "environment"
        elif "/auth" in path:
            return "authentication"
        elif "/supervisor-reviews" in path:
            return "supervisor_review"
        elif "/notifications" in path:
            return "notification"
        elif "/system-alerts" in path:
            return "system_alert"
        else:
            parts = [p for p in path.split('/') if p and p != 'api']
            return parts[0] if parts else "unknown"

    def _extract_entity_id(self, path: str) -> Optional[str]:
        """Extrae el ID de entidad de la URL si está presente"""
        try:
            # Buscar UUID en el path (formato: /api/resource/{uuid})
            parts = path.split('/')
            for part in parts:
                if len(part) == 36 and part.count('-') == 4:  # UUID format
                    return part
                elif part.isdigit():
                    return part
        except Exception:
            pass
        
        return None
