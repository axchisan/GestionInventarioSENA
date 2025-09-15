from sqlalchemy import CheckConstraint, Column, Integer, String, Date, Text, ForeignKey, TIMESTAMP, Boolean
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
import uuid

from ..database import Base

class Loan(Base):
    __tablename__ = "loans"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    instructor_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    item_id = Column(UUID(as_uuid=True), ForeignKey("inventory_items.id", ondelete="CASCADE"), nullable=True)
    admin_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL"))
    environment_id = Column(UUID(as_uuid=True), ForeignKey("environments.id", ondelete="CASCADE"), nullable=False)
    program = Column(String(100), nullable=False)
    purpose = Column(Text, nullable=False)
    start_date = Column(Date, nullable=False)
    end_date = Column(Date, nullable=False)
    actual_return_date = Column(Date)
    status = Column(String(20), nullable=False, default="pending")
    rejection_reason = Column(Text)
    item_name = Column(String(200), nullable=True)  # For non-registered items
    item_description = Column(Text, nullable=True)  # For non-registered items
    is_registered_item = Column(Boolean, default=True, nullable=False)  # True if item_id exists, False for custom items
    quantity_requested = Column(Integer, default=1, nullable=False)
    priority = Column(String(10), default="media", nullable=False)
    acta_pdf_path = Column(String(500))
    created_at = Column(TIMESTAMP, server_default=func.current_timestamp())
    updated_at = Column(TIMESTAMP, server_default=func.current_timestamp())

    instructor = relationship("User", foreign_keys=[instructor_id])
    admin = relationship("User", foreign_keys=[admin_id])
    item = relationship("InventoryItem", back_populates="loans")
    environment = relationship("Environment", back_populates="loans_from_environment")

    __table_args__ = (
        CheckConstraint("status IN ('pending', 'approved', 'rejected', 'active', 'returned', 'overdue')", name="check_status"),
        CheckConstraint("priority IN ('alta', 'media', 'baja')", name="check_priority"),
    )
