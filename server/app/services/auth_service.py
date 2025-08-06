from fastapi import HTTPException, status
from sqlalchemy.orm import Session
from datetime import datetime
from typing import cast
from ..models.users import User
from ..schemas.user import LoginRequest, TokenResponse
from ..utils.security import verify_password, create_access_token

def authenticate_user(db: Session, login_request: LoginRequest) -> TokenResponse:
    user = db.query(User).filter(User.email == login_request.email).first()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Correo o contraseña incorrectos",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    if not verify_password(login_request.password, cast(str, user.password_hash)):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Correo o contraseña incorrectos",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    if not cast(bool, user.is_active):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="La cuenta de usuario está inactiva",
        )
    
    access_token = create_access_token(data={"sub": str(user.id), "role": cast(str, user.role)})
    
    db.query(User).filter(User.id == user.id).update({"last_login": datetime.utcnow()})
    db.commit()
    
    return TokenResponse(
        access_token=access_token,
        token_type="bearer",
        role=cast(str, user.role)
    )