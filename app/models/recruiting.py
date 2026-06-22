from __future__ import annotations
from typing import Optional

from datetime import datetime
from enum import Enum

from sqlalchemy import (
    JSON,
    Boolean,
    DateTime,
    Enum as SqlEnum,
    ForeignKey,
    Integer,
    String,
    Text,
    UniqueConstraint,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.session import Base


class RecruitingVisibilityLevel(str, Enum):
    public = "public"
    coaches_only = "coaches_only"
    private = "private"


class RecruitingContactVisibility(str, Enum):
    hidden = "hidden"
    coaches_only = "coaches_only"
    full = "full"


class RecruitingProfile(Base):
    __tablename__ = "recruiting_profiles"
    __table_args__ = (UniqueConstraint("athlete_id", name="uq_recruiting_profile_athlete"),)

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    athlete_id: Mapped[int] = mapped_column(ForeignKey("users.id"), nullable=False, index=True)
    team_id: Mapped[Optional[int]] = mapped_column(ForeignKey("teams.id"), index=True)
    graduation_year: Mapped[int] = mapped_column(Integer, nullable=False, index=True)
    school_team: Mapped[Optional[str]] = mapped_column(String(160))
    weight_class: Mapped[str] = mapped_column(String(30), nullable=False, index=True)
    height: Mapped[Optional[str]] = mapped_column(String(20))
    gpa: Mapped[Optional[str]] = mapped_column(String(10))
    bio: Mapped[Optional[str]] = mapped_column(Text)
    achievements: Mapped[Optional[list]] = mapped_column(JSON)
    contact_email: Mapped[Optional[str]] = mapped_column(String(255))
    contact_phone: Mapped[Optional[str]] = mapped_column(String(30))
    location_label: Mapped[Optional[str]] = mapped_column(String(140), index=True)
    stats_summary: Mapped[Optional[dict]] = mapped_column(JSON)
    match_record_override: Mapped[Optional[str]] = mapped_column(String(40))
    profile_image_url: Mapped[Optional[str]] = mapped_column(String(500))
    is_open: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False, index=True)
    is_actively_looking: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False, index=True)
    is_featured: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False, index=True)
    boost_requested: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    visibility_level: Mapped[RecruitingVisibilityLevel] = mapped_column(
        SqlEnum(RecruitingVisibilityLevel), default=RecruitingVisibilityLevel.coaches_only, nullable=False
    )
    contact_visibility: Mapped[RecruitingContactVisibility] = mapped_column(
        SqlEnum(RecruitingContactVisibility), default=RecruitingContactVisibility.hidden, nullable=False
    )
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False
    )

    athlete = relationship("User", foreign_keys=[athlete_id])
    team = relationship("Team")
    visibility = relationship(
        "RecruitingVisibility",
        back_populates="profile",
        uselist=False,
        cascade="all, delete-orphan",
    )
    highlights = relationship("RecruitingHighlight", back_populates="profile", cascade="all, delete-orphan")
    watchlist_entries = relationship("RecruitingWatchlist", back_populates="profile", cascade="all, delete-orphan")
    notes = relationship("RecruitingNote", back_populates="profile", cascade="all, delete-orphan")
    tags = relationship("RecruitingTag", back_populates="profile", cascade="all, delete-orphan")


class RecruitingVisibility(Base):
    __tablename__ = "recruiting_visibility"
    __table_args__ = (UniqueConstraint("profile_id", name="uq_recruiting_visibility_profile"),)

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    profile_id: Mapped[int] = mapped_column(ForeignKey("recruiting_profiles.id"), nullable=False, index=True)
    show_contact_to_coaches: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    show_gpa: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    show_location: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    show_profile_photo: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    parent_visibility_required: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    allow_direct_contact_request: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False
    )

    profile = relationship("RecruitingProfile", back_populates="visibility")


class RecruitingWatchlist(Base):
    __tablename__ = "recruiting_watchlists"
    __table_args__ = (UniqueConstraint("coach_user_id", "athlete_id", name="uq_recruiting_watchlist_coach_athlete"),)

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    coach_user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), nullable=False, index=True)
    athlete_id: Mapped[int] = mapped_column(ForeignKey("users.id"), nullable=False, index=True)
    team_id: Mapped[Optional[int]] = mapped_column(ForeignKey("teams.id"), index=True)
    profile_id: Mapped[Optional[int]] = mapped_column(ForeignKey("recruiting_profiles.id"), index=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False
    )

    coach = relationship("User", foreign_keys=[coach_user_id])
    athlete = relationship("User", foreign_keys=[athlete_id])
    team = relationship("Team")
    profile = relationship("RecruitingProfile", back_populates="watchlist_entries")


class RecruitingNote(Base):
    __tablename__ = "recruiting_notes"
    __table_args__ = (UniqueConstraint("coach_user_id", "athlete_id", name="uq_recruiting_note_coach_athlete"),)

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    coach_user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), nullable=False, index=True)
    athlete_id: Mapped[int] = mapped_column(ForeignKey("users.id"), nullable=False, index=True)
    team_id: Mapped[Optional[int]] = mapped_column(ForeignKey("teams.id"), index=True)
    profile_id: Mapped[Optional[int]] = mapped_column(ForeignKey("recruiting_profiles.id"), index=True)
    note: Mapped[str] = mapped_column(Text, nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False
    )

    coach = relationship("User", foreign_keys=[coach_user_id])
    athlete = relationship("User", foreign_keys=[athlete_id])
    team = relationship("Team")
    profile = relationship("RecruitingProfile", back_populates="notes")


class RecruitingTag(Base):
    __tablename__ = "recruiting_tags"
    __table_args__ = (UniqueConstraint("coach_user_id", "athlete_id", "tag", name="uq_recruiting_tag_coach_athlete"),)

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    coach_user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), nullable=False, index=True)
    athlete_id: Mapped[int] = mapped_column(ForeignKey("users.id"), nullable=False, index=True)
    team_id: Mapped[Optional[int]] = mapped_column(ForeignKey("teams.id"), index=True)
    profile_id: Mapped[Optional[int]] = mapped_column(ForeignKey("recruiting_profiles.id"), index=True)
    tag: Mapped[str] = mapped_column(String(50), nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, nullable=False)

    coach = relationship("User", foreign_keys=[coach_user_id])
    athlete = relationship("User", foreign_keys=[athlete_id])
    team = relationship("Team")
    profile = relationship("RecruitingProfile", back_populates="tags")


class RecruitingHighlight(Base):
    __tablename__ = "recruiting_highlights"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    athlete_id: Mapped[int] = mapped_column(ForeignKey("users.id"), nullable=False, index=True)
    profile_id: Mapped[int] = mapped_column(ForeignKey("recruiting_profiles.id"), nullable=False, index=True)
    title: Mapped[str] = mapped_column(String(120), nullable=False)
    highlight_url: Mapped[str] = mapped_column(String(500), nullable=False)
    sort_order: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False
    )

    athlete = relationship("User", foreign_keys=[athlete_id])
    profile = relationship("RecruitingProfile", back_populates="highlights")
