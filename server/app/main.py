from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from .routers import auth, users, environments, inventory, schedules, checks, loans, maintenance, notifications, reports, settings

app = FastAPI(title="Sistema de Gestión de Inventarios SENA")

# Configuración de CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Ajustar en producción
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Incluir routers
app.include_router(auth.router, prefix="/api/auth", tags=["auth"])
app.include_router(users.router, prefix="/api/users", tags=["users"])
app.include_router(environments.router, prefix="/api/environments", tags=["environments"])
app.include_router(inventory.router, prefix="/api/inventory", tags=["inventory"])
app.include_router(schedules.router, prefix="/api/schedules", tags=["schedules"])
app.include_router(checks.router, prefix="/api/checks", tags=["checks"])
app.include_router(loans.router, prefix="/api/loans", tags=["loans"])
app.include_router(maintenance.router, prefix="/api/maintenance", tags=["maintenance"])
app.include_router(notifications.router, prefix="/api/notifications", tags=["notifications"])
app.include_router(reports.router, prefix="/api/reports", tags=["reports"])
app.include_router(settings.router, prefix="/api/settings", tags=["settings"])

@app.get("/")
async def root():
    return {"message": "Sistema de Gestión de Inventarios SENA"}