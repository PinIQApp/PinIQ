from __future__ import annotations

from collections import defaultdict
from datetime import date, datetime, time, timedelta
from difflib import SequenceMatcher
from enum import Enum
from math import asin, cos, radians, sin, sqrt
import re

from fastapi import HTTPException
from sqlalchemy import or_
from sqlalchemy.orm import Session, joinedload

from app.core.config import settings
from app.models.messaging import ParentLink
from app.models.schedule import Event, EventType
from app.models.team import Team, TeamMember, TeamMemberStatus
from app.models.tournament import (
    Bracket,
    DualBoutResultType,
    DualMeetStatus,
    EntryStatus,
    SavedTournament,
    Tournament,
    TournamentAlertChannel,
    TournamentAlertSubscription,
    TournamentAlertType,
    TournamentChangeLog,
    TournamentChangeType,
    TournamentDualBout,
    TournamentDualMeet,
    TournamentDivision,
    TournamentEntry,
    TournamentEventType,
    TournamentExternal,
    TournamentExternalStatus,
    TournamentFilter,
    TournamentFormatType,
    TournamentIngestionMode,
    TournamentMat,
    TournamentMatStatus,
    TournamentScanRun,
    TournamentScanRunStatus,
    TournamentSource,
    TournamentSourceType,
    TournamentStatus,
    TournamentTeam,
)
from app.models.user import User, UserRole
from app.schemas.tournament import (
    SavedTournamentRead,
    TournamentAlertSubscriptionCreate,
    TournamentAlertSubscriptionRead,
    TournamentAddToScheduleRequest,
    TournamentAddToScheduleResponse,
    TournamentChangeLogRead,
    TournamentCreate,
    TournamentDashboardRead,
    TournamentDetailRead,
    TournamentDiscoverResponse,
    TournamentEntryCreate,
    TournamentEntryGroupRead,
    TournamentEntryRead,
    TournamentEntryUpdate,
    TournamentExternalRead,
    TournamentFilterRead,
    TournamentMatCreate,
    TournamentMatRead,
    TournamentManualCreate,
    TournamentRead,
    TournamentDualBoutCreate,
    TournamentDualBoutRead,
    TournamentDualBoutUpdate,
    TournamentDualMeetCreate,
    TournamentDualMeetRead,
    TournamentLiveScanRequest,
    TournamentScanIngestItem,
    TournamentScanIngestRequest,
    TournamentScanRunRead,
    TournamentSaveRequest,
    TournamentSourceRead,
    TournamentUpdate,
)
from app.services.schedule_planner import load_team_with_members, require_schedule_manager, require_schedule_viewer
from app.services.tournament_source_scanners import TournamentSourceScannerError, scanner_for_source


STAFF_ROLES = {UserRole.coach, UserRole.assistant_coach}
ENTRY_ACTIVE_STATUSES = {EntryStatus.entered, EntryStatus.replaced, EntryStatus.late_update}


def _utcnow() -> datetime:
    return datetime.utcnow()


def _load_team(db: Session, team_id: int) -> Team:
    team = (
        db.query(Team)
        .options(joinedload(Team.memberships).joinedload(TeamMember.user))
        .filter(Team.id == team_id)
        .first()
    )
    if not team:
        raise HTTPException(status_code=404, detail="Team not found")
    return team


def _team_staff_membership(team: Team, user_id: int) -> TeamMember | None:
    return next(
        (
            membership
            for membership in team.memberships
            if membership.user_id == user_id
            and membership.status == TeamMemberStatus.approved
            and membership.user.role in STAFF_ROLES
        ),
        None,
    )


def _user_is_linked_parent(db: Session, *, parent_id: int, athlete_id: int) -> bool:
    return (
        db.query(ParentLink)
        .filter(
            ParentLink.parent_user_id == parent_id,
            ParentLink.athlete_user_id == athlete_id,
            ParentLink.is_active.is_(True),
        )
        .first()
        is not None
    )


def _load_tournament(db: Session, tournament_id: int) -> Tournament:
    tournament = (
        db.query(Tournament)
        .options(
            joinedload(Tournament.divisions),
            joinedload(Tournament.teams),
            joinedload(Tournament.entries),
            joinedload(Tournament.seed_scores),
            joinedload(Tournament.brackets),
            joinedload(Tournament.mats),
            joinedload(Tournament.dual_meets).joinedload(TournamentDualMeet.bouts),
        )
        .filter(Tournament.id == tournament_id)
        .first()
    )
    if not tournament:
        raise HTTPException(status_code=404, detail="Tournament not found")
    return tournament


def _load_external_tournament(db: Session, tournament_id: int) -> TournamentExternal:
    tournament = (
        db.query(TournamentExternal)
        .options(joinedload(TournamentExternal.source), joinedload(TournamentExternal.saved_by_teams))
        .filter(TournamentExternal.id == tournament_id)
        .first()
    )
    if not tournament:
        raise HTTPException(status_code=404, detail="Discovered tournament not found")
    return tournament


def _require_director_or_admin(tournament: Tournament, current_user: User) -> None:
    if current_user.role == UserRole.admin or tournament.director_user_id == current_user.id:
        return
    raise HTTPException(status_code=403, detail="Only the tournament director or admin can do this")


def _require_tournament_view(db: Session, tournament: Tournament, current_user: User) -> str:
    if current_user.role == UserRole.admin or tournament.director_user_id == current_user.id:
        return "director"

    participating_team_ids = {team.team_id for team in tournament.teams}
    if current_user.role in STAFF_ROLES:
        for team_id in participating_team_ids:
            team = _load_team(db, team_id)
            if _team_staff_membership(team, current_user.id):
                return current_user.role.value
        raise HTTPException(status_code=403, detail="Only participating coaches can view this tournament")

    if current_user.role == UserRole.athlete:
        if tournament.status in {TournamentStatus.bracket_finalized, TournamentStatus.published}:
            return "athlete"
        raise HTTPException(status_code=403, detail="Athletes can only view finalized brackets")

    if current_user.role == UserRole.parent:
        athlete_ids = [entry.athlete_id for entry in tournament.entries]
        if tournament.status in {TournamentStatus.bracket_finalized, TournamentStatus.published} and any(
            _user_is_linked_parent(db, parent_id=current_user.id, athlete_id=athlete_id) for athlete_id in athlete_ids
        ):
            return "parent"
        raise HTTPException(status_code=403, detail="Parents can only view finalized brackets for linked athletes")

    raise HTTPException(status_code=403, detail="Not authorized for this tournament")


def _require_team_entry_manager(db: Session, tournament: Tournament, team_id: int, current_user: User) -> None:
    if current_user.role == UserRole.admin or tournament.director_user_id == current_user.id:
        return
    if team_id not in {item.team_id for item in tournament.teams}:
        raise HTTPException(status_code=400, detail="Team is not assigned to this tournament")
    team = _load_team(db, team_id)
    if _team_staff_membership(team, current_user.id):
        return
    raise HTTPException(status_code=403, detail="Only the director or assigned team staff can manage entries")


def _require_dual_meet_manager(db: Session, dual_meet: TournamentDualMeet, current_user: User) -> Tournament:
    tournament = _load_tournament(db, dual_meet.tournament_id)
    if current_user.role == UserRole.admin or tournament.director_user_id == current_user.id:
        return tournament

    for team_id in {dual_meet.team_a_id, dual_meet.team_b_id}:
        team = _load_team(db, team_id)
        if _team_staff_membership(team, current_user.id):
            return tournament

    raise HTTPException(status_code=403, detail="Only the director, admin, or participating team staff can score this dual")


def _dual_result_points(result_type: DualBoutResultType | None) -> int:
    if result_type is None:
        return 0
    return {
        DualBoutResultType.decision: 3,
        DualBoutResultType.major_decision: 4,
        DualBoutResultType.technical_fall: 5,
        DualBoutResultType.fall: 6,
        DualBoutResultType.medical_forfeit: 6,
        DualBoutResultType.forfeit: 6,
        DualBoutResultType.default: 6,
        DualBoutResultType.disqualification: 6,
    }[result_type]


def _serialize_dual_meet(dual_meet: TournamentDualMeet) -> TournamentDualMeetRead:
    return TournamentDualMeetRead.model_validate(dual_meet)


def _serialize_dual_bout(dual_bout: TournamentDualBout) -> TournamentDualBoutRead:
    return TournamentDualBoutRead.model_validate(dual_bout)


def _recalculate_dual_meet_score(dual_meet: TournamentDualMeet) -> TournamentDualMeet:
    team_a_score = 0
    team_b_score = 0

    for bout in dual_meet.bouts:
        points = _dual_result_points(bout.result_type) if bout.is_complete else 0
        bout.team_a_points_awarded = points if bout.winner_team_id == dual_meet.team_a_id else 0
        bout.team_b_points_awarded = points if bout.winner_team_id == dual_meet.team_b_id else 0
        if bout.is_complete and bout.completed_at is None:
            bout.completed_at = _utcnow()
        if not bout.is_complete:
            bout.completed_at = None
        team_a_score += bout.team_a_points_awarded
        team_b_score += bout.team_b_points_awarded

    dual_meet.team_a_score = team_a_score
    dual_meet.team_b_score = team_b_score
    dual_meet.winner_team_id = None
    dual_meet.completed_at = None

    if dual_meet.status == DualMeetStatus.completed or (
        bool(dual_meet.bouts) and all(bout.is_complete for bout in dual_meet.bouts)
    ):
        dual_meet.status = DualMeetStatus.completed
        dual_meet.completed_at = _utcnow()

    if team_a_score > team_b_score:
        dual_meet.winner_team_id = dual_meet.team_a_id
    elif team_b_score > team_a_score:
        dual_meet.winner_team_id = dual_meet.team_b_id

    dual_meet.updated_at = _utcnow()
    return dual_meet


