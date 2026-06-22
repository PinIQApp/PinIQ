from fastapi.testclient import TestClient

from app.models.tournament import TournamentSourceType
from app.schemas.tournament import TournamentScanIngestItem
from app.services.tournament_source_scanners import TournamentSourceScanResult


def test_manual_tournament_create_is_discoverable(
    client: TestClient,
    coach_auth_headers: dict[str, str],
):
    response = client.post(
        "/api/v1/tournaments/manual",
        headers=coach_auth_headers,
        json={
            "team_id": 1,
            "name": "Manual Bluegrass Open",
            "start_date": "2026-07-18",
            "end_date": "2026-07-18",
            "location_name": "Central High",
            "city": "Lexington",
            "state": "KY",
            "age_divisions": ["High School"],
            "weight_classes": [],
            "event_type": "folkstyle",
            "registration_link": "https://example.com/register",
            "event_page_link": "https://example.com/event",
            "description": "Coach-entered event",
            "cost": "$25",
            "notes": "Manual add from Tournament Center.",
        },
    )

    assert response.status_code == 201
    body = response.json()
    assert body["tournament"]["name"] == "Manual Bluegrass Open"
    assert body["tournament"]["is_saved"] is True

    discover = client.get(
        "/api/v1/tournaments/discover?team_id=1&search=Bluegrass",
        headers=coach_auth_headers,
    )
    assert discover.status_code == 200
    assert any(
        item["name"] == "Manual Bluegrass Open"
        for item in discover.json()["tournaments"]
    )


def test_live_scan_filters_state_division_and_style(
    client: TestClient,
    coach_auth_headers: dict[str, str],
    monkeypatch,
):
    class DummyScanner:
        def fetch(self, *, search=None):
            return TournamentSourceScanResult(
                source_key=TournamentSourceType.track,
                query_snapshot={"search": search},
                items=[
                    TournamentScanIngestItem(
                        external_id="ky-girls-free",
                        name="Kentucky Girls Freestyle Open",
                        start_date="2026-07-18",
                        end_date="2026-07-18",
                        city="Lexington",
                        state="KY",
                        age_divisions=["High School Girls"],
                        weight_classes=[],
                        event_type="freestyle",
                    ),
                    TournamentScanIngestItem(
                        external_id="ky-coed-folk",
                        name="Kentucky Coed Folkstyle Classic",
                        start_date="2026-07-19",
                        end_date="2026-07-19",
                        city="Louisville",
                        state="KY",
                        age_divisions=["High School"],
                        weight_classes=[],
                        event_type="folkstyle",
                    ),
                    TournamentScanIngestItem(
                        external_id="oh-girls-free",
                        name="Ohio Girls Freestyle Open",
                        start_date="2026-07-20",
                        end_date="2026-07-20",
                        city="Cincinnati",
                        state="OH",
                        age_divisions=["High School Girls"],
                        weight_classes=[],
                        event_type="freestyle",
                    ),
                ],
            )

    monkeypatch.setattr(
        "app.services.tournament_service.scanner_for_source",
        lambda source_key: DummyScanner(),
    )

    response = client.post(
        "/api/v1/tournaments/scan-runs/live",
        headers=coach_auth_headers,
        json={
            "source_key": "track",
            "state": "KY",
            "division": "girls",
            "style": "freestyle",
        },
    )

    assert response.status_code == 201
    body = response.json()
    assert body["items_seen_count"] == 1
    assert body["items_created_count"] == 1
    assert body["query_snapshot"]["state"] == "KY"
    assert body["query_snapshot"]["division"] == "girls"
    assert body["query_snapshot"]["style"] == "freestyle"

    discover = client.get(
        "/api/v1/tournaments/discover?team_id=1",
        headers=coach_auth_headers,
    )
    assert discover.status_code == 200
    names = [item["name"] for item in discover.json()["tournaments"]]
    assert "Kentucky Girls Freestyle Open" in names
    assert "Kentucky Coed Folkstyle Classic" not in names
    assert "Ohio Girls Freestyle Open" not in names


