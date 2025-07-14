from sqlalchemy import CheckConstraint, Column, String, Date, Text, ForeignKey, TIMESTAMP
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.sql import func
import uuid

from ..database import Base

class Loan(Base):
    __tablename__ = "loans"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    instructor_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    item_id = Column(UUID(as_uuid=True), ForeignKey("inventory_items.id", ondelete="CASCADE"), nullable=False)
    admin_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL"))
    program = Column(String(100), nullable=False)
    purpose = Column(Text, nullable=False)
    start_date = Column(Date, nullable=False)
    end_date = Column(Date, nullable=False)
    actual_return_date = Column(Date)
    status = Column(String(20), nullable=False, default="pending")
    rejection_reason = Column(Text

)
    acta_pdf_path = Column(String(500))
    created_at = Column(TIMESTAMP, server_default=func.current_timestamp())
    updated_at = Column(TIMESTAMP, server_default=func.current_timestamp())

    __table_args__ = (
        CheckConstraint("status IN ('pending', 'approved', 'rejected', 'active', 'returned', 'overdue')", name="check_status"),
    )