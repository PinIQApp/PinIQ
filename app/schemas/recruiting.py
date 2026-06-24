from __future__ import annotations

from datetime import date, datetime

from pydantic import BaseModel, ConfigDict, Field, computed_field

from app.models.recruiting import RecruitingContactVisibility, RecruitingVisibilityLevel


class RecruitingHighlightBase(BaseModel):
    title: str = Field(min_length=1, max_length=120)
    highlight_url: str = Field(min_length=3, max_length=500)
    sort_order: int = Field(default=0, ge=0, le=99)


class RecruitingHighlightCreate(RecruitingHighlightBase):
    pass


class RecruitingHighlightRead(RecruitingHighlightBase):
    model_config = ConfigDict(from_attributes=True)

    id: int
    athlete_id: int
    profile_id: int
    created_at: datetime
    updated_at: datetime


class RecruitingVisibilityUpsert(BaseModel):
    show_contact_to_coaches: bool = False
    show_gpa: bool = False
    show_location: bool = True
    show_profile_photo: bool = True
    parent_visibility_required: bool = True
    allow_direct_contact_request: bool = True


class RecruitingVisibilityRead(RecruitingVisibilityUpsert):
    model_config = ConfigDict(from_attributes=True)

    id: int
    profile_id: int
    created_at: datetime
    updated_at: datetime


class RecruitingStatsMetricRead(BaseModel):
    label: str
    value: str
    numeric_value: float | None = None


class RecruitingSourceRankingRead(BaseModel):
    source: str
    record: str | None = None
    ranking: str | None = None
    weight_class: str | None = None
    season: str | None = None
    profile_url: str | None = None
    last_checked: date | None = None


class RecruitingSchoolRankingRead(BaseModel):
    source: str
    school_name: str
    state: str | None = None
    state_rank: int | None = None
    national_rank: int | None = None
    division: str | None = None
    season: str | None = None
    profile_url: str | None = None
    last_checked: date | None = None


class RecruitingPinIqRankingRead(BaseModel):
    score: float
    tier: str
    state_rank_hint: int | None = None
    national_rank_hint: int | None = None
    confidence: str
    factors: list[RecruitingStatsMetricRead] = Field(default_factory=list)


class RecruitingSourceScanAuditRead(BaseModel):
    source: str
    url: str
    scanned_at: datetime
    success: bool
    changed_fields: list[str] = Field(default_factory=list)
    message: str | None = None


class RecruitingSchoolBoardRowRead(BaseModel):
    school_name: str
    source: str
    state: str | None = None
    state_rank: int | None = None
    national_rank: int | None = None
    division: str | None = None
    season: str | None = None
    profile_url: str | None = None
    last_checked: date | None = None
    athlete_count: int = 0
    athlete_names: list[str] = Field(default_factory=list)


class RecruitingRecentMatchRead(BaseModel):
    id: int
    opponent_name: str
    opponent_school: str | None = None
    event_name: str | None = None
    match_date: date
    weight_class: str
    result: str
    result_type: str
    score_display: str


class RecruitingContactRead(BaseModel):
    email: str | None = None
    phone: str | None = None
    visible_to_viewer: bool = False
    compliance_message: str | None = None
    messaging_entrypoint: str = "/api/v1/messages"


class RecruitingProfileBase(BaseModel):
    athlete_id: int
    team_id: int | None = None
    graduation_year: int = Field(ge=2024, le=2038)
    school_team: str | None = Field(default=None, max_length=160)
    weight_class: str = Field(min_length=1, max_length=30)
    height: str | None = Field(default=None, max_length=20)
    gpa: str | None = Field(default=None, max_length=10)
    bio: str | None = Field(default=None, max_length=3000)
    achievements: list[str] = Field(default_factory=list)
    contact_email: str | None = Field(default=None, max_length=255)
    contact_phone: str | None = Field(default=None, max_length=30)
    location_label: str | None = Field(default=None, max_length=140)
    stats_summary: dict | None = None
    match_record_override: str | None = Field(default=None, max_length=40)
    profile_image_url: str | None = Field(default=None, max_length=500)
    is_open: bool = True
    is_actively_looking: bool = False
    is_featured: bool = False
    boost_requested: bool = False
    visibility_level: RecruitingVisibilityLevel = RecruitingVisibilityLevel.coaches_only
    contact_visibility: RecruitingContactVisibility = RecruitingContactVisibility.hidden
    visibility: RecruitingVisibilityUpsert = Field(default_factory=RecruitingVisibilityUpsert)
    highlights: list[RecruitingHighlightCreate] = Field(default_factory=list)