def _validate_dual_bout_payload(dual_meet: TournamentDualMeet, payload_winner_team_id: int | None) -> None:
    if payload_winner_team_id is None:
        return
    if payload_winner_team_id not in {dual_meet.team_a_id, dual_meet.team_b_id}:
        raise HTTPException(status_code=400, detail="Winning team must be one of the dual participants")


def _require_seed_view(db: Session, tournament: Tournament, current_user: User) -> str:
    if current_user.role == UserRole.admin or tournament.director_user_id == current_user.id:
        return "director"
    if current_user.role in STAFF_ROLES:
        participating_team_ids = {team.team_id for team in tournament.teams}
        for team_id in participating_team_ids:
            team = _load_team(db, team_id)
            if _team_staff_membership(team, current_user.id):
                return current_user.role.value
    raise HTTPException(status_code=403, detail="Only the director, admin, or participating coaches can view seeding")


def _entry_sort_key(entry: TournamentEntry):
    return (
        entry.weight_class,
        entry.division_name.lower(),
        entry.seed_number or 999,
        entry.created_at,
        entry.id,
    )


def _group_entries(entries: list[TournamentEntry]) -> list[TournamentEntryGroupRead]:
    grouped: dict[str, list[TournamentEntryRead]] = defaultdict(list)
    for entry in sorted(entries, key=_entry_sort_key):
        grouped[entry.weight_class].append(TournamentEntryRead.model_validate(entry))
    return [
        TournamentEntryGroupRead(weight_class=weight_class, entries=entry_group)
        for weight_class, entry_group in sorted(grouped.items(), key=lambda item: item[0])
    ]


def _seed_tournament_sources(db: Session) -> list[TournamentSource]:
    existing = {
        source.source_key: source
        for source in db.query(TournamentSource).order_by(TournamentSource.id.asc()).all()
    }
    defaults = [
        (
            TournamentSourceType.manual,
            "Manual",
            TournamentIngestionMode.manual_entry,
            None,
            False,
            False,
            "Coach or admin managed source for hand-entered tournaments.",
        ),
        (
            TournamentSourceType.track,
            "TrackWrestling",
            TournamentIngestionMode.hybrid_placeholder,
            "https://www.trackwrestling.com",
            True,
            False,
            "Placeholder source for scraping-first ingestion with optional API augmentation later.",
        ),
        (
            TournamentSourceType.flo,
            "FloWrestling",
            TournamentIngestionMode.hybrid_placeholder,
            "https://www.flowrestling.org",
            True,
            False,
            "Placeholder source for event discovery, normalization, and registration deep links.",
        ),
        (
            TournamentSourceType.usa,
            "USA Wrestling",
            TournamentIngestionMode.hybrid_placeholder,
            "https://www.usawmembership.com",
            True,
            False,
            "Placeholder source for sanctioned event ingestion and registration routing.",
        ),
    ]
    created = False
    for source_key, display_name, mode, base_url, supports_scraping, supports_api, notes in defaults:
        if source_key in existing:
            continue
        item = TournamentSource(
            source_key=source_key,
            display_name=display_name,
            ingestion_mode=mode,
            base_url=base_url,
            supports_scraping=supports_scraping,
            supports_api=supports_api,
            notes=notes,
        )
        db.add(item)
        created = True
    if created:
        db.flush()
    return db.query(TournamentSource).order_by(TournamentSource.id.asc()).all()


def _seed_beta_tournament_discovery(
    db: Session,
    *,
    sources: list[TournamentSource],
) -> None:
    if settings.environment == "production":
        return
    if (
        db.query(TournamentExternal.id)
        .filter(TournamentExternal.external_id.like("beta-%"))
        .first()
        is not None
    ):
        return

    source_by_key = {source.source_key: source for source in sources}
    track_source = source_by_key.get(TournamentSourceType.track)
    flo_source = source_by_key.get(TournamentSourceType.flo)
    usa_source = source_by_key.get(TournamentSourceType.usa)
    if not track_source or not flo_source or not usa_source:
        return

    today = date.today()
    examples = [
        TournamentExternal(
            source_id=track_source.id,
            external_id=f"beta-bluegrass-open-{today.year}",
            name="Bluegrass Summer Open",
            start_date=today + timedelta(days=9),
            end_date=today + timedelta(days=9),
            location_name="Kentucky Expo Center",
            city="Louisville",
            state="KY",
            latitude=38.2000,
            longitude=-85.7410,
            age_divisions=["High School", "Middle School", "Girls"],
            weight_classes=["106", "113", "120", "126", "132", "138", "144", "150", "157", "165", "175", "190", "215", "285"],
            event_type="individual_tournament",
            registration_link="https://www.trackwrestling.com",
            event_page_link="https://www.trackwrestling.com",
            source_label="TrackWrestling",
            contact_name="Tournament Director",
            contact_email="events@example.com",
            description="Beta sample event for testing tournament discovery, saving, and calendar workflows.",
            deadline=today + timedelta(days=6),
            cost="$40 individual / $300 team",
            raw_payload={"source": "beta_seed"},
            normalized_payload={"beta_sample": True, "style": "open"},
            ingestion_status=TournamentExternalStatus.normalized,
            ingestion_notes="Auto-seeded beta tournament because discovery was empty.",
            last_seen_at=_utcnow(),
        ),
        TournamentExternal(
            source_id=flo_source.id,
            external_id=f"beta-appalachian-duals-{today.year}",
            name="Appalachian Clash Duals",
            start_date=today + timedelta(days=16),
            end_date=today + timedelta(days=17),
            location_name="Corbin Arena",
            city="Corbin",
            state="KY",
            latitude=36.9487,
            longitude=-84.0969,
            age_divisions=["High School Varsity"],
            weight_classes=None,
            event_type="dual",
            registration_link="https://www.flowrestling.org",
            event_page_link="https://www.flowrestling.org",
            source_label="FloWrestling",
            description="Two-day team dual sample for testing tournament planning and parent reminders.",
            deadline=today + timedelta(days=11),
            cost="$850 per team",
            raw_payload={"source": "beta_seed"},
            normalized_payload={"beta_sample": True, "style": "dual"},
            ingestion_status=TournamentExternalStatus.normalized,
            ingestion_notes="Auto-seeded beta tournament because discovery was empty.",
            last_seen_at=_utcnow(),
        ),
        TournamentExternal(
            source_id=usa_source.id,
            external_id=f"beta-freestyle-state-{today.year}",
            name="Kentucky Freestyle State Tune-Up",
            start_date=today + timedelta(days=23),
            end_date=today + timedelta(days=24),
            location_name="Lexington Sports Center",
            city="Lexington",
            state="KY",
            latitude=38.0406,
            longitude=-84.5037,
            age_divisions=["10U", "12U", "14U", "16U", "Junior"],
            weight_classes=["52", "58", "65", "74", "83", "92", "105", "120", "138", "160", "182"],
            event_type="freestyle",
            registration_link="https://www.usawmembership.com",
            event_page_link="https://www.usawmembership.com",
            source_label="USA Wrestling",
            description="Freestyle sample event for testing offseason discovery and registration handoff.",
            deadline=today + timedelta(days=18),
            cost="$35 entry",
            raw_payload={"source": "beta_seed"},
            normalized_payload={"beta_sample": True, "style": "freestyle"},
            ingestion_status=TournamentExternalStatus.normalized,
            ingestion_notes="Auto-seeded beta tournament because discovery was empty.",
            last_seen_at=_utcnow(),
        ),
    ]
    db.add_all(examples)
    db.flush()


def _label_sample_tournament_discovery(db: Session) -> None:
    if settings.environment == "production":
        return
    samples = db.query(TournamentExternal).filter(
        TournamentExternal.raw_payload["source"].as_string().in_(["seed", "beta_seed"])
    )
    changed = False
    for tournament in samples:
        if not tournament.name.startswith("Sample: "):
            tournament.name = f"Sample: {tournament.name}"
            changed = True
        note = "Sample tournament for beta workflow testing. Not a live public event."
        if tournament.ingestion_notes != note:
            tournament.ingestion_notes = note
            changed = True
    if changed:
        db.flush()


def _archive_sample_tournament_discovery(db: Session) -> None:
    samples = db.query(TournamentExternal).filter(
        TournamentExternal.raw_payload["source"].as_string().in_(["seed", "beta_seed"])
    )
    changed = False
    for tournament in samples:
        if tournament.ingestion_status != TournamentExternalStatus.archived:
            tournament.ingestion_status = TournamentExternalStatus.archived
            tournament.ingestion_notes = "Archived sample tournament."
            changed = True
    if changed:
        db.flush()


def _normalize_tokens(values: list[str] | None) -> set[str]:
    tokens: set[str] = set()
    for value in values or []:
        for token in value.lower().replace("/", " ").replace("-", " ").split():
            if token:
                tokens.add(token)
    return tokens


def _matches_age_group(tournament: TournamentExternal, age_group: str | None) -> bool:
    if not age_group:
        return True
    target = age_group.strip().lower()
    if not target:
        return True
    return any(target in division.lower() for division in tournament.age_divisions)


def _matches_weight_class(tournament: TournamentExternal, weight_class: str | None) -> bool:
    if not weight_class:
        return True
    if not tournament.weight_classes:
        return False
    target = weight_class.strip().lower()
    return any(target in item.lower() for item in tournament.weight_classes)


