from __future__ import annotations

from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session, joinedload

from app.db.session import get_db
from app.models.messaging import ParentLink
from app.models.team import Team, TeamMember, TeamMemberStatus
from app.models.user import User, UserRole
from app.models.weight import (
    AthleteTarget,
    HydrationLog,
    WeightAlert,
    WeightAlertStatus,
    WeightLog,
    WeightPlan,
    WeightPlanStatus,
)
from app.routers.deps import get_current_user
from app.schemas.weight import (
    AthleteWeightSnapshot,
    LinkedAthleteRead,
    WeightAlertRead,
    WeightLogCreate,
    WeightLogRead,
    WeightPlanCalculateRequest,
    WeightPlanRead,
    WeightPlanWithHistory,
)
from app.services.permissions import require_team_manager
from app.services.weight_planning import build_alert_payloads, calculate_plan


router = APIRouter(prefix="/weights", tags=["weights"])


def _load_team_with_members(db: Session, team_id: int) -> Team:
    team = (
        db.query(Team)
        .options(joinedload(Team.memberships).joinedload(TeamMember.user))
        .filter(Team.id == team_id)
        .first()
    )
    if not team:
        raise HTTPException(status_code=404, detail="Team not found")
    return team


def _approved_membership(team: Team, user_id: int) -> TeamMember | None:
    return next(
        (
            member
            for member in team.memberships
            if member.user_id == user_id and member.status == TeamMemberStatus.approved
        ),
        None,
    )


def _load_athlete_for_team(team: Team, athlete_id: int) -> TeamMember:
    membership = next(
        (
            member
            for member in team.memberships
            if member.user_id == athlete_id
            and member.status == TeamMemberStatus.approved
            and member.user.role == UserRole.athlete
        ),
        None,
    )
    if membership is None:
        raise HTTPException(status_code=404, detail="Athlete not found for this team")
    return membership


def _is_linked_parent(db: Session, *, team_id: int, athlete_id: int, parent_user_id: int) -> bool:
    return (
        db.query(ParentLink)
        .filter(
            ParentLink.team_id == team_id,
            ParentLink.athlete_user_id == athlete_id,
            ParentLink.parent_user_id == parent_user_id,
            ParentLink.is_active.is_(True),
        )
        .first()
        is not None
    )


def _require_athlete_visibility(
    db: Session,
    *,
    team: Team,
    athlete_id: int,
    current_user: User,
) -> TeamMember:
    team_membership = _approved_membership(team, current_user.id)
    athlete_membership = _load_athlete_for_team(team, athlete_id)

    if current_user.role == UserRole.admin:
        return athlete_membership
    if current_user.id == athlete_id:
        return athlete_membership
    if team_membership and current_user.role in {UserRole.coach, UserRole.assistant_coach}:
        return athlete_membership
    if current_user.role == UserRole.parent and _is_linked_parent(
        db, team_id=team.id, athlete_id=athlete_id, parent_user_id=current_user.id
    ):
        return athlete_membership
    raise HTTPException(status_code=403, detail="Not authorized for this athlete")


def _serialize_plan(plan: WeightPlan | None) -> dict | None:
    if plan is None:
        return None
    return WeightPlanRead.model_validate(plan).model_dump()


def _derive_grade_value(graduation_year: int | None, *, today: datetime | None = None) -> int | None:
    if graduation_year is None:
        return None
    today = today or datetime.utcnow()
    grade = 12 - max(graduation_year - today.year, 0)
    if grade < 9 or grade > 12:
        return None
    return grade


def _matches_weight_class_filter(
    weight_class_filter: str | None,
    *,
    latest_plan: WeightPlan | None,
    profile_weight_class: str | None,
) -> bool:
    if not weight_class_filter:
        return True

    normalized_filter = weight_class_filter.strip().lower()
    if profile_weight_class and profile_weight_class.strip().lower() == normalized_filter:
        return True

    try:
        numeric_filter = float(weight_class_filter)
    except ValueError:
        return False

    comparable_values = [
        latest_plan.target_weight_class if latest_plan else None,
        latest_plan.estimated_reachable_class if latest_plan else None,
    ]
    return any(value is not None and round(value, 1) == round(numeric_filter, 1) for value in comparable_values)


