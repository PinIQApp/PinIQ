from __future__ import annotations
from typing import Optional

from datetime import date, datetime
from enum import Enum

from sqlalchemy import JSON, Boolean, Date, DateTime, Enum as SqlEnum, Float, ForeignKey, Integer, String, Text, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.session import Base


class TournamentEventType(str, Enum):
    dual_event = "dual_event"
    individual_tournament = "individual_tournament"
    round_robin_pool = "round_robin_pool"
    bracket_style_event = "bracket_style_event"


class TournamentFormatType(str, Enum):
    single_elimination = "single_elimination"
    round_robin = "round_robin"
    pool_to_bracket = "pool_to_bracket"
    dual_pool = "dual_pool"
    dual_bracket = "dual_bracket"
    dual_round_robin = "dual_round_robin"


class TournamentStatus(str, Enum):
    draft = "draft"
    entries_open = "entries_open"
    seeding_in_review = "seeding_in_review"
    bracket_finalized = "bracket_finalized"
    published = "published"


class EntryStatus(str, Enum):
    entered = "entered"
    scratched = "scratched"
    replaced = "replaced"
    late_update = "late_update"


class SeedingSource(str, Enum):
    calculated = "calculated"
    manual_override = "manual_override"


class BracketType(str, Enum):
    four_man = "4_man"
    eight_man = "8_man"
    sixteen_man = "16_man"
    thirty_two_man = "32_man"
    round_robin = "round_robin"


class BracketStatus(str, Enum):
    draft = "draft"
    finalized = "finalized"
    published = "published"


class BracketMatchStatus(str, Enum):
    pending = "pending"
    completed = "completed"
    bye = "bye"


class TournamentSourceType(str, Enum):
    manual = "manual"
    track = "track"
    flo = "flo"
    usa = "usa"


class TournamentIngestionMode(str, Enum):
    manual_entry = "manual_entry"
    scraping_placeholder = "scraping_placeholder"
    api_placeholder = "api_placeholder"
    hybrid_placeholder = "hybrid_placeholder"


class TournamentExternalStatus(str, Enum):
    draft = "draft"
    normalized = "normalized"
    needs_review = "needs_review"
    archived = "archived"


class TournamentScanRunStatus(str, Enum):
    queued = "queued"
    running = "running"
    completed = "completed"
    completed_with_warnings = "completed_with_warnings"
    failed = "failed"


class TournamentChangeType(str, Enum):
    created = "created"
    updated = "updated"
    merged = "merged"
    deadline_changed = "deadline_changed"
    archived = "archived"


class TournamentAlertType(str, Enum):
    new_tournament = "new_tournament"
    updated_tournament = "updated_tournament"
    deadline_reminder = "deadline_reminder"
    schedule_change = "schedule_change"


class TournamentAlertChannel(str, Enum):
    in_app = "in_app"
    email = "email"
    push = "push"


class TournamentMatStatus(str, Enum):
    offline = "offline"
    ready = "ready"
    live = "live"


class DualMeetStatus(str, Enum):
    scheduled = "scheduled"
    on_deck = "on_deck"
    in_progress = "in_progress"
    completed = "completed"


class DualBoutResultType(str, Enum):
    decision = "decision"
    major_decision = "major_decision"
    technical_fall = "technical_fall"
    fall = "fall"
    medical_forfeit = "medical_forfeit"
    forfeit = "forfeit"
    default = "default"
    disqualification = "disqualification"


