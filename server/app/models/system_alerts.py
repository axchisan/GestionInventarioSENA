from sqlalchemy import CheckConstraint, Column, Integer, String, Text, Boolean, TIMESTAMP, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.sql import func
import uuid

from ..database import Base

class SystemAlert(Base):
    __tablename__ = "system_alerts"
    id = Column(Integer, primary_key=True)
    type = Column(String(50), nullable=False)
    title = Column(String(200), nullable=False)
    message = Column(Text, nullable=False)
    severity = Column(String(20), nullable=False)
    entity_type = Column(String(50))
    entity_id = Column(Integer)
    is_resolved = Column(Boolean, default=False)
    resolved_by = Column(Integer, ForeignKey("users.id", ondelete="SET NULL"))
    resolved_at = Column(TIMESTAMP)
    created_at = Column(TIMESTAMP, server_default=func.current_timestamp())
    __table_args__ = (
        CheckConstraint("type IN ('low_stock', 'maintenance_overdue', 'equipment_missing', 'loan_overdue', 'verification_pending')", name="check_type"),
        CheckConstraint("severity IN ('low', 'medium', 'high', 'critical')", name="check_severity"),
    )