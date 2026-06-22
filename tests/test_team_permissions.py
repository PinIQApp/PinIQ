from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from app.core.security import create_access_token, get_password_hash
from app.models.team import Team, TeamMember, TeamMemberStatus
from app.models.user import User, UserRole


def _auth_headers_for(user_id: int) -> dict[str, str]:
    return {"Authorization": f"Bearer {create_access_token(user_id)}"}


def test_pending_staff_cannot_manage_team(
    client: TestClient,
    db_session: Session,
    coach_auth_headers: dict[str, str],
):
    team = db_session.query(Team).filter(Team.id == 1).first()
    assert team is not None

    pending_assistant = User(
        email="pending.assistant@example.com",
        password_hash=get_password_hash("Password123"),
        full_name="Pending Assistant",
        role=UserRole.assistant_coach,
    )
    db_session.add(pending_assistant)
    db_session.flush()

    db_session.add(
        TeamMember(
            team_id=team.id,
            user_id=pending_assistant.id,
            role_label="Assistant Coach",
            is_staff=True,
            status=TeamMemberStatus.pending,
        )
    )
    db_session.commit()

    response = client.post(
        f"/api/v1/teams/{team.id}/rotate-join-code",
        headers=_auth_headers_for(pending_assistant.id),
    )

    assert response.status_code == 403
    assert response.json()["detail"] == "Only staff can manage this team"


def test_approved_non_staff_only_sees_approved_members(
    client: TestClient,
    db_session: Session,
    coach_auth_headers: dict[str, str],
):
    team = db_session.query(Team).filter(Team.id == 1).first()
    assert team is not None

    approved_athlete = User(
        email="approved.athlete@example.com",
        password_hash=get_password_hash("Password123"),
        full_name="Approved Athlete",
        role=UserRole.athlete,
    )
    pending_parent = User(
        email="pending.parent@example.com",
        password_hash=get_password_hash("Password123"),
        full_name="Pending Parent",
        role=UserRole.parent,
    )
    db_session.add_all([approved_athlete, pending_parent])
    db_session.flush()

    db_session.add_all(
        [
            TeamMember(
                team_id=team.id,
                user_id=approved_athlete.id,
                role_label="Athlete",
                is_staff=False,
                status=TeamMemberStatus.approved,
            ),
            TeamMember(
                team_id=team.id,
                user_id=pending_parent.id,
                role_label="Parent",
                is_staff=False,
                status=TeamMemberStatus.pending,
            ),
        ]
    )
    db_session.commit()

    response = client.get(
        f"/api/v1/teams/{team.id}",
        headers=_auth_headers_for(approved_athlete.id),
    )

    assert response.status_code == 200
    members = response.json()["members"]
    assert all(member["status"] == "approved" for member in members)
    assert "pending.parent@example.com" not in {member["user"]["email"] for member in members}


def test_admin_can_still_view_pending_members(
    client: TestClient,
    db_session: Session,
    admin_auth_headers: dict[str, str],
    coach_auth_headers: dict[str, str],
):
    team = db_session.query(Team).filter(Team.id == 1).first()
    assert team is not None

    pending_parent = User(
        email="pending.viewer@example.com",
        password_hash=get_password_hash("Password123"),
        full_name="Pending Viewer",
        role=UserRole.parent,
    )
    db_session.add(pending_parent)
    db_session.flush()

    db_session.add(
        TeamMember(
            team_id=team.id,
            user_id=pending_parent.id,
            role_label="Parent",
            is_staff=False,
            status=TeamMemberStatus.pending,
        )
    )
    db_session.commit()

    response = client.get(f"/api/v1/teams/{team.id}", headers=admin_auth_headers)

    assert response.status_code == 200
    members = response.json()["members"]
    pending_member = next(member for member in members if member["user"]["email"] == "pending.viewer@example.com")
    assert pending_member["status"] == "pending"