class Tournament(Base):
    __tablename__ = "tournaments"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    name: Mapped[str] = mapped_column(String(160), nullable=False)
    host_team_id: Mapped[Optional[int]] = mapped_column(ForeignKey("teams.id"), index=True)
    director_user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), nullable=False, index=True)
    event_type: Mapped[TournamentEventType] = mapped_column(SqlEnum(TournamentEventType), nullable=False, index=True)
    format_type: Mapped[TournamentFormatType] = mapped_column(
        SqlEnum(TournamentFormatType),
        default=TournamentFormatType.single_elimination,
        nullable=False,
        index=True,
    )
    elimination_style: Mapped[Optional[str]] = mapped_column(String(40), index=True)
    bracket_size: Mapped[Optional[int]] = mapped_column(Integer)
    status: Mapped[TournamentStatus] = mapped_column(
        SqlEnum(TournamentStatus), default=TournamentStatus.draft, nullable=False, index=True
    )
    start_date: Mapped[date] = mapped_column(Date, nullable=False)
    end_date: Mapped[date] = mapped_column(Date, nullable=False)
    location: Mapped[Optional[str]] = mapped_column(String(180))
    notes: Mapped[Optional[str]] = mapped_column(Text)
    is_public: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    finalized_at: Mapped[Optional[datetime]] = mapped_column(DateTime)
    published_at: Mapped[Optional[datetime]] = mapped_column(DateTime)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False
    )

    director = relationship("User", foreign_keys=[director_user_id])
    host_team = relationship("Team", foreign_keys=[host_team_id])
    divisions = relationship("TournamentDivision", back_populates="tournament", cascade="all, delete-orphan")
    teams = relationship("TournamentTeam", back_populates="tournament", cascade="all, delete-orphan")
    entries = relationship("TournamentEntry", back_populates="tournament", cascade="all, delete-orphan")
    seed_scores = relationship("SeedScore", back_populates="tournament", cascade="all, delete-orphan")
    overrides = relationship("SeedingOverride", back_populates="tournament", cascade="all, delete-orphan")
    brackets = relationship("Bracket", back_populates="tournament", cascade="all, delete-orphan")
    mats = relationship("TournamentMat", back_populates="tournament", cascade="all, delete-orphan")
    dual_meets = relationship("TournamentDualMeet", back_populates="tournament", cascade="all, delete-orphan")


class TournamentDivision(Base):
    __tablename__ = "tournament_divisions"
    __table_args__ = (UniqueConstraint("tournament_id", "name", name="uq_tournament_division_name"),)

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    tournament_id: Mapped[int] = mapped_column(ForeignKey("tournaments.id"), nullable=False, index=True)
    name: Mapped[str] = mapped_column(String(80), nullable=False)
    min_weight_class: Mapped[Optional[str]] = mapped_column(String(30))
    max_weight_class: Mapped[Optional[str]] = mapped_column(String(30))
    notes: Mapped[Optional[str]] = mapped_column(String(255))
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, nullable=False)

    tournament = relationship("Tournament", back_populates="divisions")


class TournamentTeam(Base):
    __tablename__ = "tournament_teams"
    __table_args__ = (UniqueConstraint("tournament_id", "team_id", name="uq_tournament_team"),)

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    tournament_id: Mapped[int] = mapped_column(ForeignKey("tournaments.id"), nullable=False, index=True)
    team_id: Mapped[int] = mapped_column(ForeignKey("teams.id"), nullable=False, index=True)
    invited_by_user_id: Mapped[Optional[int]] = mapped_column(ForeignKey("users.id"))
    notes: Mapped[Optional[str]] = mapped_column(String(255))
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, nullable=False)

    tournament = relationship("Tournament", back_populates="teams")
    team = relationship("Team")
    invited_by = relationship("User", foreign_keys=[invited_by_user_id])


class TournamentMat(Base):
    __tablename__ = "tournament_mats"
    __table_args__ = (UniqueConstraint("tournament_id", "label", name="uq_tournament_mat_label"),)

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    tournament_id: Mapped[int] = mapped_column(ForeignKey("tournaments.id"), nullable=False, index=True)
    label: Mapped[str] = mapped_column(String(40), nullable=False)
    area_name: Mapped[Optional[str]] = mapped_column(String(80))
    display_order: Mapped[Optional[int]] = mapped_column(Integer)
    status: Mapped[TournamentMatStatus] = mapped_column(
        SqlEnum(TournamentMatStatus),
        default=TournamentMatStatus.ready,
        nullable=False,
        index=True,
    )
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False
    )

    tournament = relationship("Tournament", back_populates="mats")
    dual_meets = relationship("TournamentDualMeet", back_populates="mat")


