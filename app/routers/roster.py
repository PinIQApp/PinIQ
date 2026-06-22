from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session, joinedload

from app.db.session import get_db
from app.models.team import Team, TeamMember, TeamMemberStatus
from app.models.user import User, UserRole
from app.routers.deps import get_current_user
from app.schemas.team import AthleteDetail, AthleteRosterProfile


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

    roster_profile = _to_roster_profile(member)
    return AthleteDetail(
        **roster_profile.model_dump(),
        email=member.user.email,
        phone=member.user.phone,
        bio=member.user.bio,
        primary_team_id=member.user.primary_team_id,
        joined_team_at=member.created_at,
    )
