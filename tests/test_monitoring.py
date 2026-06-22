import json

from app.core.config import settings
from app.services import monitoring


def test_build_alert_payload_includes_core_context():
    payload = monitoring._build_alert_payload(
        "unhandled_exception",
        "RuntimeError: boom",
        request_id="req-123",
        metadata={"exception_type": "RuntimeError"},
    )

    assert payload["event_type"] == "unhandled_exception"
    assert payload["summary"] == "RuntimeError: boom"
    assert payload["service"] == settings.app_name
    assert payload["environment"] == settings.environment
    assert payload["request_id"] == "req-123"
    assert payload["metadata"]["exception_type"] == "RuntimeError"
    assert payload["timestamp"]


def test_report_exception_posts_to_webhook(monkeypatch):
    captured = {}

    class DummyResponse:
        status = 202

        def __enter__(self):
            return self

        def __exit__(self, exc_type, exc, tb):
            return False

        def getcode(self):
            return self.status

    def fake_urlopen(request, timeout):
        captured["url"] = request.full_url
        captured["timeout"] = timeout
        captured["headers"] = dict(request.header_items())
        captured["payload"] = json.loads(request.data.decode("utf-8"))
        return DummyResponse()

    monkeypatch.setattr(settings, "monitoring_webhook_url", "https://alerts.example.com/hooks/wrestling")
    monkeypatch.setattr(settings, "monitoring_webhook_timeout_seconds", 9)
    monkeypatch.setattr(monitoring, "urlopen", fake_urlopen)

    monitoring.report_exception(RuntimeError("Mat room offline"), request_id="req-999")

    assert captured["url"] == "https://alerts.example.com/hooks/wrestling"
    assert captured["timeout"] == 9
    assert captured["headers"]["Content-type"] == "application/json"
    assert captured["payload"]["event_type"] == "unhandled_exception"
    assert captured["payload"]["request_id"] == "req-999"
    assert captured["payload"]["metadata"]["exception_type"] == "RuntimeError"
    assert captured["payload"]["summary"] == "RuntimeError: Mat room offline"


def test_report_exception_without_webhook_does_not_send(monkeypatch):
    sent = {"called": False}

    def fake_urlopen(request, timeout):
        sent["called"] = True
        raise AssertionError("urlopen should not be called when monitoring is disabled")

    monkeypatch.setattr(settings, "monitoring_webhook_url", None)
    monkeypatch.setattr(monitoring, "urlopen", fake_urlopen)

    monitoring.report_exception(ValueError("No webhook configured"), request_id="req-555")

    assert sent["called"] is False