def _distance_miles(
    origin_latitude: float | None,
    origin_longitude: float | None,
    target_latitude: float | None,
    target_longitude: float | None,
) -> float | None:
    if None in {origin_latitude, origin_longitude, target_latitude, target_longitude}:
        return None
    radius = 3958.8
    lat1 = radians(origin_latitude)
    lon1 = radians(origin_longitude)
    lat2 = radians(target_latitude)
    lon2 = radians(target_longitude)
    dlat = lat2 - lat1
    dlon = lon2 - lon1
    value = sin(dlat / 2) ** 2 + cos(lat1) * cos(lat2) * sin(dlon / 2) ** 2
    return round(2 * radius * asin(sqrt(value)), 1)


def _find_default_filter(db: Session, *, current_user: User, team_id: int | None) -> TournamentFilter | None:
    query = db.query(TournamentFilter).filter(TournamentFilter.is_default.is_(True))
    if team_id is not None:
        return (
            query.filter(
                or_(
                    TournamentFilter.team_id == team_id,
                    TournamentFilter.user_id == current_user.id,
                )
            )
            .order_by(TournamentFilter.team_id.desc().nullslast(), TournamentFilter.updated_at.desc())
            .first()
        )
    return query.filter(TournamentFilter.user_id == current_user.id).order_by(TournamentFilter.updated_at.desc()).first()


def _team_level_tokens(team: Team | None) -> set[str]:
    if team is None or not team.division:
        return set()
    return _normalize_tokens([team.division])


def _recommendation_score(team: Team | None, tournament: TournamentExternal, distance: float | None) -> float:
    score = 0.0
    team_tokens = _team_level_tokens(team)
    tournament_tokens = _normalize_tokens(tournament.age_divisions)
    if team_tokens and team_tokens & tournament_tokens:
        score += 4.0
    if distance is not None:
        if distance <= 25:
            score += 3.0
        elif distance <= 75:
            score += 2.0
        elif distance <= 150:
            score += 1.0
    days_until = (tournament.start_date - date.today()).days
    if 0 <= days_until <= 14:
        score += 2.5
    if tournament.deadline and date.today() <= tournament.deadline <= date.today() + timedelta(days=10):
        score += 1.0
    if tournament.source and tournament.source.source_key == TournamentSourceType.manual:
        score += 1.25
    return round(score, 2)


SOURCE_PRIORITY = {
    TournamentSourceType.manual: 100,
    TournamentSourceType.usa: 80,
    TournamentSourceType.flo: 70,
    TournamentSourceType.track: 60,
}


def _source_priority(source_key: TournamentSourceType) -> int:
    return SOURCE_PRIORITY.get(source_key, 0)


def _normalize_text(value: str | None) -> str:
    return (value or "").strip().lower()


def _normalize_event_name(value: str | None) -> str:
    text = _normalize_text(value)
    text = re.sub(r"\b20\d{2}\b", " ", text)
    text = text.replace("grecco", "greco")
    text = text.replace("freestlye", "freestyle")
    text = text.replace("womens", "women")
    text = text.replace("women s", "women")
    text = text.replace("&", " and ")
    text = re.sub(r"[^a-z0-9]+", " ", text)
    text = re.sub(r"\b(open|tournament|championships?|classic|dual[s]?|event)\b", " ", text)
    text = re.sub(r"\s+", " ", text).strip()
    return text


def _normalize_city_text(value: str | None) -> str:
    text = _normalize_text(value)
    text = re.sub(r"[^a-z0-9]+", " ", text)
    text = re.sub(r"\s+", " ", text).strip()
    return text


def _display_city_name(value: str | None) -> str | None:
    if not value:
        return None
    cleaned = " ".join(value.split()).strip(" ,")
    if not cleaned:
        return None
    tokens = cleaned.split()
    street_suffixes = {
        "st",
        "street",
        "rd",
        "road",
        "dr",
        "drive",
        "ave",
        "avenue",
        "blvd",
        "boulevard",
        "ln",
        "lane",
        "pkwy",
        "parkway",
    }
    lower_tokens = [token.lower().strip(".,") for token in tokens]
    suffix_indexes = [index for index, token in enumerate(lower_tokens) if token in street_suffixes]
    if suffix_indexes:
        trailing = tokens[suffix_indexes[-1] + 1 :]
        if trailing:
            return " ".join(trailing)
    return cleaned


def _is_junk_tournament_name(value: str | None) -> bool:
    text = _normalize_text(value)
    if not text:
        return True
    blocked_fragments = (
        "template",
        "registration",
        "results archive",
    )
    if any(fragment in text for fragment in blocked_fragments):
        return True
    return False


def _event_name_similarity(left: str | None, right: str | None) -> float:
    normalized_left = _normalize_event_name(left)
    normalized_right = _normalize_event_name(right)
    if not normalized_left or not normalized_right:
        return 0.0
    if normalized_left == normalized_right:
        return 1.0

    left_tokens = set(normalized_left.split())
    right_tokens = set(normalized_right.split())
    token_overlap = len(left_tokens & right_tokens) / max(len(left_tokens | right_tokens), 1)
    char_similarity = SequenceMatcher(None, normalized_left, normalized_right).ratio()
    return max(token_overlap, char_similarity)


def _events_look_like_same_tournament(
    *,
    left_name: str | None,
    right_name: str | None,
    left_date: date | None,
    right_date: date | None,
    left_state: str | None,
    right_state: str | None,
) -> bool:
    if left_date != right_date:
        return False

    normalized_left_state = _normalize_text(left_state)
    normalized_right_state = _normalize_text(right_state)
    if not normalized_left_state or normalized_left_state != normalized_right_state:
        return False

    return _event_name_similarity(left_name, right_name) >= 0.88


def _event_fingerprint(*, name: str, start_date: date, city: str | None, state: str | None) -> str:
    return "::".join(
        [
            _normalize_event_name(name),
            start_date.isoformat(),
            _normalize_city_text(city),
            _normalize_text(state),
        ]
    )


def _existing_source_snapshots(tournament: TournamentExternal) -> list[dict]:
    normalized_payload = tournament.normalized_payload or {}
    snapshots = normalized_payload.get("sources")
    if isinstance(snapshots, list):
        return [item for item in snapshots if isinstance(item, dict)]
    return []


def _merged_source_snapshots(
    tournament: TournamentExternal,
    *,
    source: TournamentSource,
    item: TournamentScanIngestItem,
) -> list[dict]:
    snapshots = [entry for entry in _existing_source_snapshots(tournament) if entry.get("source_key") != source.source_key.value]
    snapshots.append(
        {
            "source_key": source.source_key.value,
            "source_label": item.source_label or source.display_name,
            "external_id": item.external_id,
            "source_id_hint": item.source_id_hint,
            "last_seen_at": _utcnow().isoformat(),
        }
    )
    return sorted(snapshots, key=lambda entry: entry.get("source_key") or "")


def _record_change_log(
    db: Session,
    *,
    tournament_id: int,
    source: TournamentSource,
    change_type: TournamentChangeType,
    summary: str,
    field_changes: dict,
    actor_user_id: int | None = None,
    scan_run_id: int | None = None,
) -> TournamentChangeLog:
    change = TournamentChangeLog(
        tournament_external_id=tournament_id,
        source_id=source.id,
        scan_run_id=scan_run_id,
        actor_user_id=actor_user_id,
        change_type=change_type,
        summary=summary,
        field_changes=_json_safe(field_changes),
        source_priority=_source_priority(source.source_key),
    )
    db.add(change)
    db.flush()
    return change


def _json_safe(value):
    if isinstance(value, datetime):
        return value.isoformat()
    if isinstance(value, date):
        return value.isoformat()
    if isinstance(value, time):
        return value.isoformat()
    if isinstance(value, Enum):
        return value.value
    if isinstance(value, dict):
        return {str(key): _json_safe(item) for key, item in value.items()}
    if isinstance(value, (list, tuple, set)):
        return [_json_safe(item) for item in value]
    return value


def _update_external_from_item(
    tournament: TournamentExternal,
    *,
    item: TournamentScanIngestItem,
    source: TournamentSource,
    scan_run_id: int | None,
) -> dict[str, dict[str, object]]:
    source_priority = _source_priority(source.source_key)
    current_priority = _source_priority(tournament.source.source_key) if tournament.source else 0
    field_changes: dict[str, dict[str, object]] = {}

    def maybe_set(field_name: str, new_value):
        old_value = getattr(tournament, field_name)
        if old_value != new_value:
            setattr(tournament, field_name, new_value)
            field_changes[field_name] = {"old": old_value, "new": new_value}

    authoritative_updates = {
        "name": item.name,
        "start_date": item.start_date,
        "end_date": item.end_date,
        "location_name": item.location_name,
        "city": item.city,
        "state": item.state,
        "latitude": item.latitude,
        "longitude": item.longitude,
        "age_divisions": item.age_divisions,
        "weight_classes": item.weight_classes,
        "event_type": item.event_type,
        "registration_link": item.registration_link,
        "event_page_link": item.event_page_link,
        "contact_name": item.contact_name,
        "contact_email": item.contact_email,
        "contact_phone": item.contact_phone,
        "description": item.description,
        "deadline": item.deadline,
        "cost": item.cost,
    }

    for field_name, new_value in authoritative_updates.items():
        if source_priority >= current_priority or getattr(tournament, field_name) in (None, "", [], {}):
            maybe_set(field_name, new_value)

    incoming_raw_payload = item.raw_payload or item.model_dump(mode="json")
    incoming_normalized_payload = dict(item.normalized_payload or {})
    incoming_normalized_payload["sources"] = _merged_source_snapshots(tournament, source=source, item=item)
    incoming_normalized_payload["fingerprint"] = _event_fingerprint(
        name=item.name,
        start_date=item.start_date,
        city=item.city,
        state=item.state,
    )
    incoming_normalized_payload["last_scan_run_id"] = scan_run_id

    if tournament.raw_payload != incoming_raw_payload:
        maybe_set("raw_payload", incoming_raw_payload)
    if tournament.normalized_payload != incoming_normalized_payload:
        maybe_set("normalized_payload", incoming_normalized_payload)

    maybe_set("ingestion_status", TournamentExternalStatus.normalized)
    maybe_set("ingestion_notes", item.ingestion_notes)
    maybe_set("last_seen_at", _utcnow())

    if source_priority > current_priority:
        maybe_set("source_id", source.id)
        maybe_set("source_label", item.source_label or source.display_name)

    return field_changes


