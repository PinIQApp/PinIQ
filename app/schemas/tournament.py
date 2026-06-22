from __future__ import annotations

from datetime import date, datetime

from pydantic import BaseModel, ConfigDict, Field

from app.models.tournament import (
    TournamentAlertChannel,
    TournamentAlertType,
    BracketMatchStatus,
    BracketStatus,
    BracketType,
    DualBoutResultType,
    DualMeetStatus,
    EntryStatus,
    SeedingSource,
    TournamentChangeType,
    TournamentEventType,
    TournamentExternalStatus,
    TournamentFormatType,
    TournamentIngestionMode,
    TournamentMatStatus,
    TournamentScanRunStatus,
    TournamentSourceType,
    TournamentStatus,
)


class TournamentDivisionBase(BaseModel):
    name: str = Field(min_length=1, max_length=80)
    min_weight_class: str | None = Field(default=None, max_length=30)
    max_weight_class: str | None = Field(default=None, max_length=30)
    notes: str | None = Field(default=None, max_length=255)


class TournamentDivisionRead(TournamentDivisionBase):
    model_config = ConfigDict(from_attributes=True)

    id: int
    tournament_id: int
    created_at: datetime


class TournamentTeamAssign(BaseModel):
    team_id: int
    notes: str | None = Field(default=None, max_length=255)


class TournamentTeamRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    tournament_id: int
    team_id: int
    invited_by_user_id: int | None
    notes: str | None
    created_at: datetime


class TournamentCreate(BaseModel):
    name: str = Field(min_length=1, max_length=160)
    host_team_id: int | None = None
    event_type: TournamentEventType
    format_type: TournamentFormatType = TournamentFormatType.single_elimination
    elimination_style: str | None = Field(default=None, max_length=40)
    bracket_size: int | None = Field(default=None, ge=4, le=64)
    start_date: date
    end_date: date
    location: str | None = Field(default=None, max_length=180)
    notes: str | None = Field(default=None, max_length=4000)
    is_public: bool = False
    divisions: list[TournamentDivisionBase] = Field(default_factory=list)
    teams: list[TournamentTeamAssign] = Field(default_factory=list)


class TournamentUpdate(BaseModel):
    name: str | None = Field(default=None, min_length=1, max_length=160)
    event_type: TournamentEventType | None = None
    format_type: TournamentFormatType | None = None
    elimination_style: str | None = Field(default=None, max_length=40)
    bracket_size: int | None = Field(default=None, ge=4, le=64)
    status: TournamentStatus | None = None
    start_date: date | None = None
    end_date: date | None = None
    location: str | None = Field(default=None, max_length=180)
    notes: str | None = Field(default=None, max_length=4000)
    is_public: bool | None = None
    finalized_at: datetime | None = None
    published_at: datetime | None = None


class TournamentRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    name: str
    host_team_id: int | None
    director_user_id: int
    event_type: TournamentEventType
    format_type: TournamentFormatType
    elimination_style: str | None
    bracket_size: int | None
    status: TournamentStatus
    start_date: date
    end_date: date
    location: str | None
    notes: str | None
    is_public: bool
    finalized_at: datetime | None
    published_at: datetime | None
    created_at: datetime
    updated_at: datetime
    divisions: list[TournamentDivisionRead] = Field(default_factory=list)
    teams: list[TournamentTeamRead] = Field(default_factory=list)


class TournamentEntryCreate(BaseModel):
    team_id: int
    athlete_id: int
    division_name: str = Field(min_length=1, max_length=80)
    weight_class: str = Field(min_length=1, max_length=30)
    entry_status: EntryStatus = EntryStatus.entered
    notes: str | None = Field(default=None, max_length=4000)


class TournamentEntryUpdate(BaseModel):
    athlete_id: int | None = None
    division_name: str | None = Field(default=None, min_length=1, max_length=80)
    weight_class: str | None = Field(default=None, min_length=1, max_length=30)
    entry_status: EntryStatus | None = None
    notes: str | None = Field(default=None, max_length=4000)


class TournamentEntryRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    tournament_id: int
    team_id: int
    athlete_id: int
    division_name: str
    weight_class: str
    entry_status: EntryStatus
    seed_number: int | None
    seed_locked: bool
    seeded_at: datetime | None
    notes: str | None
    created_by_user_id: int
    updated_by_user_id: int | None
    created_at: datetime
    updated_at: datetime


class TournamentEntryGroupRead(BaseModel):
    weight_class: str
    entries: list[TournamentEntryRead]


class TournamentMatCreate(BaseModel):
    label: str = Field(min_length=1, max_length=40)
    area_name: str | None = Field(default=None, max_length=80)
    display_order: int | None = Field(default=None, ge=1, le=999)
    status: TournamentMatStatus = TournamentMatStatus.ready
    is_active: bool = True


class TournamentMatRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    tournament_id: int
    label: str
    area_name: str | None
    display_order: int | None
    status: TournamentMatStatus
    is_active: bool
    created_at: datetime
    updated_at: datetime


class TournamentDualMeetCreate(BaseModel):
    team_a_id: int
    team_b_id: int
    division_name: str | None = Field(default=None, max_length=80)
    round_label: str | None = Field(default=None, max_length=80)
    pool_name: str | None = Field(default=None, max_length=80)
    bracket_slot: str | None = Field(default=None, max_length=80)
    scheduled_sequence: int | None = Field(default=None, ge=1, le=9999)
    queue_position: int | None = Field(default=None, ge=1, le=9999)
    mat_id: int | None = None
    status: DualMeetStatus = DualMeetStatus.scheduled
    starts_at: datetime | None = None
    notes: str | None = Field(default=None, max_length=4000)


class TournamentDualMeetRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    tournament_id: int
    division_name: str | None
    round_label: str | None
    pool_name: str | None
    bracket_slot: str | None
    scheduled_sequence: int | None
    queue_position: int | None
    mat_id: int | None
    team_a_id: int
    team_b_id: int
    team_a_score: int
    team_b_score: int
    winner_team_id: int | None
    status: DualMeetStatus
    starts_at: datetime | None
    completed_at: datetime | None
    notes: str | None
    created_by_user_id: int
    created_at: datetime
    updated_at: datetime
    bouts: list["TournamentDualBoutRead"] = Field(default_factory=list)


class TournamentDualBoutCreate(BaseModel):
    weight_class: str = Field(min_length=1, max_length=30)
    bout_order: int | None = Field(default=None, ge=1, le=999)
    wrestler_a_entry_id: int | None = None
    wrestler_b_entry_id: int | None = None
    wrestler_a_name: str | None = Field(default=None, max_length=160)
    wrestler_b_name: str | None = Field(default=None, max_length=160)
    wrestler_a_team_id: int | None = None
    wrestler_b_team_id: int | None = None
    winner_entry_id: int | None = None
    winner_team_id: int | None = None
    result_type: DualBoutResultType | None = None
    result_summary: str | None = Field(default=None, max_length=255)
    is_complete: bool = False


class TournamentDualBoutUpdate(BaseModel):
    bout_order: int | None = Field(default=None, ge=1, le=999)
    wrestler_a_entry_id: int | None = None
    wrestler_b_entry_id: int | None = None
    wrestler_a_name: str | None = Field(default=None, max_length=160)
    wrestler_b_name: str | None = Field(default=None, max_length=160)
    wrestler_a_team_id: int | None = None
    wrestler_b_team_id: int | None = None
    winner_entry_id: int | None = None
    winner_team_id: int | None = None
    result_type: DualBoutResultType | None = None
    result_summary: str | None = Field(default=None, max_length=255)
    is_complete: bool | None = None


class TournamentDualBoutRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    dual_meet_id: int
    weight_class: str
    bout_order: int | None
    wrestler_a_entry_id: int | None
    wrestler_b_entry_id: int | None
    wrestler_a_name: str | None
    wrestler_b_name: str | None
    wrestler_a_team_id: int | None
    wrestler_b_team_id: int | None
    winner_entry_id: int | None
    winner_team_id: int | None
    result_type: DualBoutResultType | None
    result_summary: str | None
    team_a_points_awarded: int
    team_b_points_awarded: int
    is_complete: bool
    completed_at: datetime | None
    updated_by_user_id: int | None
    created_at: datetime
    updated_at: datetime


class SeedComponentBreakdown(BaseModel):
    win_percentage: float
    head_to_head: float
    common_opponents: float
    recent_performance: float
    bonus_point_rate: float
    tournament_placements: float
    ranking_bonus: float
    coach_override_bonus: float
    tie_break_hint: str


class SeedScoreRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    tournament_id: int
    entry_id: int
    team_id: int
    athlete_id: int
    weight_class: str
    division_name: str
    seed_number: int
    seed_score: float
    score_breakdown: SeedComponentBreakdown
    seed_explanation: str
    source: SeedingSource
    created_at: datetime
    updated_at: datetime


class SeedingCalculationResponse(BaseModel):
    tournament_id: int
    weight_classes: list[str]
    generated_count: int
    status: TournamentStatus
    results: list[SeedScoreRead]


class SeedingOverrideCreate(BaseModel):
    tournament_id: int
    entry_id: int
    seed_number: int = Field(ge=1, le=32)
    override_reason: str = Field(min_length=5, max_length=2000)


class SeedingOverrideRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    tournament_id: int
    entry_id: int
    actor_id: int
    previous_seed_number: int | None
    new_seed_number: int
    override_reason: str
    previous_snapshot: dict | None
    created_at: datetime


class SeedingExplanationRead(BaseModel):
    tournament_id: int
    weight_class: str
    explanations: list[SeedScoreRead]
    overrides: list[SeedingOverrideRead]


class SeedingOverrideResultRead(BaseModel):
    override: SeedingOverrideRead
    results: list[SeedScoreRead]


class BracketGenerateRequest(BaseModel):
    division_name: str = Field(min_length=1, max_length=80)
    bracket_type: BracketType
    finalize_now: bool = False
    publish_now: bool = False


class BracketMatchUpdate(BaseModel):
    winner_entry_id: int | None = None
    match_status: BracketMatchStatus | None = None
    result_summary: str | None = Field(default=None, max_length=255)
    scheduled_at: datetime | None = None
    mat_label: str | None = Field(default=None, max_length=40)


class BracketMatchRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    bracket_id: int
    tournament_id: int
    round_number: int
    matchup_order: int
    wrestler_a_entry_id: int | None
    wrestler_b_entry_id: int | None
    wrestler_a_seed: int | None
    wrestler_b_seed: int | None
    winner_entry_id: int | None
    next_match_id: int | None
    next_match_slot: str | None
    match_status: BracketMatchStatus
    scheduled_at: datetime | None
    mat_label: str | None
    result_summary: str | None
    created_at: datetime
    updated_at: datetime


class BracketRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    tournament_id: int
    division_name: str
    weight_class: str
    bracket_type: BracketType
    bracket_size: int
    status: BracketStatus
    preview_payload: dict
    created_by_user_id: int
    finalized_by_user_id: int | None
    finalized_at: datetime | None
    published_at: datetime | None
    created_at: datetime
    updated_at: datetime
    matches: list[BracketMatchRead] = Field(default_factory=list)


class TournamentDashboardRead(BaseModel):
    tournament: TournamentRead
    entries_by_weight_class: list[TournamentEntryGroupRead]
    seeded_weight_classes: list[str]
    bracketed_weight_classes: list[str]
    can_edit: bool
    can_seed: bool
    can_finalize: bool
    visibility_label: str


class TournamentSourceRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    source_key: TournamentSourceType
    display_name: str
    ingestion_mode: TournamentIngestionMode
    base_url: str | None
    supports_scraping: bool
    supports_api: bool
    is_active: bool
    notes: str | None


class TournamentExternalBase(BaseModel):
    name: str = Field(min_length=1, max_length=180)
    start_date: date
    end_date: date
    location_name: str | None = Field(default=None, max_length=180)
    city: str | None = Field(default=None, max_length=120)
    state: str | None = Field(default=None, max_length=40)
    latitude: float | None = None
    longitude: float | None = None
    age_divisions: list[str] = Field(default_factory=list)
    weight_classes: list[str] | None = None
    event_type: str = Field(min_length=1, max_length=60)
    registration_link: str | None = Field(default=None, max_length=2000)
    event_page_link: str | None = Field(default=None, max_length=2000)
    contact_name: str | None = Field(default=None, max_length=120)
    contact_email: str | None = Field(default=None, max_length=160)
    contact_phone: str | None = Field(default=None, max_length=40)
    description: str | None = Field(default=None, max_length=8000)
    deadline: date | None = None
    cost: str | None = Field(default=None, max_length=80)


class TournamentManualCreate(TournamentExternalBase):
    team_id: int
    notes: str | None = Field(default=None, max_length=2000)


class TournamentSaveRequest(BaseModel):
    team_id: int
    tournament_id: int
    notes: str | None = Field(default=None, max_length=2000)


class TournamentAddToScheduleRequest(BaseModel):
    team_id: int
    tournament_id: int
    starts_at: datetime | None = None
    ends_at: datetime | None = None
    title_override: str | None = Field(default=None, max_length=160)
    description_override: str | None = Field(default=None, max_length=2000)
    location_override: str | None = Field(default=None, max_length=180)
    notes: str | None = Field(default=None, max_length=4000)
    checklist: list[str] = Field(default_factory=list)
    bus_departure_note: str | None = Field(default=None, max_length=255)
    weigh_in_note: str | None = Field(default=None, max_length=255)


class TournamentFilterUpsert(BaseModel):
    team_id: int | None = None
    filter_name: str = Field(min_length=1, max_length=80)
    start_date: date | None = None
    end_date: date | None = None
    radius_miles: int | None = Field(default=None, ge=1, le=500)
    origin_city: str | None = Field(default=None, max_length=120)
    origin_state: str | None = Field(default=None, max_length=40)
    origin_latitude: float | None = None
    origin_longitude: float | None = None
    age_group: str | None = Field(default=None, max_length=60)
    weight_class: str | None = Field(default=None, max_length=30)
    event_type: str | None = Field(default=None, max_length=60)
    is_default: bool = False


class TournamentFilterRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    team_id: int | None
    user_id: int | None
    filter_name: str
    start_date: date | None
    end_date: date | None
    radius_miles: int | None
    origin_city: str | None
    origin_state: str | None
    origin_latitude: float | None
    origin_longitude: float | None
    age_group: str | None
    weight_class: str | None
    event_type: str | None
    is_default: bool
    created_at: datetime
    updated_at: datetime


class TournamentExternalRead(TournamentExternalBase):
    model_config = ConfigDict(from_attributes=True)

    id: int
    source_id: int
    created_by_user_id: int | None
    external_id: str | None
    source_label: str
    ingestion_status: TournamentExternalStatus
    ingestion_notes: str | None
    last_seen_at: datetime | None
    created_at: datetime
    updated_at: datetime
    source: TournamentSourceRead | None = None
    is_saved: bool = False
    is_on_team_schedule: bool = False
    distance_miles: float | None = None
    recommendation_score: float | None = None


class SavedTournamentRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    team_id: int
    tournament_external_id: int
    saved_by_user_id: int
    notes: str | None
    added_to_schedule_at: datetime | None
    shared_to_team_at: datetime | None
    created_at: datetime
    updated_at: datetime
    tournament: TournamentExternalRead


class TournamentDiscoverResponse(BaseModel):
    tournaments: list[TournamentExternalRead]
    recommended: list[TournamentExternalRead]
    nearby: list[TournamentExternalRead]
    upcoming_weekend: list[TournamentExternalRead]
    saved_filter: TournamentFilterRead | None = None
    available_sources: list[TournamentSourceRead] = Field(default_factory=list)


class TournamentDetailRead(BaseModel):
    tournament: TournamentExternalRead
    available_registration_link: str | None
    saved_entry: SavedTournamentRead | None
    schedule_event_id: int | None
    related_team_ids: list[int] = Field(default_factory=list)
    share_context: dict = Field(default_factory=dict)


class TournamentAddToScheduleResponse(BaseModel):
    tournament: TournamentExternalRead
    saved_entry: SavedTournamentRead
    schedule_event_id: int


class TournamentScanIngestItem(TournamentExternalBase):
    external_id: str | None = Field(default=None, max_length=120)
    source_id_hint: str | None = Field(default=None, max_length=120)
    source_label: str | None = Field(default=None, max_length=40)
    ingestion_notes: str | None = Field(default=None, max_length=2000)
    raw_payload: dict | None = None
    normalized_payload: dict | None = None


class TournamentScanIngestRequest(BaseModel):
    source_key: TournamentSourceType
    notes: str | None = Field(default=None, max_length=2000)
    query_snapshot: dict = Field(default_factory=dict)
    items: list[TournamentScanIngestItem] = Field(default_factory=list)


class TournamentLiveScanRequest(BaseModel):
    source_key: TournamentSourceType
    search: str | None = Field(default=None, max_length=160)
    state: str | None = Field(default=None, max_length=40)
    division: str | None = Field(default=None, max_length=20)
    style: str | None = Field(default=None, max_length=20)


class TournamentScanRunRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    source_id: int
    triggered_by_user_id: int | None
    status: TournamentScanRunStatus
    query_snapshot: dict
    items_seen_count: int
    items_created_count: int
    items_updated_count: int
    items_merged_count: int
    items_archived_count: int
    errors_count: int
    notes: str | None
    started_at: datetime
    completed_at: datetime | None
    created_at: datetime
    updated_at: datetime


class TournamentChangeLogRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    tournament_external_id: int
    source_id: int
    scan_run_id: int | None
    actor_user_id: int | None
    change_type: TournamentChangeType
    summary: str
    field_changes: dict
    source_priority: int
    changed_at: datetime


class TournamentAlertSubscriptionCreate(BaseModel):
    team_id: int | None = None
    user_id: int | None = None
    tournament_external_id: int | None = None
    alert_type: TournamentAlertType
    channel: TournamentAlertChannel = TournamentAlertChannel.in_app
    is_enabled: bool = True


class TournamentAlertSubscriptionRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    team_id: int | None
    user_id: int | None
    tournament_external_id: int | None
    alert_type: TournamentAlertType
    channel: TournamentAlertChannel
    is_enabled: bool
    created_by_user_id: int
    created_at: datetime
    updated_at: datetime


TournamentDualMeetRead.model_rebuild()
