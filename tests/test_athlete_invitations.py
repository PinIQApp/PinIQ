from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from app.core.security import create_access_token, get_password_hash
from app.models.messaging import ParentLink
from app.models.team import AthleteInvitationStatus, AthleteParentInvitation, Team, TeamMember, TeamMemberStatus
from app.models.user import User, UserRole


def _headers(user_id: int) -> dict[str, str]:
    return {"Authorization": f"Bearer {create_access_token(user_id)}"}


def _team(db_session: Session) -> Team:
    coach = db_session.query(User).filter(User.email == "coach@example.com").first()
    return db_session.query(Team).filter(Team.id == coach.primary_team_id).first()


def _invite_payload(*, parent_phone: str = "+15559876543") -> dict[str, object]:
    return {
        "athlete_full_name": "Jordan Rivera",
        "parent_phone": parent_phone,
        "relationship_label": "guardian",
        "phone": "+15551234567",
        "hometown": "Columbus, OH",
        "graduation_year": 2028,
        "weight_class": "132",
    }


def test_coach_adds_athlete_and_sends_parent_invitation(
    client: TestClient,
    db_session: Session,
    coach_auth_headers: dict[str, str],
):
    team = _team(db_session)

    response = client.post(
        f"/api/v1/teams/{team.id}/athlete-invitations",
        headers=coach_auth_headers,
        json=_invite_payload(),
    )

    assert response.status_code == 201
    body = response.json()
    assert body["status"] == "pending"
    assert body["athlete_full_name"] == "Jordan Rivera"
    assert body["athlete_email"] is None
    assert body["parent_email"] is None
    assert body["parent_phone"] == "+15559876543"

    athlete = (
        db_session.query(User)
        .filter(User.full_name == "Jordan Rivera", User.role == UserRole.athlete)
        .first()
    )
    assert athlete is not None
    assert athlete.role == UserRole.athlete
    membership = (
        db_session.query(TeamMember)
        .filter(TeamMember.team_id == team.id, TeamMember.user_id == athlete.id)
        .first()
    )
    assert membership is not None
    assert membership.status == TeamMemberStatus.approved


def test_matching_parent_accepts_and_can_manage_athlete(
    client: TestClient,
    db_session: Session,
    coach_auth_headers: dict[str, str],
):
    team = _team(db_session)
    created = client.post(
        f"/api/v1/teams/{team.id}/athlete-invitations",
        headers=coach_auth_headers,
        json=_invite_payload(),
    )
    invitation_id = created.json()["id"]
    athlete_id = created.json()["athlete_user_id"]

    parent = User(
        email="guardian@example.com",
        password_hash=get_password_hash("Password123"),
        full_name="Taylor Rivera",
        role=UserRole.parent,
        phone="+15559876543",
    )
    db_session.add(parent)
    db_session.commit()
    parent_headers = _headers(parent.id)

    pending = client.get("/api/v1/athlete-invitations/mine", headers=parent_headers)
    assert pending.status_code == 200
    assert [item["id"] for item in pending.json()] == [invitation_id]

    accepted = client.post(
        f"/api/v1/athlete-invitations/{invitation_id}/accept",
        headers=parent_headers,
    )
    assert accepted.status_code == 200
    assert accepted.json()["status"] == "accepted"

    db_session.expire_all()
    invitation = db_session.query(AthleteParentInvitation).filter_by(id=invitation_id).first()
    assert invitation.status == AthleteInvitationStatus.accepted
    parent_membership = (
        db_session.query(TeamMember)
        .filter(TeamMember.team_id == team.id, TeamMember.user_id == parent.id)
        .first()
    )
    assert parent_membership is not None
    assert parent_membership.status == TeamMemberStatus.approved
    link = (
        db_session.query(ParentLink)
        .filter(
            ParentLink.team_id == team.id,
            ParentLink.parent_user_id == parent.id,
            ParentLink.athlete_user_id == athlete_id,
        )
        .first()
    )
    assert link is not None and link.is_active

    updated = client.put(
        f"/api/v1/teams/{team.id}/athletes/{athlete_id}",
        headers=parent_headers,
        json={
            "full_name": "Jordan A. Rivera",
            "phone": "+15557654321",
            "hometown": "Dublin, OH",
            "graduation_year": 2028,
            "weight_class": "138",
            "bio": "Second-year varsity athlete.",
        },
    )
    assert updated.status_code == 200
    assert updated.json()["full_name"] == "Jordan A. Rivera"
    assert updated.json()["weight_class"] == "138"


def test_invitation_cannot_be_accepted_by_a_different_parent(
    client: TestClient,
    db_session: Session,
    coach_auth_headers: dict[str, str],
    outsider_auth_headers: dict[str, str],
):
    team = _team(db_session)
    created = client.post(
        f"/api/v1/teams/{team.id}/athlete-invitations",
        headers=coach_auth_headers,
        json=_invite_payload(),
    )

    response = client.post(
        f"/api/v1/athlete-invitations/{created.json()['id']}/accept",
        headers=outsider_auth_headers,
    )

    assert response.status_code == 403
    assert response.json()["detail"] == "This invitation belongs to a different parent"


def test_unlinked_parent_cannot_manage_athlete(
    client: TestClient,
    db_session: Session,
    coach_auth_headers: dict[str, str],
    outsider_auth_headers: dict[str, str],
):
    team = _team(db_session)
    created = client.post(
        f"/api/v1/teams/{team.id}/athlete-invitations",
        headers=coach_auth_headers,
        json=_invite_payload(),
    )

    response = client.put(
        f"/api/v1/teams/{team.id}/athletes/{created.json()['athlete_user_id']}",
        headers=outsider_auth_headers,
        json={"full_name": "Unauthorized Rename"},
    )

    assert response.status_code == 403
