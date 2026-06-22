from datetime import datetime, timedelta

from sqlalchemy.orm import Session

from app.core.security import hash_opaque_token
from app.models.user import EmailVerificationToken, PasswordResetToken, RefreshToken, User, UserRole
from app.services.token_cleanup import cleanup_expired_auth_tokens


def test_cleanup_expired_auth_tokens_removes_stale_records(db_session: Session):
    user = User(
        email="cleanup@example.com",
        password_hash="hashed",
        full_name="Cleanup User",
        role=UserRole.coach,
    )
    db_session.add(user)
    db_session.flush()

    db_session.add_all(
        [
            RefreshToken(
                user_id=user.id,
                token_hash=hash_opaque_token("refresh"),
                expires_at=datetime.utcnow() - timedelta(minutes=1),
            ),
            PasswordResetToken(
                user_id=user.id,
                token_hash=hash_opaque_token("reset"),
                expires_at=datetime.utcnow() - timedelta(minutes=1),
            ),
            EmailVerificationToken(
                user_id=user.id,
                token_hash=hash_opaque_token("verify"),
                expires_at=datetime.utcnow() - timedelta(minutes=1),
            ),
        ]
    )
    db_session.commit()

    summary = cleanup_expired_auth_tokens(db_session)

    assert summary["refresh_tokens_deleted"] == 1
    assert summary["password_reset_tokens_deleted"] == 1
    assert summary["email_verification_tokens_deleted"] == 1
