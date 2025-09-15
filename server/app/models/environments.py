from sqlalchemy import Column, ForeignKey, String, Integer, Boolean, TIMESTAMP, Text
from sqlalchemy.orm import relationship
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.sql import func
import uuid

from ..database import Base

class Environment(Base):
    __tablename__ = "environments"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    center_id = Column(UUID(as_uuid=True), ForeignKey("centers.id", ondelete="CASCADE"), nullable=False)
    name = Column(String(100), nullable=False)
    location = Column(String(200), nullable=False)
    capacity = Column(Integer, nullable=False, default=30)
    qr_code = Column(String(100), unique=True, nullable=False)
    description = Column(Text)
    is_warehouse = Column(Boolean, default=False, nullable=False)
    is_active = Column(Boolean, default=True)
    created_at = Column(TIMESTAMP, server_default=func.current_timestamp())
    updated_at = Column(TIMESTAMP, server_default=func.current_timestamp())

    inventory_checks = relationship("InventoryCheck", back_populates="environment")
    inventory_items = relationship("InventoryItem", back_populates="environment")
    loans_from_environment = relationship("Loan", foreign_keys="[Loan.environment_id]", back_populates="environment")
