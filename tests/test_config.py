import pytest

from app.core.config import settings, validate_runtime_settings


def test_production_rejects_mock_and_local_providers(monkeypatch):
    monkeypatch.setattr(settings, "environment", "production")
    monkeypatch.setattr(settings, "secret_key", "not-the-default-secret")
    monkeypatch.setattr(settings, "auto_create_schema", False)
    monkeypatch.setattr(settings, "seed_demo_data_on_startup", False)
    monkeypatch.setattr(settings, "database_url", "postgresql+psycopg://user:pass@db:5432/wrestletech")

    with pytest.raises(ValueError, match="STORAGE_PROVIDER"):
        validate_runtime_settings()


def test_production_accepts_configured_live_providers(monkeypatch):
    monkeypatch.setattr(settings, "environment", "production")
    monkeypatch.setattr(settings, "secret_key", "not-the-default-secret")
    monkeypatch.setattr(settings, "auto_create_schema", False)
    monkeypatch.setattr(settings, "seed_demo_data_on_startup", False)
    monkeypatch.setattr(settings, "database_url", "postgresql+psycopg://user:pass@db:5432/wrestletech")
    monkeypatch.setattr(settings, "cors_origins", ["https://app.wrestletech.app"])
    monkeypatch.setattr(settings, "storage_provider", "s3")
    monkeypatch.setattr(settings, "s3_bucket_name", "wrestletech-media")
    monkeypatch.setattr(settings, "s3_region", "us-east-1")
    monkeypatch.setattr(settings, "s3_access_key_id", "access-key")
    monkeypatch.setattr(settings, "s3_secret_access_key", "secret-key")
    monkeypatch.setattr(settings, "s3_public_base_url", "https://cdn.wrestletech.app")
    monkeypatch.setattr(settings, "payment_provider", "stripe")
    monkeypatch.setattr(settings, "stripe_secret_key", "sk_live_example")
    monkeypatch.setattr(settings, "stripe_publishable_key", "pk_live_example")
    monkeypatch.setattr(settings, "stripe_webhook_secret", "whsec_example")
    monkeypatch.setattr(settings, "checkout_success_url", "https://app.wrestletech.app/store/success")
    monkeypatch.setattr(settings, "checkout_cancel_url", "https://app.wrestletech.app/store/cancel")
    monkeypatch.setattr(settings, "email_provider", "postmark")
    monkeypatch.setattr(settings, "postmark_server_token", "postmark-token")
    monkeypatch.setattr(settings, "alert_email_from", "alerts@wrestletech.app")
    monkeypatch.setattr(settings, "sms_provider", "twilio")
    monkeypatch.setattr(settings, "twilio_account_sid", "twilio-sid")
    monkeypatch.setattr(settings, "twilio_auth_token", "twilio-token")
    monkeypatch.setattr(settings, "sms_from_number", "+15550000000")
    monkeypatch.setattr(settings, "push_provider", "webhook")
    monkeypatch.setattr(settings, "push_webhook_url", "https://push.wrestletech.app/send")
    monkeypatch.setattr(settings, "nutrition_provider", "fitchef")
    monkeypatch.setattr(settings, "fitchef_api_base", "https://api.fitchef.example")
    monkeypatch.setattr(settings, "fitchef_api_key", "fitchef-key")

    validate_runtime_settings()
