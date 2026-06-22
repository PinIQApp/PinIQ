from __future__ import annotations

from datetime import datetime, timedelta, timezone

from fastapi import HTTPException
from sqlalchemy.orm import Session, joinedload

from app.models.messaging import ParentLink
from app.models.schedule import Event, EventType, PracticeBlock, PracticePlan, PracticeTemplate, PracticeTemplateBlock
from app.models.team import Team, TeamMember, TeamMemberStatus
from app.models.user import User, UserRole
from app.schemas.schedule import (
    EventCreate,
    EventUpdate,
    PracticeAssignToDateRequest,
    PracticeBlockCreate,
    PracticeDuplicateRequest,
    PracticePlanCreate,
    PracticePlanSummaryRead,
    PracticePlanUpdate,
    PracticeTemplateCreate,
    ScheduleSummaryRead,
)
from app.services.permissions import require_team_manager


def _utcnow() -> datetime:
    return datetime.now(timezone.utc).replace(tzinfo=None)


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


def approved_membership(team: Team, user_id: int) -> TeamMember | None:
    return next(
        (
            member
            for member in team.memberships
            if member.user_id == user_id and member.status == TeamMemberStatus.approved
        ),
        None,
    )


def require_schedule_viewer(db: Session, *, team: Team, current_user: User) -> str:
    membership = approved_membership(team, current_user.id)
    if current_user.role == UserRole.admin:
        return "admin"
    if membership:
        if current_user.role in {UserRole.coach, UserRole.assistant_coach}:
            return "staff"
        if current_user.role == UserRole.athlete:
            return "athlete"
        if current_user.role == UserRole.parent:
            return "parent"
    if current_user.role == UserRole.parent:
        has_link = (
            db.query(ParentLink)
            .filter(
                ParentLink.team_id == team.id,
                ParentLink.parent_user_id == current_user.id,
                ParentLink.is_active.is_(True),
            )
            .first()
            is not None
        )
        if has_link:
            return "linked_parent"
    raise HTTPException(status_code=403, detail="Not authorized to view this team schedule")


def require_schedule_manager(db: Session, *, team: Team, current_user: User) -> TeamMember | None:
    membership = approved_membership(team, current_user.id)
    require_team_manager(current_user, team, membership)
    return membership


def validate_time_range(starts_at: datetime, ends_at: datetime) -> None:
    if ends_at <= starts_at:
        raise HTTPException(status_code=400, detail="End time must be after start time")


def calculate_total_minutes(blocks: list[PracticeBlockCreate]) -> int:
    return sum(block.duration_minutes for block in blocks)


def _sync_practice_blocks(practice: PracticePlan, blocks: list[PracticeBlockCreate]) -> None:
    practice.blocks.clear()
    ordered_blocks = sorted(blocks, key=lambda block: block.block_order)
    for block in ordered_blocks:
        practice.blocks.append(
            PracticeBlock(
                block_order=block.block_order,
                block_type=block.block_type,
                title=block.title,
                notes=block.notes,
                duration_minutes=block.duration_minutes,
            )
        )
    practice.total_duration_minutes = calculate_total_minutes(ordered_blocks)


def _sync_template_blocks(template: PracticeTemplate, blocks: list[PracticeBlockCreate]) -> None:
    template.blocks.clear()
    ordered_blocks = sorted(blocks, key=lambda block: block.block_order)
    for block in ordered_blocks:
        template.blocks.append(
            PracticeTemplateBlock(
                block_order=block.block_order,
                block_type=block.block_type,
                title=block.title,
                notes=block.notes,
                duration_minutes=block.duration_minutes,
            )
        )
    template.total_duration_minutes = calculate_total_minutes(ordered_blocks)


def _load_template(db: Session, *, template_id: int, team_id: int) -> PracticeTemplate:
    template = (
        db.query(PracticeTemplate)
        .options(joinedload(PracticeTemplate.blocks))
        .filter(PracticeTemplate.id == template_id, PracticeTemplate.team_id == team_id)
        .first()
    )
    if not template:
        raise HTTPException(status_code=404, detail="Practice template not found")
    return template


