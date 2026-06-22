from __future__ import annotations

from datetime import date

from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.routers.deps import get_current_user
from app.schemas.stats import (
    AthleteRecentRead,
    AthleteStatsDashboardRead,
    MatchCreate,
    MatchRead,
    MatchStatsCreate,
    MatchStatsRead,
    MatchUpdate,
    TeamLeadersRead,
    TeamStatsDashboardRead,
)
from app.services.stats_service import (
    create_match,
    get_athlete_recent,
    get_athlete_stats_dashboard,
    get_team_leaders,
    get_team_stats_dashboard,
    list_athlete_matches,
    list_team_matches,
    update_match,
    upsert_match_stats,
)


router = APIRouter(tags=["stats"])


@router.post("/matches", response_model=MatchRead, status_code=status.HTTP_201_CREATED)
def create_match_entry(
    payload: MatchCreate,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    match = create_match(db, payload=payload, current_user=current_user)
    db.commit()
    return match


@router.get("/matches/team/{team_id}", response_model=list[MatchRead])
def get_team_match_history(
    team_id: int,
    athlete_id: int | None = Query(default=None),
    event_name: str | None = Query(default=None),
    weight_class: str | None = Query(default=None),
    date_from: date | None = Query(default=None),
    date_to: date | None = Query(default=None),
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    return list_team_matches(
        db,
        team_id=team_id,
        current_user=current_user,
        athlete_id=athlete_id,
        event_name=event_name,
        weight_class=weight_class,
        date_from=date_from,
        date_to=date_to,
    )


@router.get("/matches/athlete/{athlete_id}", response_model=list[MatchRead])
def get_athlete_match_history(
    athlete_id: int,
    team_id: int = Query(...),
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    return list_athlete_matches(db, athlete_id=athlete_id, team_id=team_id, current_user=current_user)


@router.patch("/matches/{match_id}", response_model=MatchRead)
def patch_match_entry(
    match_id: int,
    payload: MatchUpdate,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    match = update_match(db, match_id=match_id, payload=payload, current_user=current_user)
    db.commit()
    return match


@router.post("/matches/{match_id}/stats", response_model=MatchStatsRead)
def save_match_stats(
    match_id: int,
    payload: MatchStatsCreate,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    stats = upsert_match_stats(db, match_id=match_id, payload=payload, current_user=current_user)
    db.commit()
    return stats


@router.get("/stats/athlete/{athlete_id}", response_model=AthleteStatsDashboardRead)
def get_athlete_stats(
    athlete_id: int,
    team_id: int = Query(...),
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    dashboard = get_athlete_stats_dashboard(db, athlete_id=athlete_id, team_id=team_id, current_user=current_user)
    db.commit()
    return dashboard


@router.get("/stats/team/{team_id}", response_model=TeamStatsDashboardRead)
def get_team_stats(
    team_id: int,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    dashboard = get_team_stats_dashboard(db, team_id=team_id, current_user=current_user)
    db.commit()
    return dashboard


@router.get("/stats/team/{team_id}/leaders", response_model=TeamLeadersRead)
def get_team_stat_leaders(
    team_id: int,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    return get_team_leaders(db, team_id=team_id, current_user=current_user)


@router.get("/stats/athlete/{athlete_id}/recent", response_model=AthleteRecentRead)
def get_athlete_recent_matches(
    athlete_id: int,
    team_id: int = Query(...),
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    return get_athlete_recent(db, athlete_id=athlete_id, team_id=team_id, current_user=current_user)
