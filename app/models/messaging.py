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


class MessageThreadType(str, Enum):
    announcement = "announcement"
    group = "group"
    direct = "direct"


class MessageParticipantType(str, Enum):
    member = "member"
    parent_visibility = "parent_visibility"


class MessageType(str, Enum):
    text = "text"
    announcement = "announcement"
    compliance_note = "compliance_note"


class AuditAction(str, Enum):
    thread_created = "thread_created"
    announcement_sent = "announcement_sent"
    message_sent = "message_sent"
    message_edited = "message_edited"
    message_soft_deleted = "message_soft_deleted"
    thread_exported = "thread_exported"
    parent_link_created = "parent_link_created"


class SafetyAlertSeverity(str, Enum):
    info = "info"
    concern = "concern"
    urgent = "urgent"


class SafetyAlertStatus(str, Enum):
    open = "open"
    acknowledged = "acknowledged"


class AlertDeliveryChannel(str, Enum):
    sms = "sms"
    email = "email"
    push = "push"


class AlertDeliveryStatus(str, Enum):
    sent = "sent"
    failed = "failed"
    skipped = "skipped"


class MessageThread(Base):
    __tablename__ = "message_threads"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    team_id: Mapped[int] = mapped_column(ForeignKey("teams.id"), nullable=False, index=True)
    title: Mapped[str] = mapped_column(String(160), nullable=False)
    thread_type: Mapped[MessageThreadType] = mapped_column(SqlEnum(MessageThreadType), nullable=False)
    created_by_user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), nullable=False)
    parent_visibility_required: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    is_compliance_locked: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    is_deleted: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    visibility_flags: Mapped[Optional[dict]] = mapped_column(JSON)
    audit_version: Mapped[int] = mapped_column(Integer, default=1, nullable=False)
    last_message_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False
    )

    team = relationship("Team")
    creator = relationship("User", foreign_keys=[created_by_user_id])
    participants = relationship("MessageParticipant", back_populates="thread", cascade="all, delete-orphan")
    messages = relationship("Message", back_populates="thread", cascade="all, delete-orphan")
    announcement = relationship("Announcement", back_populates="thread", uselist=False)


class MessageParticipant(Base):
    __tablename__ = "message_participants"
    __table_args__ = (UniqueConstraint("thread_id", "user_id", name="uq_thread_participant_user"),)

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    thread_id: Mapped[int] = mapped_column(ForeignKey("message_threads.id"), nullable=False, index=True)
    team_id: Mapped[int] = mapped_column(ForeignKey("teams.id"), nullable=False, index=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), nullable=False, index=True)
    participant_type: Mapped[MessageParticipantType] = mapped_column(
        SqlEnum(MessageParticipantType), default=MessageParticipantType.member, nullable=False
    )
    visibility_flags: Mapped[Optional[dict]] = mapped_column(JSON)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, nullable=False)

    thread = relationship("MessageThread", back_populates="participants")
    user = relationship("User")


class Message(Base):
    __tablename__ = "messages"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    thread_id: Mapped[int] = mapped_column(ForeignKey("message_threads.id"), nullable=False, index=True)
    team_id: Mapped[int] = mapped_column(ForeignKey("teams.id"), nullable=False, index=True)
    sender_id: Mapped[int] = mapped_column(ForeignKey("users.id"), nullable=False, index=True)
    body: Mapped[str] = mapped_column(Text, nullable=False)
    message_type: Mapped[MessageType] = mapped_column(SqlEnum(MessageType), default=MessageType.text, nullable=False)
    visibility_flags: Mapped[Optional[dict]] = mapped_column(JSON)
    audit_version: Mapped[int] = mapped_column(Integer, default=1, nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False
    )
    edited_at: Mapped[Optional[datetime]] = mapped_column(DateTime)
    deleted_at: Mapped[Optional[datetime]] = mapped_column(DateTime)
    deleted_by_user_id: Mapped[Optional[int]] = mapped_column(ForeignKey("users.id"))

    thread = relationship("MessageThread", back_populates="messages")
    sender = relationship("User", foreign_keys=[sender_id])
    deleted_by = relationship("User", foreign_keys=[deleted_by_user_id])


class Announcement(Base):
    __tablename__ = "announcements"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    thread_id: Mapped[int] = mapped_column(ForeignKey("message_threads.id"), nullable=False, unique=True, index=True)
    team_id: Mapped[int] = mapped_column(ForeignKey("teams.id"), nullable=False, index=True)
    sender_id: Mapped[int] = mapped_column(ForeignKey("users.id"), nullable=False, index=True)
    title: Mapped[str] = mapped_column(String(160), nullable=False)
    body: Mapped[str] = mapped_column(Text, nullable=False)
    audience_label: Mapped[str] = mapped_column(String(60), default="team", nullable=False)
    visibility_flags: Mapped[Optional[dict]] = mapped_column(JSON)
    audit_version: Mapped[int] = mapped_column(Integer, default=1, nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False
    )

    thread = relationship("MessageThread", back_populates="announcement")
    sender = relationship("User", foreign_keys=[sender_id])


