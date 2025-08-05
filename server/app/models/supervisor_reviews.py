from sqlalchemy import CheckConstraint, Column, Integer, String, Text, ForeignKey, TIMESTAMP
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.sql import func
import uuid

from ..database import Base

class SupervisorReview(Base):
    __tablename__ = "supervisor_reviews"
    id = Column(Integer, primary_key=True)
    check_id = Column(Integer, ForeignKey("inventory_checks.id", ondelete="CASCADE"), nullable=False)
    supervisor_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    status = Column(String(20), nullable=False)
    comments = Column(Text)
    reviewed_at = Column(TIMESTAMP, server_default=func.current_timestamp())
    created_at = Column(TIMESTAMP, server_default=func.current_timestamp())
    __table_args__ = (
        CheckConstraint("status IN ('pending', 'approved', 'rejected')", name="check_status"),
    )