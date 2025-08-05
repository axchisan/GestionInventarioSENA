from sqlalchemy import CheckConstraint, Column, String, Integer, Text, ForeignKey, TIMESTAMP
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.sql import func
import uuid

from ..database import Base

class InventoryCheckItem(Base):
    __tablename__ = "inventory_check_items"
    id = Column(Integer, primary_key=True)
    check_id = Column(Integer, ForeignKey("inventory_checks.id", ondelete="CASCADE"), nullable=False)
    item_id = Column(Integer, ForeignKey("inventory_items.id", ondelete="CASCADE"), nullable=False)
    status = Column(String(20), nullable=False)
    quantity_expected = Column(Integer, default=1)
    quantity_found = Column(Integer, default=0)
    notes = Column(Text)
    created_at = Column(TIMESTAMP, server_default=func.current_timestamp())
    __table_args__ = (
        CheckConstraint("status IN ('good', 'damaged', 'missing')", name="check_status"),
    )