class TournamentDualMeet(Base):
    __tablename__ = "tournament_dual_meets"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    tournament_id: Mapped[int] = mapped_column(ForeignKey("tournaments.id"), nullable=False, index=True)
    division_name: Mapped[Optional[str]] = mapped_column(String(80), index=True)
    round_label: Mapped[Optional[str]] = mapped_column(String(80))
    pool_name: Mapped[Optional[str]] = mapped_column(String(80), index=True)
    bracket_slot: Mapped[Optional[str]] = mapped_column(String(80))
    scheduled_sequence: Mapped[Optional[int]] = mapped_column(Integer, index=True)
    queue_position: Mapped[Optional[int]] = mapped_column(Integer)
    mat_id: Mapped[Optional[int]] = mapped_column(ForeignKey("tournament_mats.id"), index=True)
    team_a_id: Mapped[int] = mapped_column(ForeignKey("teams.id"), nullable=False, index=True)
    team_b_id: Mapped[int] = mapped_column(ForeignKey("teams.id"), nullable=False, index=True)
    team_a_score: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    team_b_score: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    winner_team_id: Mapped[Optional[int]] = mapped_column(ForeignKey("teams.id"), index=True)
    status: Mapped[DualMeetStatus] = mapped_column(
        SqlEnum(DualMeetStatus),
        default=DualMeetStatus.scheduled,
        nullable=False,
        index=True,
    )
    starts_at: Mapped[Optional[datetime]] = mapped_column(DateTime)
    completed_at: Mapped[Optional[datetime]] = mapped_column(DateTime)
    notes: Mapped[Optional[str]] = mapped_column(Text)
    created_by_user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False
    )

    tournament = relationship("Tournament", back_populates="dual_meets")
    mat = relationship("TournamentMat", back_populates="dual_meets")
    team_a = relationship("Team", foreign_keys=[team_a_id])
    team_b = relationship("Team", foreign_keys=[team_b_id])
    winner_team = relationship("Team", foreign_keys=[winner_team_id])
    created_by = relationship("User", foreign_keys=[created_by_user_id])
    bouts = relationship("TournamentDualBout", back_populates="dual_meet", cascade="all, delete-orphan")


class TournamentDualBout(Base):
    __tablename__ = "tournament_dual_bouts"
    __table_args__ = (UniqueConstraint("dual_meet_id", "weight_class", name="uq_dual_meet_weight_class"),)

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    dual_meet_id: Mapped[int] = mapped_column(ForeignKey("tournament_dual_meets.id"), nullable=False, index=True)
    weight_class: Mapped[str] = mapped_column(String(30), nullable=False, index=True)
    bout_order: Mapped[Optional[int]] = mapped_column(Integer)
    wrestler_a_entry_id: Mapped[Optional[int]] = mapped_column(ForeignKey("tournament_entries.id"), index=True)
    wrestler_b_entry_id: Mapped[Optional[int]] = mapped_column(ForeignKey("tournament_entries.id"), index=True)
    wrestler_a_name: Mapped[Optional[str]] = mapped_column(String(160))
    wrestler_b_name: Mapped[Optional[str]] = mapped_column(String(160))
    wrestler_a_team_id: Mapped[Optional[int]] = mapped_column(ForeignKey("teams.id"), index=True)
    wrestler_b_team_id: Mapped[Optional[int]] = mapped_column(ForeignKey("teams.id"), index=True)
    winner_entry_id: Mapped[Optional[int]] = mapped_column(ForeignKey("tournament_entries.id"), index=True)
    winner_team_id: Mapped[Optional[int]] = mapped_column(ForeignKey("teams.id"), index=True)
    result_type: Mapped[Optional[DualBoutResultType]] = mapped_column(SqlEnum(DualBoutResultType))
    result_summary: Mapped[Optional[str]] = mapped_column(String(255))
    team_a_points_awarded: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    team_b_points_awarded: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    is_complete: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    completed_at: Mapped[Optional[datetime]] = mapped_column(DateTime)
    updated_by_user_id: Mapped[Optional[int]] = mapped_column(ForeignKey("users.id"))
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False
    )

    dual_meet = relationship("TournamentDualMeet", back_populates="bouts")
    wrestler_a_entry = relationship("TournamentEntry", foreign_keys=[wrestler_a_entry_id])
    wrestler_b_entry = relationship("TournamentEntry", foreign_keys=[wrestler_b_entry_id])
    winner_entry = relationship("TournamentEntry", foreign_keys=[winner_entry_id])
    wrestler_a_team = relationship("Team", foreign_keys=[wrestler_a_team_id])
    wrestler_b_team = relationship("Team", foreign_keys=[wrestler_b_team_id])
    winner_team = relationship("Team", foreign_keys=[winner_team_id])
    updated_by = relationship("User", foreign_keys=[updated_by_user_id])


