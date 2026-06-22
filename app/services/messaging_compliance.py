from __future__ import annotations

import re
from datetime import datetime, timedelta

from fastapi import HTTPException
from sqlalchemy.orm import Session, joinedload

from app.models.messaging import (
    Announcement,
    AlertDelivery,
    AuditAction,
    Message,
    MessageAuditLog,
    MessageParticipant,
    MessageParticipantType,
    MessageThread,
    MessageThreadType,
    MessageType,
    ParentLink,
    SafetyAlert,
    SafetyAlertSeverity,
    SafetyAlertStatus,
)
from app.models.team import Team, TeamMember, TeamMemberStatus
from app.models.user import User, UserRole
from app.services.alert_delivery import deliver_alert_bundle
from app.services.permissions import can_manage_team
from app.services.sms_alerts import render_team_text_message


RISK_RULES: dict[str, dict[str, object]] = {
    "sexual": {
        "weight": 4,
        "keywords": (
        "nude",
        "naked",
        "sex",
        "sext",
        "hook up",
        "hookup",
        "oral",
        "porn",
        "nsfw",
        ),
    },
    "drugs": {
        "weight": 3,
        "keywords": (
        "weed",
        "vape",
        "edible",
        "joint",
        "cocaine",
        "xanax",
        "perc",
        "pill",
        "drunk",
        "vodka",
        "beer",
        ),
    },
    "crime": {
        "weight": 3,
        "keywords": (
        "steal",
        "stole",
        "rob",
        "fight",
        "jump him",
        "jump her",
        "gun",
        "knife",
        "fake id",
        "shoplift",
        "crime",
        ),
    },
    "self_harm": {
        "weight": 5,
        "keywords": (
            "kill myself",
            "hurt myself",
            "suicide",
            "end it all",
            "self harm",
        ),
    },
    "bullying": {
        "weight": 2,
        "keywords": (
            "loser",
            "hate you",
            "go die",
            "humiliate",
            "embarrass him",
            "embarrass her",
        ),
    },
    "meetup_risk": {
        "weight": 2,
        "keywords": (
            "don't tell your parents",
            "meet me alone",
            "come alone",
            "secret meetup",
            "skip practice and meet",
        ),
    },
}


def utcnow() -> datetime:
    return datetime.utcnow()


def load_team_with_members(db: Session, team_id: int) -> Team:
    team = (
        db.query(Team)
        .options(joinedload(Team.memberships).joinedload(TeamMember.user))
        .filter(Team.id == team_id)
        .first()
    )
    if not team:
        raise HTTPException(status_code=404, detail="Team not found")
    return team


def require_team_access(team: Team, current_user: User) -> TeamMember | None:
    membership = next((member for member in team.memberships if member.user_id == current_user.id), None)
    if current_user.role != UserRole.admin and membership is None:
        raise HTTPException(status_code=403, detail="Not authorized for this team")
    return membership


def require_thread_access(thread: MessageThread, current_user: User, db: Session) -> None:
    participant_user_ids = {participant.user_id for participant in thread.participants}
    if current_user.role == UserRole.admin or current_user.id in participant_user_ids:
        return

    membership = (
        db.query(TeamMember)
        .filter(
            TeamMember.team_id == thread.team_id,
            TeamMember.user_id == current_user.id,
            TeamMember.status == TeamMemberStatus.approved,
        )
        .first()
    )
    if membership is not None and current_user.role in {UserRole.coach, UserRole.assistant_coach}:
        return

    athlete_ids = {
        participant.user_id
        for participant in thread.participants
        if participant.user.role == UserRole.athlete
    }
    if not athlete_ids:
        raise HTTPException(status_code=403, detail="Not authorized for this thread")

    linked = (
        db.query(ParentLink)
        .filter(
            ParentLink.team_id == thread.team_id,
            ParentLink.parent_user_id == current_user.id,
            ParentLink.athlete_user_id.in_(athlete_ids),
            ParentLink.is_active.is_(True),
        )
        .first()
    )
    if linked is None:
        raise HTTPException(status_code=403, detail="Not authorized for this thread")