def _template_blocks_as_create(template: PracticeTemplate) -> list[PracticeBlockCreate]:
    return [
        PracticeBlockCreate(
            block_order=block.block_order,
            block_type=block.block_type,
            title=block.title,
            notes=block.notes,
            duration_minutes=block.duration_minutes,
        )
        for block in template.blocks
    ]


def create_practice_plan(db: Session, *, payload: PracticePlanCreate, current_user: User) -> PracticePlan:
    team = load_team_with_members(db, payload.team_id)
    require_schedule_manager(db, team=team, current_user=current_user)

    practice = PracticePlan(
        team_id=payload.team_id,
        created_by_user_id=current_user.id,
        title=payload.title,
        description=payload.description,
        focus=payload.focus,
        practice_date=payload.practice_date,
        notes=payload.notes,
    )

    if payload.template_id is not None:
        template = _load_template(db, template_id=payload.template_id, team_id=payload.team_id)
        practice.template_id = template.id
        practice.template_name_snapshot = template.template_name
        practice.is_template_based = True
        if not payload.blocks:
            _sync_practice_blocks(practice, _template_blocks_as_create(template))

    if payload.blocks:
        _sync_practice_blocks(practice, payload.blocks)
    elif not practice.blocks:
        practice.total_duration_minutes = 0

    db.add(practice)
    db.flush()
    db.refresh(practice)
    return load_practice(db, practice.id, current_user=current_user)


def update_practice_plan(db: Session, *, practice_id: int, payload: PracticePlanUpdate, current_user: User) -> PracticePlan:
    practice = load_practice(db, practice_id, current_user=current_user, require_manage=True)
    if payload.title is not None:
        practice.title = payload.title
    if payload.description is not None:
        practice.description = payload.description
    if payload.focus is not None:
        practice.focus = payload.focus
    if payload.practice_date is not None:
        practice.practice_date = payload.practice_date
    if payload.notes is not None:
        practice.notes = payload.notes
    if payload.template_id is not None:
        template = _load_template(db, template_id=payload.template_id, team_id=practice.team_id)
        practice.template_id = template.id
        practice.template_name_snapshot = template.template_name
        practice.is_template_based = True
    if payload.blocks is not None:
        _sync_practice_blocks(practice, payload.blocks)
    db.flush()
    db.refresh(practice)
    return load_practice(db, practice.id, current_user=current_user)


def load_practice(
    db: Session,
    practice_id: int,
    *,
    current_user: User,
    require_manage: bool = False,
) -> PracticePlan:
    practice = (
        db.query(PracticePlan)
        .options(joinedload(PracticePlan.blocks), joinedload(PracticePlan.event))
        .filter(PracticePlan.id == practice_id)
        .first()
    )
    if not practice:
        raise HTTPException(status_code=404, detail="Practice not found")
    team = load_team_with_members(db, practice.team_id)
    if require_manage:
        require_schedule_manager(db, team=team, current_user=current_user)
    else:
        require_schedule_viewer(db, team=team, current_user=current_user)
    return practice


def list_practices_for_team(db: Session, *, team_id: int, current_user: User) -> list[PracticePlanSummaryRead]:
    team = load_team_with_members(db, team_id)
    require_schedule_viewer(db, team=team, current_user=current_user)

    practices = (
        db.query(PracticePlan)
        .options(joinedload(PracticePlan.blocks))
        .filter(PracticePlan.team_id == team_id)
        .order_by(PracticePlan.practice_date.asc().nulls_last(), PracticePlan.created_at.desc())
        .all()
    )
    return [
        PracticePlanSummaryRead(
            id=practice.id,
            title=practice.title,
            practice_date=practice.practice_date,
            focus=practice.focus,
            total_duration_minutes=practice.total_duration_minutes,
            template_name_snapshot=practice.template_name_snapshot,
            total_block_count=len(practice.blocks),
        )
        for practice in practices
    ]


