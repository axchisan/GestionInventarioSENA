from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from .routers import auth, environments, inventory, qr
from .config import settings

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
app.include_router(environments.router, prefix="/api/environments", tags=["environments"])
app.include_router(inventory.router, prefix="/api/inventory", tags=["inventory"])
app.include_router(qr.router, prefix="/api/qr", tags=["qr"])

@app.get("/")
async def root():
    return {"message": "Sistema de Gestión de Inventarios SENA. ¡Bienvenido!"}