def get_thread_participant(thread: MessageThread, user_id: int) -> MessageParticipant | None:
    return next((participant for participant in thread.participants if participant.user_id == user_id), None)


def require_thread_send_access(thread: MessageThread, current_user: User) -> None:
    if current_user.role == UserRole.admin:
        return

    participant = get_thread_participant(thread, current_user.id)
    if participant is None:
        raise HTTPException(status_code=403, detail="Not authorized to send messages in this thread")

    if participant.participant_type == MessageParticipantType.parent_visibility:
        raise HTTPException(
            status_code=403,
            detail="Parent visibility participants can view this thread but cannot send messages",
        )


def require_team_manager_for_audit(team: Team, current_user: User, membership: TeamMember | None) -> None:
    if not can_manage_team(current_user, membership) and current_user.role != UserRole.admin:
        raise HTTPException(status_code=403, detail="Only staff can view compliance logs")


def require_message_editor(thread: MessageThread, message: Message, current_user: User, membership: TeamMember | None) -> None:
    if current_user.role == UserRole.admin or message.sender_id == current_user.id:
        return
    if can_manage_team(current_user, membership):
        return
    raise HTTPException(status_code=403, detail="Not authorized to modify this message")


def approved_member_map(team: Team) -> dict[int, TeamMember]:
    return {
        member.user_id: member
        for member in team.memberships
        if member.status == TeamMemberStatus.approved
    }


def resolve_visible_participants(
    db: Session,
    team: Team,
    requested_user_ids: list[int],
    sender: User,
) -> tuple[list[tuple[User, MessageParticipantType, str | None]], dict]:
    approved_members = approved_member_map(team)
    if sender.id not in approved_members and sender.role != UserRole.admin:
        raise HTTPException(status_code=403, detail="Only approved team members can start threads")

    unique_ids = list(dict.fromkeys([*requested_user_ids, sender.id]))
    users = db.query(User).filter(User.id.in_(unique_ids)).all()
    user_map = {user.id: user for user in users}

    missing_ids = [user_id for user_id in unique_ids if user_id not in user_map]
    if missing_ids:
        raise HTTPException(status_code=404, detail=f"Unknown user ids: {missing_ids}")

    for user_id in unique_ids:
        user = user_map[user_id]
        if user.role != UserRole.admin and user_id not in approved_members:
            raise HTTPException(status_code=400, detail=f"{user.full_name} is not an approved member of this team")

    participant_specs: dict[int, tuple[User, MessageParticipantType, str | None]] = {
        user_id: (user_map[user_id], MessageParticipantType.member, None) for user_id in unique_ids
    }

    athlete_ids = [user_id for user_id in unique_ids if user_map[user_id].role == UserRole.athlete]
    auto_parent_links = []
    if athlete_ids:
        parent_links = (
            db.query(ParentLink)
            .options(joinedload(ParentLink.parent_user), joinedload(ParentLink.athlete_user))
            .filter(
                ParentLink.team_id == team.id,
                ParentLink.athlete_user_id.in_(athlete_ids),
                ParentLink.is_active.is_(True),
            )
            .all()
        )
        links_by_athlete: dict[int, list[ParentLink]] = {}
        for link in parent_links:
            links_by_athlete.setdefault(link.athlete_user_id, []).append(link)

        missing_parent_athletes = [user_map[user_id].full_name for user_id in athlete_ids if not links_by_athlete.get(user_id)]
        if missing_parent_athletes:
            raise HTTPException(
                status_code=400,
                detail=f"Parent visibility is required before messaging athletes: {', '.join(missing_parent_athletes)}",
            )

        for athlete_id in athlete_ids:
            for link in links_by_athlete[athlete_id]:
                participant_specs[link.parent_user_id] = (
                    link.parent_user,
                    MessageParticipantType.parent_visibility,
                    f"auto-added for athlete {link.athlete_user.full_name}",
                )
                auto_parent_links.append(
                    {
                        "athlete_user_id": athlete_id,
                        "parent_user_id": link.parent_user_id,
                        "relationship_label": link.relationship_label,
                    }
                )

    flags = {
        "has_athlete_participants": bool(athlete_ids),
        "auto_included_parent_links": auto_parent_links,
        "requested_user_ids": requested_user_ids,
        "resolved_user_ids": list(participant_specs.keys()),
    }
    return list(participant_specs.values()), flags


