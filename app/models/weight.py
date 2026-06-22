from __future__ import annotations
from typing import Optional

from datetime import date, datetime
from enum import Enum

from sqlalchemy import Date, DateTime, Enum as SqlEnum, Float, ForeignKey, Integer, JSON, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.session import Base


class WeightPlanStatus(str, Enum):
    green = "green"
    yellow = "yellow"
    red = "red"


class WeightAlertType(str, Enum):
    missing_logs = "missing_logs"
    unsafe_cut_pace = "unsafe_cut_pace"
    approaching_weigh_in = "approaching_weigh_in"
    off_target = "off_target"


class WeightAlertStatus(str, Enum):
    active = "active"
    resolved = "resolved"


class WeightLog(Base):
    __tablename__ = "weight_logs"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    athlete_id: Mapped[int] = mapped_column(ForeignKey("users.id"), nullable=False, index=True)
    team_id: Mapped[int] = mapped_column(ForeignKey("teams.id"), nullable=False, index=True)
    created_by_user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), nullable=False)
    logged_at: Mapped[datetime] = mapped_column(DateTime, nullable=False, index=True)
    weight: Mapped[float] = mapped_column(Float, nullable=False)
    body_fat_percentage: Mapped[Optional[float]] = mapped_column(Float)
    hydration_note: Mapped[Optional[str]] = mapped_column(String(255))
    comments: Mapped[Optional[str]] = mapped_column(Text)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, nullable=False)

    athlete = relationship("User", foreign_keys=[athlete_id])
    created_by = relationship("User", foreign_keys=[created_by_user_id])
    team = relationship("Team")


class HydrationLog(Base):
    __tablename__ = "hydration_logs"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    athlete_id: Mapped[int] = mapped_column(ForeignKey("users.id"), nullable=False, index=True)
    team_id: Mapped[int] = mapped_column(ForeignKey("teams.id"), nullable=False, index=True)
    logged_at: Mapped[datetime] = mapped_column(DateTime, nullable=False)
    note: Mapped[str] = mapped_column(String(255), nullable=False)
    status_label: Mapped[Optional[str]] = mapped_column(String(60))
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, nullable=False)

    athlete = relationship("User", foreign_keys=[athlete_id])
    team = relationship("Team")


class AthleteTarget(Base):
    __tablename__ = "athlete_targets"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    athlete_id: Mapped[int] = mapped_column(ForeignKey("users.id"), nullable=False, index=True)
    team_id: Mapped[int] = mapped_column(ForeignKey("teams.id"), nullable=False, index=True)
    target_weight_class: Mapped[float] = mapped_column(Float, nullable=False)
    target_date: Mapped[date] = mapped_column(Date, nullable=False)
    body_fat_percentage: Mapped[Optional[float]] = mapped_column(Float)
    is_active: Mapped[bool] = mapped_column(default=True, nullable=False)
    created_by_user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False
    )

    athlete = relationship("User", foreign_keys=[athlete_id])
    created_by = relationship("User", foreign_keys=[created_by_user_id])
    team = relationship("Team")


class WeightPlan(Base):
    __tablename__ = "weight_plans"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    athlete_id: Mapped[int] = mapped_column(ForeignKey("users.id"), nullable=False, index=True)
    team_id: Mapped[int] = mapped_column(ForeignKey("teams.id"), nullable=False, index=True)
    athlete_target_id: Mapped[Optional[int]] = mapped_column(ForeignKey("athlete_targets.id"), index=True)
    calculated_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, nullable=False, index=True)
    current_weight: Mapped[float] = mapped_column(Float, nullable=False)
    body_fat_percentage: Mapped[Optional[float]] = mapped_column(Float)
    target_weight_class: Mapped[float] = mapped_column(Float, nullable=False)
    target_date: Mapped[date] = mapped_column(Date, nullable=False)
    weekly_allowed_loss: Mapped[float] = mapped_column(Float, nullable=False)
    required_weekly_loss: Mapped[float] = mapped_column(Float, nullable=False)
    projected_reachable_weight: Mapped[float] = mapped_column(Float, nullable=False)
    estimated_reachable_class: Mapped[float] = mapped_column(Float, nullable=False)
    projected_target_date: Mapped[date] = mapped_column(Date, nullable=False)
    status: Mapped[WeightPlanStatus] = mapped_column(SqlEnum(WeightPlanStatus), nullable=False)
    warning_message: Mapped[Optional[str]] = mapped_column(Text)
    summary: Mapped[str] = mapped_column(String(255), nullable=False)
    plan_details: Mapped[Optional[dict]] = mapped_column(JSON)

    athlete = relationship("User", foreign_keys=[athlete_id])
    athlete_target = relationship("AthleteTarget")
    team = relationship("Team")


class WeightAlert(Base):
    __tablename__ = "weight_alerts"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    athlete_id: Mapped[int] = mapped_column(ForeignKey("users.id"), nullable=False, index=True)
    team_id: Mapped[int] = mapped_column(ForeignKey("teams.id"), nullable=False, index=True)
    plan_id: Mapped[Optional[int]] = mapped_column(ForeignKey("weight_plans.id"), index=True)
    alert_type: Mapped[WeightAlertType] = mapped_column(SqlEnum(WeightAlertType), nullable=False)
    alert_message: Mapped[str] = mapped_column(Text, nullable=False)
    status: Mapped[WeightAlertStatus] = mapped_column(
        SqlEnum(WeightAlertStatus), default=WeightAlertStatus.active, nullable=False
    )
    severity: Mapped[WeightPlanStatus] = mapped_column(SqlEnum(WeightPlanStatus), nullable=False)
    triggered_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, nullable=False)
    resolved_at: Mapped[Optional[datetime]] = mapped_column(DateTime)

    athlete = relationship("User", foreign_keys=[athlete_id])
    plan = relationship("WeightPlan")
    team = relationship("Team")
