from __future__ import annotations

from app.core.config import settings


def normalize_pagination(*, limit: int | None, offset: int | None) -> tuple[int, int]:
    resolved_limit = settings.default_page_size if limit is None else limit
    resolved_limit = max(1, min(resolved_limit, settings.max_page_size))
    resolved_offset = 0 if offset is None else max(0, offset)
    return resolved_limit, resolved_offset