def create_template(db: Session, *, payload: PracticeTemplateCreate, current_user: User) -> PracticeTemplate:
    team = load_team_with_members(db, payload.team_id)
    require_schedule_manager(db, team=team, current_user=current_user)

    template = PracticeTemplate(
        team_id=payload.team_id,
        created_by_user_id=current_user.id,
        template_name=payload.template_name,
        description=payload.description,
        focus=payload.focus,
    )
    _sync_template_blocks(template, payload.blocks)
    db.add(template)
    db.flush()
    db.refresh(template)
    return _load_template(db, template_id=template.id, team_id=payload.team_id)


def list_templates_for_team(db: Session, *, team_id: int, current_user: User) -> list[PracticeTemplate]:
    team = load_team_with_members(db, team_id)
    require_schedule_viewer(db, team=team, current_user=current_user)
    return (
        db.query(PracticeTemplate)
        .options(joinedload(PracticeTemplate.blocks))
        .filter(PracticeTemplate.team_id == team_id)
        .order_by(PracticeTemplate.is_system_template.desc(), PracticeTemplate.template_name.asc())
        .all()
    )


def create_event(db: Session, *, payload: EventCreate, current_user: User) -> Event:
    team = load_team_with_members(db, payload.team_id)
    require_schedule_manager(db, team=team, current_user=current_user)
    validate_time_range(payload.starts_at, payload.ends_at)

    if payload.practice_plan_id is not None:
        practice = load_practice(db, payload.practice_plan_id, current_user=current_user, require_manage=True)
        if practice.team_id != payload.team_id:
            raise HTTPException(status_code=400, detail="Practice does not belong to this team")

    event = Event(
        team_id=payload.team_id,
        created_by_user_id=current_user.id,
        practice_plan_id=payload.practice_plan_id,
        title=payload.title,
        description=payload.description,
        event_type=payload.event_type,
        starts_at=payload.starts_at,
        ends_at=payload.ends_at,
        location=payload.location,
        notes=payload.notes,
        checklist=payload.checklist,
        bus_departure_note=payload.bus_departure_note,
        weigh_in_note=payload.weigh_in_note,
    )
    db.add(event)
    db.flush()
    db.refresh(event)
    return load_event(db, event.id, current_user=current_user)


def update_event(db: Session, *, event_id: int, payload: EventUpdate, current_user: User) -> Event:
    event = load_event(db, event_id, current_user=current_user, require_manage=True)
    if payload.title is not None:
        event.title = payload.title
    if payload.description is not None:
        event.description = payload.description
    if payload.event_type is not None:
        event.event_type = payload.event_type
    if payload.starts_at is not None:
        event.starts_at = payload.starts_at
    if payload.ends_at is not None:
        event.ends_at = payload.ends_at
    validate_time_range(event.starts_at, event.ends_at)
    if payload.location is not None:
        event.location = payload.location
    if payload.notes is not None:
        event.notes = payload.notes
    if payload.checklist is not None:
        event.checklist = payload.checklist
    if payload.bus_departure_note is not None:
        event.bus_departure_note = payload.bus_departure_note
    if payload.weigh_in_note is not None:
        event.weigh_in_note = payload.weigh_in_note
    if payload.is_cancelled is not None:
        event.is_cancelled = payload.is_cancelled
    if payload.practice_plan_id is not None:
        practice = load_practice(db, payload.practice_plan_id, current_user=current_user, require_manage=True)
        if practice.team_id != event.team_id:
            raise HTTPException(status_code=400, detail="Practice does not belong to this team")
        event.practice_plan_id = payload.practice_plan_id
    db.flush()
    db.refresh(event)
    return load_event(db, event.id, current_user=current_user)


def delete_event(db: Session, *, event_id: int, current_user: User) -> None:
    event = load_event(db, event_id, current_user=current_user, require_manage=True)
    db.delete(event)
    db.flush()


