from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from .routers import auth, environments, inventory, qr, schedules, users, inventory_checks, supervisor_reviews, inventory_check_items, system_alerts, notifications, maintenance_requests, maintenance_history, stats, loans, alert_settings, reports, audit_logs, feedback
from .middleware.audit_middleware import AuditMiddleware
from .config import settings

app = FastAPI(title="Sistema de Gestión de Inventarios SENA")

# Configuración de CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.add_middleware(AuditMiddleware)

# Incluir routers
app.include_router(auth.router, prefix="/api/auth", tags=["auth"])
app.include_router(environments.router, prefix="/api/environments", tags=["environments"])
app.include_router(inventory.router, prefix="/api/inventory", tags=["inventory"])
app.include_router(inventory_checks.router, prefix="/api/inventory-checks", tags=["inventory-checks"])
app.include_router(qr.router, prefix="/api/qr", tags=["qr"])
app.include_router(schedules.router, prefix="/api/schedules")
app.include_router(users.router, prefix="/api/users", tags=["users"])
app.include_router(supervisor_reviews.router, prefix="/api/supervisor-reviews", tags=["supervisor-reviews"])
app.include_router(inventory_check_items.router, prefix="/api/inventory-check-items", tags=["inventory-check-items"])
app.include_router(system_alerts.router, prefix="/api/system-alerts", tags=["system-alerts"])
app.include_router(notifications.router, prefix="/api/notifications", tags=["notifications"])
app.include_router(maintenance_requests.router, prefix="/api/maintenance-requests", tags=["maintenance-requests"])
app.include_router(maintenance_history.router, prefix="/api/maintenance-history", tags=["maintenance-history"])
app.include_router(stats.router, prefix="/api/stats", tags=["stats"])
app.include_router(loans.router, prefix="/api/loans", tags=["loans"])
app.include_router(alert_settings.router, prefix="/api/alert-settings", tags=["alert-settings"])
app.include_router(reports.router, prefix="/api/reports", tags=["reports"])
app.include_router(audit_logs.router, prefix="/api/audit-logs", tags=["audit-logs"])
app.include_router(feedback.router, prefix="/api/feedback", tags=["feedback"])

@app.get("/")
async def root():
    return {"message": "Sistema de Gestión de Inventarios SENA. ¡Bienvenido!"}
