from fastapi.testclient import TestClient


def test_coach_can_create_update_and_delete_team_workout(
    client: TestClient,
    coach_auth_headers: dict[str, str],
):
    created = client.post(
        "/api/v1/practices",
        headers=coach_auth_headers,
        json={
            "team_id": 1,
            "title": "Monday lift",
            "description": "Controlled weight and clean form.",
            "focus": "Lifting",
            "practice_date": "2026-08-11",
            "blocks": [
                {
                    "block_order": 1,
                    "block_type": "conditioning",
                    "title": "Lifting",
                    "duration_minutes": 40,
                }
            ],
        },
    )

    assert created.status_code == 201
    workout_id = created.json()["id"]
    assert created.json()["total_duration_minutes"] == 40

    updated = client.patch(
        f"/api/v1/practices/{workout_id}",
        headers=coach_auth_headers,
        json={
            "title": "Tuesday lift",
            "practice_date": "2026-08-12",
            "blocks": [
                {
                    "block_order": 1,
                    "block_type": "conditioning",
                    "title": "Lifting",
                    "duration_minutes": 50,
                }
            ],
        },
    )

    assert updated.status_code == 200
    assert updated.json()["title"] == "Tuesday lift"
    assert updated.json()["total_duration_minutes"] == 50

    listed = client.get(
        "/api/v1/practices/team/1",
        headers=coach_auth_headers,
    )
    assert listed.status_code == 200
    assert any(item["id"] == workout_id for item in listed.json())

    deleted = client.delete(
        f"/api/v1/practices/{workout_id}",
        headers=coach_auth_headers,
    )
    assert deleted.status_code == 204

    missing = client.get(
        f"/api/v1/practices/{workout_id}",
        headers=coach_auth_headers,
    )
    assert missing.status_code == 404


def test_non_team_parent_cannot_create_workout(
    client: TestClient,
    coach_auth_headers: dict[str, str],
    outsider_auth_headers: dict[str, str],
):
    response = client.post(
        "/api/v1/practices",
        headers=outsider_auth_headers,
        json={
            "team_id": 1,
            "title": "Unauthorized workout",
            "focus": "Wrestling",
            "practice_date": "2026-08-11",
            "blocks": [],
        },
    )

    assert response.status_code == 403