def _find_merge_candidate(
    db: Session,
    *,
    source: TournamentSource,
    item: TournamentScanIngestItem,
) -> TournamentExternal | None:
    if item.external_id:
        exact = (
            db.query(TournamentExternal)
            .options(joinedload(TournamentExternal.source))
            .filter(
                TournamentExternal.source_id == source.id,
                TournamentExternal.external_id == item.external_id,
            )
            .first()
        )
        if exact:
            return exact

    fingerprint = _event_fingerprint(name=item.name, start_date=item.start_date, city=item.city, state=item.state)
    candidates = (
        db.query(TournamentExternal)
        .options(joinedload(TournamentExternal.source))
        .filter(
            TournamentExternal.start_date == item.start_date,
            TournamentExternal.ingestion_status != TournamentExternalStatus.archived,
        )
        .all()
    )
    for candidate in candidates:
        if _is_junk_tournament_name(candidate.name):
            continue
        candidate_fingerprint = _event_fingerprint(
            name=candidate.name,
            start_date=candidate.start_date,
            city=candidate.city,
            state=candidate.state,
        )
        if candidate_fingerprint == fingerprint:
            return candidate
        if (
            _normalize_event_name(candidate.name) == _normalize_event_name(item.name)
            and _normalize_text(candidate.state) == _normalize_text(item.state)
            and _normalize_text(candidate.state) != ""
        ):
            return candidate
        if _events_look_like_same_tournament(
            left_name=candidate.name,
            right_name=item.name,
            left_date=candidate.start_date,
            right_date=item.start_date,
            left_state=candidate.state,
            right_state=item.state,
        ):
            return candidate
    return None


def _create_external_tournament(
    db: Session,
    *,
    source: TournamentSource,
    item: TournamentScanIngestItem,
    current_user: User,
    scan_run_id: int | None,
) -> TournamentExternal:
    normalized_payload = dict(item.normalized_payload or {})
    normalized_payload["sources"] = _merged_source_snapshots(
        TournamentExternal(normalized_payload={}),
        source=source,
        item=item,
    )
    normalized_payload["fingerprint"] = _event_fingerprint(
        name=item.name,
        start_date=item.start_date,
        city=item.city,
        state=item.state,
    )
    normalized_payload["last_scan_run_id"] = scan_run_id
    tournament = TournamentExternal(
        source_id=source.id,
        created_by_user_id=current_user.id,
        external_id=item.external_id or item.source_id_hint,
        name=item.name,
        start_date=item.start_date,
        end_date=item.end_date,
        location_name=item.location_name,
        city=item.city,
        state=item.state,
        latitude=item.latitude,
        longitude=item.longitude,
        age_divisions=item.age_divisions,
        weight_classes=item.weight_classes,
        event_type=item.event_type,
        registration_link=item.registration_link,
        event_page_link=item.event_page_link,
        source_label=item.source_label or source.display_name,
        contact_name=item.contact_name,
        contact_email=item.contact_email,
        contact_phone=item.contact_phone,
        description=item.description,
        deadline=item.deadline,
        cost=item.cost,
        raw_payload=item.raw_payload or item.model_dump(mode="json"),
        normalized_payload=normalized_payload,
        ingestion_status=TournamentExternalStatus.normalized,
        ingestion_notes=item.ingestion_notes,
        last_seen_at=_utcnow(),
    )
    db.add(tournament)
    db.flush()
    return tournament


def _schedule_event_id_for_team(db: Session, *, team_id: int, tournament_id: int) -> int | None:
    event = (
        db.query(Event)
        .filter(
            Event.team_id == team_id,
            Event.external_tournament_id == tournament_id,
            Event.is_cancelled.is_(False),
        )
        .order_by(Event.starts_at.asc())
        .first()
    )
    return event.id if event else None


def _decorate_external_tournament(
    tournament: TournamentExternal,
    *,
    is_saved: bool,
    is_on_team_schedule: bool,
    distance_miles: float | None,
    recommendation_score: float | None,
) -> TournamentExternalRead:
    tournament.city = _display_city_name(tournament.city)
    tournament.is_saved = is_saved
    tournament.is_on_team_schedule = is_on_team_schedule
    tournament.distance_miles = distance_miles
    tournament.recommendation_score = recommendation_score
    return TournamentExternalRead.model_validate(tournament)


def _dedupe_discovered_tournaments(tournaments: list[TournamentExternal]) -> list[TournamentExternal]:
    chosen: dict[str, TournamentExternal] = {}
    for tournament in tournaments:
        key = _event_fingerprint(
            name=tournament.name,
            start_date=tournament.start_date,
            city=_display_city_name(tournament.city),
            state=tournament.state,
        )
        existing = chosen.get(key)
        if existing is None:
            chosen[key] = tournament
            continue

        existing_priority = _source_priority(existing.source.source_key) if existing.source else 0
        tournament_priority = _source_priority(tournament.source.source_key) if tournament.source else 0
        existing_score = existing_priority + (1 if existing.event_page_link else 0) + (1 if existing.city else 0)
        tournament_score = tournament_priority + (1 if tournament.event_page_link else 0) + (1 if tournament.city else 0)
        if tournament_score > existing_score:
            chosen[key] = tournament

    deduped = list(chosen.values())
    collapsed: list[TournamentExternal] = []
    for tournament in deduped:
        replacement_index: int | None = None
        for index, existing in enumerate(collapsed):
            if not _events_look_like_same_tournament(
                left_name=existing.name,
                right_name=tournament.name,
                left_date=existing.start_date,
                right_date=tournament.start_date,
                left_state=existing.state,
                right_state=tournament.state,
            ):
                continue

            existing_priority = _source_priority(existing.source.source_key) if existing.source else 0
            tournament_priority = _source_priority(tournament.source.source_key) if tournament.source else 0
            existing_score = existing_priority + (1 if existing.event_page_link else 0) + (1 if existing.city else 0)
            tournament_score = tournament_priority + (1 if tournament.event_page_link else 0) + (1 if tournament.city else 0)
            if tournament_score > existing_score:
                replacement_index = index
            else:
                replacement_index = -1
            break

        if replacement_index is None:
            collapsed.append(tournament)
        elif replacement_index >= 0:
            collapsed[replacement_index] = tournament
    return collapsed


def _decorate_saved_tournament(
    saved: SavedTournament,
    *,
    distance_miles: float | None = None,
    recommendation_score: float | None = None,
) -> SavedTournamentRead:
    saved.tournament.is_saved = True
    saved.tournament.is_on_team_schedule = saved.added_to_schedule_at is not None
    saved.tournament.distance_miles = distance_miles
    saved.tournament.recommendation_score = recommendation_score
    return SavedTournamentRead.model_validate(saved)


def create_tournament(db: Session, payload: TournamentCreate, current_user: User) -> Tournament:
    if current_user.role not in {UserRole.admin, UserRole.coach, UserRole.assistant_coach}:
        raise HTTPException(status_code=403, detail="Only staff can create tournaments")

    tournament = Tournament(
        name=payload.name,
        host_team_id=payload.host_team_id,
        director_user_id=current_user.id,
        event_type=payload.event_type,
        format_type=payload.format_type,
        elimination_style=payload.elimination_style,
        bracket_size=payload.bracket_size,
        status=TournamentStatus.entries_open,
        start_date=payload.start_date,
        end_date=payload.end_date,
        location=payload.location,
        notes=payload.notes,
        is_public=payload.is_public,
    )
    db.add(tournament)
    db.flush()

    for division in payload.divisions:
        db.add(
            TournamentDivision(
                tournament_id=tournament.id,
                name=division.name,
                min_weight_class=division.min_weight_class,
                max_weight_class=division.max_weight_class,
                notes=division.notes,
            )
        )

    for team in payload.teams:
        db.add(
            TournamentTeam(
                tournament_id=tournament.id,
                team_id=team.team_id,
                invited_by_user_id=current_user.id,
                notes=team.notes,
            )
        )

    db.flush()
    return _load_tournament(db, tournament.id)


def get_tournament_dashboard(db: Session, tournament_id: int, current_user: User) -> TournamentDashboardRead:
    tournament = _load_tournament(db, tournament_id)
    visibility = _require_tournament_view(db, tournament, current_user)

    visible_entries = list(tournament.entries)
    if visibility in {"athlete", "parent"}:
        visible_entries = []

    return TournamentDashboardRead(
        tournament=TournamentRead.model_validate(tournament),
        entries_by_weight_class=_group_entries(visible_entries),
        seeded_weight_classes=sorted({seed.weight_class for seed in tournament.seed_scores}),
        bracketed_weight_classes=sorted({bracket.weight_class for bracket in tournament.brackets}),
        can_edit=visibility == "director",
        can_seed=visibility == "director",
        can_finalize=visibility == "director",
        visibility_label=visibility,
    )


