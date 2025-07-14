from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from ..database import get_db
from ..schemas.user import LoginRequest, TokenResponse, UserCreate, UserResponse
from ..services.auth_service import authenticate_user
from ..utils.security import hash_password
from ..models.users import User

router = APIRouter(prefix="/api/auth", tags=["auth"])

@router.post("/login", response_model=TokenResponse)
async def login(login_request: LoginRequest, db: Session = Depends(get_db)):
    return authenticate_user(db, login_request)

@router.post("/register", response_model=UserResponse)
async def register(user_create: UserCreate, db: Session = Depends(get_db)):
    # Verificar si el email ya existe
    existing_user = db.query(User).filter(User.email == user_create.email).first()
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="El correo electrónico ya está registrado",
        )
    
    # Hashear la contraseña
    hashed_password = hash_password(user_create.password)
    
    # Crear nuevo usuario
    new_user = User(
        email=user_create.email,
        password_hash=hashed_password,
        role=user_create.role,
        first_name=user_create.first_name,
        last_name=user_create.last_name,
        phone=user_create.phone,
        program=user_create.program,
        ficha=user_create.ficha,
        avatar_url=user_create.avatar_url,
        is_active=True
    )
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    
    return new_user