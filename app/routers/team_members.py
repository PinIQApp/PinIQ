from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session, joinedload

from app.db.session import get_db
from app.models.team import Team, TeamMember, TeamMemberStatus
from app.models.user import User, UserRole
from app.routers.deps import get_current_user
from app.schemas.team import TeamMembershipCreate, TeamMemberStatusUpdate, TeamRead
from app.services.permissions import is_approved_team_member, require_team_manager


router = APIRouter(prefix="/team-members", tags=["team-members"])


def _load_team(db: Session, team_id: int) -> Team:
    team = (
        db.query(Team)
        .options(joinedload(Team.memberships).joinedload(TeamMember.user))
        .filter(Team.id == team_id)
        .first()
    )
    if not team:
        raise HTTPException(status_code=404, detail="Team not found")
    return team


@router.get("/teams/{team_id}", response_model=TeamRead)
def get_team_members(
    team_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    team = _load_team(db, team_id)
    membership = next((m for m in team.memberships if m.user_id == current_user.id), None)
    if current_user.role != UserRole.admin and not is_approved_team_member(membership):
        raise HTTPException(status_code=403, detail="Not authorized for this team")
    from app.routers.teams import _team_to_read

    include_pending = current_user.role == UserRole.admin or (
        is_approved_team_member(membership) and membership.is_staff
    )
    return _team_to_read(team, include_pending=include_pending)


@router.post("/teams/{team_id}", response_model=TeamRead, status_code=status.HTTP_201_CREATED)
def add_team_member(
    team_id: int,
    payload: TeamMembershipCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    team = _load_team(db, team_id)
    membership = next((m for m in team.memberships if m.user_id == current_user.id), None)
    require_team_manager(current_user, team, membership)

    user = db.query(User).filter(User.id == payload.user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    existing = (
        db.query(TeamMember)
        .filter(TeamMember.team_id == team_id, TeamMember.user_id == payload.user_id)
        .first()
    )
    if existing:
        raise HTTPException(status_code=400, detail="User already belongs to this team")

    db.add(
        TeamMember(
            team_id=team_id,
            user_id=payload.user_id,
            role_label=payload.role_label,
            is_staff=payload.is_staff,
            status=TeamMemberStatus.approved,
        )
    )
    if user.primary_team_id is None:
        user.primary_team_id = team_id
    db.commit()

    team = _load_team(db, team_id)
    from app.routers.teams import _team_to_read

    return _team_to_read(team)


@router.put("/teams/{team_id}/{member_id}/status", response_model=TeamRead)
def update_team_member_status(
    team_id: int,
    member_id: int,
    payload: TeamMemberStatusUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    team = _load_team(db, team_id)
    membership = next((m for m in team.memberships if m.user_id == current_user.id), None)
    require_team_manager(current_user, team, membership)

    member = (
        db.query(TeamMember)
        .filter(TeamMember.id == member_id, TeamMember.team_id == team_id)
        .first()
    )
    if not member:
        raise HTTPException(status_code=404, detail="Team member not found")

    member.status = payload.status
    if payload.status == TeamMemberStatus.approved:
        member.user.primary_team_id = team_id
    db.commit()

    team = _load_team(db, team_id)
    from app.routers.teams import _team_to_read

    return _team_to_read(team)


@router.delete("/teams/{team_id}/{member_id}", response_model=TeamRead)
def remove_team_member(
    team_id: int,
    member_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    team = _load_team(db, team_id)
    membership = next((m for m in team.memberships if m.user_id == current_user.id), None)
    require_team_manager(current_user, team, membership)

    member = (
        db.query(TeamMember)
        .filter(TeamMember.id == member_id, TeamMember.team_id == team_id)
        .first()
    )
    if not member:
        raise HTTPException(status_code=404, detail="Team member not found")
    if member.user_id == current_user.id:
        raise HTTPException(status_code=400, detail="You cannot remove yourself")

    user = member.user
    db.delete(member)
    if user.primary_team_id == team_id:
        user.primary_team_id = None
    db.commit()

    team = _load_team(db, team_id)
    from app.routers.teams import _team_to_read

    return _team_to_read(team)
