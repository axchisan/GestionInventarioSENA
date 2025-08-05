from sqlalchemy import CheckConstraint, Column, Integer, String, Text, Boolean, TIMESTAMP, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.sql import func
import uuid

from ..database import Base

class Notification(Base):
    __tablename__ = "notifications"
    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    type = Column(String(50), nullable=False)
    title = Column(String(200), nullable=False)
    message = Column(Text, nullable=False)
    is_read = Column(Boolean, default=False)
    priority = Column(String(20), default="medium")
    action_url = Column(String(500))
    expires_at = Column(TIMESTAMP)
    created_at = Column(TIMESTAMP, server_default=func.current_timestamp())
    __table_args__ = (
        CheckConstraint("type IN ('loan_approved', 'loan_rejected', 'loan_overdue', 'check_reminder', 'maintenance_update', 'verification_pending', 'alert', 'system')", name="check_type"),
        CheckConstraint("priority IN ('low', 'medium', 'high')", name="check_priority"),
    )