def load_event(db: Session, event_id: int, *, current_user: User, require_manage: bool = False) -> Event:
    event = (
        db.query(Event)
        .options(joinedload(Event.practice_plan).joinedload(PracticePlan.blocks))
        .filter(Event.id == event_id)
        .first()
    )
    if not event:
        raise HTTPException(status_code=404, detail="Event not found")
    team = load_team_with_members(db, event.team_id)
    if require_manage:
        require_schedule_manager(db, team=team, current_user=current_user)
    else:
        require_schedule_viewer(db, team=team, current_user=current_user)
    return event


def list_events_for_team(
    db: Session,
    *,
    team_id: int,
    current_user: User,
    event_type: EventType | None = None,
    starts_after: datetime | None = None,
    ends_before: datetime | None = None,
) -> tuple[str, list[Event], ScheduleSummaryRead]:
    team = load_team_with_members(db, team_id)
    visible_as = require_schedule_viewer(db, team=team, current_user=current_user)

    query = db.query(Event).options(joinedload(Event.practice_plan).joinedload(PracticePlan.blocks))
    query = query.filter(Event.team_id == team_id)
    if event_type is not None:
        query = query.filter(Event.event_type == event_type)
    if starts_after is not None:
        query = query.filter(Event.ends_at >= starts_after)
    if ends_before is not None:
        query = query.filter(Event.starts_at <= ends_before)

    events = query.order_by(Event.starts_at.asc()).all()
    now = _utcnow()
    week_end = now + timedelta(days=7)
    summary = ScheduleSummaryRead(
        total_events=len(events),
        practice_count=sum(1 for event in events if event.event_type == EventType.practice),
        competition_count=sum(1 for event in events if event.event_type in {EventType.dual_meet, EventType.tournament}),
        travel_count=sum(1 for event in events if event.event_type == EventType.travel),
        meeting_count=sum(1 for event in events if event.event_type == EventType.team_meeting),
        fundraiser_count=sum(1 for event in events if event.event_type == EventType.fundraiser),
        upcoming_week_count=sum(1 for event in events if now <= event.starts_at <= week_end),
    )
    return visible_as, events, summary


def duplicate_practice(
    db: Session,
    *,
    practice_id: int,
    payload: PracticeDuplicateRequest,
    current_user: User,
) -> PracticePlan:
    source = load_practice(db, practice_id, current_user=current_user, require_manage=True)
    duplicate = PracticePlan(
        team_id=source.team_id,
        created_by_user_id=current_user.id,
        template_id=source.template_id,
        title=payload.title or f"{source.title} Copy",
        description=source.description,
        focus=source.focus,
        practice_date=payload.practice_date or source.practice_date,
        notes=source.notes,
        template_name_snapshot=source.template_name_snapshot,
        is_template_based=source.is_template_based,
    )
    _sync_practice_blocks(
        duplicate,
        [
            PracticeBlockCreate(
                block_order=block.block_order,
                block_type=block.block_type,
                title=block.title,
                notes=block.notes,
                duration_minutes=block.duration_minutes,
            )
            for block in source.blocks
        ],
    )
    db.add(duplicate)
    db.flush()
    db.refresh(duplicate)
    return load_practice(db, duplicate.id, current_user=current_user)