class MessageAuditLog(Base):
    __tablename__ = "message_audit_logs"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    team_id: Mapped[int] = mapped_column(ForeignKey("teams.id"), nullable=False, index=True)
    thread_id: Mapped[Optional[int]] = mapped_column(ForeignKey("message_threads.id"), index=True)
    message_id: Mapped[Optional[int]] = mapped_column(ForeignKey("messages.id"), index=True)
    announcement_id: Mapped[Optional[int]] = mapped_column(ForeignKey("announcements.id"), index=True)
    actor_id: Mapped[int] = mapped_column(ForeignKey("users.id"), nullable=False, index=True)
    action: Mapped[AuditAction] = mapped_column(SqlEnum(AuditAction), nullable=False)
    entity_type: Mapped[str] = mapped_column(String(40), nullable=False)
    entity_id: Mapped[int] = mapped_column(Integer, nullable=False)
    before_state: Mapped[Optional[dict]] = mapped_column(JSON)
    after_state: Mapped[Optional[dict]] = mapped_column(JSON)
    visibility_flags: Mapped[Optional[dict]] = mapped_column(JSON)
    compliance_note: Mapped[Optional[str]] = mapped_column(String(255))
    audit_version: Mapped[int] = mapped_column(Integer, default=1, nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, nullable=False)

    actor = relationship("User", foreign_keys=[actor_id])


class ParentLink(Base):
    __tablename__ = "parent_links"
    __table_args__ = (UniqueConstraint("team_id", "parent_user_id", "athlete_user_id", name="uq_parent_link"),)

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    team_id: Mapped[int] = mapped_column(ForeignKey("teams.id"), nullable=False, index=True)
    parent_user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), nullable=False, index=True)
    athlete_user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), nullable=False, index=True)
    relationship_label: Mapped[str] = mapped_column(String(60), default="parent", nullable=False)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    visibility_flags: Mapped[Optional[dict]] = mapped_column(JSON)
    audit_version: Mapped[int] = mapped_column(Integer, default=1, nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False
    )

    parent_user = relationship("User", foreign_keys=[parent_user_id], back_populates="parent_links_as_parent")
    athlete_user = relationship("User", foreign_keys=[athlete_user_id], back_populates="parent_links_as_athlete")


class SafetyAlert(Base):
    __tablename__ = "safety_alerts"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    team_id: Mapped[int] = mapped_column(ForeignKey("teams.id"), nullable=False, index=True)
    source_thread_id: Mapped[int] = mapped_column(ForeignKey("message_threads.id"), nullable=False, index=True)
    source_message_id: Mapped[int] = mapped_column(ForeignKey("messages.id"), nullable=False, unique=True, index=True)
    alert_thread_id: Mapped[int] = mapped_column(ForeignKey("message_threads.id"), nullable=False, unique=True, index=True)
    source_sender_id: Mapped[int] = mapped_column(ForeignKey("users.id"), nullable=False, index=True)
    severity: Mapped[SafetyAlertSeverity] = mapped_column(
        SqlEnum(SafetyAlertSeverity), default=SafetyAlertSeverity.concern, nullable=False
    )
    status: Mapped[SafetyAlertStatus] = mapped_column(
        SqlEnum(SafetyAlertStatus), default=SafetyAlertStatus.open, nullable=False
    )
    score: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    categories: Mapped[Optional[list]] = mapped_column(JSON)
    repeated_trigger_count: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    subject_athlete_ids: Mapped[Optional[list]] = mapped_column(JSON)
    summary: Mapped[str] = mapped_column(String(255), nullable=False)
    source_excerpt: Mapped[str] = mapped_column(String(500), nullable=False)
    alert_metadata: Mapped[Optional[dict]] = mapped_column("metadata", JSON)
    acknowledged_by_user_id: Mapped[Optional[int]] = mapped_column(ForeignKey("users.id"), index=True)
    acknowledged_at: Mapped[Optional[datetime]] = mapped_column(DateTime)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False
    )

    source_thread = relationship("MessageThread", foreign_keys=[source_thread_id])
    source_message = relationship("Message", foreign_keys=[source_message_id])
    alert_thread = relationship("MessageThread", foreign_keys=[alert_thread_id])
    source_sender = relationship("User", foreign_keys=[source_sender_id])
    acknowledged_by = relationship("User", foreign_keys=[acknowledged_by_user_id])


class AlertDelivery(Base):
    __tablename__ = "alert_deliveries"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    team_id: Mapped[int] = mapped_column(ForeignKey("teams.id"), nullable=False, index=True)
    announcement_id: Mapped[Optional[int]] = mapped_column(ForeignKey("announcements.id"), index=True)
    safety_alert_id: Mapped[Optional[int]] = mapped_column(ForeignKey("safety_alerts.id"), index=True)
    recipient_user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), nullable=False, index=True)
    channel: Mapped[AlertDeliveryChannel] = mapped_column(SqlEnum(AlertDeliveryChannel), nullable=False)
    provider: Mapped[str] = mapped_column(String(40), nullable=False)
    status: Mapped[AlertDeliveryStatus] = mapped_column(SqlEnum(AlertDeliveryStatus), nullable=False)
    destination: Mapped[Optional[str]] = mapped_column(String(255))
    provider_message_id: Mapped[Optional[str]] = mapped_column(String(255), index=True)
    failure_reason: Mapped[Optional[str]] = mapped_column(String(255))
    delivery_metadata: Mapped[Optional[dict]] = mapped_column(JSON)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False
    )

    recipient = relationship("User", foreign_keys=[recipient_user_id])
    announcement = relationship("Announcement")
    safety_alert = relationship("SafetyAlert")
