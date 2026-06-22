from __future__ import annotations

from datetime import date, datetime

from pydantic import BaseModel, ConfigDict, Field, computed_field

from app.models.schedule import EventType, PracticeBlockType


class PracticeBlockBase(BaseModel):
    block_order: int = Field(ge=1)
    block_type: PracticeBlockType
    title: str | None = Field(default=None, max_length=160)
    notes: str | None = Field(default=None, max_length=2000)
    duration_minutes: int = Field(gt=0, le=240)


class PracticeBlockCreate(PracticeBlockBase):
    pass


class PracticeBlockRead(PracticeBlockBase):
    model_config = ConfigDict(from_attributes=True)

    id: int


class EventBase(BaseModel):
    team_id: int
    title: str = Field(min_length=1, max_length=160)
    description: str | None = Field(default=None, max_length=2000)
    event_type: EventType
    starts_at: datetime
    ends_at: datetime
    location: str | None = Field(default=None, max_length=180)
    notes: str | None = Field(default=None, max_length=4000)
    checklist: list[str] = Field(default_factory=list)
    bus_departure_note: str | None = Field(default=None, max_length=255)
    weigh_in_note: str | None = Field(default=None, max_length=255)
    practice_plan_id: int | None = None


class EventCreate(EventBase):
    pass


class EventUpdate(BaseModel):
    title: str | None = Field(default=None, min_length=1, max_length=160)
    description: str | None = Field(default=None, max_length=2000)
    event_type: EventType | None = None
    starts_at: datetime | None = None
    ends_at: datetime | None = None
    location: str | None = Field(default=None, max_length=180)
    notes: str | None = Field(default=None, max_length=4000)
    checklist: list[str] | None = None
    bus_departure_note: str | None = Field(default=None, max_length=255)
    weigh_in_note: str | None = Field(default=None, max_length=255)
    practice_plan_id: int | None = None
    is_cancelled: bool | None = None


class PracticePlanBase(BaseModel):
    team_id: int
    title: str = Field(min_length=1, max_length=160)
    description: str | None = Field(default=None, max_length=2000)
    focus: str | None = Field(default=None, max_length=180)
    practice_date: date | None = None
    notes: str | None = Field(default=None, max_length=4000)
    template_id: int | None = None
    blocks: list[PracticeBlockCreate] = Field(default_factory=list)


class PracticePlanCreate(PracticePlanBase):
    pass


class PracticePlanUpdate(BaseModel):
    title: str | None = Field(default=None, min_length=1, max_length=160)
    description: str | None = Field(default=None, max_length=2000)
    focus: str | None = Field(default=None, max_length=180)
    practice_date: date | None = None
    notes: str | None = Field(default=None, max_length=4000)
    template_id: int | None = None
    blocks: list[PracticeBlockCreate] | None = None


class PracticeTemplateBase(BaseModel):
    team_id: int
    template_name: str = Field(min_length=1, max_length=120)
    description: str | None = Field(default=None, max_length=2000)
    focus: str | None = Field(default=None, max_length=180)
    blocks: list[PracticeBlockCreate] = Field(default_factory=list)


class PracticeTemplateCreate(PracticeTemplateBase):
    pass


class PracticeTemplateRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    team_id: int
    created_by_user_id: int
    template_name: str
    description: str | None
    focus: str | None
    total_duration_minutes: int
    is_system_template: bool
    created_at: datetime
    updated_at: datetime
    blocks: list[PracticeBlockRead]


class PracticePlanRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    team_id: int
    created_by_user_id: int
    template_id: int | None
    title: str
    description: str | None
    focus: str | None
    practice_date: date | None
    notes: str | None
    total_duration_minutes: int
    template_name_snapshot: str | None
    is_template_based: bool
    created_at: datetime
    updated_at: datetime
    blocks: list[PracticeBlockRead]

    @computed_field
    @property
    def total_block_count(self) -> int:
        return len(self.blocks)


class EventRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    team_id: int
    created_by_user_id: int
    practice_plan_id: int | None
    external_tournament_id: int | None
    title: str
    description: str | None
    event_type: EventType
    starts_at: datetime
    ends_at: datetime
    location: str | None
    notes: str | None
    checklist: list[str] | None
    bus_departure_note: str | None
    weigh_in_note: str | None
    is_cancelled: bool
    created_at: datetime
    updated_at: datetime
    practice_plan: PracticePlanRead | None = None

    @computed_field
    @property
    def total_minutes(self) -> int:
        return int((self.ends_at - self.starts_at).total_seconds() // 60)


class PracticePlanSummaryRead(BaseModel):
    id: int
    title: str
    practice_date: date | None
    focus: str | None
    total_duration_minutes: int
    template_name_snapshot: str | None
    total_block_count: int


class ScheduleSummaryRead(BaseModel):
    total_events: int
    practice_count: int
    competition_count: int
    travel_count: int
    meeting_count: int
    fundraiser_count: int
    upcoming_week_count: int


class TeamScheduleRead(BaseModel):
    team_id: int
    visible_as: str
    summary: ScheduleSummaryRead
    events: list[EventRead]


class PracticeDuplicateRequest(BaseModel):
    practice_date: date | None = None
    title: str | None = Field(default=None, max_length=160)


class PracticeAssignToDateRequest(BaseModel):
    target_date: date
    starts_at: datetime
    ends_at: datetime
    location: str | None = Field(default=None, max_length=180)
    notes: str | None = Field(default=None, max_length=4000)
    checklist: list[str] = Field(default_factory=list)
    bus_departure_note: str | None = Field(default=None, max_length=255)
    weigh_in_note: str | None = Field(default=None, max_length=255)


class PracticeAssignmentRead(BaseModel):
    practice: PracticePlanRead
    event: EventRead