class TournamentEntry(Base):
    __tablename__ = "tournament_entries"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    tournament_id: Mapped[int] = mapped_column(ForeignKey("tournaments.id"), nullable=False, index=True)
    team_id: Mapped[int] = mapped_column(ForeignKey("teams.id"), nullable=False, index=True)
    athlete_id: Mapped[int] = mapped_column(ForeignKey("users.id"), nullable=False, index=True)
    division_name: Mapped[str] = mapped_column(String(80), nullable=False, index=True)
    weight_class: Mapped[str] = mapped_column(String(30), nullable=False, index=True)
    entry_status: Mapped[EntryStatus] = mapped_column(
        SqlEnum(EntryStatus), default=EntryStatus.entered, nullable=False, index=True
    )
    seed_number: Mapped[Optional[int]] = mapped_column(Integer)
    seed_locked: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    seeded_at: Mapped[Optional[datetime]] = mapped_column(DateTime)
    notes: Mapped[Optional[str]] = mapped_column(Text)
    created_by_user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), nullable=False)
    updated_by_user_id: Mapped[Optional[int]] = mapped_column(ForeignKey("users.id"))
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False
    )

    tournament = relationship("Tournament", back_populates="entries")
    team = relationship("Team")
    athlete = relationship("User", foreign_keys=[athlete_id])
    created_by = relationship("User", foreign_keys=[created_by_user_id])
    updated_by = relationship("User", foreign_keys=[updated_by_user_id])


class SeedScore(Base):
    __tablename__ = "seed_scores"
    __table_args__ = (UniqueConstraint("tournament_id", "entry_id", name="uq_seed_score_entry"),)

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    tournament_id: Mapped[int] = mapped_column(ForeignKey("tournaments.id"), nullable=False, index=True)
    entry_id: Mapped[int] = mapped_column(ForeignKey("tournament_entries.id"), nullable=False, index=True)
    team_id: Mapped[int] = mapped_column(ForeignKey("teams.id"), nullable=False, index=True)
    athlete_id: Mapped[int] = mapped_column(ForeignKey("users.id"), nullable=False, index=True)
    weight_class: Mapped[str] = mapped_column(String(30), nullable=False, index=True)
    division_name: Mapped[str] = mapped_column(String(80), nullable=False, index=True)
    seed_number: Mapped[int] = mapped_column(Integer, nullable=False)
    seed_score: Mapped[float] = mapped_column(Float, nullable=False)
    score_breakdown: Mapped[dict] = mapped_column(JSON, nullable=False)
    seed_explanation: Mapped[str] = mapped_column(Text, nullable=False)
    source: Mapped[SeedingSource] = mapped_column(
        SqlEnum(SeedingSource), default=SeedingSource.calculated, nullable=False
    )
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False
    )

    tournament = relationship("Tournament", back_populates="seed_scores")
    entry = relationship("TournamentEntry")
    team = relationship("Team")
    athlete = relationship("User")


class SeedingOverride(Base):
    __tablename__ = "seeding_overrides"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    tournament_id: Mapped[int] = mapped_column(ForeignKey("tournaments.id"), nullable=False, index=True)
    entry_id: Mapped[int] = mapped_column(ForeignKey("tournament_entries.id"), nullable=False, index=True)
    actor_id: Mapped[int] = mapped_column(ForeignKey("users.id"), nullable=False, index=True)
    previous_seed_number: Mapped[Optional[int]] = mapped_column(Integer)
    new_seed_number: Mapped[int] = mapped_column(Integer, nullable=False)
    override_reason: Mapped[str] = mapped_column(Text, nullable=False)
    previous_snapshot: Mapped[Optional[dict]] = mapped_column(JSON)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, nullable=False)

    tournament = relationship("Tournament", back_populates="overrides")
    entry = relationship("TournamentEntry")
    actor = relationship("User", foreign_keys=[actor_id])


