from __future__ import annotations

import hashlib
import hmac
import json
import secrets
import base64
from datetime import datetime, timedelta, timezone
from typing import Any

import bcrypt
from fastapi import HTTPException

from app.core.config import settings


ALGORITHM = "HS256"


class TokenDecodeError(ValueError):
    pass


def _base64url_encode(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).rstrip(b"=").decode("ascii")


def _base64url_decode(data: str) -> bytes:
    padding = "=" * (-len(data) % 4)
    return base64.urlsafe_b64decode(f"{data}{padding}")


def _json_b64(data: dict[str, Any]) -> str:
    payload = json.dumps(data, separators=(",", ":"), sort_keys=True).encode("utf-8")
    return _base64url_encode(payload)


def verify_password(plain_password: str, hashed_password: str) -> bool:
    try:
        return bcrypt.checkpw(
            plain_password.encode("utf-8"),
            hashed_password.encode("utf-8"),
        )
    except ValueError:
        return False


def get_password_hash(password: str) -> str:
    return bcrypt.hashpw(password.encode("utf-8"), bcrypt.gensalt()).decode("utf-8")


def validate_password_strength(password: str) -> str:
    if len(password) < 8:
        raise HTTPException(status_code=400, detail="Password must be at least 8 characters long")
    if password.lower() == password or password.upper() == password or not any(char.isdigit() for char in password):
        raise HTTPException(
            status_code=400,
            detail="Password must include uppercase, lowercase, and numeric characters",
        )
    return password


def generate_opaque_token() -> str:
    return secrets.token_urlsafe(32)


def hash_opaque_token(token: str) -> str:
    return hashlib.sha256(token.encode("utf-8")).hexdigest()


def create_access_token(subject: str | Any, expires_delta: timedelta | None = None) -> str:
    expire = datetime.now(timezone.utc) + (
        expires_delta or timedelta(minutes=settings.access_token_expire_minutes)
    )
    header = {"alg": ALGORITHM, "typ": "JWT"}
    payload = {"exp": int(expire.timestamp()), "sub": str(subject)}
    signing_input = f"{_json_b64(header)}.{_json_b64(payload)}"
    signature = hmac.new(
        settings.secret_key.encode("utf-8"),
        signing_input.encode("ascii"),
        hashlib.sha256,
    ).digest()
    return f"{signing_input}.{_base64url_encode(signature)}"


def decode_access_token(token: str) -> dict[str, Any]:
    try:
        header_segment, payload_segment, signature_segment = token.split(".")
        header = json.loads(_base64url_decode(header_segment))
        payload = json.loads(_base64url_decode(payload_segment))
    except (ValueError, json.JSONDecodeError, UnicodeDecodeError) as exc:
        raise TokenDecodeError("Malformed token") from exc

    if header.get("alg") != ALGORITHM or header.get("typ") != "JWT":
        raise TokenDecodeError("Unsupported token header")

    signing_input = f"{header_segment}.{payload_segment}"
    expected_signature = hmac.new(
        settings.secret_key.encode("utf-8"),
        signing_input.encode("ascii"),
        hashlib.sha256,
    ).digest()
    try:
        supplied_signature = _base64url_decode(signature_segment)
    except ValueError as exc:
        raise TokenDecodeError("Malformed token signature") from exc
    if not hmac.compare_digest(supplied_signature, expected_signature):
        raise TokenDecodeError("Invalid token signature")

    expires_at = payload.get("exp")
    if not isinstance(expires_at, int) or expires_at <= int(datetime.now(timezone.utc).timestamp()):
        raise TokenDecodeError("Token expired")
    return payload