class RecruitingProfileCreate(RecruitingProfileBase):
    pass


class RecruitingProfileUpdate(BaseModel):
    team_id: int | None = None
    graduation_year: int | None = Field(default=None, ge=2024, le=2038)
    school_team: str | None = Field(default=None, max_length=160)
    weight_class: str | None = Field(default=None, min_length=1, max_length=30)
    height: str | None = Field(default=None, max_length=20)
    gpa: str | None = Field(default=None, max_length=10)
    bio: str | None = Field(default=None, max_length=3000)
    achievements: list[str] | None = None
    contact_email: str | None = Field(default=None, max_length=255)
    contact_phone: str | None = Field(default=None, max_length=30)
    location_label: str | None = Field(default=None, max_length=140)
    stats_summary: dict | None = None
    match_record_override: str | None = Field(default=None, max_length=40)
    profile_image_url: str | None = Field(default=None, max_length=500)
    is_open: bool | None = None
    is_actively_looking: bool | None = None
    is_featured: bool | None = None
    boost_requested: bool | None = None
    visibility_level: RecruitingVisibilityLevel | None = None
    contact_visibility: RecruitingContactVisibility | None = None
    visibility: RecruitingVisibilityUpsert | None = None
    highlights: list[RecruitingHighlightCreate] | None = None


class RecruitingAthleteCardRead(BaseModel):
    athlete_id: int
    profile_id: int
    athlete_name: str
    school_team: str | None = None
    location_label: str | None = None
    graduation_year: int
    weight_class: str
    height: str | None = None
    profile_image_url: str | None = None
    is_open: bool
    is_actively_looking: bool
    is_featured: bool
    visibility_level: RecruitingVisibilityLevel
    record: str
    trend_label: str | None = None
    win_percentage: float | None = None
    bonus_point_rate: float | None = None
    stats_metrics: list[RecruitingStatsMetricRead] = Field(default_factory=list)
    source_rankings: list[RecruitingSourceRankingRead] = Field(default_factory=list)
    school_rankings: list[RecruitingSchoolRankingRead] = Field(default_factory=list)
    piniq_ranking: RecruitingPinIqRankingRead | None = None
    source_scan_audit: list[RecruitingSourceScanAuditRead] = Field(default_factory=list)
    achievements: list[str] = Field(default_factory=list)
    highlight_count: int = 0
    updated_at: datetime
    trending_score: float = 0
    saved_by_coach: bool = False
    tags: list[str] = Field(default_factory=list)


class RecruitingProfileRead(BaseModel):
    athlete_id: int
    profile_id: int
    athlete_name: str
    team_id: int | None = None
    school_team: str | None = None
    graduation_year: int
    weight_class: str
    height: str | None = None
    gpa: str | None = None
    bio: str | None = None
    achievements: list[str] = Field(default_factory=list)
    location_label: str | None = None
    profile_image_url: str | None = None
    is_open: bool
    is_actively_looking: bool
    is_featured: bool
    boost_requested: bool
    visibility_level: RecruitingVisibilityLevel
    contact_visibility: RecruitingContactVisibility
    stats_metrics: list[RecruitingStatsMetricRead] = Field(default_factory=list)
    source_rankings: list[RecruitingSourceRankingRead] = Field(default_factory=list)
    school_rankings: list[RecruitingSchoolRankingRead] = Field(default_factory=list)
    piniq_ranking: RecruitingPinIqRankingRead | None = None
    source_scan_audit: list[RecruitingSourceScanAuditRead] = Field(default_factory=list)
    record: str
    recent_matches: list[RecruitingRecentMatchRead] = Field(default_factory=list)
    highlights: list[RecruitingHighlightRead] = Field(default_factory=list)
    contact: RecruitingContactRead
    visibility: RecruitingVisibilityRead
    visible_as: str
    parent_visibility_required: bool
    updated_at: datetime