class Bracket(Base):
    __tablename__ = "brackets"
    __table_args__ = (UniqueConstraint("tournament_id", "weight_class", name="uq_bracket_weight_class"),)

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    tournament_id: Mapped[int] = mapped_column(ForeignKey("tournaments.id"), nullable=False, index=True)
    division_name: Mapped[str] = mapped_column(String(80), nullable=False, index=True)
    weight_class: Mapped[str] = mapped_column(String(30), nullable=False, index=True)
    bracket_type: Mapped[BracketType] = mapped_column(SqlEnum(BracketType), nullable=False, index=True)
    bracket_size: Mapped[int] = mapped_column(Integer, nullable=False)
    status: Mapped[BracketStatus] = mapped_column(
        SqlEnum(BracketStatus), default=BracketStatus.draft, nullable=False, index=True
    )
    preview_payload: Mapped[dict] = mapped_column(JSON, nullable=False)
    created_by_user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), nullable=False)
    finalized_by_user_id: Mapped[Optional[int]] = mapped_column(ForeignKey("users.id"))
    finalized_at: Mapped[Optional[datetime]] = mapped_column(DateTime)
    published_at: Mapped[Optional[datetime]] = mapped_column(DateTime)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False
    )

    tournament = relationship("Tournament", back_populates="brackets")
    created_by = relationship("User", foreign_keys=[created_by_user_id])
    finalized_by = relationship("User", foreign_keys=[finalized_by_user_id])
    matches = relationship("BracketMatch", back_populates="bracket", cascade="all, delete-orphan")


class BracketMatch(Base):
    __tablename__ = "bracket_matches"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    bracket_id: Mapped[int] = mapped_column(ForeignKey("brackets.id"), nullable=False, index=True)
    tournament_id: Mapped[int] = mapped_column(ForeignKey("tournaments.id"), nullable=False, index=True)
    round_number: Mapped[int] = mapped_column(Integer, nullable=False, index=True)
    matchup_order: Mapped[int] = mapped_column(Integer, nullable=False)
    wrestler_a_entry_id: Mapped[Optional[int]] = mapped_column(ForeignKey("tournament_entries.id"))
    wrestler_b_entry_id: Mapped[Optional[int]] = mapped_column(ForeignKey("tournament_entries.id"))
    wrestler_a_seed: Mapped[Optional[int]] = mapped_column(Integer)
    wrestler_b_seed: Mapped[Optional[int]] = mapped_column(Integer)
    winner_entry_id: Mapped[Optional[int]] = mapped_column(ForeignKey("tournament_entries.id"))
    next_match_id: Mapped[Optional[int]] = mapped_column(ForeignKey("bracket_matches.id"))
    next_match_slot: Mapped[Optional[str]] = mapped_column(String(1))
    match_status: Mapped[BracketMatchStatus] = mapped_column(
        SqlEnum(BracketMatchStatus), default=BracketMatchStatus.pending, nullable=False, index=True
    )
    scheduled_at: Mapped[Optional[datetime]] = mapped_column(DateTime)
    mat_label: Mapped[Optional[str]] = mapped_column(String(40))
    result_summary: Mapped[Optional[str]] = mapped_column(String(255))
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False
    )

    bracket = relationship("Bracket", back_populates="matches")
    tournament = relationship("Tournament")
    wrestler_a_entry = relationship("TournamentEntry", foreign_keys=[wrestler_a_entry_id])
    wrestler_b_entry = relationship("TournamentEntry", foreign_keys=[wrestler_b_entry_id])
    winner_entry = relationship("TournamentEntry", foreign_keys=[winner_entry_id])


class TournamentSource(Base):
    __tablename__ = "tournament_sources"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    source_key: Mapped[TournamentSourceType] = mapped_column(SqlEnum(TournamentSourceType), unique=True, nullable=False)
    display_name: Mapped[str] = mapped_column(String(60), nullable=False)
    ingestion_mode: Mapped[TournamentIngestionMode] = mapped_column(
        SqlEnum(TournamentIngestionMode), default=TournamentIngestionMode.manual_entry, nullable=False
    )
    base_url: Mapped[Optional[str]] = mapped_column(String(255))
    supports_scraping: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    supports_api: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    notes: Mapped[Optional[str]] = mapped_column(Text)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False
    )

    tournaments = relationship("TournamentExternal", back_populates="source")
    scan_runs = relationship("TournamentScanRun", back_populates="source", cascade="all, delete-orphan")
    change_logs = relationship("TournamentChangeLog", back_populates="source")


