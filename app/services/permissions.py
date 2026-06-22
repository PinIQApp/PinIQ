from __future__ import annotations

from fastapi import HTTPException

from app.models.team import Team, TeamMember
from app.models.user import User, UserRole


def is_approved_team_member(membership: TeamMember | None) -> bool:
    return membership is not None and membership.status.value == "approved"


def can_manage_team(current_user: User, membership: TeamMember | None) -> bool:
    return current_user.role == UserRole.admin or (
        is_approved_team_member(membership)
        and membership.is_staff
        and current_user.role in {UserRole.coach, UserRole.assistant_coach}
    )


def require_team_manager(current_user: User, team: Team, membership: TeamMember | None) -> None:
    if not can_manage_team(current_user, membership):
        raise HTTPException(status_code=403, detail="Only staff can manage this team")
