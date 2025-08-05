from sqlalchemy import CheckConstraint, Column, String, Integer, TIMESTAMP, ForeignKey
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.sql import func
import uuid

from ..database import Base

class GeneratedReport(Base):
    __tablename__ = "generated_reports"
    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    report_type = Column(String(50), nullable=False)
    title = Column(String(200), nullable=False)
    parameters = Column(JSONB)
    file_path = Column(String(500))
    file_format = Column(String(10), nullable=False)
    file_size = Column(Integer)
    status = Column(String(20), nullable=False, default="generating")
    generated_at = Column(TIMESTAMP)
    expires_at = Column(TIMESTAMP)
    download_count = Column(Integer, default=0)
    created_at = Column(TIMESTAMP, server_default=func.current_timestamp())
    __table_args__ = (
        CheckConstraint("file_format IN ('pdf', 'excel', 'csv')", name="check_file_format"),
        CheckConstraint("status IN ('generating', 'completed', 'failed')", name="check_status"),
    )