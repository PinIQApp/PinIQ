from __future__ import annotations
from typing import Optional

from datetime import date, datetime
from enum import Enum

from sqlalchemy import Boolean, Date, DateTime, Enum as SqlEnum, ForeignKey, Integer, JSON, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.session import Base


class EventType(str, Enum):
    practice = "practice"
    dual_meet = "dual_meet"
    tournament = "tournament"
    travel = "travel"
    team_meeting = "team_meeting"
    fundraiser = "fundraiser"


class PracticeBlockType(str, Enum):
    warm_up = "warm_up"
    stance_and_motion = "stance_and_motion"
    drilling = "drilling"
    live_goes = "live_goes"
    top_bottom = "top_bottom"
    neutral = "neutral"
    conditioning = "conditioning"
    cool_down = "cool_down"
    film_review = "film_review"
    recovery = "recovery"


class Event(Base):
    __tablename__ = "events"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    team_id: Mapped[int] = mapped_column(ForeignKey("teams.id"), nullable=False, index=True)
    created_by_user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), nullable=False)
    practice_plan_id: Mapped[Optional[int]] = mapped_column(ForeignKey("practice_plans.id"), index=True)
    external_tournament_id: Mapped[Optional[int]] = mapped_column(ForeignKey("tournaments_external.id"), index=True)
    title: Mapped[str] = mapped_column(String(160), nullable=False)
    description: Mapped[Optional[str]] = mapped_column(Text)
    event_type: Mapped[EventType] = mapped_column(SqlEnum(EventType), nullable=False, index=True)
    starts_at: Mapped[datetime] = mapped_column(DateTime, nullable=False, index=True)
    ends_at: Mapped[datetime] = mapped_column(DateTime, nullable=False, index=True)
    location: Mapped[Optional[str]] = mapped_column(String(180))
    notes: Mapped[Optional[str]] = mapped_column(Text)
    checklist: Mapped[Optional[list[str]]] = mapped_column(JSON)
    bus_departure_note: Mapped[Optional[str]] = mapped_column(String(255))
    weigh_in_note: Mapped[Optional[str]] = mapped_column(String(255))
    is_cancelled: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False
    )

    team = relationship("Team")
    creator = relationship("User", foreign_keys=[created_by_user_id])
    practice_plan = relationship("PracticePlan", back_populates="event", foreign_keys=[practice_plan_id])
    external_tournament = relationship("TournamentExternal", back_populates="scheduled_events")


class PracticePlan(Base):
    __tablename__ = "practice_plans"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    team_id: Mapped[int] = mapped_column(ForeignKey("teams.id"), nullable=False, index=True)
    created_by_user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), nullable=False)
    template_id: Mapped[Optional[int]] = mapped_column(ForeignKey("practice_templates.id"), index=True)
    title: Mapped[str] = mapped_column(String(160), nullable=False)
    description: Mapped[Optional[str]] = mapped_column(Text)
    focus: Mapped[Optional[str]] = mapped_column(String(180))
    practice_date: Mapped[Optional[date]] = mapped_column(Date, index=True)
    notes: Mapped[Optional[str]] = mapped_column(Text)
    total_duration_minutes: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    template_name_snapshot: Mapped[Optional[str]] = mapped_column(String(120))
    is_template_based: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False
    )

    team = relationship("Team")
    creator = relationship("User", foreign_keys=[created_by_user_id])
    blocks = relationship(
        "PracticeBlock",
        back_populates="practice_plan",
        cascade="all, delete-orphan",
        order_by="PracticeBlock.block_order",
    )
    template = relationship("PracticeTemplate", back_populates="practice_plans")
    event = relationship("Event", back_populates="practice_plan", uselist=False, foreign_keys=[Event.practice_plan_id])


class PracticeBlock(Base):
    __tablename__ = "practice_blocks"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    practice_plan_id: Mapped[int] = mapped_column(ForeignKey("practice_plans.id"), nullable=False, index=True)
    block_order: Mapped[int] = mapped_column(Integer, nullable=False)
    block_type: Mapped[PracticeBlockType] = mapped_column(SqlEnum(PracticeBlockType), nullable=False)
    title: Mapped[Optional[str]] = mapped_column(String(160))
    notes: Mapped[Optional[str]] = mapped_column(Text)
    duration_minutes: Mapped[int] = mapped_column(Integer, nullable=False)

    practice_plan = relationship("PracticePlan", back_populates="blocks")


class PracticeTemplate(Base):
    __tablename__ = "practice_templates"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    team_id: Mapped[int] = mapped_column(ForeignKey("teams.id"), nullable=False, index=True)
    created_by_user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), nullable=False)
    template_name: Mapped[str] = mapped_column(String(120), nullable=False)
    description: Mapped[Optional[str]] = mapped_column(Text)
    focus: Mapped[Optional[str]] = mapped_column(String(180))
    total_duration_minutes: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    is_system_template: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False
    )

    team = relationship("Team")
    creator = relationship("User", foreign_keys=[created_by_user_id])
    blocks = relationship(
        "PracticeTemplateBlock",
        back_populates="practice_template",
        cascade="all, delete-orphan",
        order_by="PracticeTemplateBlock.block_order",
    )
    practice_plans = relationship("PracticePlan", back_populates="template")


class PracticeTemplateBlock(Base):
    __tablename__ = "practice_template_blocks"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    practice_template_id: Mapped[int] = mapped_column(
        ForeignKey("practice_templates.id"),
        nullable=False,
        index=True,
    )
    block_order: Mapped[int] = mapped_column(Integer, nullable=False)
    block_type: Mapped[PracticeBlockType] = mapped_column(SqlEnum(PracticeBlockType), nullable=False)
    title: Mapped[Optional[str]] = mapped_column(String(160))
    notes: Mapped[Optional[str]] = mapped_column(Text)
    duration_minutes: Mapped[int] = mapped_column(Integer, nullable=False)

    practice_template = relationship("PracticeTemplate", back_populates="blocks")
