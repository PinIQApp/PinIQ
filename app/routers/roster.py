from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session, joinedload

from app.db.session import get_db
from app.models.messaging import ParentLink
from app.models.team import Team, TeamMember, TeamMemberStatus
from app.models.user import User, UserRole
from app.routers.deps import get_current_user
from app.schemas.team import AthleteDetail, AthleteManagedUpdate, AthleteRosterProfile
from app.services.permissions import can_manage_team


router = APIRouter(prefix="/teams", tags=["roster"])


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


def _require_team_access(team: Team, current_user: User) -> None:
    member_ids = {member.user_id for member in team.memberships}
    if current_user.role != UserRole.admin and current_user.id not in member_ids:
        raise HTTPException(status_code=403, detail="Not authorized for this team")


def _approved_athlete_members(team: Team) -> list[TeamMember]:
    return [
        member
        for member in team.memberships
        if member.status == TeamMemberStatus.approved and member.user.role == UserRole.athlete
    ]


def _to_roster_profile(member: TeamMember) -> AthleteRosterProfile:
    return AthleteRosterProfile(
        user_id=member.user.id,
        membership_id=member.id,
        full_name=member.user.full_name,
        role=member.user.role,
        role_label=member.role_label,
        hometown=member.user.hometown,
        graduation_year=member.user.graduation_year,
        weight_class=member.user.weight_class,
        profile_image_url=member.user.profile_image_url,
    )


def _to_athlete_detail(member: TeamMember) -> AthleteDetail:
    roster_profile = _to_roster_profile(member)
    return AthleteDetail(
        **roster_profile.model_dump(),
        email=member.user.email,
        phone=member.user.phone,
        bio=member.user.bio,
        primary_team_id=member.user.primary_team_id,
        joined_team_at=member.created_at,
    )


def _is_linked_parent(db: Session, *, team_id: int, athlete_user_id: int, parent_user_id: int) -> bool:
    return (
        db.query(ParentLink)
        .filter(
            ParentLink.team_id == team_id,
            ParentLink.athlete_user_id == athlete_user_id,
            ParentLink.parent_user_id == parent_user_id,
            ParentLink.is_active.is_(True),
        )
        .first()
        is not None
    )


def _require_athlete_manager(
    db: Session,
    *,
    team: Team,
    athlete_user_id: int,
    current_user: User,
) -> None:
    membership = next((item for item in team.memberships if item.user_id == current_user.id), None)
    if can_manage_team(current_user, membership):
        return
    if current_user.role == UserRole.parent and _is_linked_parent(
        db,
        team_id=team.id,
        athlete_user_id=athlete_user_id,
        parent_user_id=current_user.id,
    ):
        return
    raise HTTPException(status_code=403, detail="Only team staff or an accepted parent can manage this athlete")


@router.get("/{team_id}/roster", response_model=list[AthleteRosterProfile])
def get_team_roster(
    team_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    team = _load_team_with_members(db, team_id)
    _require_team_access(team, current_user)

    roster = sorted(_approved_athlete_members(team), key=lambda member: member.user.full_name.lower())
    return [_to_roster_profile(member) for member in roster]


@router.get("/{team_id}/athletes/{athlete_user_id}", response_model=AthleteDetail)
def get_athlete_detail(
    team_id: int,
    athlete_user_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    team = _load_team_with_members(db, team_id)
    _require_team_access(team, current_user)

    member = next(
        (
            item
            for item in _approved_athlete_members(team)
            if item.user_id == athlete_user_id
        ),
        None,
    )
    if not member:
        raise HTTPException(status_code=404, detail="Athlete not found on this roster")

    if current_user.role == UserRole.parent and not _is_linked_parent(
        db,
        team_id=team_id,
        athlete_user_id=athlete_user_id,
        parent_user_id=current_user.id,
    ):
        raise HTTPException(status_code=403, detail="Parents can only view athletes they manage")
    return _to_athlete_detail(member)


@router.put("/{team_id}/athletes/{athlete_user_id}", response_model=AthleteDetail)
def update_athlete_detail(
    team_id: int,
    athlete_user_id: int,
    payload: AthleteManagedUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    team = _load_team_with_members(db, team_id)
    member = next(
        (item for item in _approved_athlete_members(team) if item.user_id == athlete_user_id),
        None,
    )
    if not member:
        raise HTTPException(status_code=404, detail="Athlete not found on this roster")
    _require_athlete_manager(
        db,
        team=team,
        athlete_user_id=athlete_user_id,
        current_user=current_user,
    )

    member.user.full_name = payload.full_name.strip()
    member.user.phone = payload.phone
    member.user.profile_image_url = payload.profile_image_url.strip() if payload.profile_image_url else None
    member.user.hometown = payload.hometown.strip() if payload.hometown else None
    member.user.graduation_year = payload.graduation_year
    member.user.weight_class = payload.weight_class.strip() if payload.weight_class else None
    member.user.bio = payload.bio.strip() if payload.bio else None
    db.commit()
    db.refresh(member.user)
    return _to_athlete_detail(member)
