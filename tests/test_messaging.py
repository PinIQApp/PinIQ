from __future__ import annotations

from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.security import create_access_token, get_password_hash
from app.models.user import UserPushDevice
from app.models.messaging import ParentLink
from app.models.team import TeamMember, TeamMemberStatus
from app.models.user import User, UserRole


def _add_linked_athlete_parent_pair(
    db_session: Session,
    *,
    team_id: int,
    athlete_email: str,
    parent_email: str,
    athlete_phone: str | None = None,
    parent_phone: str | None = None,
) -> tuple[User, User]:
    athlete = User(
        email=athlete_email,
        password_hash=get_password_hash("Password123"),
        full_name=athlete_email.split("@", 1)[0].replace("-", " ").title(),
        role=UserRole.athlete,
        phone=athlete_phone,
    )
    parent = User(
        email=parent_email,
        password_hash=get_password_hash("Password123"),
        full_name=parent_email.split("@", 1)[0].replace("-", " ").title(),
        role=UserRole.parent,
        phone=parent_phone,
    )
    db_session.add_all([athlete, parent])
    db_session.flush()

    db_session.add_all(
        [
            TeamMember(
                team_id=team_id,
                user_id=athlete.id,
                role_label="Athlete",
                is_staff=False,
                status=TeamMemberStatus.approved,
            ),
            TeamMember(
                team_id=team_id,
                user_id=parent.id,
                role_label="Parent",
                is_staff=False,
                status=TeamMemberStatus.approved,
            ),
            ParentLink(
                team_id=team_id,
                parent_user_id=parent.id,
                athlete_user_id=athlete.id,
                relationship_label="parent",
                is_active=True,
            ),
        ]
    )
    db_session.commit()
    return athlete, parent


def test_thread_creation_requires_parent_link_for_athlete(
    client: TestClient,
    coach_auth_headers: dict[str, str],
    messaging_team_members: dict[str, int],
):
    response = client.post(
        "/api/v1/messages/thread/create",
        headers=coach_auth_headers,
        json={
            "team_id": messaging_team_members["team_id"],
            "title": "Check in",
            "thread_type": "direct",
            "participant_user_ids": [messaging_team_members["athlete_id"]],
        },
    )

    assert response.status_code == 400
    assert "Parent visibility is required" in response.json()["detail"]


def test_thread_creation_auto_includes_parent_visibility_participant(
    client: TestClient,
    coach_auth_headers: dict[str, str],
    messaging_team_members: dict[str, int],
    parent_link,
):
    response = client.post(
        "/api/v1/messages/thread/create",
        headers=coach_auth_headers,
        json={
            "team_id": messaging_team_members["team_id"],
            "title": "Check in",
            "thread_type": "direct",
            "participant_user_ids": [messaging_team_members["athlete_id"]],
        },
    )

    assert response.status_code == 200
    participants = response.json()["participants"]
    participant_ids = {participant["user_id"] for participant in participants}
    assert messaging_team_members["athlete_id"] in participant_ids
    assert messaging_team_members["parent_id"] in participant_ids
    assert any(
        participant["participant_type"] == "parent_visibility"
        for participant in participants
    )


