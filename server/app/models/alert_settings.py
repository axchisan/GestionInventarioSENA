from sqlalchemy import CheckConstraint, Column, String, Integer, Boolean, TIMESTAMP, ForeignKey
from sqlalchemy.dialects.postgresql import UUID, ARRAY
from sqlalchemy.sql import func
from sqlalchemy.sql.schema import UniqueConstraint


from ..database import Base

class AlertSetting(Base):
    __tablename__ = "alert_settings"
    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    alert_type = Column(String(50), nullable=False)
    is_enabled = Column(Boolean, default=True)
    threshold_value = Column(Integer)
    notification_methods = Column(ARRAY(String))
    created_at = Column(TIMESTAMP, server_default=func.current_timestamp())
    updated_at = Column(TIMESTAMP, server_default=func.current_timestamp())
    __table_args__ = (
        CheckConstraint("alert_type IS NOT NULL", name="check_alert_type"),
        CheckConstraint("is_enabled IN (true, false)", name="check_is_enabled"),
        UniqueConstraint("user_id", "alert_type", name="uq_alert_setting_user_id_alert_type"),
    )