from sqlalchemy import CheckConstraint, Column, String, Integer, Date, Time, Text, ForeignKey, TIMESTAMP
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.sql import func
import uuid

from ..database import Base

class InventoryCheck(Base):
    __tablename__ = "inventory_checks"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    environment_id = Column(UUID(as_uuid=True), ForeignKey("environments.id", ondelete="CASCADE"), nullable=False)
    student_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    schedule_id = Column(UUID(as_uuid=True), ForeignKey("schedules.id", ondelete="SET NULL"))
    check_date = Column(Date, nullable=False)
    check_time = Column(Time, nullable=False)
    status = Column(String(20), nullable=False, default="pending")
    total_items = Column(Integer, default=0)
    items_good = Column(Integer, default=0)
    items_damaged = Column(Integer, default=0)
    items_missing = Column(Integer, default=0)
    comments = Column(Text)
    created_at = Column(TIMESTAMP, server_default=func.current_timestamp())
    updated_at = Column(TIMESTAMP, server_default=func.current_timestamp())

    __table_args__ = (
        CheckConstraint("status IN ('pending', 'complete', 'incomplete', 'issues')", name="check_status"),
    )