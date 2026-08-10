from __future__ import annotations

from app.core.logging import get_logger
from app.services.alert_channels import ChannelDeliveryError, send_alert_email


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


def send_athlete_parent_invitation_email(
    *,
    email: str,
    team_name: str,
    athlete_name: str,
    frontend_origin: str,
) -> None:
    try:
        send_alert_email(
            email=email,
            subject=f"Manage {athlete_name} on {team_name} in Pin IQ",
            body=(
                f"{team_name} invited you to manage {athlete_name}'s athlete profile in Pin IQ. "
                f"Open {frontend_origin}, create or sign in to a parent account using {email}, "
                "then review and accept the invitation. Access is not granted until you accept."
            ),
        )
    except ChannelDeliveryError:
        logger.exception(
            "athlete_parent_invitation_email_failed",
            extra={"request_id": "background", "path": "athlete-invitations", "method": "BACKGROUND"},
        )
