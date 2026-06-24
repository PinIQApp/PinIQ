from datetime import datetime
from types import SimpleNamespace

from app.services.recruiting_service import _piniq_ranking


class _Query:
    def filter(self, *args, **kwargs):
        return self

    def count(self):
        return 3


class _Db:
    def query(self, *args, **kwargs):
        return _Query()


def test_piniq_ranking_uses_verified_sources_school_strength_and_stats():
    profile = SimpleNamespace(
        athlete_id=1,
        achievements=["State placer"],
        highlights=[object(), object()],
        stats_summary={
            "source_rankings": [
                {
                    "source": "KentuckyMat",
                    "record": "36-4",
                    "ranking": "#2",
                    "weight_class": "132",
                    "profile_url": "https://kentuckymat.com/rankings",
                }
            ],
            "school_rankings": [
                {
                    "source": "KentuckyMat",
                    "school_name": "Martin County",
                    "state": "KY",
                    "state_rank": 5,
                    "national_rank": 41,
                }
            ],
        },
        updated_at=datetime.utcnow(),
    )
    snapshot = SimpleNamespace(
        total_matches=40,
        win_percentage=0.9,
        bonus_point_rate=0.35,
    )

    ranking = _piniq_ranking(_Db(), profile, snapshot)

    assert ranking.score >= 80
    assert ranking.tier in {"Elite", "High Watch"}
    assert ranking.state_rank_hint == 2
    assert ranking.national_rank_hint == 41
    assert ranking.confidence == "high"
    assert {factor.label for factor in ranking.factors} >= {"Win profile", "Source rank", "School strength"}


def test_piniq_ranking_stays_low_confidence_without_verified_sources():
    profile = SimpleNamespace(
        athlete_id=1,
        achievements=[],
        highlights=[],
        stats_summary={},
        updated_at=datetime.utcnow(),
    )
    snapshot = SimpleNamespace(
        total_matches=2,
        win_percentage=0.5,
        bonus_point_rate=0.0,
    )

    ranking = _piniq_ranking(_Db(), profile, snapshot)

    assert ranking.score < 40
    assert ranking.confidence == "low"
    assert ranking.state_rank_hint is None