def _sync_alerts(
    db: Session,
    *,
    athlete_id: int,
    team_id: int,
    plan: WeightPlan | None,
    athlete_name: str,
    latest_log: WeightLog | None,
) -> list[WeightAlert]:
    existing_alerts = db.query(WeightAlert).filter(
        WeightAlert.athlete_id == athlete_id,
        WeightAlert.team_id == team_id,
        WeightAlert.status == WeightAlertStatus.active,
    )
    for alert in existing_alerts:
        db.delete(alert)
    db.flush()

    alert_payloads = build_alert_payloads(
        athlete_name=athlete_name,
        latest_log_at=latest_log.logged_at if latest_log else None,
        latest_weight=latest_log.weight if latest_log else None,
        plan=_serialize_plan(plan),
    )
    created_alerts: list[WeightAlert] = []
    for payload in alert_payloads:
        alert = WeightAlert(
            athlete_id=athlete_id,
            team_id=team_id,
            plan_id=plan.id if plan else None,
            alert_type=payload["alert_type"],
            alert_message=payload["alert_message"],
            severity=payload["severity"],
        )
        db.add(alert)
        created_alerts.append(alert)
    db.flush()
    return created_alerts


def _latest_log(db: Session, *, athlete_id: int, team_id: int) -> WeightLog | None:
    return (
        db.query(WeightLog)
        .filter(WeightLog.athlete_id == athlete_id, WeightLog.team_id == team_id)
        .order_by(WeightLog.logged_at.desc(), WeightLog.id.desc())
        .first()
    )


def _latest_plan(db: Session, *, athlete_id: int, team_id: int) -> WeightPlan | None:
    return (
        db.query(WeightPlan)
        .filter(WeightPlan.athlete_id == athlete_id, WeightPlan.team_id == team_id)
        .order_by(WeightPlan.calculated_at.desc(), WeightPlan.id.desc())
        .first()
    )


def _active_target(db: Session, *, athlete_id: int, team_id: int) -> AthleteTarget | None:
    return (
        db.query(AthleteTarget)
        .filter(
            AthleteTarget.athlete_id == athlete_id,
            AthleteTarget.team_id == team_id,
            AthleteTarget.is_active.is_(True),
        )
        .order_by(AthleteTarget.updated_at.desc(), AthleteTarget.id.desc())
        .first()
    )


def _create_plan_record(
    db: Session,
    *,
    athlete_id: int,
    team_id: int,
    athlete_target_id: int | None,
    payload: WeightPlanCalculateRequest,
) -> WeightPlan:
    calculation = calculate_plan(
        current_weight=payload.current_weight,
        body_fat_percentage=payload.body_fat_percentage,
        target_weight_class=payload.target_weight_class,
        target_date=payload.target_date,
    )
    plan = WeightPlan(
        athlete_id=athlete_id,
        team_id=team_id,
        athlete_target_id=athlete_target_id,
        current_weight=calculation["current_weight"],
        body_fat_percentage=calculation["body_fat_percentage"],
        target_weight_class=calculation["target_weight_class"],
        target_date=calculation["target_date"],
        weekly_allowed_loss=calculation["weekly_allowed_loss"],
        required_weekly_loss=calculation["required_weekly_loss"],
        projected_reachable_weight=calculation["projected_reachable_weight"],
        estimated_reachable_class=calculation["estimated_reachable_class"],
        projected_target_date=calculation["projected_target_date"],
        status=calculation["status"],
        warning_message=calculation["warning_message"],
        summary=calculation["summary"],
        plan_details=calculation["plan_details"],
    )
    db.add(plan)
    db.flush()
    return plan


