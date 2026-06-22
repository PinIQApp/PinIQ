from __future__ import annotations

from datetime import date

from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.routers.deps import get_current_user
from app.schemas.tournament import (
    BracketGenerateRequest,
    BracketMatchRead,
    BracketMatchUpdate,
    BracketRead,
    SavedTournamentRead,
    TournamentAlertSubscriptionCreate,
    TournamentAlertSubscriptionRead,
    SeedingCalculationResponse,
    SeedingExplanationRead,
    SeedingOverrideCreate,
    SeedingOverrideResultRead,
    SeedingOverrideRead,
    SeedScoreRead,
    TournamentAddToScheduleRequest,
    TournamentAddToScheduleResponse,
    TournamentChangeLogRead,
    TournamentCreate,
    TournamentDashboardRead,
    TournamentDetailRead,
    TournamentDiscoverResponse,
    TournamentDualBoutCreate,
    TournamentDualBoutRead,
    TournamentDualBoutUpdate,
    TournamentDualMeetCreate,
    TournamentDualMeetRead,
    TournamentEntryCreate,
    TournamentEntryRead,
    TournamentEntryUpdate,
    TournamentLiveScanRequest,
    TournamentMatCreate,
    TournamentMatRead,
    TournamentManualCreate,
    TournamentRead,
    TournamentScanIngestRequest,
    TournamentScanRunRead,
    TournamentSaveRequest,
    TournamentSourceType,
    TournamentStatus,
    TournamentTeamAssign,
    TournamentUpdate,
)
from app.services.bracket_service import generate_bracket, get_bracket, update_bracket_match
from app.services.seeding_service import apply_seeding_override, calculate_seeds, get_seeding_explanations, get_seeds_for_weight_class
from app.services.tournament_service import (
    add_tournament_to_schedule,
    add_tournament_team,
    create_manual_tournament,
    create_tournament_dual_bout,
    create_tournament_dual_meet,
    create_tournament_mat,
    create_tournament,
    create_tournament_entry,
    discover_tournaments,
    get_discovered_tournament_detail,
    get_tournament_dashboard,
    ingest_tournament_scan,
    list_tournament_alert_subscriptions,
    list_tournament_change_log,
    list_tournament_dual_meets,
    list_tournament_mats,
    list_saved_tournaments,
    list_team_tournaments,
    list_tournament_scan_runs,
    list_tournament_entries,
    save_tournament_for_team,
    run_live_tournament_scan,
    upsert_tournament_alert_subscription,
    update_tournament_dual_bout,
    update_tournament,
    update_tournament_entry,
)


router = APIRouter(tags=["tournaments"])


@router.get("/tournaments/discover", response_model=TournamentDiscoverResponse)
def get_discoverable_tournaments(
    team_id: int | None = Query(default=None),
    search: str | None = Query(default=None),
    source: str | None = Query(default=None),
    start_date: date | None = Query(default=None),
    end_date: date | None = Query(default=None),
    state: str | None = Query(default=None),
    city: str | None = Query(default=None),
    age_group: str | None = Query(default=None),
    weight_class: str | None = Query(default=None),
    event_type: str | None = Query(default=None),
    radius_miles: int | None = Query(default=None, ge=1, le=500),
    origin_latitude: float | None = Query(default=None),
    origin_longitude: float | None = Query(default=None),
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
    ):
    return discover_tournaments(
        db,
        current_user=current_user,
        team_id=team_id,
        search=search,
        source=source,
        start_date=start_date,
        end_date=end_date,
        state=state,
        city=city,
        age_group=age_group,
        weight_class=weight_class,
        event_type=event_type,
        radius_miles=radius_miles,
        origin_latitude=origin_latitude,
        origin_longitude=origin_longitude,
    )


