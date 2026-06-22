from __future__ import annotations

from datetime import datetime, timedelta

from fastapi import HTTPException, status
from sqlalchemy import func
from sqlalchemy.orm import Session

from app.models.user import AuthRateLimitEvent


class DatabaseRateLimiter:
    def hit(self, db: Session, key: str, *, limit: int, window_seconds: int) -> None:
        cutoff = datetime.utcnow() - timedelta(seconds=window_seconds)

        db.query(AuthRateLimitEvent).filter(AuthRateLimitEvent.occurred_at < cutoff).delete(
            synchronize_session=False
        )
        current_count = (
            db.query(func.count(AuthRateLimitEvent.id))
            .filter(AuthRateLimitEvent.key == key, AuthRateLimitEvent.occurred_at >= cutoff)
            .scalar()
            or 0
        )

        if current_count >= limit:
            raise HTTPException(
                status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                detail="Too many requests. Please wait and try again.",
            )

        db.add(AuthRateLimitEvent(key=key))
        db.commit()

    def clear(self, db: Session | None = None) -> None:
        if db is None:
            return
        db.query(AuthRateLimitEvent).delete(synchronize_session=False)
        db.commit()


auth_rate_limiter = DatabaseRateLimiter()
