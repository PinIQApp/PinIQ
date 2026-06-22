from __future__ import annotations

from datetime import date, datetime

from pydantic import BaseModel, ConfigDict, Field, computed_field

from app.models.stats import MatchOutcome, MatchResultType, StatAuditAction


class MatchBase(BaseModel):
    athlete_id: int
    team_id: int
    opponent_name: str = Field(min_length=1, max_length=120)
    opponent_school: str | None = Field(default=None, max_length=140)
    event_name: str | None = Field(default=None, max_length=160)
    match_date: date
    weight_class: str = Field(min_length=1, max_length=30)
    result: MatchOutcome
    result_type: MatchResultType
    score_for: int = Field(default=0, ge=0, le=99)
    score_against: int = Field(default=0, ge=0, le=99)
    pin_time: str | None = Field(default=None, max_length=12)
    notes: str | None = Field(default=None, max_length=4000)


class MatchCreate(MatchBase):
    pass


class MatchUpdate(BaseModel):
    opponent_name: str | None = Field(default=None, min_length=1, max_length=120)
    opponent_school: str | None = Field(default=None, max_length=140)
    event_name: str | None = Field(default=None, max_length=160)
    match_date: date | None = None
    weight_class: str | None = Field(default=None, min_length=1, max_length=30)
    result: MatchOutcome | None = None
    result_type: MatchResultType | None = None
    score_for: int | None = Field(default=None, ge=0, le=99)
    score_against: int | None = Field(default=None, ge=0, le=99)
    pin_time: str | None = Field(default=None, max_length=12)
    notes: str | None = Field(default=None, max_length=4000)


class MatchStatsCreate(BaseModel):
    takedowns: int = Field(default=0, ge=0, le=30)
    escapes: int = Field(default=0, ge=0, le=30)
    reversals: int = Field(default=0, ge=0, le=20)
    nearfall_points: int = Field(default=0, ge=0, le=30)
    stall_calls: int = Field(default=0, ge=0, le=20)
    ride_time_seconds: int | None = Field(default=None, ge=0, le=3600)
    shot_attempts: int | None = Field(default=None, ge=0, le=100)
    shot_conversions: int | None = Field(default=None, ge=0, le=100)


class MatchStatsRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    match_id: int
    athlete_id: int
    team_id: int
    takedowns: int
    escapes: int
    reversals: int
    nearfall_points: int
    stall_calls: int
    ride_time_seconds: int | None
    shot_attempts: int | None
    shot_conversions: int | None
    created_at: datetime
    updated_at: datetime

    @computed_field
    @property
    def shot_conversion_rate(self) -> float | None:
        if not self.shot_attempts:
            return None
        return round((self.shot_conversions or 0) / self.shot_attempts, 3)


class MatchRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    athlete_id: int
    team_id: int
    created_by_user_id: int
    updated_by_user_id: int | None
    opponent_name: str
    opponent_school: str | None
    event_name: str | None
    match_date: date
    weight_class: str
    result: MatchOutcome
    result_type: MatchResultType
    score_for: int
    score_against: int
    pin_time: str | None
    notes: str | None
    created_at: datetime
    updated_at: datetime
    stats: MatchStatsRead | None = None

    @computed_field
    @property
    def score_display(self) -> str:
        return f"{self.score_for}-{self.score_against}"


class RecordSummary(BaseModel):
    wins: int
    losses: int
    total_matches: int
    win_percentage: float


class ResultTypeBreakdown(BaseModel):
    pins: int
    tech_falls: int
    major_decisions: int
    decisions: int
    forfeits: int
    disqualifications: int
    medical_forfeits: int
    defaults: int
    pin_rate: float
    tech_fall_rate: float
    major_decision_rate: float
    decision_rate: float


class TrendSummary(BaseModel):
    last_five: list[str]
    trend_label: str
    recent_record: str


class StatAverages(BaseModel):
    takedowns_per_match: float
    escapes_per_match: float
    reversals_per_match: float
    nearfall_points_per_match: float
    stall_calls_per_match: float
    ride_time_seconds_per_match: float
    shot_conversion_rate: float | None


class StrengthWeaknessSummary(BaseModel):
    strengths: list[str]
    weaknesses: list[str]
    coach_summary: str


class AthleteStatsDashboardRead(BaseModel):
    athlete_id: int
    athlete_name: str
    team_id: int
    record: RecordSummary
    result_types: ResultTypeBreakdown
    bonus_point_wins: int
    bonus_point_rate: float
    recent_trend: TrendSummary
    last_five_matches: list[MatchRead]
    stat_averages: StatAverages
    strengths_weaknesses: StrengthWeaknessSummary
    visible_as: str
    snapshot_updated_at: datetime | None = None


class AthleteRecentRead(BaseModel):
    athlete_id: int
    team_id: int
    trend: TrendSummary
    matches: list[MatchRead]


class LeaderEntry(BaseModel):
    athlete_id: int
    athlete_name: str
    metric_label: str
    metric_value: float
    subtitle: str | None = None


class WeightClassBreakdownItem(BaseModel):
    weight_class: str
    total_matches: int
    wins: int
    losses: int
    win_percentage: float


class TeamStatsDashboardRead(BaseModel):
    team_id: int
    team_name: str
    record: RecordSummary
    bonus_point_wins: int
    bonus_point_rate: float
    total_pins: int
    recent_trend: TrendSummary
    leaders: list[LeaderEntry]
    weight_class_breakdown: list[WeightClassBreakdownItem]
    recent_matches: list[MatchRead]
    visible_as: str
    snapshot_updated_at: datetime | None = None


class TeamLeadersRead(BaseModel):
    team_id: int
    most_pins: list[LeaderEntry]
    best_win_percentage: list[LeaderEntry]
    bonus_point_leaders: list[LeaderEntry]


class StatAuditLogRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    team_id: int
    athlete_id: int | None
    match_id: int | None
    actor_id: int
    action: StatAuditAction
    entity_type: str
    entity_id: int
    before_state: dict | None
    after_state: dict | None
    created_at: datetime
