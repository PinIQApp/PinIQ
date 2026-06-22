from __future__ import annotations

from datetime import date, datetime

from pydantic import BaseModel, ConfigDict, Field

from app.models.weight import WeightAlertStatus, WeightAlertType, WeightPlanStatus


class WeightLogCreate(BaseModel):
    athlete_id: int
    team_id: int
    logged_at: datetime
    weight: float = Field(gt=0, le=400)
    body_fat_percentage: float | None = Field(default=None, ge=1, le=50)
    hydration_note: str | None = Field(default=None, max_length=255)
    comments: str | None = Field(default=None, max_length=1000)


class WeightLogRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    athlete_id: int
    team_id: int
    created_by_user_id: int
    logged_at: datetime
    weight: float
    body_fat_percentage: float | None
    hydration_note: str | None
    comments: str | None
    created_at: datetime


class LinkedAthleteRead(BaseModel):
    athlete_id: int
    athlete_name: str
    team_id: int
    relationship_label: str


class WeightPlanCalculateRequest(BaseModel):
    athlete_id: int
    team_id: int
    current_weight: float = Field(gt=0, le=400)
    body_fat_percentage: float | None = Field(default=None, ge=1, le=50)
    target_weight_class: float = Field(gt=0, le=400)
    target_date: date


class WeightPlanRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    athlete_id: int
    team_id: int
    athlete_target_id: int | None
    calculated_at: datetime
    current_weight: float
    body_fat_percentage: float | None
    target_weight_class: float
    target_date: date
    weekly_allowed_loss: float
    required_weekly_loss: float
    projected_reachable_weight: float
    estimated_reachable_class: float
    projected_target_date: date
    status: WeightPlanStatus
    warning_message: str | None
    summary: str
    plan_details: dict | None


class WeightAlertRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    athlete_id: int
    team_id: int
    plan_id: int | None
    alert_type: WeightAlertType
    alert_message: str
    status: WeightAlertStatus
    severity: WeightPlanStatus
    triggered_at: datetime
    resolved_at: datetime | None


class AthleteWeightSnapshot(BaseModel):
    athlete_id: int
    athlete_name: str
    grade_label: str | None
    team_group: str | None
    current_weight: float | None
    latest_log_at: datetime | None
    target_weight_class: float | None
    target_date: date | None
    projected_reachable_weight: float | None
    projected_class: float | None
    weekly_allowed_loss: float | None
    required_weekly_loss: float | None
    status: WeightPlanStatus
    status_summary: str
    warning_message: str | None
    alerts: list[WeightAlertRead]


class WeightPlanWithHistory(BaseModel):
    athlete_id: int
    latest_plan: WeightPlanRead | None
    recent_logs: list[WeightLogRead]
    active_alerts: list[WeightAlertRead]

