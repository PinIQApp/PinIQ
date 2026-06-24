from types import SimpleNamespace

from app.schemas.recruiting import RecruitingSourceLinksUpsert, RecruitingSourceScanRequest, RecruitingSourceLink
from app.services import recruiting_source_scanners
from app.services.recruiting_service import (
    _source_rankings,
    run_saved_recruiting_source_scans,
    save_recruiting_source_links,
    scan_recruiting_sources,
)


def test_public_recruiting_scan_extracts_kentuckymat_athlete_and_school_rows(monkeypatch):
    html = """
    <html>
      <body>
        <table>
          <tr><td>Jordan Blake Martin County 132 36-4 State Rank #2 2026</td></tr>
          <tr><td>Martin County KY State Rank #5 National Rank #41 2026</td></tr>
        </table>
      </body>
    </html>
    """
    monkeypatch.setattr(recruiting_source_scanners, "_fetch_html", lambda url: html)

    result = recruiting_source_scanners.scan_public_recruiting_source(
        source="KentuckyMat",
        url="https://kentuckymat.com/rankings",
        athlete_name="Jordan Blake",
        school_name="Martin County",
        state="KY",
    )

    assert result.source == "KentuckyMat"
    assert len(result.source_rankings) == 1
    assert result.source_rankings[0].record == "36-4"
    assert result.source_rankings[0].ranking == "#2"
    assert result.source_rankings[0].weight_class == "132"
    assert len(result.school_rankings) == 1
    assert result.school_rankings[0].state_rank == 5
    assert result.school_rankings[0].national_rank == 41


def test_recruiting_scan_does_not_invent_rankings_when_name_missing(monkeypatch):
    monkeypatch.setattr(
        recruiting_source_scanners,
        "_fetch_html",
        lambda url: "<p>Someone Else 120 24-2 Rank #1</p>",
    )

    result = recruiting_source_scanners.scan_public_recruiting_source(
        source="TrackWrestling",
        url="https://www.trackwrestling.com/membership/MemberRankings.jsp",
        athlete_name="Jordan Blake",
    )

    assert result.source_rankings == []
    assert result.school_rankings == []


def test_source_rankings_normalize_real_supported_sources():
    profile = SimpleNamespace(
        school_team="Martin County",
        stats_summary={
            "source_rankings": [
                {"source": "flow wrestling", "ranking": "#8", "profile_url": "https://www.flowrestling.org/rankings"},
                {"source": "track wrestling", "record": "28-5", "profile_url": "https://www.trackwrestling.com/profile"},
                {"source": "kentucky mat", "ranking": "#2", "profile_url": "https://kentuckymat.com"},
                {"source": "made up", "ranking": "#1"},
            ]
        },
    )

    rankings = _source_rankings(profile)

    assert [item.source for item in rankings] == ["FloWrestling", "TrackWrestling", "KentuckyMat"]


def test_scan_recruiting_sources_can_update_existing_profile(client, db_session, coach_auth_headers, monkeypatch):
    from app.core.security import get_password_hash
    from app.models.recruiting import RecruitingProfile, RecruitingVisibility
    from app.models.user import User, UserRole

    athlete = User(
        email="athlete@example.com",
        password_hash=get_password_hash("Password123"),
        full_name="Jordan Blake",
        role=UserRole.athlete,
    )
    db_session.add(athlete)
    db_session.flush()
    profile = RecruitingProfile(
        athlete_id=athlete.id,
        graduation_year=2027,
        school_team="Martin County",
        weight_class="132",
        stats_summary={},
    )
    db_session.add(profile)
    db_session.flush()
    db_session.add(RecruitingVisibility(profile_id=profile.id))
    db_session.commit()

    monkeypatch.setattr(
        "app.services.recruiting_service.scan_public_recruiting_source",
        lambda **kwargs: recruiting_source_scanners.RecruitingSourceScanResult(
            source="KentuckyMat",
            url=kwargs["url"],
            source_rankings=[
                recruiting_source_scanners.RecruitingSourceRankingRead(
                    source="KentuckyMat",
                    record="36-4",
                    ranking="#2",
                    weight_class="132",
                    profile_url=kwargs["url"],
                )
            ],
            school_rankings=[
                recruiting_source_scanners.RecruitingSchoolRankingRead(
                    source="KentuckyMat",
                    school_name="Martin County",
                    state="KY",
                    state_rank=5,
                    national_rank=41,
                    profile_url=kwargs["url"],
                )
            ],
        ),
    )

    payload = RecruitingSourceScanRequest(
        athlete_id=athlete.id,
        update_profile=True,
        source_links=[RecruitingSourceLink(source="KentuckyMat", url="https://kentuckymat.com/rankings")],
    )
    user = db_session.query(User).filter(User.email == "coach@example.com").one()

    result = scan_recruiting_sources(db_session, payload=payload, current_user=user)

    db_session.refresh(profile)
    assert result.updated_profile is True
    assert profile.stats_summary["source_rankings"][0]["record"] == "36-4"
    assert profile.stats_summary["school_rankings"][0]["state_rank"] == 5


def test_saved_recruiting_source_scan_updates_profiles_with_saved_links(client, db_session, coach_auth_headers, monkeypatch):
    from app.core.security import get_password_hash
    from app.models.recruiting import RecruitingProfile, RecruitingVisibility
    from app.models.user import User, UserRole

    athlete = User(
        email="saved-athlete@example.com",
        password_hash=get_password_hash("Password123"),
        full_name="Jordan Blake",
        role=UserRole.athlete,
    )
    db_session.add(athlete)
    db_session.flush()
    profile = RecruitingProfile(
        athlete_id=athlete.id,
        graduation_year=2027,
        school_team="Martin County",
        weight_class="132",
        location_label="KY",
        stats_summary={},
    )
    db_session.add(profile)
    db_session.flush()
    db_session.add(RecruitingVisibility(profile_id=profile.id))
    db_session.commit()

    coach = db_session.query(User).filter(User.email == "coach@example.com").one()
    save_recruiting_source_links(
        db_session,
        athlete_id=athlete.id,
        payload=RecruitingSourceLinksUpsert(
            source_links=[
                RecruitingSourceLink(source="KentuckyMat", url="https://kentuckymat.com/rankings"),
            ]
        ),
        current_user=athlete,
    )
    db_session.commit()

    monkeypatch.setattr(
        "app.services.recruiting_service.scan_public_recruiting_source",
        lambda **kwargs: recruiting_source_scanners.RecruitingSourceScanResult(
            source="KentuckyMat",
            url=kwargs["url"],
            source_rankings=[
                recruiting_source_scanners.RecruitingSourceRankingRead(
                    source="KentuckyMat",
                    record="36-4",
                    ranking="#2",
                    weight_class="132",
                    profile_url=kwargs["url"],
                )
            ],
            school_rankings=[
                recruiting_source_scanners.RecruitingSchoolRankingRead(
                    source="KentuckyMat",
                    school_name="Martin County",
                    state="KY",
                    state_rank=5,
                    national_rank=41,
                    profile_url=kwargs["url"],
                )
            ],
        ),
    )

    result = run_saved_recruiting_source_scans(db_session, limit=10)

    db_session.refresh(profile)
    assert coach.role == UserRole.coach
    assert result.profiles_checked == 1
    assert result.profiles_updated == 1
    assert result.source_rankings_found == 1
    assert result.school_rankings_found == 1
    assert profile.stats_summary["source_rankings"][0]["ranking"] == "#2"
    assert profile.stats_summary["source_links"][0]["source"] == "KentuckyMat"
