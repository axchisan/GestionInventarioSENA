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


@app.get("/")
async def root():
    return {"message": "Sistema de Gestión de Inventarios SENA"}