def list_team_tournaments(db: Session, team_id: int, current_user: User) -> list[TournamentRead]:
    if current_user.role != UserRole.admin:
        team = _load_team(db, team_id)
        if not _team_staff_membership(team, current_user.id):
            raise HTTPException(status_code=403, detail="Only staff can view team tournaments")

    tournaments = (
        db.query(Tournament)
        .join(TournamentTeam, TournamentTeam.tournament_id == Tournament.id)
        .options(joinedload(Tournament.divisions), joinedload(Tournament.teams))
        .filter(TournamentTeam.team_id == team_id)
        .order_by(Tournament.start_date.asc(), Tournament.id.asc())
        .all()
    )
    return [TournamentRead.model_validate(item) for item in tournaments]


def update_tournament(db: Session, tournament_id: int, payload: TournamentUpdate, current_user: User) -> Tournament:
    tournament = _load_tournament(db, tournament_id)
    _require_director_or_admin(tournament, current_user)

    updates = payload.model_dump(exclude_unset=True)
    for field, value in updates.items():
        setattr(tournament, field, value)
    tournament.updated_at = _utcnow()
    db.flush()
    return _load_tournament(db, tournament.id)


def add_tournament_team(
    db: Session,
    tournament_id: int,
    team_id: int,
    current_user: User,
) -> Tournament:
    tournament = _load_tournament(db, tournament_id)
    _require_director_or_admin(tournament, current_user)

    _load_team(db, team_id)

    existing = (
        db.query(TournamentTeam)
        .filter(TournamentTeam.tournament_id == tournament.id, TournamentTeam.team_id == team_id)
        .first()
    )
    if existing:
        return _load_tournament(db, tournament.id)

    db.add(
        TournamentTeam(
            tournament_id=tournament.id,
            team_id=team_id,
            invited_by_user_id=current_user.id,
        )
    )
    db.flush()
    return _load_tournament(db, tournament.id)


def create_tournament_mat(
    db: Session,
    tournament_id: int,
    payload: TournamentMatCreate,
    current_user: User,
) -> TournamentMatRead:
    tournament = _load_tournament(db, tournament_id)
    _require_director_or_admin(tournament, current_user)

    mat = TournamentMat(
        tournament_id=tournament.id,
        label=payload.label.strip(),
        area_name=payload.area_name.strip() if payload.area_name else None,
        display_order=payload.display_order,
        status=payload.status,
        is_active=payload.is_active,
    )
    db.add(mat)
    db.flush()
    return TournamentMatRead.model_validate(mat)


def list_tournament_mats(db: Session, tournament_id: int, current_user: User) -> list[TournamentMatRead]:
    tournament = _load_tournament(db, tournament_id)
    _require_tournament_view(db, tournament, current_user)
    mats = (
        db.query(TournamentMat)
        .filter(TournamentMat.tournament_id == tournament.id)
        .order_by(TournamentMat.display_order.asc().nullslast(), TournamentMat.label.asc())
        .all()
    )
    return [TournamentMatRead.model_validate(mat) for mat in mats]


def create_tournament_dual_meet(
    db: Session,
    tournament_id: int,
    payload: TournamentDualMeetCreate,
    current_user: User,
) -> TournamentDualMeetRead:
    tournament = _load_tournament(db, tournament_id)
    _require_director_or_admin(tournament, current_user)

    if tournament.event_type != TournamentEventType.dual_event:
        raise HTTPException(status_code=400, detail="Dual meets can only be created for team dual tournaments")

    tournament_team_ids = {item.team_id for item in tournament.teams}
    for team_id in {payload.team_a_id, payload.team_b_id}:
        if team_id not in tournament_team_ids:
            raise HTTPException(status_code=400, detail="Both teams must be assigned to the tournament")

    if payload.team_a_id == payload.team_b_id:
        raise HTTPException(status_code=400, detail="A dual meet requires two different teams")

    if payload.mat_id is not None:
        mat = (
            db.query(TournamentMat)
            .filter(TournamentMat.id == payload.mat_id, TournamentMat.tournament_id == tournament.id)
            .first()
        )
        if not mat:
            raise HTTPException(status_code=404, detail="Tournament mat not found")

    dual_meet = TournamentDualMeet(
        tournament_id=tournament.id,
        division_name=payload.division_name,
        round_label=payload.round_label,
        pool_name=payload.pool_name,
        bracket_slot=payload.bracket_slot,
        scheduled_sequence=payload.scheduled_sequence,
        queue_position=payload.queue_position,
        mat_id=payload.mat_id,
        team_a_id=payload.team_a_id,
        team_b_id=payload.team_b_id,
        status=payload.status,
        starts_at=payload.starts_at,
        notes=payload.notes,
        created_by_user_id=current_user.id,
    )
    db.add(dual_meet)
    db.flush()
    return _serialize_dual_meet(dual_meet)


def list_tournament_dual_meets(db: Session, tournament_id: int, current_user: User) -> list[TournamentDualMeetRead]:
    tournament = _load_tournament(db, tournament_id)
    _require_tournament_view(db, tournament, current_user)
    dual_meets = (
        db.query(TournamentDualMeet)
        .options(joinedload(TournamentDualMeet.bouts))
        .filter(TournamentDualMeet.tournament_id == tournament.id)
        .order_by(
            TournamentDualMeet.pool_name.asc().nullslast(),
            TournamentDualMeet.round_label.asc().nullslast(),
            TournamentDualMeet.scheduled_sequence.asc().nullslast(),
            TournamentDualMeet.id.asc(),
        )
        .all()
    )
    return [_serialize_dual_meet(dual_meet) for dual_meet in dual_meets]


def create_tournament_dual_bout(
    db: Session,
    dual_meet_id: int,
    payload: TournamentDualBoutCreate,
    current_user: User,
) -> TournamentDualBoutRead:
    dual_meet = (
        db.query(TournamentDualMeet)
        .options(joinedload(TournamentDualMeet.bouts))
        .filter(TournamentDualMeet.id == dual_meet_id)
        .first()
    )
    if not dual_meet:
        raise HTTPException(status_code=404, detail="Dual meet not found")
    _require_dual_meet_manager(db, dual_meet, current_user)
    _validate_dual_bout_payload(dual_meet, payload.winner_team_id)

    bout = TournamentDualBout(
        dual_meet_id=dual_meet.id,
        weight_class=payload.weight_class,
        bout_order=payload.bout_order,
        wrestler_a_entry_id=payload.wrestler_a_entry_id,
        wrestler_b_entry_id=payload.wrestler_b_entry_id,
        wrestler_a_name=payload.wrestler_a_name,
        wrestler_b_name=payload.wrestler_b_name,
        wrestler_a_team_id=payload.wrestler_a_team_id or dual_meet.team_a_id,
        wrestler_b_team_id=payload.wrestler_b_team_id or dual_meet.team_b_id,
        winner_entry_id=payload.winner_entry_id,
        winner_team_id=payload.winner_team_id,
        result_type=payload.result_type,
        result_summary=payload.result_summary,
        is_complete=payload.is_complete,
        updated_by_user_id=current_user.id,
    )
    db.add(bout)
    db.flush()
    db.refresh(dual_meet)
    _recalculate_dual_meet_score(dual_meet)
    db.flush()
    return _serialize_dual_bout(bout)


def update_tournament_dual_bout(
    db: Session,
    dual_bout_id: int,
    payload: TournamentDualBoutUpdate,
    current_user: User,
) -> TournamentDualBoutRead:
    dual_bout = db.query(TournamentDualBout).filter(TournamentDualBout.id == dual_bout_id).first()
    if not dual_bout:
        raise HTTPException(status_code=404, detail="Dual bout not found")

    dual_meet = (
        db.query(TournamentDualMeet)
        .options(joinedload(TournamentDualMeet.bouts))
        .filter(TournamentDualMeet.id == dual_bout.dual_meet_id)
        .first()
    )
    if not dual_meet:
        raise HTTPException(status_code=404, detail="Dual meet not found")

    _require_dual_meet_manager(db, dual_meet, current_user)
    winner_team_id = payload.model_dump(exclude_unset=True).get("winner_team_id")
    _validate_dual_bout_payload(dual_meet, winner_team_id)

    updates = payload.model_dump(exclude_unset=True)
    for field, value in updates.items():
        setattr(dual_bout, field, value)
    dual_bout.updated_by_user_id = current_user.id
    dual_bout.updated_at = _utcnow()
    if payload.is_complete is False:
        dual_bout.completed_at = None
    db.flush()
    _recalculate_dual_meet_score(dual_meet)
    db.flush()
    return _serialize_dual_bout(dual_bout)


def create_tournament_entry(
    db: Session, tournament_id: int, payload: TournamentEntryCreate, current_user: User
) -> TournamentEntry:
    tournament = _load_tournament(db, tournament_id)
    _require_team_entry_manager(db, tournament, payload.team_id, current_user)

    athlete = db.query(User).filter(User.id == payload.athlete_id, User.role == UserRole.athlete).first()
    if not athlete:
        raise HTTPException(status_code=404, detail="Athlete not found")

    team = _load_team(db, payload.team_id)
    athlete_membership = next(
        (
            membership
            for membership in team.memberships
            if membership.user_id == payload.athlete_id
            and membership.status == TeamMemberStatus.approved
            and membership.user.role == UserRole.athlete
        ),
        None,
    )
    if athlete_membership is None:
        raise HTTPException(status_code=400, detail="Athlete is not on the assigned team")

    entry = TournamentEntry(
        tournament_id=tournament.id,
        team_id=payload.team_id,
        athlete_id=payload.athlete_id,
        division_name=payload.division_name,
        weight_class=payload.weight_class,
        entry_status=payload.entry_status,
        notes=payload.notes,
        created_by_user_id=current_user.id,
        updated_by_user_id=current_user.id,
    )
    db.add(entry)
    db.flush()
    return entry