def test_parent_can_view_linked_athlete_messages_from_coach_and_other_athletes(
    client: TestClient,
    db_session: Session,
    coach_auth_headers: dict[str, str],
    messaging_team_members: dict[str, int],
    parent_link: ParentLink,
):
    team_id = messaging_team_members["team_id"]

    other_athlete, _ = _add_linked_athlete_parent_pair(
        db_session,
        team_id=team_id,
        athlete_email="other-athlete@example.com",
        parent_email="other-parent@example.com",
    )

    parent_headers = {"Authorization": f"Bearer {create_access_token(messaging_team_members['parent_id'])}"}
    other_athlete_headers = {"Authorization": f"Bearer {create_access_token(other_athlete.id)}"}

    create_response = client.post(
        "/api/v1/messages/thread/create",
        headers=coach_auth_headers,
        json={
            "team_id": team_id,
            "title": "Athlete group chat",
            "thread_type": "group",
            "participant_user_ids": [
                messaging_team_members["athlete_id"],
                other_athlete.id,
            ],
        },
    )

    assert create_response.status_code == 200
    thread_id = create_response.json()["id"]

    coach_message = client.post(
        "/api/v1/messages/send",
        headers=coach_auth_headers,
        json={"thread_id": thread_id, "body": "Practice starts at 5:30 sharp."},
    )
    assert coach_message.status_code == 200

    athlete_message = client.post(
        "/api/v1/messages/send",
        headers=other_athlete_headers,
        json={"thread_id": thread_id, "body": "I can bring the speaker."},
    )
    assert athlete_message.status_code == 200

    parent_thread = client.get(
        f"/api/v1/messages/thread/{thread_id}",
        headers=parent_headers,
    )
    assert parent_thread.status_code == 200
    messages = parent_thread.json()["messages"]
    assert [message["body"] for message in messages] == [
        "Practice starts at 5:30 sharp.",
        "I can bring the speaker.",
    ]

    athlete_inbox = client.get(
        f"/api/v1/messages/user/{messaging_team_members['athlete_id']}",
        headers=parent_headers,
    )
    assert athlete_inbox.status_code == 200
    assert any(thread["id"] == thread_id for thread in athlete_inbox.json())

    parent_inbox = client.get(
        f"/api/v1/messages/user/{messaging_team_members['parent_id']}",
        headers=parent_headers,
    )
    assert parent_inbox.status_code == 200
    assert any(thread["id"] == thread_id for thread in parent_inbox.json())


def test_parent_visibility_participant_cannot_send_messages(
    client: TestClient,
    coach_auth_headers: dict[str, str],
    messaging_team_members: dict[str, int],
    parent_link: ParentLink,
):
    parent_headers = {"Authorization": f"Bearer {create_access_token(messaging_team_members['parent_id'])}"}

    create_response = client.post(
        "/api/v1/messages/thread/create",
        headers=coach_auth_headers,
        json={
            "team_id": messaging_team_members["team_id"],
            "title": "Check in",
            "thread_type": "direct",
            "participant_user_ids": [messaging_team_members["athlete_id"]],
        },
    )

    assert create_response.status_code == 200
    thread_id = create_response.json()["id"]

    response = client.post(
        "/api/v1/messages/send",
        headers=parent_headers,
        json={"thread_id": thread_id, "body": "Parent replying here."},
    )

    assert response.status_code == 403
    assert "can view this thread but cannot send" in response.json()["detail"]


