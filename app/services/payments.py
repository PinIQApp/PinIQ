from __future__ import annotations

import json
from datetime import datetime
from hashlib import sha256

from fastapi import HTTPException
from sqlalchemy.orm import Session

from app.core.config import settings
from app.models.store import Order, OrderStatus, PaymentProvider, PaymentStatus, PaymentWebhookEvent
from app.schemas.store import CheckoutSessionResponse, PaymentWebhookResponse


def create_checkout_session(
    db: Session,
    *,
    order: Order,
    idempotency_key: str | None = None,
) -> CheckoutSessionResponse:
    if order.payment_status == PaymentStatus.paid:
        return CheckoutSessionResponse(
            order_id=order.id,
            provider=order.payment_provider,
            payment_status=order.payment_status,
            checkout_url=order.payment_checkout_url,
            client_secret=order.payment_client_secret,
            publishable_key=settings.stripe_publishable_key,
        )
    if order.payment_status == PaymentStatus.requires_action and (
        order.payment_checkout_url or order.payment_client_secret or order.payment_reference
    ):
        return CheckoutSessionResponse(
            order_id=order.id,
            provider=order.payment_provider,
            payment_status=order.payment_status,
            checkout_url=order.payment_checkout_url,
            client_secret=order.payment_client_secret,
            publishable_key=settings.stripe_publishable_key if order.payment_provider == PaymentProvider.stripe else None,
        )

    if settings.payment_provider == "stripe":
        return _create_stripe_checkout_session(db, order=order, idempotency_key=idempotency_key)
    return _create_mock_checkout_session(db, order=order)


def process_payment_webhook(
    db: Session,
    *,
    provider: PaymentProvider,
    payload: dict,
    signature: str | None = None,
) -> PaymentWebhookResponse:
    if provider == PaymentProvider.stripe:
        return _process_stripe_webhook(db, payload=payload, signature=signature)
    return _process_mock_webhook(db, payload=payload)


def _create_mock_checkout_session(db: Session, *, order: Order) -> CheckoutSessionResponse:
    order.payment_provider = PaymentProvider.mock
    order.payment_status = PaymentStatus.requires_action
    order.payment_reference = f"mock-order-{order.id}"
    order.payment_checkout_url = f"/mock-checkout/orders/{order.id}"
    order.payment_client_secret = f"mock-secret-{order.id}"
    db.flush()
    return CheckoutSessionResponse(
        order_id=order.id,
        provider=order.payment_provider,
        payment_status=order.payment_status,
        checkout_url=order.payment_checkout_url,
        client_secret=order.payment_client_secret,
    )


def _create_stripe_checkout_session(
    db: Session,
    *,
    order: Order,
    idempotency_key: str | None = None,
) -> CheckoutSessionResponse:
    if not settings.stripe_secret_key or not settings.checkout_success_url or not settings.checkout_cancel_url:
        raise HTTPException(status_code=503, detail="Stripe checkout is not fully configured")

    try:
        import stripe
    except ModuleNotFoundError as exc:
        raise HTTPException(status_code=503, detail="stripe package is required for Stripe payments") from exc

    stripe.api_key = settings.stripe_secret_key
    session = stripe.checkout.Session.create(
        mode="payment",
        success_url=settings.checkout_success_url,
        cancel_url=settings.checkout_cancel_url,
        metadata={"order_id": str(order.id)},
        line_items=[
            {
                "price_data": {
                    "currency": "usd",
                    "product_data": {"name": f"Order #{order.id}"},
                    "unit_amount": int(round(order.total * 100)),
                },
                "quantity": 1,
            }
        ],
        idempotency_key=idempotency_key or f"checkout-session-order-{order.id}",
    )

    order.payment_provider = PaymentProvider.stripe
    order.payment_status = PaymentStatus.requires_action
    order.payment_reference = session.id
    order.payment_checkout_url = session.url
    order.payment_client_secret = getattr(session, "client_secret", None)
    db.flush()

    return CheckoutSessionResponse(
        order_id=order.id,
        provider=order.payment_provider,
        payment_status=order.payment_status,
        checkout_url=order.payment_checkout_url,
        client_secret=order.payment_client_secret,
        publishable_key=settings.stripe_publishable_key,
    )


