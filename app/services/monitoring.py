from __future__ import annotations

import json
from datetime import datetime, timezone
from typing import Any, Optional
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen

from app.core.config import settings
from app.core.logging import get_logger


logger = get_logger("app.monitoring")


def _build_alert_payload(
    event_type: str,
    summary: str,
    *,
    request_id: Optional[str] = None,
    metadata: Optional[dict[str, Any]] = None,
) -> dict[str, Any]:
    payload: dict[str, Any] = {
        "event_type": event_type,
        "summary": summary,
        "service": settings.app_name,
        "environment": settings.environment,
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "metadata": metadata or {},
    }
    if request_id is not None:
        payload["request_id"] = request_id
    return payload


def _send_alert(payload: dict[str, Any]) -> bool:
    if not settings.monitoring_webhook_url:
        return False

    request = Request(
        settings.monitoring_webhook_url,
        data=json.dumps(payload).encode("utf-8"),
        headers={
            "Content-Type": "application/json",
            "User-Agent": f"{settings.app_name}/monitoring",
        },
        method="POST",
    )

    try:
        with urlopen(request, timeout=settings.monitoring_webhook_timeout_seconds) as response:
            status_code = getattr(response, "status", response.getcode())
    except (HTTPError, URLError, OSError, TimeoutError) as exc:
        logger.error(
            "monitoring_alert_send_failed",
            exc_info=exc,
            extra={
                "request_id": payload.get("request_id"),
                "monitoring_event_type": payload.get("event_type"),
            },
        )
        return False

    logger.info(
        "monitoring_alert_sent",
        extra={
            "request_id": payload.get("request_id"),
            "monitoring_event_type": payload.get("event_type"),
            "monitoring_status_code": status_code,
        },
    )
    return True


def report_exception(exc: Exception, *, request_id: Optional[str] = None) -> None:
    payload = _build_alert_payload(
        "unhandled_exception",
        f"{type(exc).__name__}: {exc}",
        request_id=request_id,
        metadata={
            "exception_type": type(exc).__name__,
        },
    )
    _send_alert(payload)

    logger.error(
        "captured_unhandled_exception",
        exc_info=exc,
        extra={
            "request_id": request_id,
            "monitoring_event_type": "unhandled_exception",
        },
    )