def test_flagged_message_auto_alerts_coaches_and_parents(
    client: TestClient,
    db_session: Session,
    coach_auth_headers: dict[str, str],
    messaging_team_members: dict[str, int],
    parent_link: ParentLink,
):
    team_id = messaging_team_members["team_id"]
    other_athlete, other_parent = _add_linked_athlete_parent_pair(
        db_session,
        team_id=team_id,
        athlete_email="alert-athlete@example.com",
        parent_email="alert-parent@example.com",
    )

    athlete_headers = {"Authorization": f"Bearer {create_access_token(messaging_team_members['athlete_id'])}"}
    parent_headers = {"Authorization": f"Bearer {create_access_token(messaging_team_members['parent_id'])}"}
    other_parent_headers = {"Authorization": f"Bearer {create_access_token(other_parent.id)}"}

    create_response = client.post(
        "/api/v1/messages/thread/create",
        headers=athlete_headers,
        json={
            "team_id": team_id,
            "title": "Weekend plans",
            "thread_type": "group",
            "participant_user_ids": [other_athlete.id],
        },
    )

    assert create_response.status_code == 200
    source_thread_id = create_response.json()["id"]

    risky_message = client.post(
        "/api/v1/messages/send",
        headers=athlete_headers,
        json={
            "thread_id": source_thread_id,
            "body": "Let's bring weed and steal beer after practice.",
        },
    )

    assert risky_message.status_code == 200
    flags = risky_message.json()["visibility_flags"]
    assert flags["content_risk_flags"] == ["drugs", "crime"]
    assert flags["auto_escalated_to_parent_and_coaches"] is True
    assert flags["severity"] == "concern"
    assert flags["score"] >= 6

    coach = db_session.query(User).filter(User.email == "coach@example.com").first()
    coach_inbox = client.get(
        f"/api/v1/messages/user/{coach.id}",
        headers=coach_auth_headers,
    )
    assert coach_inbox.status_code == 200
    alert_threads = [
        thread for thread in coach_inbox.json() if (thread["visibility_flags"] or {}).get("compliance_alert") is True
    ]
    assert len(alert_threads) == 1

    alert_thread_id = alert_threads[0]["id"]
    parent_alert = client.get(
        f"/api/v1/messages/thread/{alert_thread_id}",
        headers=parent_headers,
    )
    assert parent_alert.status_code == 200
    assert parent_alert.json()["messages"][0]["message_type"] == "compliance_note"
    assert "weed and steal beer" in parent_alert.json()["messages"][0]["body"]

    other_parent_alert = client.get(
        f"/api/v1/messages/thread/{alert_thread_id}",
        headers=other_parent_headers,
    )
    assert other_parent_alert.status_code == 200

    review_queue = client.get(
        f"/api/v1/messages/safety-alerts/team/{team_id}",
        headers=coach_auth_headers,
    )
    assert review_queue.status_code == 200
    assert len(review_queue.json()) == 1
    alert = review_queue.json()[0]
    assert alert["severity"] == "concern"
    assert alert["status"] == "open"
    assert alert["categories"] == ["drugs", "crime"]
    assert alert["alert_thread_id"] == alert_thread_id

    acknowledged = client.post(
        f"/api/v1/messages/safety-alerts/{alert['id']}/acknowledge",
        headers=coach_auth_headers,
    )
    assert acknowledged.status_code == 200
    assert acknowledged.json()["alert"]["status"] == "acknowledged"
    assert acknowledged.json()["alert"]["acknowledged_by"]["id"] == coach.id


def test_messages_cannot_be_deleted(
    client: TestClient,
    coach_auth_headers: dict[str, str],
    messaging_team_members: dict[str, int],
    parent_link: ParentLink,
):
    create_response = client.post(
        "/api/v1/messages/thread/create",
        headers=coach_auth_headers,
        json={
            "team_id": messaging_team_members["team_id"],
            "title": "Immutable thread",
            "thread_type": "direct",
            "participant_user_ids": [messaging_team_members["athlete_id"]],
        },
    )
    assert create_response.status_code == 200

    send_response = client.post(
        "/api/v1/messages/send",
        headers=coach_auth_headers,
        json={"thread_id": create_response.json()["id"], "body": "This message stays."},
    )
    assert send_response.status_code == 200

    delete_response = client.post(
        f"/api/v1/messages/{send_response.json()['id']}/soft-delete",
        headers=coach_auth_headers,
    )
    assert delete_response.status_code == 403
    assert "cannot be deleted" in delete_response.json()["detail"]


