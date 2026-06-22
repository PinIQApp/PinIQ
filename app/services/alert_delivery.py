from __future__ import annotations

from dataclasses import dataclass

from sqlalchemy.orm import Session

from app.models.messaging import AlertDelivery, AlertDeliveryChannel, AlertDeliveryStatus
from app.models.user import User, UserPushDevice
from app.services.alert_channels import ChannelDeliveryError, send_alert_email, send_push_alert
from app.services.sms_alerts import SmsDeliveryError, send_sms_message


@dataclass
class AlertDispatchSummary:
    sms_provider: str | None = None
    sms_sent_count: int = 0
    sms_failed_count: int = 0
    email_sent_count: int = 0
    email_failed_count: int = 0
    push_sent_count: int = 0
    push_failed_count: int = 0
    skipped_count: int = 0
    delivered_user_ids: list[int] | None = None
    skipped_user_ids: list[int] | None = None
    skipped_missing_phone_user_ids: list[int] | None = None

    def __post_init__(self) -> None:
        if self.delivered_user_ids is None:
            self.delivered_user_ids = []
        if self.skipped_user_ids is None:
            self.skipped_user_ids = []
        if self.skipped_missing_phone_user_ids is None:
            self.skipped_missing_phone_user_ids = []

    def as_dict(self) -> dict[str, int]:
        return {
            "provider": self.sms_provider,
            "sms_sent_count": self.sms_sent_count,
            "sms_failed_count": self.sms_failed_count,
            "email_sent_count": self.email_sent_count,
            "email_failed_count": self.email_failed_count,
            "push_sent_count": self.push_sent_count,
            "push_failed_count": self.push_failed_count,
            "skipped_count": self.skipped_count,
            "delivered_phone_count": self.sms_sent_count,
            "delivered_user_ids": self.delivered_user_ids,
            "skipped_user_ids": self.skipped_user_ids,
            "skipped_missing_phone_user_ids": self.skipped_missing_phone_user_ids,
        }


def _record_delivery(
    db: Session,
    *,
    team_id: int,
    announcement_id: int | None,
    safety_alert_id: int | None,
    recipient_user_id: int,
    channel: AlertDeliveryChannel,
    provider: str,
    status: AlertDeliveryStatus,
    destination: str | None,
    provider_message_id: str | None = None,
    failure_reason: str | None = None,
    delivery_metadata: dict | None = None,
) -> AlertDelivery:
    delivery = AlertDelivery(
        team_id=team_id,
        announcement_id=announcement_id,
        safety_alert_id=safety_alert_id,
        recipient_user_id=recipient_user_id,
        channel=channel,
        provider=provider,
        status=status,
        destination=destination,
        provider_message_id=provider_message_id,
        failure_reason=failure_reason,
        delivery_metadata=delivery_metadata,
    )
    db.add(delivery)
    db.flush()
    return delivery


def deliver_alert_bundle(
    db: Session,
    *,
    team_id: int,
    users: list[User],
    announcement_id: int | None,
    safety_alert_id: int | None,
    message_title: str,
    message_body: str,
    push_title: str | None = None,
    push_body: str | None = None,
    push_data: dict | None = None,
    initiated_by_user_id: int | None = None,
) -> AlertDispatchSummary:
    summary = AlertDispatchSummary()
    unique_device_users = {user.id: user for user in users}
    device_map: dict[int, list[UserPushDevice]] = {
        user_id: [device for device in user.push_devices if device.push_enabled]
        for user_id, user in unique_device_users.items()
    }

    for user in users:
        if initiated_by_user_id is not None and user.id == initiated_by_user_id:
            summary.skipped_count += 1
            summary.skipped_user_ids.append(user.id)
            _record_delivery(
                db,
                team_id=team_id,
                announcement_id=announcement_id,
                safety_alert_id=safety_alert_id,
                recipient_user_id=user.id,
                channel=AlertDeliveryChannel.sms,
                provider="system",
                status=AlertDeliveryStatus.skipped,
                destination=None,
                failure_reason="Sender excluded from distribution",
            )
            continue

        sms_succeeded = False
        try:
            sms_result = send_sms_message(
                phone_number=user.phone,
                message=message_body,
                team_id=team_id,
                user_id=user.id,
            )
            _record_delivery(
                db,
                team_id=team_id,
                announcement_id=announcement_id,
                safety_alert_id=safety_alert_id,
                recipient_user_id=user.id,
                channel=AlertDeliveryChannel.sms,
                provider=sms_result.provider,
                status=AlertDeliveryStatus.sent,
                destination=sms_result.destination,
                provider_message_id=sms_result.provider_message_id,
            )
            sms_succeeded = True
            summary.sms_provider = sms_result.provider
            summary.sms_sent_count += 1
            summary.delivered_user_ids.append(user.id)
        except SmsDeliveryError as exc:
            failure_reason = str(exc)
            _record_delivery(
                db,
                team_id=team_id,
                announcement_id=announcement_id,
                safety_alert_id=safety_alert_id,
                recipient_user_id=user.id,
                channel=AlertDeliveryChannel.sms,
                provider="twilio" if "twilio" in str(exc).lower() else "sms",
                status=AlertDeliveryStatus.failed,
                destination=user.phone,
                failure_reason=failure_reason,
            )
            summary.sms_failed_count += 1
            if "phone" in failure_reason.casefold():
                summary.skipped_missing_phone_user_ids.append(user.id)

        if sms_succeeded:
            continue

        try:
            email_result = send_alert_email(
                email=user.email,
                subject=message_title,
                body=message_body,
            )
            _record_delivery(
                db,
                team_id=team_id,
                announcement_id=announcement_id,
                safety_alert_id=safety_alert_id,
                recipient_user_id=user.id,
                channel=AlertDeliveryChannel.email,
                provider=email_result.provider,
                status=AlertDeliveryStatus.sent,
                destination=email_result.destination,
                provider_message_id=email_result.provider_message_id,
            )
            summary.email_sent_count += 1
        except ChannelDeliveryError as exc:
            _record_delivery(
                db,
                team_id=team_id,
                announcement_id=announcement_id,
                safety_alert_id=safety_alert_id,
                recipient_user_id=user.id,
                channel=AlertDeliveryChannel.email,
                provider="email",
                status=AlertDeliveryStatus.failed,
                destination=user.email,
                failure_reason=str(exc),
            )
            summary.email_failed_count += 1

        try:
            push_result = send_push_alert(
                devices=device_map.get(user.id, []),
                title=push_title or message_title,
                body=push_body or message_body,
                data=push_data,
            )
            _record_delivery(
                db,
                team_id=team_id,
                announcement_id=announcement_id,
                safety_alert_id=safety_alert_id,
                recipient_user_id=user.id,
                channel=AlertDeliveryChannel.push,
                provider=push_result.provider,
                status=AlertDeliveryStatus.sent,
                destination=push_result.destination,
                provider_message_id=push_result.provider_message_id,
            )
            summary.push_sent_count += 1
        except ChannelDeliveryError as exc:
            _record_delivery(
                db,
                team_id=team_id,
                announcement_id=announcement_id,
                safety_alert_id=safety_alert_id,
                recipient_user_id=user.id,
                channel=AlertDeliveryChannel.push,
                provider="push",
                status=AlertDeliveryStatus.failed,
                destination=None,
                failure_reason=str(exc),
            )
            summary.push_failed_count += 1

    return summary
