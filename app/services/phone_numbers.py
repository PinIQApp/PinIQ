from __future__ import annotations

import re

from pydantic import field_validator


def normalize_phone_number(phone: str | None) -> str | None:
    if phone is None:
        return None

    trimmed = phone.strip()
    if not trimmed:
        return None

    digits = re.sub(r"\D", "", trimmed)
    if not digits:
        raise ValueError("Phone number must contain digits")
    if len(digits) == 10:
        return f"+1{digits}"
    if len(digits) == 11 and digits.startswith("1"):
        return f"+{digits}"
    if trimmed.startswith("+") and len(digits) >= 8:
        return f"+{digits}"
    raise ValueError("Phone number must be a valid US mobile number")


def has_valid_phone_number(phone: str | None) -> bool:
    try:
        return normalize_phone_number(phone) is not None
    except ValueError:
        return False


def phone_number_field_validator(field_name: str):
    @field_validator(field_name, mode="before")
    @classmethod
    def _validate_phone_number(cls, value: str | None):
        return normalize_phone_number(value)

    return _validate_phone_number