@router.get("/tournaments/scan-runs", response_model=list[TournamentScanRunRead])
def get_tournament_scan_runs(
    source_key: TournamentSourceType | None = Query(default=None),
    limit: int = Query(default=20, ge=1, le=100),
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    return list_tournament_scan_runs(db, current_user=current_user, source_key=source_key, limit=limit)


@router.post("/tournaments/scan-runs/ingest", response_model=TournamentScanRunRead, status_code=status.HTTP_201_CREATED)
def post_tournament_scan_ingest(
    payload: TournamentScanIngestRequest,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    run = ingest_tournament_scan(db, payload=payload, current_user=current_user)
    db.commit()
    return run


@router.post("/tournaments/scan-runs/live", response_model=TournamentScanRunRead, status_code=status.HTTP_201_CREATED)
def post_tournament_live_scan(
    payload: TournamentLiveScanRequest,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    run = run_live_tournament_scan(db, payload=payload, current_user=current_user)
    db.commit()
    return run


@router.get("/tournaments/change-log", response_model=list[TournamentChangeLogRead])
def get_tournament_change_log(
    tournament_id: int | None = Query(default=None),
    limit: int = Query(default=50, ge=1, le=200),
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    return list_tournament_change_log(db, current_user=current_user, tournament_id=tournament_id, limit=limit)


@router.get("/tournaments/alerts", response_model=list[TournamentAlertSubscriptionRead])
def get_tournament_alerts(
    team_id: int | None = Query(default=None),
    tournament_external_id: int | None = Query(default=None),
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    return list_tournament_alert_subscriptions(
        db,
        current_user=current_user,
        team_id=team_id,
        tournament_external_id=tournament_external_id,
    )


@router.post("/tournaments/alerts", response_model=TournamentAlertSubscriptionRead, status_code=status.HTTP_201_CREATED)
def post_tournament_alert(
    payload: TournamentAlertSubscriptionCreate,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    subscription = upsert_tournament_alert_subscription(db, payload=payload, current_user=current_user)
    db.commit()
    return subscription


@router.get("/tournaments/saved/{team_id}", response_model=list[SavedTournamentRead])
def get_saved_tournaments(
    team_id: int,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    return list_saved_tournaments(db, team_id=team_id, current_user=current_user)


@router.post("/tournaments/save", response_model=SavedTournamentRead, status_code=status.HTTP_201_CREATED)
def post_save_tournament(
    payload: TournamentSaveRequest,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    saved = save_tournament_for_team(db, payload=payload, current_user=current_user)
    db.commit()
    return saved


@router.post("/tournaments/add-to-schedule", response_model=TournamentAddToScheduleResponse)
def post_add_tournament_to_schedule(
    payload: TournamentAddToScheduleRequest,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    response = add_tournament_to_schedule(db, payload=payload, current_user=current_user)
    db.commit()
    return response


@router.post("/tournaments/manual", response_model=TournamentDetailRead, status_code=status.HTTP_201_CREATED)
def post_manual_tournament(
    payload: TournamentManualCreate,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    detail = create_manual_tournament(db, payload=payload, current_user=current_user)
    db.commit()
    return detail


@router.post("/tournaments", response_model=TournamentRead, status_code=status.HTTP_201_CREATED)
def post_tournament(
    payload: TournamentCreate,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    tournament = create_tournament(db, payload=payload, current_user=current_user)
    db.commit()
    return tournament


@router.get("/tournaments/team/{team_id}", response_model=list[TournamentRead])
def get_team_tournaments(
    team_id: int,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    return list_team_tournaments(db, team_id=team_id, current_user=current_user)


@router.get("/tournaments/managed/{tournament_id}", response_model=TournamentDashboardRead)
def get_managed_tournament(
    tournament_id: int,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    return get_tournament_dashboard(db, tournament_id=tournament_id, current_user=current_user)


@router.post("/tournaments/managed/{tournament_id}/mats", response_model=TournamentMatRead, status_code=status.HTTP_201_CREATED)
def post_tournament_mat(
    tournament_id: int,
    payload: TournamentMatCreate,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    mat = create_tournament_mat(db, tournament_id=tournament_id, payload=payload, current_user=current_user)
    db.commit()
    return mat


@router.get("/tournaments/managed/{tournament_id}/mats", response_model=list[TournamentMatRead])
def get_tournament_mats(
    tournament_id: int,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    return list_tournament_mats(db, tournament_id=tournament_id, current_user=current_user)


@router.post(
    "/tournaments/managed/{tournament_id}/dual-meets",
    response_model=TournamentDualMeetRead,
    status_code=status.HTTP_201_CREATED,
)
def post_tournament_dual_meet(
    tournament_id: int,
    payload: TournamentDualMeetCreate,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    dual_meet = create_tournament_dual_meet(db, tournament_id=tournament_id, payload=payload, current_user=current_user)
    db.commit()
    return dual_meet


@router.get("/tournaments/managed/{tournament_id}/dual-meets", response_model=list[TournamentDualMeetRead])
def get_tournament_dual_meets(
    tournament_id: int,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    return list_tournament_dual_meets(db, tournament_id=tournament_id, current_user=current_user)


@router.get("/tournaments/{tournament_id}", response_model=TournamentDetailRead)
def get_tournament(
    tournament_id: int,
    team_id: int | None = Query(default=None),
    origin_latitude: float | None = Query(default=None),
    origin_longitude: float | None = Query(default=None),
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    return get_discovered_tournament_detail(
        db,
        tournament_id=tournament_id,
        current_user=current_user,
        team_id=team_id,
        origin_latitude=origin_latitude,
        origin_longitude=origin_longitude,
    )


@router.patch("/tournaments/managed/{tournament_id}", response_model=TournamentRead)
def patch_tournament(
    tournament_id: int,
    payload: TournamentUpdate,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    tournament = update_tournament(db, tournament_id=tournament_id, payload=payload, current_user=current_user)
    db.commit()
    return tournament


@router.post("/tournaments/managed/{tournament_id}/teams", response_model=TournamentRead, status_code=status.HTTP_201_CREATED)
def post_tournament_team(
    tournament_id: int,
    payload: TournamentTeamAssign,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    tournament = add_tournament_team(
        db,
        tournament_id=tournament_id,
        team_id=payload.team_id,
        current_user=current_user,
    )
    db.commit()
    return tournament


@router.post("/tournaments/{tournament_id}/entries", response_model=TournamentEntryRead, status_code=status.HTTP_201_CREATED)
def post_tournament_entry(
    tournament_id: int,
    payload: TournamentEntryCreate,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    entry = create_tournament_entry(db, tournament_id=tournament_id, payload=payload, current_user=current_user)
    db.commit()
    return entry


@router.get("/tournaments/{tournament_id}/entries", response_model=list[TournamentEntryRead])
def get_tournament_entries(
    tournament_id: int,
    weight_class: str | None = Query(default=None),
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    return list_tournament_entries(db, tournament_id=tournament_id, current_user=current_user, weight_class=weight_class)


@router.patch("/tournaments/entries/{entry_id}", response_model=TournamentEntryRead)
def patch_tournament_entry(
    entry_id: int,
    payload: TournamentEntryUpdate,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    entry = update_tournament_entry(db, entry_id=entry_id, payload=payload, current_user=current_user)
    db.commit()
    return entry


@router.post("/dual-meets/{dual_meet_id}/bouts", response_model=TournamentDualBoutRead, status_code=status.HTTP_201_CREATED)
def post_tournament_dual_bout(
    dual_meet_id: int,
    payload: TournamentDualBoutCreate,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    bout = create_tournament_dual_bout(db, dual_meet_id=dual_meet_id, payload=payload, current_user=current_user)
    db.commit()
    return bout


@router.patch("/dual-bouts/{dual_bout_id}", response_model=TournamentDualBoutRead)
def patch_tournament_dual_bout(
    dual_bout_id: int,
    payload: TournamentDualBoutUpdate,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    bout = update_tournament_dual_bout(db, dual_bout_id=dual_bout_id, payload=payload, current_user=current_user)
    db.commit()
    return bout


@router.post("/seeding/calculate/{tournament_id}", response_model=SeedingCalculationResponse)
def post_seed_calculation(
    tournament_id: int,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    response = calculate_seeds(db, tournament_id=tournament_id, current_user=current_user)
    db.commit()
    return response


@router.get("/seeding/{tournament_id}/{weight_class}", response_model=list[SeedScoreRead])
def get_weight_class_seeds(
    tournament_id: int,
    weight_class: str,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    return get_seeds_for_weight_class(db, tournament_id=tournament_id, weight_class=weight_class, current_user=current_user)


@router.post("/seeding/override", response_model=SeedingOverrideResultRead)
def post_seed_override(
    payload: SeedingOverrideCreate,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    result = apply_seeding_override(db, payload=payload, current_user=current_user)
    db.commit()
    return {
        "override": SeedingOverrideRead.model_validate(result["override"]),
        "results": result["results"],
    }


@router.get("/seeding/explanations/{tournament_id}/{weight_class}", response_model=SeedingExplanationRead)
def get_seed_explanations(
    tournament_id: int,
    weight_class: str,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    return get_seeding_explanations(db, tournament_id=tournament_id, weight_class=weight_class, current_user=current_user)


@router.post("/brackets/generate/{tournament_id}/{weight_class}", response_model=BracketRead)
def post_bracket_generation(
    tournament_id: int,
    weight_class: str,
    payload: BracketGenerateRequest,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    bracket = generate_bracket(
        db,
        tournament_id=tournament_id,
        weight_class=weight_class,
        payload=payload,
        current_user=current_user,
    )
    db.commit()
    return bracket


@router.get("/brackets/{tournament_id}/{weight_class}", response_model=BracketRead)
def get_weight_class_bracket(
    tournament_id: int,
    weight_class: str,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    return get_bracket(db, tournament_id=tournament_id, weight_class=weight_class, current_user=current_user)


@router.patch("/brackets/matches/{match_id}", response_model=BracketMatchRead)
def patch_weight_class_match(
    match_id: int,
    payload: BracketMatchUpdate,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    match = update_bracket_match(db, match_id=match_id, payload=payload, current_user=current_user)
    db.commit()
    return match
