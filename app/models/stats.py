from __future__ import annotations
from typing import Optional

from datetime import date, datetime
from enum import Enum

from sqlalchemy import (
    JSON,
    Date,
    DateTime,
    Enum as SqlEnum,
    Float,
    ForeignKey,
    Integer,
    String,
    Text,
    UniqueConstraint,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.session import Base


class MatchOutcome(str, Enum):
    win = "win"
    loss = "loss"


class MatchResultType(str, Enum):
    pin = "pin"
    tech_fall = "tech_fall"
    major_decision = "major_decision"
    decision = "decision"
    medical_forfeit = "medical_forfeit"
    forfeit = "forfeit"
    default = "default"
    disqualification = "disqualification"


class StatAuditAction(str, Enum):
    match_created = "match_created"
    match_updated = "match_updated"
    match_stats_created = "match_stats_created"
    match_stats_updated = "match_stats_updated"


class Match(Base):
    __tablename__ = "matches"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    athlete_id: Mapped[int] = mapped_column(ForeignKey("users.id"), nullable=False, index=True)
    team_id: Mapped[int] = mapped_column(ForeignKey("teams.id"), nullable=False, index=True)
    created_by_user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), nullable=False)
    updated_by_user_id: Mapped[Optional[int]] = mapped_column(ForeignKey("users.id"))
    opponent_name: Mapped[str] = mapped_column(String(120), nullable=False)
    opponent_school: Mapped[Optional[str]] = mapped_column(String(140))
    event_name: Mapped[Optional[str]] = mapped_column(String(160))
    match_date: Mapped[date] = mapped_column(Date, nullable=False, index=True)
    weight_class: Mapped[str] = mapped_column(String(30), nullable=False, index=True)
    result: Mapped[MatchOutcome] = mapped_column(SqlEnum(MatchOutcome), nullable=False, index=True)
    result_type: Mapped[MatchResultType] = mapped_column(SqlEnum(MatchResultType), nullable=False, index=True)
    score_for: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    score_against: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    pin_time: Mapped[Optional[str]] = mapped_column(String(12))
    notes: Mapped[Optional[str]] = mapped_column(Text)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False
    )

    athlete = relationship("User", foreign_keys=[athlete_id])
    created_by = relationship("User", foreign_keys=[created_by_user_id])
    updated_by = relationship("User", foreign_keys=[updated_by_user_id])
    team = relationship("Team")
    stats = relationship("MatchStats", back_populates="match", uselist=False, cascade="all, delete-orphan")


class MatchStats(Base):
    __tablename__ = "match_stats"
    __table_args__ = (UniqueConstraint("match_id", name="uq_match_stats_match_id"),)

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    match_id: Mapped[int] = mapped_column(ForeignKey("matches.id"), nullable=False, index=True)
    athlete_id: Mapped[int] = mapped_column(ForeignKey("users.id"), nullable=False, index=True)
    team_id: Mapped[int] = mapped_column(ForeignKey("teams.id"), nullable=False, index=True)
    takedowns: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    escapes: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    reversals: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    nearfall_points: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    stall_calls: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    ride_time_seconds: Mapped[Optional[int]] = mapped_column(Integer)
    shot_attempts: Mapped[Optional[int]] = mapped_column(Integer)
    shot_conversions: Mapped[Optional[int]] = mapped_column(Integer)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False
    )

    athlete = relationship("User", foreign_keys=[athlete_id])
    match = relationship("Match", back_populates="stats")
    team = relationship("Team")


class AthleteStatSnapshot(Base):
    __tablename__ = "athlete_stat_snapshots"
    __table_args__ = (UniqueConstraint("team_id", "athlete_id", name="uq_athlete_stat_snapshot"),)

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    team_id: Mapped[int] = mapped_column(ForeignKey("teams.id"), nullable=False, index=True)
    athlete_id: Mapped[int] = mapped_column(ForeignKey("users.id"), nullable=False, index=True)
    total_matches: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    wins: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    losses: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    win_percentage: Mapped[float] = mapped_column(Float, default=0, nullable=False)
    bonus_point_rate: Mapped[float] = mapped_column(Float, default=0, nullable=False)
    recent_trend: Mapped[Optional[str]] = mapped_column(String(60))
    strengths_summary: Mapped[Optional[str]] = mapped_column(String(255))
    weaknesses_summary: Mapped[Optional[str]] = mapped_column(String(255))
    summary_payload: Mapped[Optional[dict]] = mapped_column(JSON)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False
    )

    athlete = relationship("User", foreign_keys=[athlete_id])
    team = relationship("Team")


class TeamStatSnapshot(Base):
    __tablename__ = "team_stat_snapshots"
    __table_args__ = (UniqueConstraint("team_id", name="uq_team_stat_snapshot"),)

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    team_id: Mapped[int] = mapped_column(ForeignKey("teams.id"), nullable=False, index=True)
    total_matches: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    wins: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    losses: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    win_percentage: Mapped[float] = mapped_column(Float, default=0, nullable=False)
    recent_trend: Mapped[Optional[str]] = mapped_column(String(120))
    summary_payload: Mapped[Optional[dict]] = mapped_column(JSON)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False
    )

    team = relationship("Team")


class StatAuditLog(Base):
    __tablename__ = "stat_audit_logs"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    team_id: Mapped[int] = mapped_column(ForeignKey("teams.id"), nullable=False, index=True)
    athlete_id: Mapped[Optional[int]] = mapped_column(ForeignKey("users.id"), index=True)
    match_id: Mapped[Optional[int]] = mapped_column(ForeignKey("matches.id"), index=True)
    actor_id: Mapped[int] = mapped_column(ForeignKey("users.id"), nullable=False, index=True)
    action: Mapped[StatAuditAction] = mapped_column(SqlEnum(StatAuditAction), nullable=False)
    entity_type: Mapped[str] = mapped_column(String(40), nullable=False)
    entity_id: Mapped[int] = mapped_column(Integer, nullable=False)
    before_state: Mapped[Optional[dict]] = mapped_column(JSON)
    after_state: Mapped[Optional[dict]] = mapped_column(JSON)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, nullable=False)

    actor = relationship("User", foreign_keys=[actor_id])
    athlete = relationship("User", foreign_keys=[athlete_id])
    match = relationship("Match", foreign_keys=[match_id])
    team = relationship("Team")