def ensure_thread_parent_visibility(db: Session, thread: MessageThread) -> None:
    participant_user_ids = {participant.user_id for participant in thread.participants}
    athlete_ids = [participant.user_id for participant in thread.participants if participant.user.role == UserRole.athlete]
    if not athlete_ids:
        return

    parent_links = (
        db.query(ParentLink)
        .options(joinedload(ParentLink.parent_user), joinedload(ParentLink.athlete_user))
        .filter(
            ParentLink.team_id == thread.team_id,
            ParentLink.athlete_user_id.in_(athlete_ids),
            ParentLink.is_active.is_(True),
        )
        .all()
    )
    links_by_athlete: dict[int, list[ParentLink]] = {}
    for link in parent_links:
        links_by_athlete.setdefault(link.athlete_user_id, []).append(link)

    missing_parent_athletes = [str(athlete_id) for athlete_id in athlete_ids if not links_by_athlete.get(athlete_id)]
    if missing_parent_athletes:
        raise HTTPException(
            status_code=400,
            detail="Thread is not compliant because one or more athletes no longer have active parent links",
        )

    for athlete_id in athlete_ids:
        for link in links_by_athlete[athlete_id]:
            if link.parent_user_id in participant_user_ids:
                continue
            participant = MessageParticipant(
                thread_id=thread.id,
                team_id=thread.team_id,
                user_id=link.parent_user_id,
                participant_type=MessageParticipantType.parent_visibility,
                visibility_flags={
                    "auto_included_reason": f"auto-added for athlete {link.athlete_user.full_name}",
                    "relationship_label": link.relationship_label,
                },
            )
            db.add(participant)
            thread.participants.append(participant)
            participant_user_ids.add(link.parent_user_id)

    thread.parent_visibility_required = True
    visibility_flags = dict(thread.visibility_flags or {})
    visibility_flags["parent_visibility_enforced"] = True
    visibility_flags["participant_count"] = len(participant_user_ids)
    thread.visibility_flags = visibility_flags


def detect_message_risk_categories(body: str) -> list[str]:
    normalized = body.casefold()
    categories: list[str] = []

    for category, rule in RISK_RULES.items():
        keywords = rule["keywords"]
        if any(re.search(rf"\b{re.escape(keyword)}\b", normalized) for keyword in keywords):
            categories.append(category)

    return categories


def score_risk_categories(categories: list[str]) -> int:
    return sum(int(RISK_RULES[category]["weight"]) for category in categories)


def severity_for_score(score: int) -> SafetyAlertSeverity:
    if score >= 8:
        return SafetyAlertSeverity.urgent
    if score >= 4:
        return SafetyAlertSeverity.concern
    return SafetyAlertSeverity.info


def _team_staff_recipients(db: Session, thread: MessageThread) -> list[User]:
    memberships = (
        db.query(TeamMember)
        .options(joinedload(TeamMember.user))
        .filter(
            TeamMember.team_id == thread.team_id,
            TeamMember.status == TeamMemberStatus.approved,
        )
        .all()
    )
    return [
        membership.user
        for membership in memberships
        if membership.user.role in {UserRole.coach, UserRole.assistant_coach}
    ]


def _thread_linked_parent_recipients(db: Session, thread: MessageThread) -> list[User]:
    athlete_ids = [
        participant.user_id
        for participant in thread.participants
        if participant.user.role == UserRole.athlete
    ]
    if not athlete_ids:
        return []

    parent_links = (
        db.query(ParentLink)
        .options(joinedload(ParentLink.parent_user))
        .filter(
            ParentLink.team_id == thread.team_id,
            ParentLink.athlete_user_id.in_(athlete_ids),
            ParentLink.is_active.is_(True),
        )
        .all()
    )
    unique_parent_users: dict[int, User] = {}
    for link in parent_links:
        unique_parent_users[link.parent_user_id] = link.parent_user
    return list(unique_parent_users.values())