@router.get("/linked-athletes", response_model=list[LinkedAthleteRead])
def get_linked_athletes(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if current_user.role != UserRole.parent:
        return []

    links = (
        db.query(ParentLink)
        .options(joinedload(ParentLink.athlete_user))
        .filter(ParentLink.parent_user_id == current_user.id, ParentLink.is_active.is_(True))
        .order_by(ParentLink.created_at.desc())
        .all()
    )
    return [
        LinkedAthleteRead(
            athlete_id=link.athlete_user_id,
            athlete_name=link.athlete_user.full_name,
            team_id=link.team_id,
            relationship_label=link.relationship_label,
        )
        for link in links
    ]


@router.post("/log", response_model=WeightLogRead, status_code=status.HTTP_201_CREATED)
def create_weight_log(
    payload: WeightLogCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    team = _load_team_with_members(db, payload.team_id)
    _require_athlete_visibility(db, team=team, athlete_id=payload.athlete_id, current_user=current_user)

    if current_user.role == UserRole.parent:
        raise HTTPException(status_code=403, detail="Parents can view weight data but cannot create logs")

    weight_log = WeightLog(
        athlete_id=payload.athlete_id,
        team_id=payload.team_id,
        created_by_user_id=current_user.id,
        logged_at=payload.logged_at,
        weight=payload.weight,
        body_fat_percentage=payload.body_fat_percentage,
        hydration_note=payload.hydration_note,
        comments=payload.comments,
    )
    db.add(weight_log)
    if payload.hydration_note:
        db.add(
            HydrationLog(
                athlete_id=payload.athlete_id,
                team_id=payload.team_id,
                logged_at=payload.logged_at,
                note=payload.hydration_note,
                status_label="note",
            )
        )
    db.flush()

    target = _active_target(db, athlete_id=payload.athlete_id, team_id=payload.team_id)
    plan = None
    if target:
        plan = _create_plan_record(
            db,
            athlete_id=payload.athlete_id,
            team_id=payload.team_id,
            athlete_target_id=target.id,
            payload=WeightPlanCalculateRequest(
                athlete_id=payload.athlete_id,
                team_id=payload.team_id,
                current_weight=payload.weight,
                body_fat_percentage=payload.body_fat_percentage or target.body_fat_percentage,
                target_weight_class=target.target_weight_class,
                target_date=target.target_date,
            ),
        )
    athlete_membership = _load_athlete_for_team(team, payload.athlete_id)
    _sync_alerts(
        db,
        athlete_id=payload.athlete_id,
        team_id=payload.team_id,
        plan=plan or _latest_plan(db, athlete_id=payload.athlete_id, team_id=payload.team_id),
        athlete_name=athlete_membership.user.full_name,
        latest_log=weight_log,
    )
    db.commit()
    db.refresh(weight_log)
    return weight_log


@router.get("/history/{athlete_id}", response_model=list[WeightLogRead])
def get_weight_history(
    athlete_id: int,
    team_id: int = Query(...),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    team = _load_team_with_members(db, team_id)
    _require_athlete_visibility(db, team=team, athlete_id=athlete_id, current_user=current_user)
    return (
        db.query(WeightLog)
        .filter(WeightLog.athlete_id == athlete_id, WeightLog.team_id == team_id)
        .order_by(WeightLog.logged_at.desc(), WeightLog.id.desc())
        .all()
    )


@router.post("/plan/calculate", response_model=WeightPlanRead, status_code=status.HTTP_201_CREATED)
def calculate_weight_plan(
    payload: WeightPlanCalculateRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    team = _load_team_with_members(db, payload.team_id)
    _require_athlete_visibility(db, team=team, athlete_id=payload.athlete_id, current_user=current_user)
    if current_user.role == UserRole.parent:
        raise HTTPException(status_code=403, detail="Parents can view plans but cannot create them")

    target = _active_target(db, athlete_id=payload.athlete_id, team_id=payload.team_id)
    if target is None:
        target = AthleteTarget(
            athlete_id=payload.athlete_id,
            team_id=payload.team_id,
            target_weight_class=payload.target_weight_class,
            target_date=payload.target_date,
            body_fat_percentage=payload.body_fat_percentage,
            created_by_user_id=current_user.id,
        )
        db.add(target)
        db.flush()
    else:
        target.target_weight_class = payload.target_weight_class
        target.target_date = payload.target_date
        target.body_fat_percentage = payload.body_fat_percentage

    plan = _create_plan_record(
        db,
        athlete_id=payload.athlete_id,
        team_id=payload.team_id,
        athlete_target_id=target.id,
        payload=payload,
    )
    athlete_membership = _load_athlete_for_team(team, payload.athlete_id)
    latest_log = _latest_log(db, athlete_id=payload.athlete_id, team_id=payload.team_id)
    _sync_alerts(
        db,
        athlete_id=payload.athlete_id,
        team_id=payload.team_id,
        plan=plan,
        athlete_name=athlete_membership.user.full_name,
        latest_log=latest_log,
    )
    db.commit()
    db.refresh(plan)
    return plan


@router.get("/plan/{athlete_id}", response_model=WeightPlanWithHistory)
def get_weight_plan(
    athlete_id: int,
    team_id: int = Query(...),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    team = _load_team_with_members(db, team_id)
    athlete_membership = _require_athlete_visibility(db, team=team, athlete_id=athlete_id, current_user=current_user)
    plan = _latest_plan(db, athlete_id=athlete_id, team_id=team_id)
    recent_logs = (
        db.query(WeightLog)
        .filter(WeightLog.athlete_id == athlete_id, WeightLog.team_id == team_id)
        .order_by(WeightLog.logged_at.desc(), WeightLog.id.desc())
        .limit(10)
        .all()
    )
    active_alerts = _sync_alerts(
        db,
        athlete_id=athlete_id,
        team_id=team_id,
        plan=plan,
        athlete_name=athlete_membership.user.full_name,
        latest_log=recent_logs[0] if recent_logs else None,
    )
    db.commit()
    return WeightPlanWithHistory(
        athlete_id=athlete_id,
        latest_plan=WeightPlanRead.model_validate(plan) if plan else None,
        recent_logs=[WeightLogRead.model_validate(log) for log in recent_logs],
        active_alerts=[WeightAlertRead.model_validate(alert) for alert in active_alerts],
    )


@router.get("/team-dashboard/{team_id}", response_model=list[AthleteWeightSnapshot])
def get_team_weight_dashboard(
    team_id: int,
    group: str | None = Query(default=None),
    grade: int | None = Query(default=None),
    weight_class: str | None = Query(default=None),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    team = _load_team_with_members(db, team_id)
    membership = _approved_membership(team, current_user.id)
    require_team_manager(current_user, team, membership)

    snapshots: list[AthleteWeightSnapshot] = []
    for member in sorted(
        (
            team_member
            for team_member in team.memberships
            if team_member.status == TeamMemberStatus.approved and team_member.user.role == UserRole.athlete
        ),
        key=lambda team_member: team_member.user.full_name.lower(),
    ):
        if group and member.role_label.lower() != group.lower():
            continue

        latest_log = _latest_log(db, athlete_id=member.user_id, team_id=team_id)
        latest_plan = _latest_plan(db, athlete_id=member.user_id, team_id=team_id)
        derived_grade = _derive_grade_value(member.user.graduation_year)
        if grade and derived_grade != grade:
            continue
        if not _matches_weight_class_filter(
            weight_class,
            latest_plan=latest_plan,
            profile_weight_class=member.user.weight_class,
        ):
            continue
        alerts = _sync_alerts(
            db,
            athlete_id=member.user_id,
            team_id=team_id,
            plan=latest_plan,
            athlete_name=member.user.full_name,
            latest_log=latest_log,
        )
        status = latest_plan.status if latest_plan else WeightPlanStatus.yellow
        summary = latest_plan.summary if latest_plan else "No active plan yet. Logging is available."
        snapshots.append(
            AthleteWeightSnapshot(
                athlete_id=member.user_id,
                athlete_name=member.user.full_name,
                grade_label=str(derived_grade) if derived_grade else None,
                team_group=member.role_label,
                current_weight=round(latest_log.weight, 1) if latest_log else None,
                latest_log_at=latest_log.logged_at if latest_log else None,
                target_weight_class=latest_plan.target_weight_class if latest_plan else None,
                target_date=latest_plan.target_date if latest_plan else None,
                projected_reachable_weight=latest_plan.projected_reachable_weight if latest_plan else None,
                projected_class=latest_plan.estimated_reachable_class if latest_plan else None,
                weekly_allowed_loss=latest_plan.weekly_allowed_loss if latest_plan else None,
                required_weekly_loss=latest_plan.required_weekly_loss if latest_plan else None,
                status=status,
                status_summary=summary,
                warning_message=latest_plan.warning_message if latest_plan else None,
                alerts=[WeightAlertRead.model_validate(alert) for alert in alerts],
            )
        )
    db.commit()
    return snapshots


@router.get("/alerts/{team_id}", response_model=list[WeightAlertRead])
def get_team_weight_alerts(
    team_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    team = _load_team_with_members(db, team_id)
    membership = _approved_membership(team, current_user.id)
    require_team_manager(current_user, team, membership)
    return (
        db.query(WeightAlert)
        .filter(WeightAlert.team_id == team_id, WeightAlert.status == WeightAlertStatus.active)
        .order_by(WeightAlert.triggered_at.desc(), WeightAlert.id.desc())
        .all()
    )
