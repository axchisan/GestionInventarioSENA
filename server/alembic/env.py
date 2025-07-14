from logging.config import fileConfig
from sqlalchemy import engine_from_config, pool
from alembic import context
from app.database import Base
from app.config import settings

# Modelos para importar
from app.models import users, environments, inventory_items, schedules, inventory_checks, inventory_check_items
from app.models import supervisor_reviews, loans, maintenance_requests, maintenance_history, notifications
from app.models import system_alerts, alert_settings, generated_reports, feedback, audit_logs, user_settings

config = context.config
fileConfig(config.config_file_name)

connectable = engine_from_config(
    config.get_section(config.config_ini_section),
    prefix="sqlalchemy.",
    poolclass=pool.NullPool)

with connectable.connect() as connection:
    context.configure(
        connection=connection,
        target_metadata=Base.metadata
    )

    with context.begin_transaction():
        context.run_migrations()