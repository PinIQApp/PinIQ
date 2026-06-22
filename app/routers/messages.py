from __future__ import annotations

import csv
import io
from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException, Query
from fastapi.responses import PlainTextResponse
from sqlalchemy.orm import Session, joinedload

from app.db.session import get_db
from app.models.messaging import (
    Announcement,
    AlertDelivery,
    AuditAction,
    Message,
    MessageAuditLog,
    MessageParticipant,
    MessageType,
    MessageThread,
    MessageThreadType,
    ParentLink,
    SafetyAlert,
    SafetyAlertSeverity,
    SafetyAlertStatus,
)
from app.models.user import User, UserRole
from app.routers.deps import get_current_user
from app.schemas.messaging import (
    AnnouncementRead,
    AnnouncementSendRequest,
    AlertDeliveryRead,
    MessageAuditLogRead,
    MessageEditRequest,
    MessageExportResponse,
    MessageRead,
    MessageSendRequest,
    SafetyAlertAcknowledgeResponse,
    SafetyAlertRead,
    MessageThreadDetail,
    MessageThreadSummary,
    ParentLinkCreate,
    ParentLinkRead,
    TeamTextAlertReadinessMember,
    TeamTextAlertReadinessResponse,
    TeamTextAlertReadinessSummary,
    ThreadCreateRequest,
)
from app.services.alert_delivery import deliver_alert_bundle
from app.services.pagination import normalize_pagination
from app.services.messaging_compliance import (
    announcement_to_read,
    audit_to_read,
    detect_message_risk_categories,
    ensure_thread_parent_visibility,
    escalate_flagged_message,
    get_thread_participant,
    load_team_with_members,
    log_action,
    message_to_read,
    participant_to_read,
    require_message_editor,
    require_thread_send_access,
    require_team_access,
    require_team_manager_for_audit,
    require_thread_access,
    resolve_visible_participants,
    safety_alert_to_read,
    thread_to_detail,
    thread_to_summary,
    utcnow,
)
from app.services.sms_alerts import render_team_text_message
from app.services.phone_numbers import has_valid_phone_number, normalize_phone_number


router = APIRouter(tags=["messaging"])


def _build_delivery_summary(deliveries: list[AlertDelivery]) -> dict[str, object]:
    channel_counts: dict[str, int] = {}
    status_counts: dict[str, int] = {}
    fallback_user_ids: set[int] = set()
    for delivery in deliveries:
        channel_key = f"{delivery.channel.value}_{delivery.status.value}_count"
        channel_counts[channel_key] = channel_counts.get(channel_key, 0) + 1
        status_key = delivery.status.value
        status_counts[status_key] = status_counts.get(status_key, 0) + 1
        if delivery.channel.value in {"email", "push"} and delivery.status.value == "sent":
            fallback_user_ids.add(delivery.recipient_user_id)

    return {
        **channel_counts,
        "status_counts": status_counts,
        "fallback_user_ids": sorted(fallback_user_ids),
    }


def _require_team_text_alert_sender(current_user: User) -> None:
    if current_user.role not in {UserRole.coach, UserRole.admin}:
        raise HTTPException(
            status_code=403,
            detail="Only coaches and administrators can send team text alerts",
        )


def _load_thread(db: Session, thread_id: int) -> MessageThread:
    thread = (
        db.query(MessageThread)
        .options(
            joinedload(MessageThread.participants).joinedload(MessageParticipant.user),
            joinedload(MessageThread.messages).joinedload(Message.sender),
            joinedload(MessageThread.announcement).joinedload(Announcement.sender),
        )
        .filter(MessageThread.id == thread_id, MessageThread.is_deleted.is_(False))
        .first()
    )
    if not thread:
        raise HTTPException(status_code=404, detail="Thread not found")
    return thread


