from pathlib import Path

from fastapi.testclient import TestClient


def test_logo_upload_rejects_disallowed_extension(client: TestClient, coach_auth_headers: dict[str, str]):
    response = client.post(
        "/api/v1/uploads/teams/1/logo",
        headers=coach_auth_headers,
        files={"file": ("logo.gif", b"fake-image-content", "image/gif")},
    )

    assert response.status_code == 400
    assert "Unsupported file type" in response.json()["detail"]


def test_logo_upload_rejects_oversized_files(client: TestClient, coach_auth_headers: dict[str, str]):
    response = client.post(
        "/api/v1/uploads/teams/1/logo",
        headers=coach_auth_headers,
        files={"file": ("logo.png", b"x" * 2048, "image/png")},
    )

    assert response.status_code == 413
    assert "File exceeds max upload size" in response.json()["detail"]


def test_logo_upload_saves_valid_file(client: TestClient, coach_auth_headers: dict[str, str]):
    response = client.post(
        "/api/v1/uploads/teams/1/logo",
        headers=coach_auth_headers,
        files={"file": ("logo.png", b"small-image", "image/png")},
    )

    assert response.status_code == 200
    logo_url = response.json()["logo_url"]
    assert logo_url.startswith("/media/team_logos/")

    saved_path = Path(client.app.state.media_dir_override or "").joinpath(logo_url.removeprefix("/media/"))
    assert saved_path.exists()