def test_coach_can_send_team_text_alert_to_whole_team_and_parents(
    client: TestClient,
    db_session: Session,
    coach_auth_headers: dict[str, str],
    messaging_team_members: dict[str, int],
    parent_link: ParentLink,
):
    coach = db_session.query(User).filter(User.email == "coach@example.com").first()
    athlete = db_session.query(User).filter(User.id == messaging_team_members["athlete_id"]).first()
    parent = db_session.query(User).filter(User.id == messaging_team_members["parent_id"]).first()
    coach.phone = "555-111-1111"
    athlete.phone = "555-222-2222"
    parent.phone = "555-333-3333"
    db_session.commit()

    response = client.post(
        "/api/v1/announcements/send",
        headers=coach_auth_headers,
        json={
            "team_id": messaging_team_members["team_id"],
            "title": "Bus update",
            "body": "Bus leaves at 6:15 AM. Bring team gear.",
            "audience_label": "team",
            "send_text_alert": True,
        },
    )

    assert response.status_code == 200
    flags = response.json()["visibility_flags"]
    assert flags["team_text_alert"] is True
    assert flags["text_alert_delivery"]["provider"] == "mock"
    assert set(flags["text_alert_delivery"]["delivered_user_ids"]) == {
        messaging_team_members["athlete_id"],
        messaging_team_members["parent_id"],
    }
    assert coach.id not in flags["text_alert_delivery"]["delivered_user_ids"]
    assert flags["text_alert_delivery"]["delivered_phone_count"] == 2


def test_admin_can_send_team_text_alert_to_team_and_parents(
    client: TestClient,
    db_session: Session,
    coach_auth_headers: dict[str, str],
    admin_auth_headers: dict[str, str],
    messaging_team_members: dict[str, int],
    parent_link: ParentLink,
):
    coach = db_session.query(User).filter(User.email == "coach@example.com").first()
    athlete = db_session.query(User).filter(User.id == messaging_team_members["athlete_id"]).first()
    parent = db_session.query(User).filter(User.id == messaging_team_members["parent_id"]).first()
    coach.phone = "555-111-1111"
    athlete.phone = "555-222-2222"
    parent.phone = "555-333-3333"
    db_session.commit()

    response = client.post(
        "/api/v1/announcements/send",
        headers=admin_auth_headers,
        json={
            "team_id": messaging_team_members["team_id"],
            "title": "Weather alert",
            "body": "Practice is moving indoors tonight.",
            "audience_label": "team",
            "send_text_alert": True,
        },
    )

    assert response.status_code == 200
    flags = response.json()["visibility_flags"]
    assert flags["team_text_alert"] is True
    assert set(flags["text_alert_delivery"]["delivered_user_ids"]) == {
        coach.id,
        messaging_team_members["athlete_id"],
        messaging_team_members["parent_id"],
    }
    assert flags["text_alert_delivery"]["delivered_phone_count"] == 3


def test_assistant_coach_cannot_send_team_text_alert(
    client: TestClient,
    db_session: Session,
    coach_auth_headers: dict[str, str],
    messaging_team_members: dict[str, int],
    parent_link: ParentLink,
):
    assistant = User(
        email="assistant@example.com",
        password_hash=get_password_hash("Password123"),
        full_name="Assistant Coach",
        role=UserRole.assistant_coach,
        phone="555-444-4444",
    )
    db_session.add(assistant)
    db_session.flush()
    db_session.add(
        TeamMember(
            team_id=messaging_team_members["team_id"],
            user_id=assistant.id,
            role_label="Assistant Coach",
            is_staff=True,
            status=TeamMemberStatus.approved,
        )
    )
    db_session.commit()
    assistant_headers = {"Authorization": f"Bearer {create_access_token(assistant.id)}"}

    response = client.post(
        "/api/v1/announcements/send",
        headers=assistant_headers,
        json={
            "team_id": messaging_team_members["team_id"],
            "title": "Bus update",
            "body": "Bus leaves at 6:15 AM. Bring team gear.",
            "audience_label": "team",
            "send_text_alert": True,
        },
    )

    assert response.status_code == 403
    assert "Only coaches and administrators" in response.json()["detail"]