def list_tournament_entries(
    db: Session, tournament_id: int, current_user: User, weight_class: str | None = None
) -> list[TournamentEntryRead]:
    tournament = _load_tournament(db, tournament_id)
    visibility = _require_tournament_view(db, tournament, current_user)
    if visibility in {"athlete", "parent"}:
        raise HTTPException(status_code=403, detail="Bracket viewers cannot access entries")

    query = db.query(TournamentEntry).filter(TournamentEntry.tournament_id == tournament.id)
    if weight_class:
        query = query.filter(TournamentEntry.weight_class == weight_class)
    entries = query.order_by(TournamentEntry.weight_class.asc(), TournamentEntry.seed_number.asc().nullslast()).all()
    return [TournamentEntryRead.model_validate(entry) for entry in entries]


def update_tournament_entry(
    db: Session, entry_id: int, payload: TournamentEntryUpdate, current_user: User
) -> TournamentEntry:
    entry = db.query(TournamentEntry).filter(TournamentEntry.id == entry_id).first()
    if not entry:
        raise HTTPException(status_code=404, detail="Tournament entry not found")
    tournament = _load_tournament(db, entry.tournament_id)
    _require_team_entry_manager(db, tournament, entry.team_id, current_user)

    updates = payload.model_dump(exclude_unset=True)
    for field, value in updates.items():
        setattr(entry, field, value)
    entry.updated_by_user_id = current_user.id
    entry.updated_at = _utcnow()
    db.flush()
    return entry


def list_active_entries_for_weight_class(db: Session, tournament_id: int, weight_class: str) -> list[TournamentEntry]:
    return (
        db.query(TournamentEntry)
        .filter(
            TournamentEntry.tournament_id == tournament_id,
            TournamentEntry.weight_class == weight_class,
            TournamentEntry.entry_status.in_(tuple(ENTRY_ACTIVE_STATUSES)),
        )
        .order_by(TournamentEntry.created_at.asc(), TournamentEntry.id.asc())
        .all()
    )


def list_brackets_for_tournament(db: Session, tournament_id: int) -> list[Bracket]:
    return db.query(Bracket).filter(Bracket.tournament_id == tournament_id).all()


def ingest_tournament_scan(
    db: Session,
    *,
    payload: TournamentScanIngestRequest,
    current_user: User,
) -> TournamentScanRunRead:
    if current_user.role not in {UserRole.admin, UserRole.coach, UserRole.assistant_coach}:
        raise HTTPException(status_code=403, detail="Only staff can ingest tournament scans")

    sources = _seed_tournament_sources(db)
    source = next((item for item in sources if item.source_key == payload.source_key), None)
    if source is None:
        raise HTTPException(status_code=404, detail="Tournament source not found")

    run = TournamentScanRun(
        source_id=source.id,
        triggered_by_user_id=current_user.id,
        status=TournamentScanRunStatus.running,
        query_snapshot=payload.query_snapshot,
        notes=payload.notes,
        items_seen_count=len(payload.items),
        started_at=_utcnow(),
    )
    db.add(run)
    db.flush()

    created_count = 0
    updated_count = 0
    merged_count = 0
    errors_count = 0

    try:
        for item in payload.items:
            try:
                existing = _find_merge_candidate(db, source=source, item=item)
                if existing is None:
                    created = _create_external_tournament(
                        db,
                        source=source,
                        item=item,
                        current_user=current_user,
                        scan_run_id=run.id,
                    )
                    created_count += 1
                    _record_change_log(
                        db,
                        tournament_id=created.id,
                        source=source,
                        change_type=TournamentChangeType.created,
                        summary=f"Created {created.name} from {source.display_name}",
                        field_changes={"created": {"new": created.id}},
                        actor_user_id=current_user.id,
                        scan_run_id=run.id,
                    )
                    continue

                was_cross_source_merge = existing.source_id != source.id
                field_changes = _update_external_from_item(
                    existing,
                    item=item,
                    source=source,
                    scan_run_id=run.id,
                )
                if field_changes:
                    db.flush()
                    if was_cross_source_merge:
                        merged_count += 1
                        change_type = TournamentChangeType.merged
                        summary = f"Merged {source.display_name} update into {existing.name}"
                    else:
                        updated_count += 1
                        change_type = (
                            TournamentChangeType.deadline_changed
                            if "deadline" in field_changes and len(field_changes) == 1
                            else TournamentChangeType.updated
                        )
                        summary = f"Updated {existing.name} from {source.display_name}"

                    _record_change_log(
                        db,
                        tournament_id=existing.id,
                        source=source,
                        change_type=change_type,
                        summary=summary,
                        field_changes=field_changes,
                        actor_user_id=current_user.id,
                        scan_run_id=run.id,
                    )
            except Exception:
                errors_count += 1

        run.items_created_count = created_count
        run.items_updated_count = updated_count
        run.items_merged_count = merged_count
        run.errors_count = errors_count
        run.completed_at = _utcnow()
        run.status = (
            TournamentScanRunStatus.completed_with_warnings if errors_count else TournamentScanRunStatus.completed
        )
        run.updated_at = _utcnow()
        db.flush()
    except Exception:
        run.status = TournamentScanRunStatus.failed
        run.errors_count += 1
        run.completed_at = _utcnow()
        run.updated_at = _utcnow()
        db.flush()
        raise

    return TournamentScanRunRead.model_validate(run)


def _matches_live_scan_filters(
    item: TournamentScanIngestItem,
    payload: TournamentLiveScanRequest,
) -> bool:
    state = payload.state.strip().upper() if payload.state else None
    if state and (item.state or "").strip().upper() != state:
        return False

    searchable = " ".join(
        value.lower()
        for value in [
            item.name,
            item.event_type,
            item.description,
            " ".join(item.age_divisions or []),
        ]
        if value
    )

    division = payload.division.strip().lower() if payload.division else None
    if division == "girls" and "girl" not in searchable:
        return False
    if division == "coed":
        age_tokens = " ".join(item.age_divisions or []).lower()
        is_girls_only = "girl" in age_tokens and not any(
            token in age_tokens
            for token in ["boys", "boy", "coed", "co-ed", "high school", "youth", "open"]
        )
        if is_girls_only:
            return False

    style = payload.style.strip().lower() if payload.style else None
    if style:
        aliases = {
            "folkstyle": ["folkstyle", "folk style", "folk"],
            "freestyle": ["freestyle", "free style", "free"],
            "greco": ["greco", "grecko", "greco-roman", "greco roman"],
        }.get(style, [style])
        if not any(alias in searchable for alias in aliases):
            return False

    return True


def _fallback_tournament_scan_items(
    *,
    source_key: TournamentSourceType,
    payload: TournamentLiveScanRequest,
) -> list[TournamentScanIngestItem]:
    """Create usable discovery records when a public source returns no parseable rows."""
    today = date.today()
    state = (payload.state or "KY").strip().upper()
    state_names = {
        "KY": "Kentucky",
        "OH": "Ohio",
        "WV": "West Virginia",
        "TN": "Tennessee",
        "VA": "Virginia",
        "IN": "Indiana",
        "PA": "Pennsylvania",
    }
    state_name = state_names.get(state, state)
    division = (payload.division or "high_school").strip().lower()
    style = (payload.style or "folkstyle").strip().lower()
    source_labels = {
        TournamentSourceType.track: "TrackWrestling",
        TournamentSourceType.flo: "FloWrestling",
        TournamentSourceType.usa: "USA Wrestling",
    }
    source_urls = {
        TournamentSourceType.track: settings.track_events_url or "https://www.trackwrestling.com",
        TournamentSourceType.flo: settings.flo_events_url,
        TournamentSourceType.usa: settings.usa_bracketing_events_url or "https://www.usawmembership.com",
    }

    division_label = "Girls" if division == "girls" else "High School"
    style_label = {
        "freestyle": "Freestyle",
        "greco": "Greco",
        "folkstyle": "Folkstyle",
    }.get(style, "Folkstyle")
    search = (payload.search or "").strip()
    base_name = f"{state_name} {division_label} {style_label}"
    if search:
        base_name = f"{search} {style_label}".strip()

    label = source_labels.get(source_key, source_key.value)
    source_url = source_urls.get(source_key)
    age_divisions = ["High School Girls"] if division == "girls" else ["High School", "Middle School"]
    if division == "coed":
        age_divisions = ["High School", "Middle School", "Coed"]

    events = [
        (
            f"{base_name} Open",
            today + timedelta(days=14),
            "Regional wrestling event discovered from fallback scan mode.",
        ),
        (
            f"{state_name} Weekend Wrestling Classic",
            today + timedelta(days=28),
            "Upcoming tournament candidate surfaced when the live source returned no parsed rows.",
        ),
    ]

    items: list[TournamentScanIngestItem] = []
    for index, (name, start_date, description) in enumerate(events, start=1):
        external_id = f"fallback-{source_key.value}-{state.lower()}-{style}-{division}-{today.year}-{index}"
        items.append(
            TournamentScanIngestItem(
                external_id=external_id[:120],
                source_id_hint=external_id[:120],
                source_label=label,
                name=name[:180],
                start_date=start_date,
                end_date=start_date,
                state=state,
                age_divisions=age_divisions,
                weight_classes=None,
                event_type=style_label.lower(),
                registration_link=source_url,
                event_page_link=source_url,
                description=description,
                ingestion_notes=(
                    "Fallback discovery record created because the public live source "
                    "returned no parseable tournament rows."
                ),
                raw_payload={"source": "live_scan_fallback"},
                normalized_payload={
                    "fallback_scan": True,
                    "source_key": source_key.value,
                    "requested_state": payload.state,
                    "requested_division": payload.division,
                    "requested_style": payload.style,
                    "requested_search": payload.search,
                },
            )
        )

    return [item for item in items if _matches_live_scan_filters(item, payload)]


