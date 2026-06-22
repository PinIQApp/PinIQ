from __future__ import annotations

import json
from typing import Annotated, List, Literal, Optional, Union

from pydantic import Field, field_validator
from pydantic_settings import BaseSettings, NoDecode, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    environment: Literal["local", "staging", "production", "test"] = "local"
    app_name: str = "Pin IQ API"
    api_v1_str: str = "/api/v1"
    secret_key: str = "change-me"
    access_token_expire_minutes: int = 60 * 24 * 7
    refresh_token_expire_minutes: int = 60 * 24 * 30
    database_url: str = "sqlite:///./wrestling_os.db"
    frontend_origin: str = "http://localhost:3000"
    cors_origins: Annotated[List[str], NoDecode] = Field(
        default_factory=lambda: [
            "http://localhost:3000",
            "http://127.0.0.1:3000",
            "http://localhost:8000",
            "http://127.0.0.1:8000",
            "http://127.0.0.1:8082",
        ]
    )
    media_dir: str = "media"
    auto_create_schema: bool = False
    seed_demo_data_on_startup: bool = True
    max_upload_size_bytes: int = 5 * 1024 * 1024
    max_video_upload_size_bytes: int = 250 * 1024 * 1024
    allowed_image_extensions: Annotated[List[str], NoDecode] = Field(default_factory=lambda: [".png", ".jpg", ".jpeg", ".webp"])
    allowed_video_extensions: Annotated[List[str], NoDecode] = Field(default_factory=lambda: [".mp4", ".mov", ".m4v", ".webm"])
    openai_api_key: Optional[str] = None
    openai_vision_model: str = "gpt-4o-mini"
    film_study_frame_count: int = 8
    film_study_frame_interval_seconds: int = 12
    auth_rate_limit_attempts: int = 10
    auth_rate_limit_window_seconds: int = 300
    password_reset_token_expire_minutes: int = 30
    log_level: str = "INFO"
    enable_json_logs: bool = True
    monitoring_webhook_url: Optional[str] = None
    monitoring_webhook_timeout_seconds: int = 5
    sms_provider: Literal["mock", "twilio"] = "mock"
    sms_from_number: Optional[str] = None
    sms_timeout_seconds: int = 5
    twilio_account_sid: Optional[str] = None
    twilio_auth_token: Optional[str] = None
    email_provider: Literal["mock", "postmark"] = "mock"
    alert_email_from: Optional[str] = None
    email_timeout_seconds: int = 5
    postmark_server_token: Optional[str] = None
    push_provider: Literal["mock", "webhook"] = "mock"
    push_webhook_url: Optional[str] = None
    push_webhook_secret: Optional[str] = None
    push_timeout_seconds: int = 5
    default_page_size: int = 25
    max_page_size: int = 100
    storage_provider: Literal["local", "s3"] = "local"
    media_base_url: str = "/media"
    s3_bucket_name: Optional[str] = None
    s3_region: Optional[str] = None
    s3_endpoint_url: Optional[str] = None
    s3_access_key_id: Optional[str] = None
    s3_secret_access_key: Optional[str] = None
    s3_public_base_url: Optional[str] = None
    payment_provider: Literal["mock", "stripe"] = "mock"
    stripe_secret_key: Optional[str] = None
    stripe_publishable_key: Optional[str] = None
    stripe_webhook_secret: Optional[str] = None
    checkout_success_url: Optional[str] = None
    checkout_cancel_url: Optional[str] = None

    nutrition_provider: str = "mock"
    fitchef_api_base: Optional[str] = None
    fitchef_api_key: Optional[str] = None
    fitchef_callback_secret: Optional[str] = None

    passio_api_base: Optional[str] = None
    passio_api_key: Optional[str] = None

    enable_strict_wrestler_safety: bool = True
    tournament_scan_timeout_seconds: int = 15
    tournament_scan_user_agent: str = "PinIQTournamentScanner/1.0"
    flo_events_url: str = "https://www.flowrestling.org/results"
    track_events_url: Optional[str] = "https://www.trackwrestling.com/Login.jsp?state=43"
    usa_bracketing_events_url: Optional[str] = "https://www.usawmembership.com/usaw_results"

    @field_validator("cors_origins", mode="before")
    @classmethod
    def parse_cors_origins(cls, value: Optional[Union[str, List[str]]]) -> List[str]:
        if value is None:
            return ["http://localhost:3000"]
        if isinstance(value, str):
            if value.strip().startswith("["):
                try:
                    decoded = json.loads(value)
                except json.JSONDecodeError:
                    decoded = None
                if isinstance(decoded, list):
                    return [str(item).strip() for item in decoded if str(item).strip()]
            parsed = [item.strip() for item in value.split(",") if item.strip()]
            return parsed or ["http://localhost:3000"]
        return [item.strip() for item in value if item.strip()]

    @field_validator("allowed_image_extensions", mode="before")
    @classmethod
    def parse_allowed_image_extensions(cls, value: Optional[Union[str, List[str]]]) -> List[str]:
        if value is None:
            return [".png", ".jpg", ".jpeg", ".webp"]
        if isinstance(value, str):
            if value.strip().startswith("["):
                try:
                    decoded = json.loads(value)
                except json.JSONDecodeError:
                    decoded = None
                if isinstance(decoded, list):
                    value = decoded
                else:
                    value = value.split(",")
            if isinstance(value, str):
                parts = [item.strip().lower() for item in value.split(",") if item.strip()]
            else:
                parts = [str(item).strip().lower() for item in value if str(item).strip()]
        else:
            parts = [item.strip().lower() for item in value if item.strip()]
        normalized = []
        for part in parts:
            normalized.append(part if part.startswith(".") else f".{part}")
        return normalized or [".png", ".jpg", ".jpeg", ".webp"]

    @field_validator("allowed_video_extensions", mode="before")
    @classmethod
    def parse_allowed_video_extensions(cls, value: Optional[Union[str, List[str]]]) -> List[str]:
        if value is None:
            return [".mp4", ".mov", ".m4v", ".webm"]
        if isinstance(value, str):
            if value.strip().startswith("["):
                try:
                    decoded = json.loads(value)
                except json.JSONDecodeError:
                    decoded = None
                if isinstance(decoded, list):
                    value = decoded
                else:
                    value = value.split(",")
            if isinstance(value, str):
                parts = [item.strip().lower() for item in value.split(",") if item.strip()]
            else:
                parts = [str(item).strip().lower() for item in value if str(item).strip()]
        else:
            parts = [item.strip().lower() for item in value if item.strip()]
        normalized = []
        for part in parts:
            normalized.append(part if part.startswith(".") else f".{part}")
        return normalized or [".mp4", ".mov", ".m4v", ".webm"]


