from __future__ import annotations

import secrets
import string

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session, joinedload

from app.db.session import get_db
from app.models.team import Team, TeamMember, TeamMemberStatus
from app.models.user import User, UserRole
from app.routers.deps import get_current_user
from app.schemas.team import JoinCodeRotateResponse, TeamCreate, TeamJoinRequest, TeamLookupRead, TeamMemberRead, TeamRead
from app.services.pagination import normalize_pagination
from app.services.permissions import is_approved_team_member, require_team_manager


router = APIRouter(prefix="/teams", tags=["teams"])


def _generate_join_code(length: int = 8) -> str:
    alphabet = string.ascii_uppercase + string.digits
    return "".join(secrets.choice(alphabet) for _ in range(length))


def _team_to_read(team: Team, *, include_pending: bool = True) -> TeamRead:
    memberships = team.memberships if include_pending else [
        member for member in team.memberships if member.status == TeamMemberStatus.approved
    ]
    return TeamRead(
        id=team.id,
        name=team.name,
        slug=team.slug,
        join_code=team.join_code,
        school_name=team.school_name,
        school_abbreviation=team.school_abbreviation,
        mascot_name=team.mascot_name,
        division=team.division,
        season_label=team.season_label,
        dark_mode=team.dark_mode,
        primary_color=team.primary_color,
        secondary_color=team.secondary_color,
        accent_color=team.accent_color,
        surface_color=team.surface_color,
        logo_url=team.logo_url,
        tagline=team.tagline,
        created_by_user_id=team.created_by_user_id,
        created_at=team.created_at,
        members=[TeamMemberRead.model_validate(member, from_attributes=True) for member in memberships],
    )


@router.post("", response_model=TeamRead, status_code=status.HTTP_201_CREATED)
def create_team(
    payload: TeamCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if current_user.role not in {UserRole.coach, UserRole.assistant_coach, UserRole.admin}:
        raise HTTPException(status_code=403, detail="Only staff can create teams")

    existing = db.query(Team).filter(Team.slug == payload.slug).first()
    if existing:
        raise HTTPException(status_code=400, detail="Team slug already exists")

    team = Team(**payload.model_dump(), created_by_user_id=current_user.id)
    db.add(team)
    db.flush()

    membership = TeamMember(
        team_id=team.id,
        user_id=current_user.id,
        role_label=current_user.role.value.replace("_", " ").title(),
        is_staff=True,
        status=TeamMemberStatus.approved,
    )
    db.add(membership)
    current_user.primary_team_id = team.id
    db.commit()

    team = (
        db.query(Team)
        .options(joinedload(Team.memberships).joinedload(TeamMember.user))
        .filter(Team.id == team.id)
        .first()
    )
    return _team_to_read(team)


@router.get("", response_model=list[TeamRead])
def list_teams(
    limit: int | None = Query(default=None, ge=1),
    offset: int | None = Query(default=None, ge=0),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    limit, offset = normalize_pagination(limit=limit, offset=offset)
    teams = (
        db.query(Team)
        .join(TeamMember, TeamMember.team_id == Team.id)
        .filter(TeamMember.user_id == current_user.id)
        .options(joinedload(Team.memberships).joinedload(TeamMember.user))
        .offset(offset)
        .limit(limit)
        .all()
    )
    return [_team_to_read(team) for team in teams]


@router.get("/search", response_model=list[TeamLookupRead])
def search_teams(
    query: str = Query(min_length=2, max_length=80),
    limit: int | None = Query(default=10, ge=1, le=25),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if current_user.role not in {UserRole.admin, UserRole.coach, UserRole.assistant_coach}:
        raise HTTPException(status_code=403, detail="Only staff can search teams")

    limit, _ = normalize_pagination(limit=limit, offset=0)
    pattern = f"%{query.strip()}%"
    teams = (
        db.query(Team)
        .filter(
            (Team.name.ilike(pattern))
            | (Team.school_name.ilike(pattern))
            | (Team.mascot_name.ilike(pattern))
        )
        .order_by(Team.school_name.asc(), Team.name.asc())
        .limit(limit)
        .all()
    )
    return [
        TeamLookupRead(
            id=team.id,
            name=team.name,
            school_name=team.school_name,
            mascot_name=team.mascot_name,
            division=team.division,
        )
        for team in teams
    ]


@router.get("/{team_id}", response_model=TeamRead)
def get_team(
    team_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    team = (
        db.query(Team)
        .options(joinedload(Team.memberships).joinedload(TeamMember.user))
        .filter(Team.id == team_id)
        .first()
    )
    if not team:
        raise HTTPException(status_code=404, detail="Team not found")

    member_ids = [member.user_id for member in team.memberships]
    membership = next((member for member in team.memberships if member.user_id == current_user.id), None)
    if current_user.role != UserRole.admin and not is_approved_team_member(membership):
        raise HTTPException(status_code=403, detail="Not authorized for this team")

    include_pending = current_user.role == UserRole.admin or (
        is_approved_team_member(membership) and membership.is_staff
    )
    return _team_to_read(team, include_pending=include_pending)


@router.post("/join", response_model=TeamRead)
def join_team(
    payload: TeamJoinRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    team = (
        db.query(Team)
        .options(joinedload(Team.memberships).joinedload(TeamMember.user))
        .filter(Team.join_code == payload.join_code.upper())
        .first()
    )
    if not team:
        raise HTTPException(status_code=404, detail="Join code not found")

    existing_member = (
        db.query(TeamMember)
        .filter(TeamMember.team_id == team.id, TeamMember.user_id == current_user.id)
        .first()
    )
    if existing_member:
        raise HTTPException(status_code=400, detail="User is already on this team")

    membership = TeamMember(
        team_id=team.id,
        user_id=current_user.id,
        role_label=current_user.role.value.replace("_", " ").title(),
        is_staff=current_user.role in {UserRole.coach, UserRole.assistant_coach, UserRole.admin},
        status=(
            TeamMemberStatus.approved
            if current_user.role in {UserRole.coach, UserRole.admin}
            else TeamMemberStatus.pending
        ),
    )
    db.add(membership)
    if membership.status == TeamMemberStatus.approved:
        current_user.primary_team_id = team.id
    db.commit()

    team = (
        db.query(Team)
        .options(joinedload(Team.memberships).joinedload(TeamMember.user))
        .filter(Team.id == team.id)
        .first()
    )
    return _team_to_read(team)


@router.post("/{team_id}/rotate-join-code", response_model=JoinCodeRotateResponse)
def rotate_join_code(
    team_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    team = (
        db.query(Team)
        .options(joinedload(Team.memberships))
        .filter(Team.id == team_id)
        .first()
    )
    if not team:
        raise HTTPException(status_code=404, detail="Team not found")

    membership = next((m for m in team.memberships if m.user_id == current_user.id), None)
    require_team_manager(current_user, team, membership)

    join_code = _generate_join_code()
    while db.query(Team).filter(Team.join_code == join_code).first():
        join_code = _generate_join_code()

    team.join_code = join_code
    db.commit()
    return JoinCodeRotateResponse(join_code=join_code)