def _thread_athlete_ids(thread: MessageThread) -> list[int]:
    return [
        participant.user_id
        for participant in thread.participants
        if participant.user.role == UserRole.athlete
    ]


def _recent_sender_alert_count(db: Session, *, team_id: int, source_sender_id: int) -> int:
    since = utcnow() - timedelta(days=30)
    return (
        db.query(SafetyAlert)
        .filter(
            SafetyAlert.team_id == team_id,
            SafetyAlert.source_sender_id == source_sender_id,
            SafetyAlert.created_at >= since,
        )
        .count()
    )


def escalate_flagged_message(
    db: Session,
    *,
    thread: MessageThread,
    message: Message,
    categories: list[str],
    sender: User,
) -> bool:
    existing_alert = (
        db.query(SafetyAlert)
        .filter(SafetyAlert.source_message_id == message.id)
        .first()
    )

    parent_recipients = _thread_linked_parent_recipients(db, thread)
    if not parent_recipients:
        return False

    coach_recipients = _team_staff_recipients(db, thread)
    recipient_users: dict[int, User] = {user.id: user for user in [*coach_recipients, *parent_recipients]}
    if not recipient_users:
        return False

    athlete_ids = _thread_athlete_ids(thread)
    repeat_count = _recent_sender_alert_count(
        db,
        team_id=thread.team_id,
        source_sender_id=sender.id,
    )
    score = score_risk_categories(categories) + min(repeat_count, 3)
    severity = severity_for_score(score)
    summary = (
        f"{severity.value.title()} safety alert for {sender.full_name}: "
        f"{', '.join(category.replace('_', ' ') for category in categories)}"
    )
    excerpt = message.body[:500]

    common_flags = {
        "compliance_alert": True,
        "source_thread_id": thread.id,
        "source_message_id": message.id,
        "source_sender_id": sender.id,
        "detected_categories": categories,
        "severity": severity.value,
        "score": score,
        "repeat_trigger_count": repeat_count,
    }

    if existing_alert is not None:
        existing_alert.severity = severity
        existing_alert.status = SafetyAlertStatus.open
        existing_alert.score = score
        existing_alert.categories = categories
        existing_alert.repeated_trigger_count = repeat_count
        existing_alert.subject_athlete_ids = athlete_ids
        existing_alert.summary = summary
        existing_alert.source_excerpt = excerpt
        existing_alert.alert_metadata = {
            "recipient_count": len(recipient_users),
            "source_title": thread.title,
        }
        existing_alert.acknowledged_by_user_id = None
        existing_alert.acknowledged_at = None
        existing_alert.updated_at = utcnow()
        existing_alert.alert_thread.visibility_flags = {
            **(existing_alert.alert_thread.visibility_flags or {}),
            **common_flags,
        }
        if severity == SafetyAlertSeverity.urgent:
            existing_delivery = (
                db.query(AlertDelivery)
                .filter(AlertDelivery.safety_alert_id == existing_alert.id)
                .first()
            )
            if existing_delivery is None:
                dispatch_summary = deliver_alert_bundle(
                    db,
                    team_id=thread.team_id,
                    users=list(recipient_users.values()),
                    announcement_id=None,
                    safety_alert_id=existing_alert.id,
                    message_title=f"Urgent safety alert: {thread.title}",
                    message_body=render_team_text_message(
                        team_name="Pin IQ Safety",
                        title=f"Urgent alert for {thread.title}",
                        body=summary,
                    ),
                    push_title="Urgent safety alert",
                    push_body=summary,
                    push_data={"safety_alert_id": existing_alert.id, "team_id": thread.team_id},
                )
                existing_alert.alert_metadata = {
                    **(existing_alert.alert_metadata or {}),
                    "notification_summary": dispatch_summary.as_dict(),
                }
        return True

    alert_thread = MessageThread(
        team_id=thread.team_id,
        title=f"Safety Alert: {thread.title}",
        thread_type=MessageThreadType.group,
        created_by_user_id=sender.id,
        parent_visibility_required=False,
        is_compliance_locked=True,
        visibility_flags=common_flags,
        last_message_at=utcnow(),
    )
    db.add(alert_thread)
    db.flush()

    for recipient in recipient_users.values():
        alert_thread.participants.append(
            MessageParticipant(
                thread_id=alert_thread.id,
                team_id=thread.team_id,
                user_id=recipient.id,
                participant_type=MessageParticipantType.member,
                visibility_flags={"compliance_alert_recipient": True},
            )
        )

    alert_body = (
        f"Potential safety concern detected in \"{thread.title}\". "
        f"Severity: {severity.value}. "
        f"Categories: {', '.join(categories)}. "
        f"Sender: {sender.full_name}. "
        f"Original message: {message.body}"
    )
    alert_message = Message(
        thread_id=alert_thread.id,
        team_id=thread.team_id,
        sender_id=sender.id,
        body=alert_body,
        message_type=MessageType.compliance_note,
        visibility_flags=alert_thread.visibility_flags,
    )
    db.add(alert_message)
    db.flush()

    safety_alert = SafetyAlert(
        team_id=thread.team_id,
        source_thread_id=thread.id,
        source_message_id=message.id,
        alert_thread_id=alert_thread.id,
        source_sender_id=sender.id,
        severity=severity,
        status=SafetyAlertStatus.open,
        score=score,
        categories=categories,
        repeated_trigger_count=repeat_count,
        subject_athlete_ids=athlete_ids,
        summary=summary,
        source_excerpt=excerpt,
        alert_metadata={
            "recipient_count": len(recipient_users),
            "source_title": thread.title,
        },
    )
    db.add(safety_alert)
    db.flush()

    if severity == SafetyAlertSeverity.urgent:
        dispatch_summary = deliver_alert_bundle(
            db,
            team_id=thread.team_id,
            users=list(recipient_users.values()),
            announcement_id=None,
            safety_alert_id=safety_alert.id,
            message_title=f"Urgent safety alert: {thread.title}",
            message_body=render_team_text_message(
                team_name="Pin IQ Safety",
                title=f"Urgent alert for {thread.title}",
                body=summary,
            ),
            push_title="Urgent safety alert",
            push_body=summary,
            push_data={"safety_alert_id": safety_alert.id, "team_id": thread.team_id},
        )
        safety_alert.alert_metadata = {
            **(safety_alert.alert_metadata or {}),
            "notification_summary": dispatch_summary.as_dict(),
        }

    log_action(
        db,
        team_id=thread.team_id,
        actor_id=sender.id,
        action=AuditAction.thread_created,
        entity_type="thread",
        entity_id=alert_thread.id,
        thread_id=alert_thread.id,
        after_state={
            "title": alert_thread.title,
            "thread_type": alert_thread.thread_type.value,
            "participant_count": len(alert_thread.participants),
        },
        visibility_flags=alert_thread.visibility_flags,
        compliance_note="Compliance alert thread auto-created for flagged message",
    )
    log_action(
        db,
        team_id=thread.team_id,
        actor_id=sender.id,
        action=AuditAction.message_sent,
        entity_type="message",
        entity_id=alert_message.id,
        thread_id=alert_thread.id,
        message_id=alert_message.id,
        after_state={
            "body": alert_message.body,
            "message_type": alert_message.message_type.value,
        },
        visibility_flags=alert_message.visibility_flags,
        compliance_note="Flagged message escalated to linked parents and team staff",
        audit_version=alert_message.audit_version,
    )
    return True


