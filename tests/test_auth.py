from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from app.core.security import get_password_hash
from app.models.user import EmailVerificationToken, PasswordResetToken, RefreshToken, User, UserRole


def test_inactive_user_cannot_log_in(client: TestClient, db_session: Session):
    user = User(
        email="inactive@example.com",
        password_hash=get_password_hash("Password123"),
        full_name="Inactive User",
        role=UserRole.coach,
        is_active=False,
    )
    db_session.add(user)
    db_session.commit()

    response = client.post(
        "/api/v1/auth/login",
        json={"email": "inactive@example.com", "password": "Password123"},
    )

    assert response.status_code == 403
    assert response.json()["detail"] == "User account is inactive"


def test_login_returns_refresh_token(client: TestClient, db_session: Session):
    user = User(
        email="active@example.com",
        password_hash=get_password_hash("Password123"),
        full_name="Active User",
        role=UserRole.coach,
    )
    db_session.add(user)
    db_session.commit()

    response = client.post(
        "/api/v1/auth/login",
        json={"email": "active@example.com", "password": "Password123"},
    )

    body = response.json()
    assert response.status_code == 200
    assert body["access_token"]
    assert body["refresh_token"]
    assert body["token_type"] == "bearer"
    assert db_session.query(RefreshToken).count() == 1


def test_refresh_rotates_refresh_token(client: TestClient, db_session: Session):
    user = User(
        email="rotate@example.com",
        password_hash=get_password_hash("Password123"),
        full_name="Rotate User",
        role=UserRole.coach,
    )
    db_session.add(user)
    db_session.commit()

    login_response = client.post(
        "/api/v1/auth/login",
        json={"email": "rotate@example.com", "password": "Password123"},
    )
    first_refresh_token = login_response.json()["refresh_token"]

    refresh_response = client.post(
        "/api/v1/auth/refresh",
        json={"refresh_token": first_refresh_token},
    )

    assert refresh_response.status_code == 200
    assert refresh_response.json()["refresh_token"] != first_refresh_token
    revoked_count = db_session.query(RefreshToken).filter(RefreshToken.revoked_at.is_not(None)).count()
    assert revoked_count == 1


def test_password_reset_request_and_confirm(client: TestClient, db_session: Session):
    user = User(
        email="reset@example.com",
        password_hash=get_password_hash("Password123"),
        full_name="Reset User",
        role=UserRole.coach,
    )
    db_session.add(user)
    db_session.commit()

    request_response = client.post(
        "/api/v1/auth/password-reset/request",
        json={"email": "reset@example.com"},
    )

    assert request_response.status_code == 200
    reset_token = request_response.json()["reset_token"]
    assert reset_token
    assert db_session.query(PasswordResetToken).count() == 1

    confirm_response = client.post(
        "/api/v1/auth/password-reset/confirm",
        json={"token": reset_token, "new_password": "NewPassword9"},
    )

    assert confirm_response.status_code == 200
    login_response = client.post(
        "/api/v1/auth/login",
        json={"email": "reset@example.com", "password": "NewPassword9"},
    )
    assert login_response.status_code == 200


def test_login_rate_limit_kicks_in(client: TestClient):
    for _ in range(3):
        response = client.post(
            "/api/v1/auth/login",
            json={"email": "missing@example.com", "password": "Password123"},
        )
        assert response.status_code == 400

    blocked = client.post(
        "/api/v1/auth/login",
        json={"email": "missing@example.com", "password": "Password123"},
    )

    assert blocked.status_code == 429


def test_email_verification_request_and_confirm(client: TestClient, db_session: Session):
    user = User(
        email="verify@example.com",
        password_hash=get_password_hash("Password123"),
        full_name="Verify User",
        role=UserRole.coach,
    )
    db_session.add(user)
    db_session.commit()

    request_response = client.post(
        "/api/v1/auth/email-verification/request",
        json={"email": "verify@example.com"},
    )

    assert request_response.status_code == 200
    verification_token = request_response.json()["verification_token"]
    assert verification_token
    assert db_session.query(EmailVerificationToken).count() == 1

    confirm_response = client.post(
        "/api/v1/auth/email-verification/confirm",
        json={"token": verification_token},
    )

    assert confirm_response.status_code == 200
    db_session.refresh(user)
    assert user.email_verified is True


def test_register_rejects_invalid_phone_number(client: TestClient):
    response = client.post(
        "/api/v1/auth/register",
        json={
            "email": "bad-phone@example.com",
            "password": "Password123",
            "full_name": "Bad Phone",
            "role": "coach",
            "phone": "12345",
        },
    )

    assert response.status_code == 422
