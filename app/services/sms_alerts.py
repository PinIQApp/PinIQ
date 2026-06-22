from __future__ import annotations

from dataclasses import dataclass
from uuid import uuid4

import httpx

from app.core.config import settings
from app.core.logging import get_logger
from app.services.phone_numbers import normalize_phone_number


logger = get_logger("app.sms")


@dataclass
class SmsProviderResult:
    provider: str
    destination: str
    provider_message_id: str | None


class SmsDeliveryError(Exception):
    pass


def _render_text_message(*, team_name: str, title: str, body: str) -> str:
    return f"{team_name}\n{title}\n{body}".strip()


def _send_mock_sms(*, phone_number: str, message: str, team_id: int, user_id: int) -> SmsProviderResult:
    message_id = f"mock-sms-{uuid4().hex}"
    logger.info(
        "mock_sms_alert_sent",
        extra={
            "request_id": "background",
            "path": "messaging.team-text-alert",
            "method": "BACKGROUND",
            "team_id": team_id,
            "recipient_user_id": user_id,
            "recipient_phone": phone_number,
            "message_preview": message[:160],
            "alert_channel": "sms",
            "alert_provider": "mock",
            "alert_delivery_status": "sent",
        },
    )
    return SmsProviderResult(provider="mock", destination=phone_number, provider_message_id=message_id)


def _send_twilio_sms(*, phone_number: str, message: str) -> SmsProviderResult:
    if not settings.twilio_account_sid or not settings.twilio_auth_token or not settings.sms_from_number:
        raise SmsDeliveryError("SMS provider is not configured")

    try:
        response = httpx.post(
            f"https://api.twilio.com/2010-04-01/Accounts/{settings.twilio_account_sid}/Messages.json",
            auth=(settings.twilio_account_sid, settings.twilio_auth_token),
            data={
                "From": settings.sms_from_number,
                "To": phone_number,
                "Body": message,
            },
            timeout=settings.sms_timeout_seconds,
        )
        response.raise_for_status()
        payload = response.json()
        return SmsProviderResult(
            provider="twilio",
            destination=phone_number,
            provider_message_id=payload.get("sid"),
        )
    except httpx.HTTPError as exc:
        raise SmsDeliveryError("Team text alert delivery failed") from exc


def send_sms_message(*, phone_number: str | None, message: str, team_id: int, user_id: int) -> SmsProviderResult:
    try:
        normalized_phone = normalize_phone_number(phone_number)
    except ValueError as exc:
        raise SmsDeliveryError(str(exc)) from exc
    if normalized_phone is None:
        raise SmsDeliveryError("Missing valid phone number")

    if settings.sms_provider == "twilio":
        return _send_twilio_sms(phone_number=normalized_phone, message=message)
    return _send_mock_sms(
        phone_number=normalized_phone,
        message=message,
        team_id=team_id,
        user_id=user_id,
    )


def render_team_text_message(*, team_name: str, title: str, body: str) -> str:
    return _render_text_message(team_name=team_name, title=title, body=body)
