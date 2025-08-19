from pydantic import BaseModel
from uuid import UUID
from datetime import date, time, datetime
from typing import Optional

class ScheduleCreate(BaseModel):
    environment_id: UUID
    instructor_id: UUID
    program: str
    ficha: str
    topic: Optional[str] = None
    start_time: time
    end_time: time
    day_of_week: int
    start_date: date
    end_date: date
    student_count: int = 0
    is_active: bool = True

class ScheduleResponse(BaseModel):
    id: UUID
    environment_id: UUID
    instructor_id: UUID
    program: str
    ficha: str
    topic: Optional[str]
    start_time: time
    end_time: time
    day_of_week: int
    start_date: date
    end_date: date
    student_count: int
    is_active: bool
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True
