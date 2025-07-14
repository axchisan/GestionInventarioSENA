from sqlalchemy import CheckConstraint, Column, String, Text, Date, Numeric, ForeignKey, TIMESTAMP
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.sql import func
import uuid

from ..database import Base

class MaintenanceHistory(Base):
    __tablename__ = "maintenance_history"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    item_id = Column(UUID(as_uuid=True), ForeignKey("inventory_items.id", ondelete="CASCADE"), nullable=False)
    request_id = Column(UUID(as_uuid=True), ForeignKey("maintenance_requests.id", ondelete="SET NULL"))
    technician_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL"))
    maintenance_type = Column(String(50), nullable=False)
    description = Column(Text, nullable=False)
    cost = Column(Numeric(10, 2))
    parts_replaced = Column(Text)
    maintenance_date = Column(Date, nullable=False)
    next_maintenance_date = Column(Date)
    created_at = Column(TIMESTAMP, server_default=func.current_timestamp())

    __table_args__ = (
        CheckConstraint("maintenance_type IN ('preventive', 'corrective', 'upgrade')", name="check_maintenance_type"),
    )