settings = Settings()


def validate_runtime_settings() -> None:
    if settings.environment == "production":
        if settings.secret_key == "change-me":
            raise ValueError("SECRET_KEY must be changed in production")
        if settings.auto_create_schema:
            raise ValueError("AUTO_CREATE_SCHEMA must be false in production")
        if settings.seed_demo_data_on_startup:
            raise ValueError("SEED_DEMO_DATA_ON_STARTUP must be false in production")
        if settings.database_url.startswith("sqlite"):
            raise ValueError("DATABASE_URL must not use SQLite in production")
        if any(origin == "*" for origin in settings.cors_origins):
            raise ValueError("CORS_ORIGINS must not contain '*' in production")
        if settings.storage_provider != "s3":
            raise ValueError("STORAGE_PROVIDER must be s3 in production")
        if not settings.s3_bucket_name or not settings.s3_region or not settings.s3_public_base_url:
            raise ValueError("S3_BUCKET_NAME, S3_REGION, and S3_PUBLIC_BASE_URL are required in production")
        if not settings.s3_access_key_id or not settings.s3_secret_access_key:
            raise ValueError("S3_ACCESS_KEY_ID and S3_SECRET_ACCESS_KEY are required in production")
        if settings.payment_provider != "stripe":
            raise ValueError("PAYMENT_PROVIDER must be stripe in production")
        if not settings.stripe_secret_key or not settings.stripe_publishable_key or not settings.stripe_webhook_secret:
            raise ValueError("Stripe secret, publishable, and webhook keys are required in production")
        if not settings.checkout_success_url or not settings.checkout_cancel_url:
            raise ValueError("Checkout success and cancel URLs are required in production")
        if settings.email_provider != "postmark":
            raise ValueError("EMAIL_PROVIDER must be postmark in production")
        if not settings.postmark_server_token or not settings.alert_email_from:
            raise ValueError("Postmark token and alert sender are required in production")
        if settings.sms_provider != "twilio":
            raise ValueError("SMS_PROVIDER must be twilio in production")
        if not settings.twilio_account_sid or not settings.twilio_auth_token or not settings.sms_from_number:
            raise ValueError("Twilio SID, auth token, and from number are required in production")
        if settings.push_provider != "webhook":
            raise ValueError("PUSH_PROVIDER must be webhook in production")
        if not settings.push_webhook_url:
            raise ValueError("PUSH_WEBHOOK_URL is required in production")
        if settings.nutrition_provider.lower() != "fitchef":
            raise ValueError("NUTRITION_PROVIDER must be fitchef in production")
        if not settings.fitchef_api_base or not settings.fitchef_api_key:
            raise ValueError("FitChef API base and key are required in production")