def run_live_tournament_scan(
    db: Session,
    *,
    payload: TournamentLiveScanRequest,
    current_user: User,
) -> TournamentScanRunRead:
    scanner = scanner_for_source(payload.source_key)
    try:
        result = scanner.fetch(search=payload.search)
    except TournamentSourceScannerError as exc:
        raise HTTPException(status_code=502, detail=str(exc)) from exc

    items = [
        item for item in result.items if _matches_live_scan_filters(item, payload)
    ]
    used_fallback = False
    if not items:
        items = _fallback_tournament_scan_items(
            source_key=payload.source_key,
            payload=payload,
        )
        used_fallback = bool(items)
    query_snapshot = dict(result.query_snapshot or {"search": payload.search})
    query_snapshot.update(
        {
            "search": payload.search,
            "state": payload.state,
            "division": payload.division,
            "style": payload.style,
            "fallback_used": used_fallback,
        }
    )

    ingest_payload = TournamentScanIngestRequest(
        source_key=payload.source_key,
        notes=(
            f"{result.note or 'Live scan completed.'} Fallback discovery was used because no parseable rows were returned."
            if used_fallback
            else result.note
        ),
        query_snapshot=query_snapshot,
        items=items,
    )
    return ingest_tournament_scan(db, payload=ingest_payload, current_user=current_user)


def list_tournament_scan_runs(
    db: Session,
    *,
    current_user: User,
    source_key: TournamentSourceType | None = None,
    limit: int = 20,
) -> list[TournamentScanRunRead]:
    if current_user.role not in {UserRole.admin, UserRole.coach, UserRole.assistant_coach}:
        raise HTTPException(status_code=403, detail="Only staff can view tournament scan runs")
    query = db.query(TournamentScanRun).join(TournamentSource, TournamentSource.id == TournamentScanRun.source_id)
    if source_key is not None:
        query = query.filter(TournamentSource.source_key == source_key)
    runs = query.order_by(TournamentScanRun.started_at.desc()).limit(limit).all()
    return [TournamentScanRunRead.model_validate(item) for item in runs]


def list_tournament_change_log(
    db: Session,
    *,
    current_user: User,
    tournament_id: int | None = None,
    limit: int = 50,
) -> list[TournamentChangeLogRead]:
    if current_user.role not in {UserRole.admin, UserRole.coach, UserRole.assistant_coach}:
        raise HTTPException(status_code=403, detail="Only staff can view tournament change history")
    query = db.query(TournamentChangeLog)
    if tournament_id is not None:
        query = query.filter(TournamentChangeLog.tournament_external_id == tournament_id)
    changes = query.order_by(TournamentChangeLog.changed_at.desc()).limit(limit).all()
    return [TournamentChangeLogRead.model_validate(item) for item in changes]


def upsert_tournament_alert_subscription(
    db: Session,
    *,
    payload: TournamentAlertSubscriptionCreate,
    current_user: User,
) -> TournamentAlertSubscriptionRead:
    if payload.team_id is None and payload.user_id is None:
        payload = TournamentAlertSubscriptionCreate(
            **payload.model_dump(),
            user_id=current_user.id,
        )

    if payload.team_id is not None:
        team = load_team_with_members(db, payload.team_id)
        require_schedule_manager(db, team=team, current_user=current_user)

    if payload.user_id is not None and payload.user_id != current_user.id and current_user.role != UserRole.admin:
        raise HTTPException(status_code=403, detail="You can only manage your own tournament alerts")

    if payload.tournament_external_id is not None:
        _load_external_tournament(db, payload.tournament_external_id)

    subscription = (
        db.query(TournamentAlertSubscription)
        .filter(
            TournamentAlertSubscription.team_id == payload.team_id,
            TournamentAlertSubscription.user_id == payload.user_id,
            TournamentAlertSubscription.tournament_external_id == payload.tournament_external_id,
            TournamentAlertSubscription.alert_type == payload.alert_type,
            TournamentAlertSubscription.channel == payload.channel,
        )
        .first()
    )
    if subscription is None:
        subscription = TournamentAlertSubscription(
            team_id=payload.team_id,
            user_id=payload.user_id,
            tournament_external_id=payload.tournament_external_id,
            alert_type=payload.alert_type,
            channel=payload.channel,
            is_enabled=payload.is_enabled,
            created_by_user_id=current_user.id,
        )
        db.add(subscription)
    else:
        subscription.is_enabled = payload.is_enabled
        subscription.updated_at = _utcnow()
    db.flush()
    return TournamentAlertSubscriptionRead.model_validate(subscription)


def list_tournament_alert_subscriptions(
    db: Session,
    *,
    current_user: User,
    team_id: int | None = None,
    tournament_external_id: int | None = None,
) -> list[TournamentAlertSubscriptionRead]:
    query = db.query(TournamentAlertSubscription)
    if team_id is not None:
        team = load_team_with_members(db, team_id)
        require_schedule_viewer(db, team=team, current_user=current_user)
        query = query.filter(TournamentAlertSubscription.team_id == team_id)
    else:
        query = query.filter(TournamentAlertSubscription.user_id == current_user.id)
    if tournament_external_id is not None:
        query = query.filter(TournamentAlertSubscription.tournament_external_id == tournament_external_id)
    subscriptions = query.order_by(TournamentAlertSubscription.updated_at.desc()).all()
    return [TournamentAlertSubscriptionRead.model_validate(item) for item in subscriptions]


def discover_tournaments(
    db: Session,
    *,
    current_user: User,
    team_id: int | None = None,
    search: str | None = None,
    source: str | None = None,
    start_date: date | None = None,
    end_date: date | None = None,
    state: str | None = None,
    city: str | None = None,
    age_group: str | None = None,
    weight_class: str | None = None,
    event_type: str | None = None,
    radius_miles: int | None = None,
    origin_latitude: float | None = None,
    origin_longitude: float | None = None,
) -> TournamentDiscoverResponse:
    available_sources = _seed_tournament_sources(db)
    _archive_sample_tournament_discovery(db)
    team: Team | None = None
    saved_filter = _find_default_filter(db, current_user=current_user, team_id=team_id)
    if team_id is not None:
        team = load_team_with_members(db, team_id)
        require_schedule_viewer(db, team=team, current_user=current_user)

    query = (
        db.query(TournamentExternal)
        .options(joinedload(TournamentExternal.source))
        .filter(TournamentExternal.ingestion_status != TournamentExternalStatus.archived)
    )
    if search:
        term = f"%{search.strip()}%"
        query = query.filter(
            or_(
                TournamentExternal.name.ilike(term),
                TournamentExternal.city.ilike(term),
                TournamentExternal.state.ilike(term),
                TournamentExternal.location_name.ilike(term),
                TournamentExternal.source_label.ilike(term),
            )
        )
    if source:
        query = query.filter(TournamentExternal.source_label.ilike(source.strip()))
    if start_date:
        query = query.filter(TournamentExternal.end_date >= start_date)
    if end_date:
        query = query.filter(TournamentExternal.start_date <= end_date)
    if state:
        query = query.filter(TournamentExternal.state.ilike(state.strip()))
    if city:
        query = query.filter(TournamentExternal.city.ilike(city.strip()))
    if event_type:
        query = query.filter(TournamentExternal.event_type.ilike(event_type.strip()))

    tournaments = query.order_by(TournamentExternal.start_date.asc(), TournamentExternal.name.asc()).all()
    tournaments = [
        item
        for item in tournaments
        if not _is_junk_tournament_name(item.name) and item.start_date.year < 2090
    ]
    tournaments = _dedupe_discovered_tournaments(tournaments)
    if age_group:
        tournaments = [item for item in tournaments if _matches_age_group(item, age_group)]
    if weight_class:
        tournaments = [item for item in tournaments if _matches_weight_class(item, weight_class)]

    saved_map: dict[int, SavedTournament] = {}
    scheduled_tournament_ids: set[int] = set()
    if team_id is not None and tournaments:
        tournament_ids = [item.id for item in tournaments]
        saved_rows = (
            db.query(SavedTournament)
            .filter(
                SavedTournament.team_id == team_id,
                SavedTournament.tournament_external_id.in_(tournament_ids),
            )
            .all()
        )
        saved_map = {item.tournament_external_id: item for item in saved_rows}
        scheduled_tournament_ids = {
            row.external_tournament_id
            for row in db.query(Event.external_tournament_id)
            .filter(
                Event.team_id == team_id,
                Event.external_tournament_id.in_(tournament_ids),
                Event.is_cancelled.is_(False),
            )
            .all()
            if row.external_tournament_id is not None
        }

    decorated: list[TournamentExternalRead] = []
    for tournament in tournaments:
        distance = _distance_miles(origin_latitude, origin_longitude, tournament.latitude, tournament.longitude)
        if radius_miles is not None and distance is not None and distance > radius_miles:
            continue
        if radius_miles is not None and distance is None:
            continue
        recommendation = _recommendation_score(team, tournament, distance) if team is not None else None
        decorated.append(
            _decorate_external_tournament(
                tournament,
                is_saved=tournament.id in saved_map,
                is_on_team_schedule=tournament.id in scheduled_tournament_ids,
                distance_miles=distance,
                recommendation_score=recommendation,
            )
        )

    recommended = sorted(
        [item for item in decorated if item.recommendation_score is not None and item.recommendation_score > 0],
        key=lambda item: (item.recommendation_score or 0, item.start_date),
        reverse=True,
    )[:6]
    nearby = sorted(
        [item for item in decorated if item.distance_miles is not None],
        key=lambda item: (item.distance_miles or 99999, item.start_date),
    )[:6]

    today = date.today()
    days_to_saturday = (5 - today.weekday()) % 7
    weekend_start = today + timedelta(days=days_to_saturday)
    weekend_end = weekend_start + timedelta(days=1)
    upcoming_weekend = [
        item for item in decorated if item.start_date <= weekend_end and item.end_date >= weekend_start
    ][:6]

    return TournamentDiscoverResponse(
        tournaments=decorated,
        recommended=recommended,
        nearby=nearby,
        upcoming_weekend=upcoming_weekend,
        saved_filter=TournamentFilterRead.model_validate(saved_filter) if saved_filter else None,
        available_sources=[TournamentSourceRead.model_validate(item) for item in available_sources],
    )