class TournamentExternal(Base):
    __tablename__ = "tournaments_external"
    __table_args__ = (UniqueConstraint("source_id", "external_id", name="uq_external_source_external_id"),)

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    source_id: Mapped[int] = mapped_column(ForeignKey("tournament_sources.id"), nullable=False, index=True)
    created_by_user_id: Mapped[Optional[int]] = mapped_column(ForeignKey("users.id"), index=True)
    external_id: Mapped[Optional[str]] = mapped_column(String(120), index=True)
    name: Mapped[str] = mapped_column(String(180), nullable=False, index=True)
    start_date: Mapped[date] = mapped_column(Date, nullable=False, index=True)
    end_date: Mapped[date] = mapped_column(Date, nullable=False, index=True)
    location_name: Mapped[Optional[str]] = mapped_column(String(180))
    city: Mapped[Optional[str]] = mapped_column(String(120), index=True)
    state: Mapped[Optional[str]] = mapped_column(String(40), index=True)
    latitude: Mapped[Optional[float]] = mapped_column(Float)
    longitude: Mapped[Optional[float]] = mapped_column(Float)
    age_divisions: Mapped[list[str]] = mapped_column(JSON, default=list, nullable=False)
    weight_classes: Mapped[Optional[list[str]]] = mapped_column(JSON)
    event_type: Mapped[str] = mapped_column(String(60), nullable=False, index=True)
    registration_link: Mapped[Optional[str]] = mapped_column(Text)
    event_page_link: Mapped[Optional[str]] = mapped_column(Text)
    source_label: Mapped[str] = mapped_column(String(40), nullable=False)
    contact_name: Mapped[Optional[str]] = mapped_column(String(120))
    contact_email: Mapped[Optional[str]] = mapped_column(String(160))
    contact_phone: Mapped[Optional[str]] = mapped_column(String(40))
    description: Mapped[Optional[str]] = mapped_column(Text)
    deadline: Mapped[Optional[date]] = mapped_column(Date, index=True)
    cost: Mapped[Optional[str]] = mapped_column(String(80))
    raw_payload: Mapped[Optional[dict]] = mapped_column(JSON)
    normalized_payload: Mapped[Optional[dict]] = mapped_column(JSON)
    ingestion_status: Mapped[TournamentExternalStatus] = mapped_column(
        SqlEnum(TournamentExternalStatus), default=TournamentExternalStatus.normalized, nullable=False, index=True
    )
    ingestion_notes: Mapped[Optional[str]] = mapped_column(Text)
    last_seen_at: Mapped[Optional[datetime]] = mapped_column(DateTime, index=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False
    )

    source = relationship("TournamentSource", back_populates="tournaments")
    created_by = relationship("User", foreign_keys=[created_by_user_id])
    saved_by_teams = relationship("SavedTournament", back_populates="tournament", cascade="all, delete-orphan")
    scheduled_events = relationship("Event", back_populates="external_tournament")
    change_logs = relationship("TournamentChangeLog", back_populates="tournament", cascade="all, delete-orphan")
    alert_subscriptions = relationship(
        "TournamentAlertSubscription", back_populates="tournament", cascade="all, delete-orphan"
    )


class SavedTournament(Base):
    __tablename__ = "saved_tournaments"
    __table_args__ = (UniqueConstraint("team_id", "tournament_external_id", name="uq_saved_tournament_team"),)

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    team_id: Mapped[int] = mapped_column(ForeignKey("teams.id"), nullable=False, index=True)
    tournament_external_id: Mapped[int] = mapped_column(ForeignKey("tournaments_external.id"), nullable=False, index=True)
    saved_by_user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), nullable=False, index=True)
    notes: Mapped[Optional[str]] = mapped_column(Text)
    added_to_schedule_at: Mapped[Optional[datetime]] = mapped_column(DateTime)
    shared_to_team_at: Mapped[Optional[datetime]] = mapped_column(DateTime)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False
    )

    team = relationship("Team")
    tournament = relationship("TournamentExternal", back_populates="saved_by_teams")
    saved_by = relationship("User", foreign_keys=[saved_by_user_id])


