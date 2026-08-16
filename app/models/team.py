from __future__ import annotations
from typing import Optional

from datetime import datetime
from enum import Enum

from sqlalchemy import Boolean, DateTime, Enum as SqlEnum, ForeignKey, Integer, String, Text, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.session import Base


class Team(Base):
    __tablename__ = "teams"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    name: Mapped[str] = mapped_column(String(120), nullable=False)
    slug: Mapped[str] = mapped_column(String(120), unique=True, index=True, nullable=False)
    join_code: Mapped[str] = mapped_column(String(12), unique=True, index=True, nullable=False)
    school_name: Mapped[str] = mapped_column(String(140), nullable=False)
    school_abbreviation: Mapped[Optional[str]] = mapped_column(String(12))
    mascot_name: Mapped[str] = mapped_column(String(120), nullable=False)
    division: Mapped[Optional[str]] = mapped_column(String(50))
    season_label: Mapped[Optional[str]] = mapped_column(String(30))
    dark_mode: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    primary_color: Mapped[str] = mapped_column(String(7), default="#D62828", nullable=False)
    secondary_color: Mapped[str] = mapped_column(String(7), default="#F77F00", nullable=False)
    accent_color: Mapped[str] = mapped_column(String(7), default="#FCBF49", nullable=False)
    surface_color: Mapped[str] = mapped_column(String(7), default="#15171C", nullable=False)
    logo_url: Mapped[Optional[str]] = mapped_column(Text)
    tagline: Mapped[Optional[str]] = mapped_column(String(180))
    created_by_user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False
    )

    creator = relationship("User", foreign_keys=[created_by_user_id])
    memberships = relationship("TeamMember", back_populates="team", cascade="all, delete-orphan")
    primary_users = relationship("User", back_populates="primary_team", foreign_keys="User.primary_team_id")


class TeamMemberStatus(str, Enum):
    pending = "pending"
    approved = "approved"


class AthleteInvitationStatus(str, Enum):
    pending = "pending"
    accepted = "accepted"
    declined = "declined"
    revoked = "revoked"


class TeamMember(Base):
    __tablename__ = "team_members"
    __table_args__ = (UniqueConstraint("team_id", "user_id", name="uq_team_user"),)

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    team_id: Mapped[int] = mapped_column(ForeignKey("teams.id"), nullable=False)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), nullable=False)
    role_label: Mapped[str] = mapped_column(String(60), nullable=False)
    is_staff: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    status: Mapped[TeamMemberStatus] = mapped_column(
        SqlEnum(TeamMemberStatus), default=TeamMemberStatus.approved, nullable=False
    )
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, nullable=False)

    team = relationship("Team", back_populates="memberships")
    user = relationship("User", back_populates="memberships")


class AthleteParentInvitation(Base):
    __tablename__ = "athlete_parent_invitations"
    __table_args__ = (
        UniqueConstraint(
            "team_id",
            "athlete_user_id",
            "parent_email",
            name="uq_athlete_parent_invitation",
        ),
        UniqueConstraint(
            "team_id",
            "athlete_user_id",
            "parent_phone",
            name="uq_athlete_parent_phone_invitation",
        ),
    )

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    team_id: Mapped[int] = mapped_column(ForeignKey("teams.id"), nullable=False, index=True)
    athlete_user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), nullable=False, index=True)
    parent_email: Mapped[str] = mapped_column(String(255), nullable=False, index=True)
    parent_phone: Mapped[Optional[str]] = mapped_column(String(30), index=True)
    relationship_label: Mapped[str] = mapped_column(String(60), default="parent", nullable=False)
    status: Mapped[AthleteInvitationStatus] = mapped_column(
        SqlEnum(AthleteInvitationStatus),
        default=AthleteInvitationStatus.pending,
        nullable=False,
        index=True,
    )
    invited_by_user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), nullable=False)
    accepted_by_user_id: Mapped[Optional[int]] = mapped_column(ForeignKey("users.id"))
    expires_at: Mapped[datetime] = mapped_column(DateTime, nullable=False)
    accepted_at: Mapped[Optional[datetime]] = mapped_column(DateTime)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False
    )

    team = relationship("Team", foreign_keys=[team_id])
    athlete_user = relationship("User", foreign_keys=[athlete_user_id])
    invited_by_user = relationship("User", foreign_keys=[invited_by_user_id])
    accepted_by_user = relationship("User", foreign_keys=[accepted_by_user_id])
