#!/usr/bin/env python3
from __future__ import annotations

import os
from pathlib import Path
import sys

PROJECT_ROOT = Path(__file__).resolve().parents[1]
if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))

from pydantic_settings import SettingsConfigDict

from app.core.config import Settings, validate_runtime_settings


PRODUCTION_REQUIRED_REAL_VALUES = {
    "secret_key": ("replace", "change-me"),
    "database_url": ("replace",),
    "postgres_password": ("replace",),
    "frontend_origin": ("yourdomain.com",),
    "cors_origins": ("yourdomain.com",),
    "sms_from_number": ("replace",),
    "twilio_account_sid": ("replace",),
    "twilio_auth_token": ("replace",),
    "alert_email_from": ("yourdomain.com",),
    "postmark_server_token": ("replace",),
    "push_webhook_url": ("example.com",),
    "push_webhook_secret": ("replace",),
    "media_base_url": ("yourdomain.com",),
    "s3_bucket_name": ("replace",),
    "s3_access_key_id": ("replace",),
    "s3_secret_access_key": ("replace",),
    "s3_public_base_url": ("yourdomain.com",),
    "stripe_secret_key": ("replace",),
    "stripe_publishable_key": ("replace",),
    "stripe_webhook_secret": ("replace",),
    "checkout_success_url": ("yourdomain.com",),
    "checkout_cancel_url": ("yourdomain.com",),
    "fitchef_api_base": ("example.com",),
    "fitchef_api_key": ("replace",),
}

BETA_REQUIRED_REAL_VALUES = {
    "secret_key": ("replace", "change-me"),
    "database_url": ("replace",),
    "frontend_origin": ("yourdomain.com", "replace"),
    "cors_origins": ("yourdomain.com", "replace"),
}


def _env_values(env_path: Path) -> dict[str, str]:
    values: dict[str, str] = {}
    for raw_line in env_path.read_text().splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        values[key.strip().lower()] = value.strip().strip('"').strip("'")
    return values


def _reject_placeholders(env_path: Path) -> None:
    values = _env_values(env_path)
    environment = values.get("environment", "").lower()
    required_values = (
        BETA_REQUIRED_REAL_VALUES
        if environment == "staging"
        else PRODUCTION_REQUIRED_REAL_VALUES
    )
    errors: list[str] = []
    for key, blocked_tokens in required_values.items():
        value = values.get(key, "")
        lowered = value.lower()
        if not value:
            errors.append(f"{key.upper()} is empty")
            continue
        if any(token in lowered for token in blocked_tokens):
            errors.append(f"{key.upper()} still contains a placeholder value")

    if errors:
        joined = "\n- ".join(errors)
        label = "Beta" if environment == "staging" else "Production"
        raise SystemExit(f"{label} environment is not ready:\n- {joined}")


def main() -> None:
    env_path = Path(os.environ.get("PRODUCTION_ENV_FILE", ".env.production"))
    if not env_path.exists():
        raise SystemExit(f"Missing {env_path}. Copy .env.production.example and fill in real values.")
    _reject_placeholders(env_path)

    original_config = Settings.model_config
    Settings.model_config = SettingsConfigDict(env_file=str(env_path), env_file_encoding="utf-8", extra="ignore")
    try:
        production_settings = Settings()
    finally:
        Settings.model_config = original_config

    from app.core import config

    original_settings = config.settings
    config.settings = production_settings
    try:
        validate_runtime_settings()
    finally:
        config.settings = original_settings

    print(f"{production_settings.environment.title()} environment validates.")


if __name__ == "__main__":
    main()