class TournamentFilter(Base):
    __tablename__ = "tournament_filters"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    team_id: Mapped[Optional[int]] = mapped_column(ForeignKey("teams.id"), index=True)
    user_id: Mapped[Optional[int]] = mapped_column(ForeignKey("users.id"), index=True)
    filter_name: Mapped[str] = mapped_column(String(80), nullable=False)
    start_date: Mapped[Optional[date]] = mapped_column(Date)
    end_date: Mapped[Optional[date]] = mapped_column(Date)
    radius_miles: Mapped[Optional[int]] = mapped_column(Integer)
    origin_city: Mapped[Optional[str]] = mapped_column(String(120))
    origin_state: Mapped[Optional[str]] = mapped_column(String(40))
    origin_latitude: Mapped[Optional[float]] = mapped_column(Float)
    origin_longitude: Mapped[Optional[float]] = mapped_column(Float)
    age_group: Mapped[Optional[str]] = mapped_column(String(60))
    weight_class: Mapped[Optional[str]] = mapped_column(String(30))
    event_type: Mapped[Optional[str]] = mapped_column(String(60))
    is_default: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False
    )

    team = relationship("Team")
    user = relationship("User")


class TournamentScanRun(Base):
    __tablename__ = "tournament_scan_runs"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    source_id: Mapped[int] = mapped_column(ForeignKey("tournament_sources.id"), nullable=False, index=True)
    triggered_by_user_id: Mapped[Optional[int]] = mapped_column(ForeignKey("users.id"), index=True)
    status: Mapped[TournamentScanRunStatus] = mapped_column(
        SqlEnum(TournamentScanRunStatus), default=TournamentScanRunStatus.queued, nullable=False, index=True
    )
    query_snapshot: Mapped[dict] = mapped_column(JSON, default=dict, nullable=False)
    items_seen_count: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    items_created_count: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    items_updated_count: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    items_merged_count: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    items_archived_count: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    errors_count: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    notes: Mapped[Optional[str]] = mapped_column(Text)
    started_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, nullable=False, index=True)
    completed_at: Mapped[Optional[datetime]] = mapped_column(DateTime, index=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False
    )

    source = relationship("TournamentSource", back_populates="scan_runs")
    triggered_by = relationship("User", foreign_keys=[triggered_by_user_id])
    change_logs = relationship("TournamentChangeLog", back_populates="scan_run")


class TournamentChangeLog(Base):
    __tablename__ = "tournament_change_logs"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    tournament_external_id: Mapped[int] = mapped_column(
        ForeignKey("tournaments_external.id"), nullable=False, index=True
    )
    source_id: Mapped[int] = mapped_column(ForeignKey("tournament_sources.id"), nullable=False, index=True)
    scan_run_id: Mapped[Optional[int]] = mapped_column(ForeignKey("tournament_scan_runs.id"), index=True)
    actor_user_id: Mapped[Optional[int]] = mapped_column(ForeignKey("users.id"), index=True)
    change_type: Mapped[TournamentChangeType] = mapped_column(SqlEnum(TournamentChangeType), nullable=False, index=True)
    summary: Mapped[str] = mapped_column(String(255), nullable=False)
    field_changes: Mapped[dict] = mapped_column(JSON, default=dict, nullable=False)
    source_priority: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    changed_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, nullable=False, index=True)

    tournament = relationship("TournamentExternal", back_populates="change_logs")
    source = relationship("TournamentSource", back_populates="change_logs")
    scan_run = relationship("TournamentScanRun", back_populates="change_logs")
    actor = relationship("User", foreign_keys=[actor_user_id])


class TournamentAlertSubscription(Base):
    __tablename__ = "tournament_alert_subscriptions"
    __table_args__ = (
        UniqueConstraint(
            "team_id",
            "user_id",
            "tournament_external_id",
            "alert_type",
            "channel",
            name="uq_tournament_alert_subscription_scope",
        ),
    )

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    team_id: Mapped[Optional[int]] = mapped_column(ForeignKey("teams.id"), index=True)
    user_id: Mapped[Optional[int]] = mapped_column(ForeignKey("users.id"), index=True)
    tournament_external_id: Mapped[Optional[int]] = mapped_column(ForeignKey("tournaments_external.id"), index=True)
    alert_type: Mapped[TournamentAlertType] = mapped_column(SqlEnum(TournamentAlertType), nullable=False, index=True)
    channel: Mapped[TournamentAlertChannel] = mapped_column(
        SqlEnum(TournamentAlertChannel), default=TournamentAlertChannel.in_app, nullable=False, index=True
    )
    is_enabled: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    created_by_user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), nullable=False, index=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False
    )

    team = relationship("Team")
    user = relationship("User", foreign_keys=[user_id])
    tournament = relationship("TournamentExternal", back_populates="alert_subscriptions")
    created_by = relationship("User", foreign_keys=[created_by_user_id])