def log_action(
    db: Session,
    *,
    team_id: int,
    actor_id: int,
    action: AuditAction,
    entity_type: str,
    entity_id: int,
    thread_id: int | None = None,
    message_id: int | None = None,
    announcement_id: int | None = None,
    before_state: dict | None = None,
    after_state: dict | None = None,
    visibility_flags: dict | None = None,
    compliance_note: str | None = None,
    audit_version: int = 1,
) -> None:
    db.add(
        MessageAuditLog(
            team_id=team_id,
            actor_id=actor_id,
            action=action,
            entity_type=entity_type,
            entity_id=entity_id,
            thread_id=thread_id,
            message_id=message_id,
            announcement_id=announcement_id,
            before_state=before_state,
            after_state=after_state,
            visibility_flags=visibility_flags,
            compliance_note=compliance_note,
            audit_version=audit_version,
        )
    )


def thread_to_summary(thread: MessageThread) -> dict:
    ordered_messages = sorted(thread.messages, key=lambda item: item.created_at)
    last_message = ordered_messages[-1] if ordered_messages else None
    return {
        "id": thread.id,
        "team_id": thread.team_id,
        "title": thread.title,
        "thread_type": thread.thread_type,
        "parent_visibility_required": thread.parent_visibility_required,
        "is_compliance_locked": thread.is_compliance_locked,
        "visibility_flags": thread.visibility_flags,
        "audit_version": thread.audit_version,
        "last_message_at": thread.last_message_at,
        "created_at": thread.created_at,
        "participants": [participant_to_read(participant) for participant in thread.participants],
        "last_message_preview": None if last_message is None else last_message.body[:120],
    }


