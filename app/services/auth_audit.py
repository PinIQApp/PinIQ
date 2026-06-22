from __future__ import annotations

from app.core.logging import get_logger


logger = get_logger("app.auth_audit")


def log_auth_event(event: str, *, user_id: int | None = None, email: str | None = None, actor_id: int | None = None) -> None:
    logger.info(
        event,
        extra={
            "request_id": "audit",
            "user_id": user_id,
            "email": email,
            "actor_id": actor_id,
        },
    )
