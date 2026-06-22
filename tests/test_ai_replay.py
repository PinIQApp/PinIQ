from fastapi.testclient import TestClient


def test_ai_replay_video_upload_returns_beta_analysis(
    client: TestClient,
    coach_auth_headers: dict[str, str],
):
    response = client.post(
        "/api/v1/ai-replay/analyze-video",
        headers=coach_auth_headers,
        files={"file": ("match.mp4", b"not-a-real-video", "video/mp4")},
    )

    assert response.status_code == 200
    body = response.json()
    assert body["status"] == "ready"
    assert body["analysis_mode"] in {"beta_fallback", "openai_vision"}
    assert body["film_source"] == "match.mp4"
    assert body["findings"]
    assert {"right", "wrong", "fix", "drill"}.issubset(body["findings"][0])
    assert body["media_url"].startswith("/media/film/")
