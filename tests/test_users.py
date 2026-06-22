from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from app.core.security import get_password_hash
from app.models.user import User, UserRole


def test_admin_can_deactivate_user(
    client: TestClient,
    db_session: Session,
    admin_auth_headers: dict[str, str],
):
    user = User(
        email="member@example.com",
        password_hash=get_password_hash("Password123"),
        full_name="Member User",
        role=UserRole.coach,
    )
    db_session.add(user)
    db_session.commit()

    response = client.patch(
        f"/api/v1/users/{user.id}/status",
        headers=admin_auth_headers,
        json={"is_active": False},
    )

    assert response.status_code == 200
    assert response.json()["is_active"] is False


def test_admin_cannot_deactivate_self(
    client: TestClient,
    db_session: Session,
    admin_auth_headers: dict[str, str],
):
    admin = db_session.query(User).filter(User.email == "admin@example.com").first()

    response = client.patch(
        f"/api/v1/users/{admin.id}/status",
        headers=admin_auth_headers,
        json={"is_active": False},
    )

    assert response.status_code == 400
    assert response.json()["detail"] == "Admins cannot deactivate themselves"


def test_update_me_normalizes_phone_number(
    client: TestClient,
    coach_auth_headers: dict[str, str],
):
    response = client.put(
        "/api/v1/users/me",
        headers=coach_auth_headers,
        json={
            "full_name": "Coach Carter",
            "phone": "(555) 222-3333",
            "profile_image_url": None,
            "hometown": None,
            "graduation_year": None,
            "weight_class": None,
            "bio": None,
        },
    )

    assert response.status_code == 200
    assert response.json()["phone"] == "+15552223333"


def test_update_me_rejects_invalid_phone_number(
    client: TestClient,
    coach_auth_headers: dict[str, str],
):
    response = client.put(
        "/api/v1/users/me",
        headers=coach_auth_headers,
        json={
            "full_name": "Coach Carter",
            "phone": "12345",
            "profile_image_url": None,
            "hometown": None,
            "graduation_year": None,
            "weight_class": None,
            "bio": None,
        },
    )

    assert response.status_code == 422


def test_user_can_register_and_remove_push_device(
    client: TestClient,
    coach_auth_headers: dict[str, str],
):
    register = client.post(
        "/api/v1/users/me/push-devices",
        headers=coach_auth_headers,
        json={"platform": "ios", "device_token": "device-token-123456"},
    )

    assert register.status_code == 200
    device_id = register.json()["id"]

    listed = client.get("/api/v1/users/me/push-devices", headers=coach_auth_headers)
    assert listed.status_code == 200
    assert len(listed.json()) == 1

    deleted = client.delete(f"/api/v1/users/me/push-devices/{device_id}", headers=coach_auth_headers)
    assert deleted.status_code == 200