def assign_practice_to_date(
    db: Session,
    *,
    practice_id: int,
    payload: PracticeAssignToDateRequest,
    current_user: User,
) -> tuple[PracticePlan, Event]:
    practice = load_practice(db, practice_id, current_user=current_user, require_manage=True)
    validate_time_range(payload.starts_at, payload.ends_at)

    practice.practice_date = payload.target_date
    if practice.event is None:
        practice.event = Event(
            team_id=practice.team_id,
            created_by_user_id=current_user.id,
            title=practice.title,
            description=practice.description,
            event_type=EventType.practice,
            starts_at=payload.starts_at,
            ends_at=payload.ends_at,
            location=payload.location,
            notes=payload.notes or practice.notes,
            checklist=payload.checklist,
            bus_departure_note=payload.bus_departure_note,
            weigh_in_note=payload.weigh_in_note,
        )
    else:
        practice.event.title = practice.title
        practice.event.description = practice.description
        practice.event.event_type = EventType.practice
        practice.event.starts_at = payload.starts_at
        practice.event.ends_at = payload.ends_at
        practice.event.location = payload.location
        practice.event.notes = payload.notes or practice.notes
        practice.event.checklist = payload.checklist
        practice.event.bus_departure_note = payload.bus_departure_note
        practice.event.weigh_in_note = payload.weigh_in_note

    db.add(practice)
    db.flush()
    db.refresh(practice)
    db.refresh(practice.event)
    return load_practice(db, practice.id, current_user=current_user), load_event(
        db,
        practice.event.id,
        current_user=current_user,
    )


def seed_default_templates(db: Session, *, team_id: int, created_by_user_id: int) -> None:
    if db.query(PracticeTemplate).filter(PracticeTemplate.team_id == team_id).first():
        return

    templates = [
        (
            "Pre-Match",
            "Tapered session focused on timing, feel, and confidence before competition.",
            "Sharp hand fighting and live situational readiness",
            [
                ("warm_up", "Dynamic warm-up", 10),
                ("stance_and_motion", "Short stance and motion", 8),
                ("drilling", "Set-up to finish chains", 15),
                ("live_goes", "Short intense goes", 12),
                ("cool_down", "Stretch and breathe", 10),
            ],
        ),
        (
            "Hard Practice",
            "High-output room session for conditioning and gritty positions.",
            "Pressure wrestling and pace",
            [
                ("warm_up", "Mat movement warm-up", 12),
                ("stance_and_motion", "Pressure stance work", 10),
                ("drilling", "Hard drilling circuits", 20),
                ("top_bottom", "Top and bottom grind", 18),
                ("live_goes", "Full live goes", 24),
                ("conditioning", "Sprint and carry finisher", 15),
                ("cool_down", "Recovery stretch", 8),
            ],
        ),
        (
            "Tournament Prep",
            "Scenario-based plan for bracket readiness and mat awareness.",
            "Situations, match management, and quick resets",
            [
                ("warm_up", "Activation and movement", 10),
                ("neutral", "First-score neutral chains", 16),
                ("top_bottom", "Ride and escape scenarios", 18),
                ("live_goes", "Tournament pace goes", 18),
                ("film_review", "Opponent tendencies and reminders", 15),
                ("recovery", "Flush and mobility", 10),
            ],
        ),
        (
            "Recovery Day",
            "Lower-load practice emphasizing mobility, film, and cleanup reps.",
            "Recovery and technical sharpness",
            [
                ("warm_up", "Mobility flow", 10),
                ("drilling", "Low-intensity technical reps", 18),
                ("film_review", "Film room notes", 20),
                ("recovery", "Bands, breathing, and reset", 15),
            ],
        ),
        (
            "Beginner Fundamentals",
            "Introductory practice for new athletes building position basics.",
            "Foundational motion and mat awareness",
            [
                ("warm_up", "Intro warm-up games", 10),
                ("stance_and_motion", "Stance and level changes", 15),
                ("neutral", "Basic shots and sprawls", 18),
                ("top_bottom", "Top/bottom starts", 18),
                ("conditioning", "Bodyweight finisher", 10),
                ("cool_down", "Team stretch", 8),
            ],
        ),
    ]

    for template_name, description, focus, blocks in templates:
        template = PracticeTemplate(
            team_id=team_id,
            created_by_user_id=created_by_user_id,
            template_name=template_name,
            description=description,
            focus=focus,
            is_system_template=True,
        )
        _sync_template_blocks(
            template,
            [
                PracticeBlockCreate(
                    block_order=index,
                    block_type=block_type,
                    title=title,
                    duration_minutes=duration,
                )
                for index, (block_type, title, duration) in enumerate(blocks, start=1)
            ],
        )
        db.add(template)
