from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.routers.deps import get_current_user
from app.schemas.recruiting import (
    RecruitingAthleteCardRead,
    RecruitingBoardRead,
    RecruitingNoteCreate,
    RecruitingNoteRead,
    RecruitingProfileCreate,
    RecruitingProfileRead,
    RecruitingProfileUpdate,
    RecruitingProfileWriteResponse,
    RecruitingSearchParams,
    RecruitingSearchResponse,
    RecruitingSavedSourceScanResponse,
    RecruitingSourceLinksRead,
    RecruitingSourceLinksUpsert,
    RecruitingSourceScanRequest,
    RecruitingSourceScanResponse,
    RecruitingTrendingRead,
    RecruitingWatchlistCreate,
    RecruitingWatchlistRead,
    RecruitingWatchlistResponse,
)
from app.services.recruiting_service import (
    create_recruiting_profile,
    get_recruiting_board,
    get_recruiting_profile,
    get_recruiting_source_links,
    get_trending_athletes,
    get_watchlist,
    list_recruiting_athletes,
    run_saved_recruiting_source_scans,
    save_recruiting_note,
    save_recruiting_source_links,
    save_watchlist_entry,
    scan_recruiting_sources,
    search_recruiting_athletes,
    update_recruiting_profile,
)


router = APIRouter(tags=["recruiting"])


@router.get("/recruiting/athletes", response_model=list[RecruitingAthleteCardRead])
def get_recruiting_athletes(
    featured_only: bool = Query(default=False),
    open_only: bool = Query(default=False),
    sort_by: str = Query(default="updated"),
    limit: int = Query(default=50, ge=1, le=100),
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    return list_recruiting_athletes(
        db,
        current_user=current_user,
        featured_only=featured_only,
        open_only=open_only,
        sort_by=sort_by,
        limit=limit,
    )


@router.get("/recruiting/athlete/{athlete_id}", response_model=RecruitingProfileRead)
def get_recruiting_athlete_profile(
    athlete_id: int,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    return get_recruiting_profile(db, athlete_id=athlete_id, current_user=current_user)


@router.get("/recruiting/athlete/{athlete_id}/source-links", response_model=RecruitingSourceLinksRead)
def get_recruiting_source_links_route(
    athlete_id: int,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    return get_recruiting_source_links(db, athlete_id=athlete_id, current_user=current_user)


@router.put("/recruiting/athlete/{athlete_id}/source-links", response_model=RecruitingSourceLinksRead)
def put_recruiting_source_links_route(
    athlete_id: int,
    payload: RecruitingSourceLinksUpsert,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    result = save_recruiting_source_links(db, athlete_id=athlete_id, payload=payload, current_user=current_user)
    db.commit()
    return result


@router.post("/recruiting/profile", response_model=RecruitingProfileWriteResponse, status_code=status.HTTP_201_CREATED)
def create_recruiting_profile_route(
    payload: RecruitingProfileCreate,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    result = create_recruiting_profile(db, payload=payload, current_user=current_user)
    db.commit()
    return result


@router.patch("/recruiting/profile/{athlete_id}", response_model=RecruitingProfileWriteResponse)
def patch_recruiting_profile_route(
    athlete_id: int,
    payload: RecruitingProfileUpdate,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    result = update_recruiting_profile(db, athlete_id=athlete_id, payload=payload, current_user=current_user)
    db.commit()
    return result


@router.get("/recruiting/search", response_model=RecruitingSearchResponse)
def search_recruiting_athletes_route(
    weight_class: str | None = Query(default=None),
    graduation_year: int | None = Query(default=None),
    location: str | None = Query(default=None),
    min_win_percentage: float | None = Query(default=None),
    min_bonus_rate: float | None = Query(default=None),
    min_takedowns_per_match: float | None = Query(default=None),
    is_open: bool | None = Query(default=None),
    is_actively_looking: bool | None = Query(default=None),
    query: str | None = Query(default=None),
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    params = RecruitingSearchParams(
        weight_class=weight_class,
        graduation_year=graduation_year,
        location=location,
        min_win_percentage=min_win_percentage,
        min_bonus_rate=min_bonus_rate,
        min_takedowns_per_match=min_takedowns_per_match,
        is_open=is_open,
        is_actively_looking=is_actively_looking,
        query=query,
    )
    return search_recruiting_athletes(db, current_user=current_user, params=params)


@router.get("/recruiting/board", response_model=RecruitingBoardRead)
def get_recruiting_board_route(
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    return get_recruiting_board(db, current_user=current_user)


@router.post("/recruiting/source-scan", response_model=RecruitingSourceScanResponse)
def post_recruiting_source_scan_route(
    payload: RecruitingSourceScanRequest,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    result = scan_recruiting_sources(db, payload=payload, current_user=current_user)
    if payload.update_profile:
        db.commit()
    return result


@router.post("/recruiting/source-scan/saved", response_model=RecruitingSavedSourceScanResponse)
def post_saved_recruiting_source_scan_route(
    limit: int = Query(default=100, ge=1, le=500),
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    if getattr(current_user.role, "value", current_user.role) != "admin":
        # Coaches can scan individual source links, but global scheduled scans are admin/system work.
        raise HTTPException(status_code=403, detail="Only admins can run saved recruiting source scans")
    result = run_saved_recruiting_source_scans(db, limit=limit)
    db.commit()
    return result


@router.post("/recruiting/watchlist", response_model=RecruitingWatchlistResponse, status_code=status.HTTP_201_CREATED)
def create_watchlist_entry_route(
    payload: RecruitingWatchlistCreate,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    result = save_watchlist_entry(db, payload=payload, current_user=current_user)
    db.commit()
    return result


@router.get("/recruiting/watchlist/{coach_id}", response_model=list[RecruitingWatchlistRead])
def get_watchlist_route(
    coach_id: int,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    return get_watchlist(db, coach_id=coach_id, current_user=current_user)


@router.post("/recruiting/notes", response_model=RecruitingNoteRead, status_code=status.HTTP_201_CREATED)
def create_recruiting_note_route(
    payload: RecruitingNoteCreate,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    result = save_recruiting_note(db, payload=payload, current_user=current_user)
    db.commit()
    return result


@router.get("/recruiting/trending", response_model=RecruitingTrendingRead)
def get_recruiting_trending_route(
    limit: int = Query(default=10, ge=1, le=25),
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    return get_trending_athletes(db, current_user=current_user, limit=limit)