def test_team_text_alert_rejects_individual_recipient_targeting(
    client: TestClient,
    coach_auth_headers: dict[str, str],
    messaging_team_members: dict[str, int],
    parent_link: ParentLink,
):
    response = client.post(
        "/api/v1/announcements/send",
        headers=coach_auth_headers,
        json={
            "team_id": messaging_team_members["team_id"],
            "title": "Bus update",
            "body": "Bus leaves at 6:15 AM. Bring team gear.",
            "audience_label": "team",
            "recipient_user_ids": [messaging_team_members["athlete_id"]],
            "send_text_alert": True,
        },
    )

    assert response.status_code == 400
    assert "whole team and linked parents" in response.json()["detail"]


def test_team_text_alert_readiness_reports_missing_phone_numbers(
    client: TestClient,
    db_session: Session,
    coach_auth_headers: dict[str, str],
    messaging_team_members: dict[str, int],
    parent_link: ParentLink,
):
    coach = db_session.query(User).filter(User.email == "coach@example.com").first()
    athlete = db_session.query(User).filter(User.id == messaging_team_members["athlete_id"]).first()
    parent = db_session.query(User).filter(User.id == messaging_team_members["parent_id"]).first()
    coach.phone = "+15551111111"
    athlete.phone = None
    parent.phone = "555-333-3333"
    db_session.commit()

    response = client.get(
        f"/api/v1/announcements/team/{messaging_team_members['team_id']}/text-alert-readiness",
        headers=coach_auth_headers,
    )

    assert response.status_code == 200
    body = response.json()
    assert body["summary"]["eligible_recipient_count"] == 3
    assert body["summary"]["valid_phone_recipient_count"] == 2
    assert body["summary"]["missing_phone_recipient_count"] == 1
    athlete_entry = next(
        member for member in body["members"] if member["user_id"] == messaging_team_members["athlete_id"]
    )
    parent_entry = next(
        member for member in body["members"] if member["user_id"] == messaging_team_members["parent_id"]
    )
    assert athlete_entry["has_valid_phone"] is False
    assert parent_entry["auto_included_reason"] == "auto-added for athlete Athlete User"


def test_team_text_alert_records_twilio_provider_message_ids(
    client: TestClient,
    db_session: Session,
    coach_auth_headers: dict[str, str],
    messaging_team_members: dict[str, int],
    parent_link: ParentLink,
    monkeypatch,
):
    coach = db_session.query(User).filter(User.email == "coach@example.com").first()
    athlete = db_session.query(User).filter(User.id == messaging_team_members["athlete_id"]).first()
    parent = db_session.query(User).filter(User.id == messaging_team_members["parent_id"]).first()
    coach.phone = "+15551111111"
    athlete.phone = "+15552222222"
    parent.phone = "+15553333333"
    db_session.commit()

    monkeypatch.setattr(settings, "sms_provider", "twilio")
    monkeypatch.setattr(settings, "twilio_account_sid", "acct-123")
    monkeypatch.setattr(settings, "twilio_auth_token", "token-123")
    monkeypatch.setattr(settings, "sms_from_number", "+15550000000")

    class _FakeResponse:
        def raise_for_status(self):
            return None

        def json(self):
            return {"sid": "SM123456789"}

    def _fake_post(*args, **kwargs):
        return _FakeResponse()

    monkeypatch.setattr("app.services.sms_alerts.httpx.post", _fake_post)

    response = client.post(
        "/api/v1/announcements/send",
        headers=coach_auth_headers,
        json={
            "team_id": messaging_team_members["team_id"],
            "title": "Travel update",
            "body": "Leave campus at 5:45 sharp.",
            "audience_label": "team",
            "send_text_alert": True,
        },
    )

    assert response.status_code == 200
    announcement_id = response.json()["id"]
    deliveries = client.get(
        f"/api/v1/announcements/{announcement_id}/deliveries",
        headers=coach_auth_headers,
    )
    assert deliveries.status_code == 200
    sms_deliveries = [item for item in deliveries.json() if item["channel"] == "sms" and item["status"] == "sent"]
    assert len(sms_deliveries) == 2
    assert all(item["provider"] == "twilio" for item in sms_deliveries)
    assert all(item["provider_message_id"] == "SM123456789" for item in sms_deliveries)


