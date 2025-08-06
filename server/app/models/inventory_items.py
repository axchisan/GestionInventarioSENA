from sqlalchemy import TIMESTAMP, CheckConstraint, Column, String, Integer, Date, Text, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.sql import func
import uuid

from ..database import Base

class InventoryItem(Base):
    __tablename__ = "inventory_items"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    environment_id = Column(UUID(as_uuid=True), ForeignKey("environments.id", ondelete="SET NULL"))
    name = Column(String(100), nullable=False)
    serial_number = Column(String(100), unique=True)
    internal_code = Column(String(50), unique=True, nullable=False)
    category = Column(String(20), nullable=False)
    brand = Column(String(50))
    model = Column(String(100))
    status = Column(String(20), nullable=False, default="available")
    purchase_date = Column(Date)
    warranty_expiry = Column(Date)
    last_maintenance = Column(Date)
    next_maintenance = Column(Date)
    image_url = Column(String(500))
    notes = Column(Text)
    created_at = Column(TIMESTAMP, server_default=func.current_timestamp())
    updated_at = Column(TIMESTAMP, server_default=func.current_timestamp())

    __table_args__ = (
        CheckConstraint("category IN ('computer', 'projector', 'keyboard', 'mouse', 'tv', 'camera', 'microphone', 'tablet', 'other')", name="check_category"),
        CheckConstraint("status IN ('available', 'in_use', 'maintenance', 'damaged', 'lost')", name="check_status"),
    )