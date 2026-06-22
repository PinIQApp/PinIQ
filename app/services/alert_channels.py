from __future__ import annotations

from dataclasses import dataclass
from uuid import uuid4

import httpx

from app.core.config import settings
from app.core.logging import get_logger
from app.models.user import UserPushDevice


logger = get_logger("app.alert_channels")


@dataclass
class ChannelDeliveryResult:
    provider: str
    destination: str
    provider_message_id: str | None


class ChannelDeliveryError(Exception):
    pass


def send_alert_email(*, email: str, subject: str, body: str) -> ChannelDeliveryResult:
    if settings.email_provider == "postmark":
        if not settings.postmark_server_token or not settings.alert_email_from:
            raise ChannelDeliveryError("Email provider is not configured")
        try:
            response = httpx.post(
                "https://api.postmarkapp.com/email",
                headers={
                    "Accept": "application/json",
                    "Content-Type": "application/json",
                    "X-Postmark-Server-Token": settings.postmark_server_token,
                },
                json={
                    "From": settings.alert_email_from,
                    "To": email,
                    "Subject": subject,
                    "TextBody": body,
                },
                timeout=settings.email_timeout_seconds,
            )
            response.raise_for_status()
            payload = response.json()
            return ChannelDeliveryResult(
                provider="postmark",
                destination=email,
                provider_message_id=str(payload.get("MessageID") or ""),
            )
        except httpx.HTTPError as exc:
            raise ChannelDeliveryError("Email alert delivery failed") from exc

    message_id = f"mock-email-{uuid4().hex}"
    logger.info(
        "mock_email_alert_sent",
        extra={
            "request_id": "background",
            "path": "messaging.alert-email",
            "method": "BACKGROUND",
            "alert_channel": "email",
            "alert_provider": "mock",
            "alert_delivery_status": "sent",
            "recipient_email": email,
            "subject": subject,
        },
    )
    return ChannelDeliveryResult(provider="mock", destination=email, provider_message_id=message_id)


def send_push_alert(*, devices: list[UserPushDevice], title: str, body: str, data: dict | None = None) -> ChannelDeliveryResult:
    if not devices:
        raise ChannelDeliveryError("No push devices are registered")

    device_tokens = [device.device_token for device in devices if device.push_enabled]
    if not device_tokens:
        raise ChannelDeliveryError("No enabled push devices are registered")

    if settings.push_provider == "webhook":
        if not settings.push_webhook_url:
            raise ChannelDeliveryError("Push provider is not configured")
        headers = {"Content-Type": "application/json"}
        if settings.push_webhook_secret:
            headers["X-Push-Webhook-Secret"] = settings.push_webhook_secret
        try:
            response = httpx.post(
                settings.push_webhook_url,
                headers=headers,
                json={
                    "tokens": device_tokens,
                    "title": title,
                    "body": body,
                    "data": data or {},
                },
                timeout=settings.push_timeout_seconds,
            )
            response.raise_for_status()
            payload = response.json() if response.content else {}
            return ChannelDeliveryResult(
                provider="webhook",
                destination=",".join(device_tokens),
                provider_message_id=str(payload.get("message_id") or ""),
            )
        except httpx.HTTPError as exc:
            raise ChannelDeliveryError("Push alert delivery failed") from exc

    message_id = f"mock-push-{uuid4().hex}"
    logger.info(
        "mock_push_alert_sent",
        extra={
            "request_id": "background",
            "path": "messaging.alert-push",
            "method": "BACKGROUND",
            "alert_channel": "push",
            "alert_provider": "mock",
            "alert_delivery_status": "sent",
            "device_count": len(device_tokens),
            "title": title,
        },
    )
    return ChannelDeliveryResult(
        provider="mock",
        destination=",".join(device_tokens),
        provider_message_id=message_id,
    )
