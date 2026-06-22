from __future__ import annotations

from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field

from app.models.messaging import (
    AlertDeliveryChannel,
    AlertDeliveryStatus,
    AuditAction,
    MessageParticipantType,
    MessageThreadType,
    MessageType,
    SafetyAlertSeverity,
    SafetyAlertStatus,
)
from app.models.user import UserRole
from app.schemas.user import UserRead


class ParentLinkCreate(BaseModel):
    team_id: int
    parent_user_id: int
    athlete_user_id: int
    relationship_label: str = Field(default="parent", min_length=2, max_length=60)


class ParentLinkRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    team_id: int
    parent_user_id: int
    athlete_user_id: int
    relationship_label: str
    is_active: bool
    audit_version: int
    created_at: datetime


class ThreadCreateRequest(BaseModel):
    team_id: int
    title: str = Field(min_length=2, max_length=160)
    thread_type: MessageThreadType
    participant_user_ids: list[int] = Field(min_length=1)


class MessageSendRequest(BaseModel):
    thread_id: int
    body: str = Field(min_length=1, max_length=4000)
    message_type: MessageType = MessageType.text


class MessageEditRequest(BaseModel):
    body: str = Field(min_length=1, max_length=4000)


class AnnouncementSendRequest(BaseModel):
    team_id: int
    title: str = Field(min_length=2, max_length=160)
    body: str = Field(min_length=1, max_length=4000)
    audience_label: str = Field(default="team", min_length=2, max_length=60)
    recipient_user_ids: list[int] | None = None
    send_text_alert: bool = False


class TeamTextAlertReadinessMember(BaseModel):
    user_id: int
    full_name: str
    role: UserRole
    phone: str | None
    has_valid_phone: bool
    normalized_phone: str | None = None
    auto_included_reason: str | None = None


class TeamTextAlertReadinessSummary(BaseModel):
    eligible_recipient_count: int
    valid_phone_recipient_count: int
    missing_phone_recipient_count: int
    coach_count: int
    athlete_count: int
    parent_count: int


class TeamTextAlertReadinessResponse(BaseModel):
    team_id: int
    summary: TeamTextAlertReadinessSummary
    members: list[TeamTextAlertReadinessMember]


class AlertDeliveryRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    team_id: int
    announcement_id: int | None
    safety_alert_id: int | None
    recipient_user_id: int
    channel: AlertDeliveryChannel
    provider: str
    status: AlertDeliveryStatus
    destination: str | None
    provider_message_id: str | None
    failure_reason: str | None
    delivery_metadata: dict | None
    created_at: datetime
    updated_at: datetime
    recipient: UserRead


class MessageParticipantRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    team_id: int
    user_id: int
    participant_type: MessageParticipantType
    visibility_flags: dict | None
    created_at: datetime
    user: UserRead


class MessageRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    thread_id: int
    team_id: int
    sender_id: int
    body: str
    message_type: MessageType
    visibility_flags: dict | None
    audit_version: int
    created_at: datetime
    updated_at: datetime
    edited_at: datetime | None
    deleted_at: datetime | None
    sender: UserRead


class MessageThreadSummary(BaseModel):
    id: int
    team_id: int
    title: str
    thread_type: MessageThreadType
    parent_visibility_required: bool
    is_compliance_locked: bool
    visibility_flags: dict | None
    audit_version: int
    last_message_at: datetime
    created_at: datetime
    participants: list[MessageParticipantRead]
    last_message_preview: str | None = None


class MessageThreadDetail(MessageThreadSummary):
    messages: list[MessageRead]


class AnnouncementRead(BaseModel):
    id: int
    thread_id: int
    team_id: int
    sender_id: int
    title: str
    body: str
    audience_label: str
    visibility_flags: dict | None
    audit_version: int
    created_at: datetime
    sender: UserRead


class MessageAuditLogRead(BaseModel):
    id: int
    team_id: int
    thread_id: int | None
    message_id: int | None
    announcement_id: int | None
    actor_id: int
    action: AuditAction
    entity_type: str
    entity_id: int
    before_state: dict | None
    after_state: dict | None
    visibility_flags: dict | None
    compliance_note: str | None
    audit_version: int
    created_at: datetime
    actor: UserRead


class MessageExportResponse(BaseModel):
    exported_at: datetime
    thread: MessageThreadDetail
    audit_logs: list[MessageAuditLogRead]


class RecipientPreview(BaseModel):
    user_id: int
    full_name: str
    role: UserRole
    auto_included_reason: str | None = None


class SafetyAlertRead(BaseModel):
    id: int
    team_id: int
    source_thread_id: int
    source_message_id: int
    alert_thread_id: int
    source_sender_id: int
    severity: SafetyAlertSeverity
    status: SafetyAlertStatus
    score: int
    categories: list[str] | None
    repeated_trigger_count: int
    subject_athlete_ids: list[int] | None
    summary: str
    source_excerpt: str
    metadata: dict | None
    acknowledged_at: datetime | None
    created_at: datetime
    updated_at: datetime
    source_sender: UserRead
    acknowledged_by: UserRead | None


class SafetyAlertAcknowledgeResponse(BaseModel):
    alert: SafetyAlertRead