def test_team_text_alert_falls_back_to_email_and_push_when_sms_fails(
    client: TestClient,
    db_session: Session,
    coach_auth_headers: dict[str, str],
    messaging_team_members: dict[str, int],
    parent_link: ParentLink,
):
    athlete = db_session.query(User).filter(User.id == messaging_team_members["athlete_id"]).first()
    parent = db_session.query(User).filter(User.id == messaging_team_members["parent_id"]).first()
    athlete.phone = None
    parent.phone = None
    db_session.add(
        UserPushDevice(
            user_id=athlete.id,
            platform="ios",
            device_token="push-token-athlete",
        )
    )
    db_session.commit()

    response = client.post(
        "/api/v1/announcements/send",
        headers=coach_auth_headers,
        json={
            "team_id": messaging_team_members["team_id"],
            "title": "Gym move",
            "body": "Practice moved to the auxiliary gym.",
            "audience_label": "team",
            "send_text_alert": True,
        },
    )

    assert response.status_code == 200
    summary = response.json()["visibility_flags"]["text_alert_delivery"]
    assert summary["sms_failed_count"] == 2
    assert summary["email_sent_count"] == 2
    assert summary["push_sent_count"] == 1
    assert summary["push_failed_count"] == 1

    deliveries = client.get(
        f"/api/v1/announcements/{response.json()['id']}/deliveries",
        headers=coach_auth_headers,
    )
    assert deliveries.status_code == 200
    payload = deliveries.json()
    assert len([item for item in payload if item["channel"] == "sms" and item["status"] == "failed"]) == 2
    assert len([item for item in payload if item["channel"] == "email" and item["status"] == "sent"]) == 2
    assert len([item for item in payload if item["channel"] == "push" and item["status"] == "sent"]) == 1


def test_urgent_safety_alert_auto_dispatches_notifications(
    client: TestClient,
    db_session: Session,
    coach_auth_headers: dict[str, str],
    messaging_team_members: dict[str, int],
    parent_link: ParentLink,
):
    coach = db_session.query(User).filter(User.email == "coach@example.com").first()
    athlete = db_session.query(User).filter(User.id == messaging_team_members["athlete_id"]).first()
    parent = db_session.query(User).filter(User.id == messaging_team_members["parent_id"]).first()
    coach.phone = "+15551111111"
    parent.phone = "+15553333333"
    db_session.commit()

    athlete_headers = {"Authorization": f"Bearer {create_access_token(athlete.id)}"}
    create_response = client.post(
        "/api/v1/messages/thread/create",
        headers=coach_auth_headers,
        json={
            "team_id": messaging_team_members["team_id"],
            "title": "Check in",
            "thread_type": "direct",
            "participant_user_ids": [athlete.id],
        },
    )
    assert create_response.status_code == 200

    send_response = client.post(
        "/api/v1/messages/send",
        headers=athlete_headers,
        json={
            "thread_id": create_response.json()["id"],
            "body": "Let's bring weed, steal beer, and send nude pics after practice.",
        },
    )
    assert send_response.status_code == 200
    assert send_response.json()["visibility_flags"]["severity"] == "urgent"

    review_queue = client.get(
        f"/api/v1/messages/safety-alerts/team/{messaging_team_members['team_id']}",
        headers=coach_auth_headers,
    )
    assert review_queue.status_code == 200
    alert = review_queue.json()[0]
    assert alert["severity"] == "urgent"
    assert alert["metadata"]["notification_summary"]["sms_sent_count"] >= 2

    deliveries = client.get(
        f"/api/v1/messages/safety-alerts/{alert['id']}/deliveries",
        headers=coach_auth_headers,
    )
    assert deliveries.status_code == 200
    sms_deliveries = [item for item in deliveries.json() if item["channel"] == "sms" and item["status"] == "sent"]
    assert len(sms_deliveries) >= 2