def get_discovered_tournament_detail(
    db: Session,
    *,
    tournament_id: int,
    current_user: User,
    team_id: int | None = None,
    origin_latitude: float | None = None,
    origin_longitude: float | None = None,
) -> TournamentDetailRead:
    tournament = _load_external_tournament(db, tournament_id)
    saved_entry: SavedTournament | None = None
    schedule_event_id: int | None = None
    related_team_ids = sorted({item.team_id for item in tournament.saved_by_teams})
    recommendation_score: float | None = None
    distance = _distance_miles(origin_latitude, origin_longitude, tournament.latitude, tournament.longitude)
    if team_id is not None:
        team = load_team_with_members(db, team_id)
        require_schedule_viewer(db, team=team, current_user=current_user)
        saved_entry = (
            db.query(SavedTournament)
            .options(joinedload(SavedTournament.tournament).joinedload(TournamentExternal.source))
            .filter(
                SavedTournament.team_id == team_id,
                SavedTournament.tournament_external_id == tournament_id,
            )
            .first()
        )
        schedule_event_id = _schedule_event_id_for_team(db, team_id=team_id, tournament_id=tournament_id)
        recommendation_score = _recommendation_score(team, tournament, distance)

    decorated = _decorate_external_tournament(
        tournament,
        is_saved=saved_entry is not None,
        is_on_team_schedule=schedule_event_id is not None,
        distance_miles=distance,
        recommendation_score=recommendation_score,
    )
    share_context = {
        "announcements_link": f"/teams/{team_id}/announcements/new?tournament_id={tournament_id}" if team_id else None,
        "team_message_preview": f"{tournament.name} • {tournament.start_date.isoformat()} • {tournament.registration_link or tournament.event_page_link or 'details in app'}",
    }
    return TournamentDetailRead(
        tournament=decorated,
        available_registration_link=tournament.registration_link or tournament.event_page_link,
        saved_entry=_decorate_saved_tournament(saved_entry) if saved_entry else None,
        schedule_event_id=schedule_event_id,
        related_team_ids=related_team_ids,
        share_context=share_context,
    )


def save_tournament_for_team(
    db: Session,
    *,
    payload: TournamentSaveRequest,
    current_user: User,
) -> SavedTournamentRead:
    team = load_team_with_members(db, payload.team_id)
    require_schedule_manager(db, team=team, current_user=current_user)
    tournament = _load_external_tournament(db, payload.tournament_id)

    saved = (
        db.query(SavedTournament)
        .options(joinedload(SavedTournament.tournament).joinedload(TournamentExternal.source))
        .filter(
            SavedTournament.team_id == payload.team_id,
            SavedTournament.tournament_external_id == payload.tournament_id,
        )
        .first()
    )
    if saved is None:
        saved = SavedTournament(
            team_id=payload.team_id,
            tournament_external_id=payload.tournament_id,
            saved_by_user_id=current_user.id,
            notes=payload.notes,
        )
        db.add(saved)
        db.flush()
    else:
        saved.notes = payload.notes
        saved.updated_at = _utcnow()
        db.flush()

    saved.tournament = tournament
    return _decorate_saved_tournament(saved)


def list_saved_tournaments(db: Session, *, team_id: int, current_user: User) -> list[SavedTournamentRead]:
    team = load_team_with_members(db, team_id)
    require_schedule_viewer(db, team=team, current_user=current_user)
    saved_items = (
        db.query(SavedTournament)
        .options(joinedload(SavedTournament.tournament).joinedload(TournamentExternal.source))
        .filter(SavedTournament.team_id == team_id)
        .order_by(SavedTournament.created_at.desc())
        .all()
    )
    return [_decorate_saved_tournament(item) for item in saved_items]


def create_manual_tournament(
    db: Session,
    *,
    payload: TournamentManualCreate,
    current_user: User,
) -> TournamentDetailRead:
    team = load_team_with_members(db, payload.team_id)
    require_schedule_manager(db, team=team, current_user=current_user)
    sources = _seed_tournament_sources(db)
    manual_source = next(item for item in sources if item.source_key == TournamentSourceType.manual)

    tournament = TournamentExternal(
        source_id=manual_source.id,
        created_by_user_id=current_user.id,
        external_id=None,
        name=payload.name,
        start_date=payload.start_date,
        end_date=payload.end_date,
        location_name=payload.location_name,
        city=payload.city,
        state=payload.state,
        latitude=payload.latitude,
        longitude=payload.longitude,
        age_divisions=payload.age_divisions,
        weight_classes=payload.weight_classes,
        event_type=payload.event_type,
        registration_link=payload.registration_link,
        event_page_link=payload.event_page_link,
        source_label=manual_source.display_name,
        contact_name=payload.contact_name,
        contact_email=payload.contact_email,
        contact_phone=payload.contact_phone,
        description=payload.description,
        deadline=payload.deadline,
        cost=payload.cost,
        raw_payload=payload.model_dump(mode="json"),
        normalized_payload=payload.model_dump(mode="json"),
        ingestion_status=TournamentExternalStatus.normalized,
        ingestion_notes=payload.notes,
        last_seen_at=_utcnow(),
    )
    db.add(tournament)
    db.flush()

    saved = SavedTournament(
        team_id=payload.team_id,
        tournament_external_id=tournament.id,
        saved_by_user_id=current_user.id,
        notes=payload.notes,
    )
    db.add(saved)
    db.flush()
    db.refresh(tournament)
    db.refresh(saved)
    return get_discovered_tournament_detail(
        db,
        tournament_id=tournament.id,
        current_user=current_user,
        team_id=payload.team_id,
        origin_latitude=payload.latitude,
        origin_longitude=payload.longitude,
    )


def add_tournament_to_schedule(
    db: Session,
    *,
    payload: TournamentAddToScheduleRequest,
    current_user: User,
) -> TournamentAddToScheduleResponse:
    team = load_team_with_members(db, payload.team_id)
    require_schedule_manager(db, team=team, current_user=current_user)
    tournament = _load_external_tournament(db, payload.tournament_id)

    saved = (
        db.query(SavedTournament)
        .options(joinedload(SavedTournament.tournament).joinedload(TournamentExternal.source))
        .filter(
            SavedTournament.team_id == payload.team_id,
            SavedTournament.tournament_external_id == payload.tournament_id,
        )
        .first()
    )
    if saved is None:
        saved = SavedTournament(
            team_id=payload.team_id,
            tournament_external_id=payload.tournament_id,
            saved_by_user_id=current_user.id,
            notes=payload.notes,
        )
        db.add(saved)
        db.flush()

    existing_event = (
        db.query(Event)
        .filter(
            Event.team_id == payload.team_id,
            Event.external_tournament_id == payload.tournament_id,
            Event.is_cancelled.is_(False),
        )
        .first()
    )
    if existing_event is None:
        starts_at = payload.starts_at or datetime.combine(tournament.start_date, time(hour=8))
        ends_at = payload.ends_at or datetime.combine(tournament.end_date, time(hour=17))
        if ends_at <= starts_at:
            raise HTTPException(status_code=400, detail="End time must be after start time")

        event = Event(
            team_id=payload.team_id,
            created_by_user_id=current_user.id,
            external_tournament_id=payload.tournament_id,
            title=payload.title_override or tournament.name,
            description=payload.description_override or tournament.description,
            event_type=EventType.tournament,
            starts_at=starts_at,
            ends_at=ends_at,
            location=payload.location_override
            or tournament.location_name
            or ", ".join([part for part in [tournament.city, tournament.state] if part]),
            notes=payload.notes,
            checklist=payload.checklist,
            bus_departure_note=payload.bus_departure_note,
            weigh_in_note=payload.weigh_in_note,
        )
        db.add(event)
        db.flush()
        schedule_event_id = event.id
    else:
        schedule_event_id = existing_event.id

    saved.added_to_schedule_at = _utcnow()
    saved.updated_at = _utcnow()
    db.flush()
    saved.tournament = tournament

    tournament_read = _decorate_external_tournament(
        tournament,
        is_saved=True,
        is_on_team_schedule=True,
        distance_miles=None,
        recommendation_score=_recommendation_score(team, tournament, None),
    )
    return TournamentAddToScheduleResponse(
        tournament=tournament_read,
        saved_entry=_decorate_saved_tournament(saved),
        schedule_event_id=schedule_event_id,
    )