class RecruitingSourceLink(BaseModel):
    source: str = Field(min_length=2, max_length=80)
    url: str = Field(min_length=8, max_length=1000)


class RecruitingSourceLinksUpsert(BaseModel):
    source_links: list[RecruitingSourceLink] = Field(default_factory=list, max_length=12)


class RecruitingSourceLinksRead(BaseModel):
    athlete_id: int
    source_links: list[RecruitingSourceLink] = Field(default_factory=list)


class RecruitingSourceScanRequest(BaseModel):
    athlete_id: int | None = None
    athlete_name: str | None = Field(default=None, max_length=160)
    school_name: str | None = Field(default=None, max_length=160)
    state: str | None = Field(default=None, max_length=30)
    update_profile: bool = False
    source_links: list[RecruitingSourceLink] = Field(min_length=1, max_length=8)


class RecruitingSourceScanResultRead(BaseModel):
    source: str
    url: str
    success: bool
    message: str | None = None
    source_rankings: list[RecruitingSourceRankingRead] = Field(default_factory=list)
    school_rankings: list[RecruitingSchoolRankingRead] = Field(default_factory=list)


class RecruitingSourceScanResponse(BaseModel):
    scanned_at: datetime
    updated_profile: bool = False
    source_rankings: list[RecruitingSourceRankingRead] = Field(default_factory=list)
    school_rankings: list[RecruitingSchoolRankingRead] = Field(default_factory=list)
    results: list[RecruitingSourceScanResultRead] = Field(default_factory=list)


class RecruitingSavedSourceScanResponse(BaseModel):
    scanned_at: datetime
    profiles_checked: int = 0
    profiles_updated: int = 0
    source_rankings_found: int = 0
    school_rankings_found: int = 0
    failures: list[str] = Field(default_factory=list)


class RecruitingBoardRead(BaseModel):
    trending_athletes: list[RecruitingAthleteCardRead]
    featured_athletes: list[RecruitingAthleteCardRead]
    recently_updated: list[RecruitingAthleteCardRead]
    top_performers: list[RecruitingAthleteCardRead]
    state_school_rankings: list[RecruitingSchoolBoardRowRead] = Field(default_factory=list)
    national_school_rankings: list[RecruitingSchoolBoardRowRead] = Field(default_factory=list)


class RecruitingWatchlistCreate(BaseModel):
    coach_id: int
    athlete_id: int
    tag_labels: list[str] = Field(default_factory=list)


class RecruitingTagRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    coach_user_id: int
    athlete_id: int
    team_id: int | None
    profile_id: int | None
    tag: str
    created_at: datetime


class RecruitingWatchlistRead(BaseModel):
    id: int
    coach_id: int
    athlete_id: int
    created_at: datetime
    athlete: RecruitingAthleteCardRead
    note: str | None = None
    tags: list[str] = Field(default_factory=list)


class RecruitingNoteCreate(BaseModel):
    coach_id: int
    athlete_id: int
    note: str = Field(min_length=1, max_length=5000)
    tag_labels: list[str] = Field(default_factory=list)


class RecruitingNoteRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    coach_user_id: int
    athlete_id: int
    team_id: int | None
    profile_id: int | None
    note: str
    created_at: datetime
    updated_at: datetime
    tags: list[str] = Field(default_factory=list)


class RecruitingSearchResponse(BaseModel):
    results: list[RecruitingAthleteCardRead]
    total: int
    filters_applied: dict


class RecruitingSearchParams(BaseModel):
    weight_class: str | None = None
    graduation_year: int | None = None
    location: str | None = None
    min_win_percentage: float | None = Field(default=None, ge=0, le=1)
    min_bonus_rate: float | None = Field(default=None, ge=0, le=1)
    min_takedowns_per_match: float | None = Field(default=None, ge=0)
    is_open: bool | None = None
    is_actively_looking: bool | None = None
    query: str | None = None


class RecruitingProfileWriteResponse(BaseModel):
    message: str
    profile: RecruitingProfileRead


class RecruitingWatchlistResponse(BaseModel):
    message: str
    entry: RecruitingWatchlistRead


class RecruitingTrendingRead(BaseModel):
    generated_at: datetime
    athletes: list[RecruitingAthleteCardRead]
