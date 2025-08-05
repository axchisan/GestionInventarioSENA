from sqlalchemy import Column, Integer, String, Boolean, TIMESTAMP, CheckConstraint
from sqlalchemy.sql import func


from ..database import Base

class User(Base):
    __tablename__ = "users"
    id = Column(Integer, primary_key=True)
    email = Column(String(255), unique=True, nullable=False)
    password_hash = Column(String(255), nullable=False)
    role = Column(String(20), nullable=False)
    first_name = Column(String(100), nullable=False)
    last_name = Column(String(100), nullable=False)
    phone = Column(String(20))
    program = Column(String(100))
    ficha = Column(String(20))
    avatar_url = Column(String(500))
    is_active = Column(Boolean, default=True)
    last_login = Column(TIMESTAMP)
    created_at = Column(TIMESTAMP, server_default=func.current_timestamp())
    updated_at = Column(TIMESTAMP, server_default=func.current_timestamp())
    __table_args__ = (
        CheckConstraint("role IN ('student', 'instructor', 'supervisor', 'admin')", name="check_role"),
    )