@router.post("/announcements/send", response_model=AnnouncementRead)
def send_announcement(
    payload: AnnouncementSendRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    team = load_team_with_members(db, payload.team_id)
    membership = require_team_access(team, current_user)
    require_team_manager_for_audit(team, current_user, membership)

    if payload.send_text_alert:
        _require_team_text_alert_sender(current_user)
        if payload.recipient_user_ids is not None:
            raise HTTPException(
                status_code=400,
                detail="Team text alerts always go to the whole team and linked parents",
            )

    recipient_ids = (
        [
            member.user_id
            for member in team.memberships
            if member.status.value == "approved"
        ]
        if payload.send_text_alert
        else payload.recipient_user_ids
        or [
            member.user_id
            for member in team.memberships
            if member.status.value == "approved"
        ]
    )
    resolved_participants, flags = resolve_visible_participants(db, team, recipient_ids, current_user)

    thread = MessageThread(
        team_id=team.id,
        title=payload.title.strip(),
        thread_type=MessageThreadType.announcement,
        created_by_user_id=current_user.id,
        parent_visibility_required=flags["has_athlete_participants"],
        is_compliance_locked=True,
        visibility_flags={
            **flags,
            "announcement_scope": payload.audience_label,
            "team_text_alert": payload.send_text_alert,
            "text_alert_delivery": None,
        },
        last_message_at=utcnow(),
    )
    db.add(thread)
    db.flush()

    for user, participant_type, reason in resolved_participants:
        thread.participants.append(
            MessageParticipant(
                thread_id=thread.id,
                team_id=team.id,
                user_id=user.id,
                participant_type=participant_type,
                visibility_flags={"auto_included_reason": reason} if reason else None,
            )
        )

    message = Message(
        thread_id=thread.id,
        team_id=team.id,
        sender_id=current_user.id,
        body=payload.body.strip(),
        message_type=MessageType.announcement,
        visibility_flags={
            "announcement": True,
            "audience_label": payload.audience_label,
            "team_text_alert": payload.send_text_alert,
        },
    )
    db.add(message)
    db.flush()

    announcement = Announcement(
        thread_id=thread.id,
        team_id=team.id,
        sender_id=current_user.id,
        title=payload.title.strip(),
        body=payload.body.strip(),
        audience_label=payload.audience_label,
        visibility_flags=thread.visibility_flags,
    )
    db.add(announcement)
    db.flush()

    if payload.send_text_alert:
        delivery_summary = deliver_alert_bundle(
            db,
            team_id=team.id,
            users=[user for user, _, _ in resolved_participants],
            announcement_id=announcement.id,
            safety_alert_id=None,
            message_title=payload.title.strip(),
            message_body=render_team_text_message(
                team_name=team.name,
                title=payload.title.strip(),
                body=payload.body.strip(),
            ),
            push_title=payload.title.strip(),
            push_body=payload.body.strip(),
            push_data={"announcement_id": announcement.id, "team_id": team.id},
            initiated_by_user_id=current_user.id,
        )
        announcement.visibility_flags = {
            **(announcement.visibility_flags or {}),
            "text_alert_delivery": delivery_summary.as_dict(),
        }
        thread.visibility_flags = {
            **(thread.visibility_flags or {}),
            "text_alert_delivery": delivery_summary.as_dict(),
        }

    log_action(
        db,
        team_id=team.id,
        actor_id=current_user.id,
        action=AuditAction.thread_created,
        entity_type="thread",
        entity_id=thread.id,
        thread_id=thread.id,
        after_state={"title": thread.title, "thread_type": thread.thread_type.value, "participant_count": len(thread.participants)},
        visibility_flags=thread.visibility_flags,
        compliance_note="Announcement thread created with parent visibility enforcement",
    )
    log_action(
        db,
        team_id=team.id,
        actor_id=current_user.id,
        action=AuditAction.announcement_sent,
        entity_type="announcement",
        entity_id=announcement.id,
        thread_id=thread.id,
        message_id=message.id,
        announcement_id=announcement.id,
        after_state={"title": announcement.title, "audience_label": announcement.audience_label},
        visibility_flags=announcement.visibility_flags,
        compliance_note="Announcement stored and distributed to all visible participants",
    )
    db.commit()

    announcement = (
        db.query(Announcement)
        .options(joinedload(Announcement.sender))
        .filter(Announcement.id == announcement.id)
        .first()
    )
    return announcement_to_read(announcement)


@router.get("/announcements/{announcement_id}/deliveries", response_model=list[AlertDeliveryRead])
def get_announcement_deliveries(
    announcement_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    announcement = db.query(Announcement).filter(Announcement.id == announcement_id).first()
    if not announcement:
        raise HTTPException(status_code=404, detail="Announcement not found")

    team = load_team_with_members(db, announcement.team_id)
    membership = require_team_access(team, current_user)
    require_team_manager_for_audit(team, current_user, membership)

    deliveries = (
        db.query(AlertDelivery)
        .options(joinedload(AlertDelivery.recipient))
        .filter(AlertDelivery.announcement_id == announcement_id)
        .order_by(AlertDelivery.created_at.asc(), AlertDelivery.id.asc())
        .all()
    )
    return deliveries


@router.get(
    "/announcements/team/{team_id}/text-alert-readiness",
    response_model=TeamTextAlertReadinessResponse,
)
def get_team_text_alert_readiness(
    team_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    team = load_team_with_members(db, team_id)
    membership = require_team_access(team, current_user)
    require_team_manager_for_audit(team, current_user, membership)
    _require_team_text_alert_sender(current_user)

    requested_user_ids = [
        member.user_id
        for member in team.memberships
        if member.status.value == "approved"
    ]
    resolved_participants, _ = resolve_visible_participants(db, team, requested_user_ids, current_user)

    deduped_members: dict[int, TeamTextAlertReadinessMember] = {}
    for user, _, reason in resolved_participants:
        try:
            normalized_phone = normalize_phone_number(user.phone)
        except ValueError:
            normalized_phone = None
        deduped_members[user.id] = TeamTextAlertReadinessMember(
            user_id=user.id,
            full_name=user.full_name,
            role=user.role,
            phone=user.phone,
            has_valid_phone=has_valid_phone_number(user.phone),
            normalized_phone=normalized_phone,
            auto_included_reason=reason,
        )

    members = sorted(
        deduped_members.values(),
        key=lambda item: (
            0 if item.has_valid_phone else 1,
            item.role.value,
            item.full_name.casefold(),
        ),
    )
    summary = TeamTextAlertReadinessSummary(
        eligible_recipient_count=len(members),
        valid_phone_recipient_count=sum(1 for member in members if member.has_valid_phone),
        missing_phone_recipient_count=sum(1 for member in members if not member.has_valid_phone),
        coach_count=sum(1 for member in members if member.role == UserRole.coach),
        athlete_count=sum(1 for member in members if member.role == UserRole.athlete),
        parent_count=sum(1 for member in members if member.role == UserRole.parent),
    )
    return TeamTextAlertReadinessResponse(team_id=team_id, summary=summary, members=members)


@router.get("/messages/safety-alerts/{alert_id}/deliveries", response_model=list[AlertDeliveryRead])
def get_safety_alert_deliveries(
    alert_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    alert = db.query(SafetyAlert).filter(SafetyAlert.id == alert_id).first()
    if not alert:
        raise HTTPException(status_code=404, detail="Safety alert not found")

    team = load_team_with_members(db, alert.team_id)
    membership = require_team_access(team, current_user)
    require_team_manager_for_audit(team, current_user, membership)

    deliveries = (
        db.query(AlertDelivery)
        .options(joinedload(AlertDelivery.recipient))
        .filter(AlertDelivery.safety_alert_id == alert_id)
        .order_by(AlertDelivery.created_at.asc(), AlertDelivery.id.asc())
        .all()
    )
    return deliveries


@router.get("/announcements/team/{team_id}", response_model=list[AnnouncementRead])
def get_team_announcements(
    team_id: int,
    limit: int | None = Query(default=None, ge=1),
    offset: int | None = Query(default=None, ge=0),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    limit, offset = normalize_pagination(limit=limit, offset=offset)
    team = load_team_with_members(db, team_id)
    require_team_access(team, current_user)

    announcements = (
        db.query(Announcement)
        .options(joinedload(Announcement.sender))
        .filter(Announcement.team_id == team_id)
        .order_by(Announcement.created_at.desc())
        .offset(offset)
        .limit(limit)
        .all()
    )
    visible = []
    for announcement in announcements:
        thread = _load_thread(db, announcement.thread_id)
        try:
            require_thread_access(thread, current_user, db)
            visible.append(announcement_to_read(announcement))
        except HTTPException:
            continue
    return visible


@router.post("/messages/parent-links", response_model=ParentLinkRead)
def create_parent_link(
    payload: ParentLinkCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    team = load_team_with_members(db, payload.team_id)
    membership = require_team_access(team, current_user)
    require_team_manager_for_audit(team, current_user, membership)

    parent_member = next((member for member in team.memberships if member.user_id == payload.parent_user_id), None)
    athlete_member = next((member for member in team.memberships if member.user_id == payload.athlete_user_id), None)
    if parent_member is None or athlete_member is None:
        raise HTTPException(status_code=400, detail="Parent and athlete must both belong to the team")
    if parent_member.user.role != UserRole.parent:
        raise HTTPException(status_code=400, detail="Parent link requires a parent account")
    if athlete_member.user.role != UserRole.athlete:
        raise HTTPException(status_code=400, detail="Parent link requires an athlete account")

    existing = (
        db.query(ParentLink)
        .filter(
            ParentLink.team_id == payload.team_id,
            ParentLink.parent_user_id == payload.parent_user_id,
            ParentLink.athlete_user_id == payload.athlete_user_id,
        )
        .first()
    )
    if existing:
        existing.is_active = True
        existing.relationship_label = payload.relationship_label.strip()
        existing.audit_version += 1
        link = existing
    else:
        link = ParentLink(
            team_id=payload.team_id,
            parent_user_id=payload.parent_user_id,
            athlete_user_id=payload.athlete_user_id,
            relationship_label=payload.relationship_label.strip(),
            visibility_flags={"compliance_required": True},
        )
        db.add(link)
        db.flush()

    log_action(
        db,
        team_id=payload.team_id,
        actor_id=current_user.id,
        action=AuditAction.parent_link_created,
        entity_type="parent_link",
        entity_id=link.id,
        after_state={
            "parent_user_id": link.parent_user_id,
            "athlete_user_id": link.athlete_user_id,
            "relationship_label": link.relationship_label,
        },
        visibility_flags=link.visibility_flags,
        compliance_note="Parent link created to satisfy minor messaging visibility",
        audit_version=link.audit_version,
    )
    db.commit()
    db.refresh(link)
    return link


@router.get("/messages/parent-links/team/{team_id}", response_model=list[ParentLinkRead])
def get_parent_links(
    team_id: int,
    limit: int | None = Query(default=None, ge=1),
    offset: int | None = Query(default=None, ge=0),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    limit, offset = normalize_pagination(limit=limit, offset=offset)
    team = load_team_with_members(db, team_id)
    membership = require_team_access(team, current_user)
    require_team_manager_for_audit(team, current_user, membership)
    return (
        db.query(ParentLink)
        .filter(ParentLink.team_id == team_id, ParentLink.is_active.is_(True))
        .order_by(ParentLink.created_at.asc())
        .offset(offset)
        .limit(limit)
        .all()
    )


@router.post("/messages/thread/create", response_model=MessageThreadDetail)
def create_message_thread(
    payload: ThreadCreateRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    team = load_team_with_members(db, payload.team_id)
    require_team_access(team, current_user)
    resolved_participants, flags = resolve_visible_participants(db, team, payload.participant_user_ids, current_user)

    if payload.thread_type == MessageThreadType.announcement:
        raise HTTPException(status_code=400, detail="Use the announcements endpoint for announcement threads")

    thread = MessageThread(
        team_id=team.id,
        title=payload.title.strip(),
        thread_type=payload.thread_type,
        created_by_user_id=current_user.id,
        parent_visibility_required=flags["has_athlete_participants"],
        is_compliance_locked=False,
        visibility_flags={
            **flags,
            "coach_to_minor_requires_visibility": True,
        },
        last_message_at=utcnow(),
    )
    db.add(thread)
    db.flush()

    for user, participant_type, reason in resolved_participants:
        thread.participants.append(
            MessageParticipant(
                thread_id=thread.id,
                team_id=team.id,
                user_id=user.id,
                participant_type=participant_type,
                visibility_flags={"auto_included_reason": reason} if reason else None,
            )
        )

    log_action(
        db,
        team_id=team.id,
        actor_id=current_user.id,
        action=AuditAction.thread_created,
        entity_type="thread",
        entity_id=thread.id,
        thread_id=thread.id,
        after_state={
            "title": thread.title,
            "thread_type": thread.thread_type.value,
            "participants": [
                {
                    "user_id": participant.user_id,
                    "participant_type": participant.participant_type.value,
                }
                for participant in thread.participants
            ],
        },
        visibility_flags=thread.visibility_flags,
        compliance_note="Thread created with automatic parent inclusion when athletes are present",
    )
    db.commit()
    thread = _load_thread(db, thread.id)
    return thread_to_detail(thread)


@router.post("/messages/send", response_model=MessageRead)
def send_message(
    payload: MessageSendRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    thread = _load_thread(db, payload.thread_id)
    require_thread_access(thread, current_user, db)
    require_thread_send_access(thread, current_user)
    ensure_thread_parent_visibility(db, thread)

    sender_participant = get_thread_participant(thread, current_user.id)
    message_visibility_flags = {
        **(thread.visibility_flags or {}),
        "sender_participant_type": None if sender_participant is None else sender_participant.participant_type.value,
    }
    risk_categories = detect_message_risk_categories(payload.body.strip()) if payload.message_type == MessageType.text else []
    if risk_categories:
        message_visibility_flags["content_risk_flags"] = risk_categories

    message = Message(
        thread_id=thread.id,
        team_id=thread.team_id,
        sender_id=current_user.id,
        body=payload.body.strip(),
        message_type=payload.message_type,
        visibility_flags=message_visibility_flags,
    )
    thread.last_message_at = utcnow()
    db.add(message)
    db.flush()

    if risk_categories:
        escalated = escalate_flagged_message(
            db,
            thread=thread,
            message=message,
            categories=risk_categories,
            sender=current_user,
        )
        alert = db.query(SafetyAlert).filter(SafetyAlert.source_message_id == message.id).first()
        message.visibility_flags = {
            **(message.visibility_flags or {}),
            "auto_escalated_to_parent_and_coaches": escalated,
            "severity": None if alert is None else alert.severity.value,
            "score": None if alert is None else alert.score,
        }

    log_action(
        db,
        team_id=thread.team_id,
        actor_id=current_user.id,
        action=AuditAction.message_sent,
        entity_type="message",
        entity_id=message.id,
        thread_id=thread.id,
        message_id=message.id,
        after_state={"body": message.body, "message_type": message.message_type.value},
        visibility_flags=message.visibility_flags,
        compliance_note="Message stored with immutable audit trail",
        audit_version=message.audit_version,
    )
    db.commit()
    message = (
        db.query(Message)
        .options(joinedload(Message.sender))
        .filter(Message.id == message.id)
        .first()
    )
    return message_to_read(message)


@router.post("/messages/{message_id}/edit", response_model=MessageRead)
def edit_message(
    message_id: int,
    payload: MessageEditRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    message = (
        db.query(Message)
        .options(
            joinedload(Message.sender),
            joinedload(Message.thread).joinedload(MessageThread.participants).joinedload(MessageParticipant.user),
        )
        .filter(Message.id == message_id)
        .first()
    )
    if not message:
        raise HTTPException(status_code=404, detail="Message not found")
    thread = message.thread
    require_thread_access(thread, current_user, db)
    team = load_team_with_members(db, thread.team_id)
    membership = require_team_access(team, current_user)
    require_message_editor(thread, message, current_user, membership)

    before_state = {"body": message.body, "audit_version": message.audit_version}
    message.body = payload.body.strip()
    message.audit_version += 1
    message.edited_at = utcnow()
    message.updated_at = utcnow()
    visibility_flags = dict(message.visibility_flags or {})
    risk_categories = detect_message_risk_categories(message.body) if message.message_type == MessageType.text else []
    if risk_categories:
        visibility_flags["content_risk_flags"] = risk_categories
        visibility_flags["auto_escalated_to_parent_and_coaches"] = escalate_flagged_message(
            db,
            thread=thread,
            message=message,
            categories=risk_categories,
            sender=current_user,
        )
        alert = db.query(SafetyAlert).filter(SafetyAlert.source_message_id == message.id).first()
        visibility_flags["severity"] = None if alert is None else alert.severity.value
        visibility_flags["score"] = None if alert is None else alert.score
    message.visibility_flags = visibility_flags

    log_action(
        db,
        team_id=thread.team_id,
        actor_id=current_user.id,
        action=AuditAction.message_edited,
        entity_type="message",
        entity_id=message.id,
        thread_id=thread.id,
        message_id=message.id,
        before_state=before_state,
        after_state={"body": message.body, "audit_version": message.audit_version},
        visibility_flags=message.visibility_flags,
        compliance_note="Message edit preserved previous version in audit log",
        audit_version=message.audit_version,
    )
    db.commit()
    db.refresh(message)
    return message_to_read(message)


@router.post("/messages/{message_id}/soft-delete", response_model=MessageRead)
def soft_delete_message(
    message_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    message = (
        db.query(Message)
        .options(
            joinedload(Message.sender),
            joinedload(Message.thread).joinedload(MessageThread.participants).joinedload(MessageParticipant.user),
        )
        .filter(Message.id == message_id)
        .first()
    )
    if not message:
        raise HTTPException(status_code=404, detail="Message not found")
    thread = message.thread
    require_thread_access(thread, current_user, db)
    team = load_team_with_members(db, thread.team_id)
    membership = require_team_access(team, current_user)
    require_message_editor(thread, message, current_user, membership)
    raise HTTPException(status_code=403, detail="Messages are immutable and cannot be deleted")


@router.get("/messages/thread/{thread_id}", response_model=MessageThreadDetail)
def get_message_thread(
    thread_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    thread = _load_thread(db, thread_id)
    require_thread_access(thread, current_user, db)
    ensure_thread_parent_visibility(db, thread)
    db.commit()
    thread = _load_thread(db, thread.id)
    return thread_to_detail(thread)


@router.get("/messages/user/{user_id}", response_model=list[MessageThreadSummary])
def get_user_threads(
    user_id: int,
    limit: int | None = Query(default=None, ge=1),
    offset: int | None = Query(default=None, ge=0),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    limit, offset = normalize_pagination(limit=limit, offset=offset)
    if current_user.role != UserRole.admin and current_user.id != user_id:
        linked = (
            db.query(ParentLink)
            .filter(
                ParentLink.parent_user_id == current_user.id,
                ParentLink.athlete_user_id == user_id,
                ParentLink.is_active.is_(True),
            )
            .first()
        )
        if linked is None:
            raise HTTPException(status_code=403, detail="Not authorized for this user inbox")

    participant_rows = (
        db.query(MessageThread.id)
        .join(MessageParticipant)
        .filter(
            MessageParticipant.user_id == user_id,
            MessageThread.is_deleted.is_(False),
        )
        .all()
    )
    thread_ids = [row[0] for row in participant_rows]
    threads = (
        db.query(MessageThread)
        .options(
            joinedload(MessageThread.participants).joinedload(MessageParticipant.user),
            joinedload(MessageThread.messages).joinedload(Message.sender),
        )
        .filter(MessageThread.id.in_(thread_ids))
        .order_by(MessageThread.last_message_at.desc())
        .offset(offset)
        .limit(limit)
        .all()
    )

    visible_threads = []
    for thread in threads:
        try:
            require_thread_access(thread, current_user, db)
            visible_threads.append(thread_to_summary(thread))
        except HTTPException:
            continue
    return visible_threads


@router.get("/messages/audit/{team_id}", response_model=list[MessageAuditLogRead])
def get_team_message_audit(
    team_id: int,
    limit: int | None = Query(default=None, ge=1),
    offset: int | None = Query(default=None, ge=0),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    limit, offset = normalize_pagination(limit=limit, offset=offset)
    team = load_team_with_members(db, team_id)
    membership = require_team_access(team, current_user)
    require_team_manager_for_audit(team, current_user, membership)

    logs = (
        db.query(MessageAuditLog)
        .options(joinedload(MessageAuditLog.actor))
        .filter(MessageAuditLog.team_id == team_id)
        .order_by(MessageAuditLog.created_at.desc())
        .offset(offset)
        .limit(limit)
        .all()
    )
    return [audit_to_read(log) for log in logs]


@router.get("/messages/safety-alerts/team/{team_id}", response_model=list[SafetyAlertRead])
def get_team_safety_alerts(
    team_id: int,
    severity: SafetyAlertSeverity | None = Query(default=None),
    status: SafetyAlertStatus | None = Query(default=None),
    category: str | None = Query(default=None),
    limit: int | None = Query(default=None, ge=1),
    offset: int | None = Query(default=None, ge=0),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    limit, offset = normalize_pagination(limit=limit, offset=offset)
    team = load_team_with_members(db, team_id)
    membership = require_team_access(team, current_user)
    require_team_manager_for_audit(team, current_user, membership)

    alerts = (
        db.query(SafetyAlert)
        .options(
            joinedload(SafetyAlert.source_sender),
            joinedload(SafetyAlert.acknowledged_by),
        )
        .filter(SafetyAlert.team_id == team_id)
        .order_by(SafetyAlert.created_at.desc())
        .all()
    )
    if severity is not None:
        alerts = [alert for alert in alerts if alert.severity == severity]
    if status is not None:
        alerts = [alert for alert in alerts if alert.status == status]
    if category:
        normalized_category = category.strip().casefold()
        alerts = [
            alert
            for alert in alerts
            if any(item.casefold() == normalized_category for item in (alert.categories or []))
        ]
    return [safety_alert_to_read(alert) for alert in alerts[offset : offset + limit]]


@router.post("/messages/safety-alerts/{alert_id}/acknowledge", response_model=SafetyAlertAcknowledgeResponse)
def acknowledge_safety_alert(
    alert_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    alert = (
        db.query(SafetyAlert)
        .options(
            joinedload(SafetyAlert.source_sender),
            joinedload(SafetyAlert.acknowledged_by),
        )
        .filter(SafetyAlert.id == alert_id)
        .first()
    )
    if not alert:
        raise HTTPException(status_code=404, detail="Safety alert not found")

    team = load_team_with_members(db, alert.team_id)
    membership = require_team_access(team, current_user)
    require_team_manager_for_audit(team, current_user, membership)

    alert.status = SafetyAlertStatus.acknowledged
    alert.acknowledged_by_user_id = current_user.id
    alert.acknowledged_at = utcnow()
    alert.updated_at = utcnow()
    db.commit()

    alert = (
        db.query(SafetyAlert)
        .options(
            joinedload(SafetyAlert.source_sender),
            joinedload(SafetyAlert.acknowledged_by),
        )
        .filter(SafetyAlert.id == alert_id)
        .first()
    )
    return {"alert": safety_alert_to_read(alert)}


@router.get("/messages/export/{thread_id}", response_model=MessageExportResponse)
def export_thread(
    thread_id: int,
    format: str = Query(default="json", pattern="^(json|csv)$"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    thread = _load_thread(db, thread_id)
    require_thread_access(thread, current_user, db)

    logs = (
        db.query(MessageAuditLog)
        .options(joinedload(MessageAuditLog.actor))
        .filter(MessageAuditLog.thread_id == thread_id)
        .order_by(MessageAuditLog.created_at.asc())
        .all()
    )

    log_action(
        db,
        team_id=thread.team_id,
        actor_id=current_user.id,
        action=AuditAction.thread_exported,
        entity_type="thread",
        entity_id=thread.id,
        thread_id=thread.id,
        visibility_flags={"format": format},
        compliance_note="Thread exported for compliance review",
    )
    db.commit()

    if format == "csv":
        buffer = io.StringIO()
        writer = csv.writer(buffer)
        writer.writerow(["thread_id", "thread_title", "message_id", "sender", "message_type", "body", "created_at", "edited_at", "deleted_at"])
        for message in sorted(thread.messages, key=lambda item: item.created_at):
            writer.writerow(
                [
                    thread.id,
                    thread.title,
                    message.id,
                    message.sender.full_name,
                    message.message_type.value,
                    message.body,
                    message.created_at.isoformat(),
                    message.edited_at.isoformat() if message.edited_at else "",
                    message.deleted_at.isoformat() if message.deleted_at else "",
                ]
            )
        return PlainTextResponse(
            buffer.getvalue(),
            media_type="text/csv",
            headers={"Content-Disposition": f'attachment; filename="thread-{thread.id}-export.csv"'},
        )

    refreshed_thread = _load_thread(db, thread_id)
    refreshed_logs = (
        db.query(MessageAuditLog)
        .options(joinedload(MessageAuditLog.actor))
        .filter(MessageAuditLog.thread_id == thread_id)
        .order_by(MessageAuditLog.created_at.asc())
        .all()
    )
    return {
        "exported_at": datetime.utcnow(),
        "thread": thread_to_detail(refreshed_thread),
        "audit_logs": [audit_to_read(log) for log in refreshed_logs],
    }
