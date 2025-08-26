from sqlalchemy import Boolean, CheckConstraint, Column, String, Integer, Date, Time, Text, ForeignKey, TIMESTAMP, DateTime
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
import uuid

from ..database import Base

class InventoryCheck(Base):
    __tablename__ = "inventory_checks"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    environment_id = Column(UUID(as_uuid=True), ForeignKey('environments.id', ondelete='CASCADE'), nullable=False)
    student_id = Column(UUID(as_uuid=True), ForeignKey('users.id', ondelete='CASCADE'), nullable=False)
    instructor_id = Column(UUID(as_uuid=True), ForeignKey('users.id', ondelete='SET NULL'))  
    schedule_id = Column(UUID(as_uuid=True), ForeignKey('schedules.id', ondelete='SET NULL'))
    check_date = Column(Date, nullable=False)
    check_time = Column(Time, nullable=False)
    status = Column(String(20), nullable=False)  
    total_items = Column(Integer)
    items_good = Column(Integer)
    items_damaged = Column(Integer)
    items_missing = Column(Integer)
    is_clean = Column(Boolean)
    is_organized = Column(Boolean)
    inventory_complete = Column(Boolean)
    cleaning_notes = Column(Text)
    comments = Column(Text)
    instructor_confirmed_at = Column(DateTime, server_default=func.now())
    created_at = Column(DateTime, server_default=func.now())
    updated_at = Column(DateTime, server_default=func.now(), onupdate=func.now())

    environment = relationship("Environment", back_populates="inventory_checks")
    student = relationship("User", foreign_keys=[student_id], back_populates="inventory_checks_student")
    instructor = relationship("User", foreign_keys=[instructor_id], back_populates="inventory_checks_instructor")
    schedule = relationship("Schedule", back_populates="inventory_checks")
    items = relationship("InventoryCheckItem", back_populates="check")
    supervisor_reviews = relationship("SupervisorReview", back_populates="check")


    __table_args__ = (
        CheckConstraint("status IN ('pending', 'complete', 'incomplete', 'issues', 'supervisor_review', 'instructor_review')", name="check_status"),
    )