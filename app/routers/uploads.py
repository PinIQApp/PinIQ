from __future__ import annotations

from fastapi import APIRouter, Depends, File, HTTPException, UploadFile
from sqlalchemy.orm import Session, joinedload

from app.db.session import get_db
from app.models.team import Team, TeamMember
from app.models.user import User
from app.routers.deps import get_current_user
from app.routers.teams import _team_to_read
from app.schemas.team import TeamRead
from app.services.file_storage import save_team_logo, validate_image_upload
from app.services.permissions import require_team_manager


router = APIRouter(prefix="/uploads", tags=["uploads"])


@router.post("/teams/{team_id}/logo", response_model=TeamRead)
def upload_team_logo(
    team_id: int,
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if not file.content_type or not file.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="Only image uploads are allowed")
    validate_image_upload(file)

    team = db.query(Team).filter(Team.id == team_id).first()
    if not team:
        raise HTTPException(status_code=404, detail="Team not found")

    membership = (
        db.query(TeamMember)
        .filter(TeamMember.team_id == team_id, TeamMember.user_id == current_user.id)
        .first()
    )
    require_team_manager(current_user, team, membership)

    team.logo_url = save_team_logo(file)
    db.commit()
    db.refresh(team)

    team = (
        db.query(Team)
        .options(joinedload(Team.memberships).joinedload(TeamMember.user))
        .filter(Team.id == team_id)
        .first()
    )
    return _team_to_read(team)