def thread_to_detail(thread: MessageThread) -> dict:
    summary = thread_to_summary(thread)
    summary["messages"] = [message_to_read(message) for message in sorted(thread.messages, key=lambda item: item.created_at)]
    return summary


def participant_to_read(participant: MessageParticipant) -> dict:
    return {
        "id": participant.id,
        "team_id": participant.team_id,
        "user_id": participant.user_id,
        "participant_type": participant.participant_type,
        "visibility_flags": participant.visibility_flags,
        "created_at": participant.created_at,
        "user": participant.user,
    }


def message_to_read(message: Message) -> dict:
    return {
        "id": message.id,
        "thread_id": message.thread_id,
        "team_id": message.team_id,
        "sender_id": message.sender_id,
        "body": message.body,
        "message_type": message.message_type,
        "visibility_flags": message.visibility_flags,
        "audit_version": message.audit_version,
        "created_at": message.created_at,
        "updated_at": message.updated_at,
        "edited_at": message.edited_at,
        "deleted_at": message.deleted_at,
        "sender": message.sender,
    }


def announcement_to_read(announcement: Announcement) -> dict:
    return {
        "id": announcement.id,
        "thread_id": announcement.thread_id,
        "team_id": announcement.team_id,
        "sender_id": announcement.sender_id,
        "title": announcement.title,
        "body": announcement.body,
        "audience_label": announcement.audience_label,
        "visibility_flags": announcement.visibility_flags,
        "audit_version": announcement.audit_version,
        "created_at": announcement.created_at,
        "sender": announcement.sender,
    }


def audit_to_read(log: MessageAuditLog) -> dict:
    return {
        "id": log.id,
        "team_id": log.team_id,
        "thread_id": log.thread_id,
        "message_id": log.message_id,
        "announcement_id": log.announcement_id,
        "actor_id": log.actor_id,
        "action": log.action,
        "entity_type": log.entity_type,
        "entity_id": log.entity_id,
        "before_state": log.before_state,
        "after_state": log.after_state,
        "visibility_flags": log.visibility_flags,
        "compliance_note": log.compliance_note,
        "audit_version": log.audit_version,
        "created_at": log.created_at,
        "actor": log.actor,
    }


def safety_alert_to_read(alert: SafetyAlert) -> dict:
    return {
        "id": alert.id,
        "team_id": alert.team_id,
        "source_thread_id": alert.source_thread_id,
        "source_message_id": alert.source_message_id,
        "alert_thread_id": alert.alert_thread_id,
        "source_sender_id": alert.source_sender_id,
        "severity": alert.severity,
        "status": alert.status,
        "score": alert.score,
        "categories": alert.categories,
        "repeated_trigger_count": alert.repeated_trigger_count,
        "subject_athlete_ids": alert.subject_athlete_ids,
        "summary": alert.summary,
        "source_excerpt": alert.source_excerpt,
        "metadata": alert.alert_metadata,
        "acknowledged_at": alert.acknowledged_at,
        "created_at": alert.created_at,
        "updated_at": alert.updated_at,
        "source_sender": alert.source_sender,
        "acknowledged_by": alert.acknowledged_by,
    }