def _process_mock_webhook(db: Session, *, payload: dict) -> PaymentWebhookResponse:
    event_type = str(payload.get("event_type") or "mock.payment.succeeded")
    order_id = payload.get("order_id")
    payment_status = str(payload.get("payment_status") or "paid")
    if order_id is None:
        raise HTTPException(status_code=400, detail="Mock webhook requires order_id")
    event_id = str(payload.get("event_id") or _build_mock_event_id(payload=payload, event_type=event_type))

    existing = (
        db.query(PaymentWebhookEvent)
        .filter(PaymentWebhookEvent.provider == PaymentProvider.mock, PaymentWebhookEvent.event_id == event_id)
        .first()
    )
    if existing:
        return PaymentWebhookResponse(processed=False, provider=PaymentProvider.mock, event_id=event_id, order_id=existing.order_id)

    order = db.query(Order).filter(Order.id == int(order_id)).first()
    if not order:
        raise HTTPException(status_code=404, detail="Order not found for webhook")

    if payment_status == "paid":
        order.payment_status = PaymentStatus.paid
        order.status = OrderStatus.paid
        order.paid_at = datetime.utcnow()
    elif payment_status == "failed":
        order.payment_status = PaymentStatus.failed

    db.add(
        PaymentWebhookEvent(
            order_id=order.id,
            provider=PaymentProvider.mock,
            event_id=event_id,
            event_type=event_type,
            payload_json=json.dumps(payload, separators=(",", ":"), sort_keys=True),
        )
    )
    db.commit()
    return PaymentWebhookResponse(processed=True, provider=PaymentProvider.mock, event_id=event_id, order_id=order.id)


def _process_stripe_webhook(db: Session, *, payload: dict, signature: str | None) -> PaymentWebhookResponse:
    if not settings.stripe_secret_key or not settings.stripe_webhook_secret:
        raise HTTPException(status_code=503, detail="Stripe webhook is not fully configured")

    try:
        import stripe
    except ModuleNotFoundError as exc:
        raise HTTPException(status_code=503, detail="stripe package is required for Stripe payments") from exc

    stripe.api_key = settings.stripe_secret_key
    if signature is None:
        raise HTTPException(status_code=400, detail="Missing Stripe signature")

    raw_payload = json.dumps(payload)
    try:
        event = stripe.Webhook.construct_event(raw_payload, signature, settings.stripe_webhook_secret)
    except Exception as exc:  # noqa: BLE001
        raise HTTPException(status_code=400, detail="Invalid Stripe webhook signature") from exc

    event_id = event["id"]
    existing = (
        db.query(PaymentWebhookEvent)
        .filter(PaymentWebhookEvent.provider == PaymentProvider.stripe, PaymentWebhookEvent.event_id == event_id)
        .first()
    )
    if existing:
        return PaymentWebhookResponse(processed=False, provider=PaymentProvider.stripe, event_id=event_id, order_id=existing.order_id)

    object_data = event["data"]["object"]
    order_id = object_data.get("metadata", {}).get("order_id")
    order = db.query(Order).filter(Order.id == int(order_id)).first() if order_id else None
    if order is None:
        raise HTTPException(status_code=404, detail="Order not found for Stripe webhook")

    if event["type"] == "checkout.session.completed":
        order.payment_status = PaymentStatus.paid
        order.status = OrderStatus.paid
        order.paid_at = datetime.utcnow()
        order.payment_reference = object_data.get("id")

    db.add(
        PaymentWebhookEvent(
            order_id=order.id,
            provider=PaymentProvider.stripe,
            event_id=event_id,
            event_type=event["type"],
            payload_json=raw_payload,
        )
    )
    db.commit()
    return PaymentWebhookResponse(processed=True, provider=PaymentProvider.stripe, event_id=event_id, order_id=order.id)


def _build_mock_event_id(*, payload: dict, event_type: str) -> str:
    normalized_payload = {
        "event_type": event_type,
        "order_id": payload.get("order_id"),
        "payment_status": str(payload.get("payment_status") or "paid"),
        "payment_reference": payload.get("payment_reference"),
    }
    fingerprint = sha256(json.dumps(normalized_payload, sort_keys=True, separators=(",", ":")).encode("utf-8")).hexdigest()
    return f"mock-{fingerprint}"
