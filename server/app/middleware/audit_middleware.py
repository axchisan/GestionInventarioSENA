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
    
    # Endpoints que requieren auditoría
    AUDIT_ENDPOINTS = {
        # Autenticación
        "/api/auth/login": "LOGIN",
        "/api/auth/register": "REGISTER",
        "/api/auth/logout": "LOGOUT",
        
        # Inventario
        "/api/inventory": {
            "GET": "INVENTORY_VIEW",
            "POST": "INVENTORY_CREATE",
            "PUT": "INVENTORY_UPDATE",
            "DELETE": "INVENTORY_DELETE"
        },
        
        # Préstamos
        "/api/loans": {
            "GET": "LOAN_VIEW",
            "POST": "LOAN_CREATE",
            "PUT": "LOAN_UPDATE",
            "DELETE": "LOAN_DELETE"
        },
        
        # Usuarios
        "/api/users": {
            "GET": "USER_VIEW",
            "POST": "USER_CREATE",
            "PUT": "USER_UPDATE",
            "DELETE": "USER_DELETE"
        },
        
        # Mantenimiento
        "/api/maintenance-requests": {
            "GET": "MAINTENANCE_VIEW",
            "POST": "MAINTENANCE_CREATE",
            "PUT": "MAINTENANCE_UPDATE",
            "DELETE": "MAINTENANCE_DELETE"
        },
        
        # Verificaciones de inventario
        "/api/inventory-checks": {
            "GET": "CHECK_VIEW",
            "POST": "CHECK_CREATE",
            "PUT": "CHECK_UPDATE",
            "DELETE": "CHECK_DELETE"
        },
        
        # Ambientes
        "/api/environments": {
            "GET": "ENVIRONMENT_VIEW",
            "POST": "ENVIRONMENT_CREATE",
            "PUT": "ENVIRONMENT_UPDATE",
            "DELETE": "ENVIRONMENT_DELETE"
        }
    }
    
    # Métodos HTTP que requieren auditoría
    AUDIT_METHODS = {"POST", "PUT", "DELETE", "PATCH"}
    
    # Endpoints que NO requieren auditoría (por rendimiento o privacidad)
    EXCLUDE_ENDPOINTS = {
        "/api/audit-logs",  # Evitar recursión
        "/docs",
        "/openapi.json",
        "/favicon.ico",
        "/"
    }

    async def dispatch(self, request: Request, call_next: Callable) -> Response:
        # Verificar si el endpoint requiere auditoría
        if not self._should_audit(request):
            return await call_next(request)
        
        # Capturar datos de la request
        start_time = time.time()
        request_data = await self._capture_request_data(request)
        
        # Ejecutar la request
        response = await call_next(request)
        
        # Capturar datos de la response
        response_data = await self._capture_response_data(response)
        
        # Crear log de auditoría de forma asíncrona
        await self._create_audit_log(
            request=request,
            response=response,
            request_data=request_data,
            response_data=response_data,
            duration=time.time() - start_time
        )
        
        return response

    def _should_audit(self, request: Request) -> bool:
        """Determina si una request debe ser auditada"""
        path = request.url.path
        method = request.method
        
        # Excluir endpoints específicos
        for exclude_path in self.EXCLUDE_ENDPOINTS:
            if path.startswith(exclude_path):
                return False
        
        # Auditar métodos específicos o endpoints configurados
        if method in self.AUDIT_METHODS:
            return True
        
        # Auditar endpoints específicos independientemente del método
        for audit_path in self.AUDIT_ENDPOINTS:
            if path.startswith(audit_path):
                return True
        
        return False

    async def _capture_request_data(self, request: Request) -> Dict[str, Any]:
        """Captura datos relevantes de la request"""
        try:
            # Leer el body de la request
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
                "headers": dict(request.headers),
                "body": request_body,
                "client_ip": request.client.host,
                "user_agent": request.headers.get("user-agent", "")
            }
        except Exception as e:
            return {
                "error": f"Failed to capture request data: {str(e)}",
                "method": request.method,
                "path": request.url.path
            }

    async def _capture_response_data(self, response: Response) -> Dict[str, Any]:
        """Captura datos relevantes de la response"""
        try:
            response_data = {
                "status_code": response.status_code,
                "headers": dict(response.headers)
            }
            
            # Capturar body de la response si es posible
            if hasattr(response, 'body') and response.body:
                try:
                    body_content = response.body.decode()
                    if len(body_content) < 1000:  # Solo capturar responses pequeñas
                        response_body = json.loads(body_content)
                        response_data["body"] = self._filter_sensitive_data(response_body)
                except (json.JSONDecodeError, UnicodeDecodeError, AttributeError):
                    pass
            
            return response_data
        except Exception as e:
            return {
                "error": f"Failed to capture response data: {str(e)}",
                "status_code": getattr(response, 'status_code', 500)
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

    async def _create_audit_log(
        self,
        request: Request,
        response: Response,
        request_data: Dict[str, Any],
        response_data: Dict[str, Any],
        duration: float
    ):
        """Crea un registro de auditoría en la base de datos"""
        try:
            # Obtener información del usuario autenticado
            user_id = None
            user_info = await self._get_user_from_request(request)
            if user_info:
                user_id = user_info.get("user_id")
            
            # Determinar la acción basada en el endpoint y método
            action = self._determine_action(request.url.path, request.method)
            
            # Determinar el tipo de entidad
            entity_type = self._determine_entity_type(request.url.path)
            
            # Extraer ID de entidad si está en la URL
            entity_id = self._extract_entity_id(request.url.path)
            
            # Crear el log de auditoría
            db = next(get_db())
            try:
                audit_log = AuditLog(
                    user_id=user_id,
                    action=action,
                    entity_type=entity_type,
                    entity_id=entity_id,
                    old_values=None,  # Se puede implementar para operaciones UPDATE
                    new_values={
                        "request": request_data,
                        "response": response_data,
                        "duration_seconds": round(duration, 3),
                        "timestamp": datetime.utcnow().isoformat()
                    },
                    ip_address=request.client.host,
                    user_agent=request.headers.get("user-agent", ""),
                    session_id=request.headers.get("x-session-id")
                )
                
                db.add(audit_log)
                db.commit()
            finally:
                db.close()
                
        except Exception as e:
            # Log error but don't break the request flow
            print(f"Error creating audit log: {str(e)}")

    async def _get_user_from_request(self, request: Request) -> Optional[Dict[str, Any]]:
        """Extrae información del usuario de la request"""
        try:
            # Buscar token en headers
            auth_header = request.headers.get("authorization")
            if auth_header and auth_header.startswith("Bearer "):
                token = auth_header.split(" ")[1]
                user_data = decode_token(token)
                return user_data
        except Exception:
            pass
        
        return None

    def _determine_action(self, path: str, method: str) -> str:
        """Determina la acción basada en el path y método HTTP"""
        # Buscar en configuración específica
        for endpoint_path, config in self.AUDIT_ENDPOINTS.items():
            if path.startswith(endpoint_path):
                if isinstance(config, dict):
                    return config.get(method, f"{method}_{endpoint_path.split('/')[-1].upper()}")
                else:
                    return config
        
        # Acción genérica basada en método HTTP
        action_map = {
            "GET": "VIEW",
            "POST": "CREATE",
            "PUT": "UPDATE",
            "PATCH": "UPDATE",
            "DELETE": "DELETE"
        }
        
        entity = path.split('/')[-1] if '/' in path else "RESOURCE"
        return f"{action_map.get(method, method)}_{entity.upper()}"

    def _determine_entity_type(self, path: str) -> str:
        """Determina el tipo de entidad basado en el path"""
        if "/inventory" in path:
            return "inventory_item"
        elif "/loans" in path:
            return "loan"
        elif "/users" in path:
            return "user"
        elif "/maintenance" in path:
            return "maintenance_request"
        elif "/environments" in path:
            return "environment"
        elif "/inventory-checks" in path:
            return "inventory_check"
        elif "/auth" in path:
            return "authentication"
        else:
            return "unknown"

    def _extract_entity_id(self, path: str) -> Optional[str]:
        """Extrae el ID de entidad de la URL si está presente"""
        try:
            # Buscar UUID en el path (formato: /api/resource/{uuid})
            parts = path.split('/')
            for part in parts:
                if len(part) == 36 and part.count('-') == 4:  # UUID format
                    return part
        except Exception:
            pass
        
        return None
