from __future__ import annotations

from app.core.logging import get_logger


logger = get_logger("app.email")


def send_password_reset_email(*, email: str, reset_token: str | None) -> None:
    logger.info(
        "password_reset_email_queued",
        extra={"request_id": "background", "path": "auth.password-reset", "method": "BACKGROUND"},
    )
    if reset_token:
        logger.info(
            "password_reset_token_generated_for_local_delivery",
            extra={"request_id": "background"},
        )


def send_email_verification_email(*, email: str, verification_token: str | None) -> None:
    logger.info(
        "email_verification_email_queued",
        extra={"request_id": "background", "path": "auth.email-verification", "method": "BACKGROUND"},
    )
    if verification_token:
        logger.info(
            "email_verification_token_generated_for_local_delivery",
            extra={"request_id": "background"},
        )
