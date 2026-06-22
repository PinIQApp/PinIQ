from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session, joinedload

from app.db.session import get_db
from app.models.team import Team, TeamMember
from app.models.user import User, UserRole
from app.routers.deps import get_current_user
from app.routers.teams import _team_to_read
from app.schemas.team import BrandingUpdate, TeamRead
from app.services.permissions import require_team_manager


router = APIRouter(prefix="/branding", tags=["branding"])


@router.put("/teams/{team_id}", response_model=TeamRead)
def update_branding(
    team_id: int,
    payload: BrandingUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    team = db.query(Team).filter(Team.id == team_id).first()
    if not team:
        raise HTTPException(status_code=404, detail="Team not found")

    membership = (
        db.query(TeamMember)
        .filter(TeamMember.team_id == team_id, TeamMember.user_id == current_user.id)
        .first()
    )
    require_team_manager(current_user, team, membership)

    for key, value in payload.model_dump().items():
        setattr(team, key, value)

    db.commit()
    team = (
        db.query(Team)
        .options(joinedload(Team.memberships).joinedload(TeamMember.user))
        .filter(Team.id == team_id)
        .first()
    )
    return _team_to_read(team)
