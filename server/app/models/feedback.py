from sqlalchemy import CheckConstraint, Column, String, Text, Integer, Boolean, TIMESTAMP, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.sql import func
import uuid

from ..database import Base

class Feedback(Base):
    __tablename__ = "feedback"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    type = Column(String(20), nullable=False)
    category = Column(String(50))
    title = Column(String(200), nullable=False)
    description = Column(Text, nullable=False)
    steps_to_reproduce = Column(Text)
    priority = Column(String(20), default="medium")
    rating = Column(Integer)
    status = Column(String(20), default="submitted")
    admin_response = Column(Text)
    include_device_info = Column(Boolean, default=False)
    include_logs = Column(Boolean, default=False)
    allow_follow_up = Column(Boolean, default=True)
    created_at = Column(TIMESTAMP, server_default=func.current_timestamp())
    updated_at = Column(TIMESTAMP, server_default=func.current_timestamp())

    __table_args__ = (
        CheckConstraint("type IN ('bug', 'suggestion', 'feature', 'compliment', 'complaint', 'other')", name="check_type"),
        CheckConstraint("priority IN ('low', 'medium', 'high')", name="check_priority"),
        CheckConstraint("status IN ('submitted', 'reviewed', 'in_progress', 'completed', 'rejected')", name="check_status"),
        CheckConstraint("rating BETWEEN 1 AND 5", name="check_rating"),
    )