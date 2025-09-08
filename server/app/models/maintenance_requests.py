from sqlalchemy import Column, Integer, String, Text, Date, Numeric, ForeignKey, CheckConstraint, TIMESTAMP
from sqlalchemy.dialects.postgresql import UUID, ARRAY
from sqlalchemy.sql import func
import uuid

from ..database import Base

class MaintenanceRequest(Base):
    __tablename__ = "maintenance_requests"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    item_id = Column(UUID(as_uuid=True), ForeignKey("inventory_items.id", ondelete="CASCADE"), nullable=True)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    assigned_technician_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL"))
    environment_id = Column(UUID(as_uuid=True), ForeignKey("environments.id", ondelete="CASCADE"), nullable=True)
    title = Column(String(200), nullable=False)
    description = Column(Text, nullable=False)
    priority = Column(String(20), nullable=False, default="medium")
    status = Column(String(20), nullable=False, default="pending")
    category = Column(String(50), nullable=True)
    location = Column(String(200), nullable=True)
    estimated_completion = Column(Date)
    actual_completion = Column(Date)
    cost = Column(Numeric(10, 2))
    notes = Column(Text)
    images_urls = Column(ARRAY(String))
    quantity_affected = Column(Integer, default=1)  
    created_at = Column(TIMESTAMP, server_default=func.current_timestamp())
    updated_at = Column(TIMESTAMP, server_default=func.current_timestamp())

    __table_args__ = (
        CheckConstraint("priority IN ('low', 'medium', 'high', 'urgent')", name="check_priority"),
        CheckConstraint("status IN ('pending', 'assigned', 'in_progress', 'completed', 'cancelled')", name="check_status"),
        CheckConstraint("(item_id IS NOT NULL) OR (environment_id IS NOT NULL)", name="check_item_or_environment"),
    )