def test_tournament_scan_ingest_creates_discoverable_tournament(
    client: TestClient,
    coach_auth_headers: dict[str, str],
):
    response = client.post(
        "/api/v1/tournaments/scan-runs/ingest",
        headers=coach_auth_headers,
        json={
            "source_key": "track",
            "notes": "Nightly import",
            "query_snapshot": {"state": "KY"},
            "items": [
                {
                    "external_id": "track-1001",
                    "name": "Bluegrass Brawl",
                    "start_date": "2026-12-05",
                    "end_date": "2026-12-06",
                    "location_name": "Central High",
                    "city": "Louisa",
                    "state": "KY",
                    "age_divisions": ["High School Girls"],
                    "weight_classes": ["114", "120"],
                    "event_type": "Tournament",
                    "registration_link": "https://example.com/register",
                    "event_page_link": "https://example.com/event",
                    "contact_name": "Coach Blue",
                    "contact_email": "blue@example.com",
                    "description": "Regional event",
                    "cost": "$250",
                }
            ],
        },
    )

    assert response.status_code == 201
    body = response.json()
    assert body["items_created_count"] == 1
    assert body["items_updated_count"] == 0
    assert body["status"] == "completed"

    discover = client.get("/api/v1/tournaments/discover?team_id=1", headers=coach_auth_headers)
    assert discover.status_code == 200
    assert any(item["name"] == "Bluegrass Brawl" for item in discover.json()["tournaments"])

    changes = client.get("/api/v1/tournaments/change-log", headers=coach_auth_headers)
    assert changes.status_code == 200
    assert changes.json()[0]["change_type"] == "created"


def test_tournament_ingest_merges_cross_source_and_allows_alert_subscription(
    client: TestClient,
    coach_auth_headers: dict[str, str],
):
    first = client.post(
        "/api/v1/tournaments/scan-runs/ingest",
        headers=coach_auth_headers,
        json={
            "source_key": "track",
            "items": [
                {
                    "external_id": "track-2001",
                    "name": "Cardinal Clash",
                    "start_date": "2026-11-20",
                    "end_date": "2026-11-21",
                    "city": "Inez",
                    "state": "KY",
                    "age_divisions": ["High School"],
                    "weight_classes": ["126"],
                    "event_type": "Tournament",
                }
            ],
        },
    )
    assert first.status_code == 201

    second = client.post(
        "/api/v1/tournaments/scan-runs/ingest",
        headers=coach_auth_headers,
        json={
            "source_key": "flo",
            "items": [
                {
                    "external_id": "flo-9001",
                    "name": "Cardinal Clash",
                    "start_date": "2026-11-20",
                    "end_date": "2026-11-21",
                    "city": "Inez",
                    "state": "KY",
                    "age_divisions": ["High School"],
                    "weight_classes": ["126", "132"],
                    "event_type": "Tournament",
                    "deadline": "2026-11-10",
                }
            ],
        },
    )
    assert second.status_code == 201
    assert second.json()["items_merged_count"] == 1

    discover = client.get("/api/v1/tournaments/discover?team_id=1", headers=coach_auth_headers)
    tournament = next(item for item in discover.json()["tournaments"] if item["name"] == "Cardinal Clash")

    subscribe = client.post(
        "/api/v1/tournaments/alerts",
        headers=coach_auth_headers,
        json={
            "team_id": 1,
            "tournament_external_id": tournament["id"],
            "alert_type": "deadline_reminder",
            "channel": "in_app",
            "is_enabled": True,
        },
    )
    assert subscribe.status_code == 201
    assert subscribe.json()["alert_type"] == "deadline_reminder"

    alerts = client.get(
        f"/api/v1/tournaments/alerts?team_id=1&tournament_external_id={tournament['id']}",
        headers=coach_auth_headers,
    )
    assert alerts.status_code == 200
    assert len(alerts.json()) == 1
