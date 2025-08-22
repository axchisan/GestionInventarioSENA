from sqlalchemy import Column, ForeignKey, String, Boolean, TIMESTAMP, CheckConstraint
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
import uuid

from ..database import Base

class User(Base):
    __tablename__ = "users"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    email = Column(String(255), unique=True, nullable=False)
    password_hash = Column(String(255), nullable=False)
    role = Column(String(20), nullable=False)
    first_name = Column(String(100), nullable=False)
    last_name = Column(String(100), nullable=False)
    phone = Column(String(20))
    program = Column(String(100))
    ficha = Column(String(20))
    environment_id = Column(UUID(as_uuid=True), ForeignKey("environments.id", ondelete="SET NULL"))
    avatar_url = Column(String(500))
    is_active = Column(Boolean, default=True)
    last_login = Column(TIMESTAMP)
    created_at = Column(TIMESTAMP, server_default=func.current_timestamp())
    updated_at = Column(TIMESTAMP, server_default=func.current_timestamp())

    inventory_checks_student = relationship("InventoryCheck", foreign_keys="InventoryCheck.student_id", back_populates="student")
    inventory_checks_instructor = relationship("InventoryCheck", foreign_keys="InventoryCheck.instructor_id", back_populates="instructor")

    __table_args__ = (
        CheckConstraint("role IN ('student', 'instructor', 'supervisor', 'admin', 'admin_general')", name="check_role"),
    )