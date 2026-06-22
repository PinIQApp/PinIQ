from __future__ import annotations

from datetime import datetime

from sqlalchemy.orm import Session

from app.models.user import EmailVerificationToken, PasswordResetToken, RefreshToken


def cleanup_expired_auth_tokens(db: Session) -> dict[str, int]:
    now = datetime.utcnow()

    expired_refresh_count = (
        db.query(RefreshToken)
        .filter((RefreshToken.expires_at <= now) | (RefreshToken.revoked_at.is_not(None)))
        .delete(synchronize_session=False)
    )
    expired_reset_count = (
        db.query(PasswordResetToken)
        .filter((PasswordResetToken.expires_at <= now) | (PasswordResetToken.used_at.is_not(None)))
        .delete(synchronize_session=False)
    )
    expired_verification_count = (
        db.query(EmailVerificationToken)
        .filter((EmailVerificationToken.expires_at <= now) | (EmailVerificationToken.used_at.is_not(None)))
        .delete(synchronize_session=False)
    )

    db.commit()
    return {
        "refresh_tokens_deleted": expired_refresh_count,
        "password_reset_tokens_deleted": expired_reset_count,
        "email_verification_tokens_deleted": expired_verification_count,
    }
