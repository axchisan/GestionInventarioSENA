from sqlalchemy import TIMESTAMP, Column, String, Integer, Date, Text, ForeignKey, CheckConstraint
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
import uuid

from ..database import Base

class InventoryItem(Base):
    __tablename__ = "inventory_items"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    environment_id = Column(UUID(as_uuid=True), ForeignKey("environments.id", ondelete="CASCADE"))
    name = Column(String(100), nullable=False)
    serial_number = Column(String(100), unique=True, nullable=True)  
    internal_code = Column(String(50), unique=True, nullable=False)
    category = Column(String(20), nullable=False)
    brand = Column(String(50), nullable=True)  
    model = Column(String(100), nullable=True)  
    status = Column(String(20), nullable=False, default="available")
    purchase_date = Column(Date, nullable=True)
    warranty_expiry = Column(Date, nullable=True)
    last_maintenance = Column(Date, nullable=True)
    next_maintenance = Column(Date, nullable=True)
    image_url = Column(String(500), nullable=True)
    notes = Column(Text, nullable=True)
    quantity = Column(Integer, default=1, nullable=False)  
    item_type = Column(String(10), default='individual', nullable=False)  

    created_at = Column(TIMESTAMP, server_default=func.current_timestamp())
    updated_at = Column(TIMESTAMP, server_default=func.current_timestamp())

    environment = relationship("Environment", back_populates="inventory_items")

    __table_args__ = (
        CheckConstraint("category IN ('computer', 'projector', 'keyboard', 'mouse', 'tv', 'camera', 'microphone', 'tablet', 'other')", name="check_category"),
        CheckConstraint("status IN ('available', 'in_use', 'maintenance', 'damaged', 'lost')", name="check_status"),
        CheckConstraint("item_type IN ('individual', 'group')", name="check_item_type"),
        CheckConstraint("quantity >= 1", name="check_quantity"),
    )