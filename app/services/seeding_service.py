from __future__ import annotations

from collections import defaultdict
from datetime import datetime

from fastapi import HTTPException
from sqlalchemy.orm import Session, joinedload

from app.models.stats import AthleteStatSnapshot, Match, MatchOutcome, MatchResultType
from app.models.tournament import EntryStatus, SeedScore, SeedingOverride, SeedingSource, TournamentEntry, TournamentStatus
from app.models.user import User, UserRole
from app.schemas.tournament import SeedingCalculationResponse, SeedingExplanationRead, SeedingOverrideCreate, SeedScoreRead
from app.services.tournament_service import _load_tournament, _require_director_or_admin, _require_seed_view


BONUS_RESULTS = {
    MatchResultType.pin,
    MatchResultType.tech_fall,
    MatchResultType.major_decision,
    MatchResultType.forfeit,
    MatchResultType.default,
    MatchResultType.disqualification,
    MatchResultType.medical_forfeit,
}

SEED_WEIGHTS = {
    "win_percentage": 0.30,
    "head_to_head": 0.22,
    "common_opponents": 0.12,
    "recent_performance": 0.14,
    "bonus_point_rate": 0.08,
    "tournament_placements": 0.09,
    "ranking_bonus": 0.03,
    "coach_override_bonus": 0.02,
}

ENTRY_ACTIVE_STATUSES = {EntryStatus.entered, EntryStatus.replaced, EntryStatus.late_update}


def _load_entries(db: Session, tournament_id: int, weight_class: str | None = None) -> list[TournamentEntry]:
    query = (
        db.query(TournamentEntry)
        .options(joinedload(TournamentEntry.athlete))
        .filter(
            TournamentEntry.tournament_id == tournament_id,
            TournamentEntry.entry_status.in_(tuple(ENTRY_ACTIVE_STATUSES)),
        )
    )
    if weight_class:
        query = query.filter(TournamentEntry.weight_class == weight_class)
    return query.order_by(TournamentEntry.weight_class.asc(), TournamentEntry.created_at.asc()).all()


def _load_matches_for_athlete(db: Session, athlete_id: int, weight_class: str) -> list[Match]:
    matches = (
        db.query(Match)
        .filter(Match.athlete_id == athlete_id)
        .order_by(Match.match_date.desc(), Match.id.desc())
        .all()
    )
    weighted_matches = [match for match in matches if match.weight_class == weight_class]
    return weighted_matches or matches


def _load_snapshot(db: Session, athlete_id: int) -> AthleteStatSnapshot | None:
    return db.query(AthleteStatSnapshot).filter(AthleteStatSnapshot.athlete_id == athlete_id).first()


def _safe_ratio(value: float, total: int) -> float:
    if total <= 0:
        return 0.0
    return round(value / total, 4)


def _opponent_identity(match: Match) -> str:
    school = (match.opponent_school or "").strip().lower()
    return f"{match.opponent_name.strip().lower()}::{school}"


def _recent_form_score(matches: list[Match]) -> float:
    recent = matches[:5]
    if not recent:
        return 0.0
    weighted_total = 0.0
    max_total = 0.0
    for index, match in enumerate(recent):
        weight = 5 - index
        max_total += weight
        if match.result == MatchOutcome.win:
            weighted_total += weight
            if match.result_type in BONUS_RESULTS:
                weighted_total += 0.25
    return min(round(weighted_total / (max_total + 1.25), 4), 1.0)


def _placement_bonus(snapshot: AthleteStatSnapshot | None) -> float:
    if snapshot is None or not snapshot.summary_payload:
        return 0.0
    payload = snapshot.summary_payload
    explicit = payload.get("tournament_placement_score")
    if isinstance(explicit, (int, float)):
        return min(max(float(explicit), 0.0), 1.0)
    placements = payload.get("placements") or []
    if isinstance(placements, list) and placements:
        aggregate = 0.0
        for placement in placements[:3]:
            if placement == 1:
                aggregate += 1.0
            elif placement == 2:
                aggregate += 0.7
            elif placement == 3:
                aggregate += 0.45
            else:
                aggregate += 0.15
        return min(round(aggregate / max(len(placements[:3]), 1), 4), 1.0)
    return 0.0


def _ranking_bonus(snapshot: AthleteStatSnapshot | None) -> float:
    if snapshot is None or not snapshot.summary_payload:
        return 0.0
    payload = snapshot.summary_payload
    explicit = payload.get("ranking_bonus")
    if isinstance(explicit, (int, float)):
        return min(max(float(explicit), 0.0), 1.0)
    rank = payload.get("state_rank")
    if isinstance(rank, int) and rank > 0:
        return round(max(0.0, (11 - min(rank, 10)) / 10), 4)
    return 0.0


def _coach_bonus(snapshot: AthleteStatSnapshot | None) -> float:
    if snapshot is None or not snapshot.summary_payload:
        return 0.0
    explicit = snapshot.summary_payload.get("coach_seed_bonus")
    if isinstance(explicit, (int, float)):
        return min(max(float(explicit), 0.0), 1.0)
    return 0.0


def _head_to_head_score(entry: TournamentEntry, matches: list[Match], peers: list[TournamentEntry]) -> tuple[float, str]:
    peer_names = {peer.athlete.full_name.strip().lower() for peer in peers if peer.id != entry.id}
    relevant = [match for match in matches if match.opponent_name.strip().lower() in peer_names]
    if not relevant:
        return 0.0, "No direct head-to-head results in the current field."
    wins = sum(1 for match in relevant if match.result == MatchOutcome.win)
    return _safe_ratio(wins, len(relevant)), f"{wins}-{len(relevant) - wins} against wrestlers in this bracket pool."


def _common_opponent_score(
    entry: TournamentEntry,
    matches: list[Match],
    peers: list[TournamentEntry],
    peer_match_map: dict[int, list[Match]],
) -> tuple[float, str]:
    if not matches:
        return 0.0, "No recent data available."
    my_results = {_opponent_identity(match): match.result for match in matches}
    total = 0
    wins = 0
    for peer in peers:
        if peer.id == entry.id:
            continue
        for peer_match in peer_match_map[peer.id]:
            identity = _opponent_identity(peer_match)
            if identity not in my_results:
                continue
            total += 1
            if my_results[identity] == MatchOutcome.win and peer_match.result == MatchOutcome.loss:
                wins += 1
            elif my_results[identity] == peer_match.result:
                wins += 0.5
    if total == 0:
        return 0.0, "No common-opponent crossover found."
    return round(wins / total, 4), f"Compared well across {total} common-opponent datapoints."


def _component_breakdown(
    db: Session,
    entry: TournamentEntry,
    matches: list[Match],
    peers: list[TournamentEntry],
    peer_match_map: dict[int, list[Match]],
) -> tuple[dict, str]:
    total_matches = len(matches)
    wins = sum(1 for match in matches if match.result == MatchOutcome.win)
    win_percentage = _safe_ratio(wins, total_matches)
    bonus_wins = sum(1 for match in matches if match.result == MatchOutcome.win and match.result_type in BONUS_RESULTS)
    bonus_point_rate = _safe_ratio(bonus_wins, max(wins, 1))
    recent_performance = _recent_form_score(matches)
    snapshot = _load_snapshot(db, entry.athlete_id)
    placements = _placement_bonus(snapshot)
    ranking = _ranking_bonus(snapshot)
    coach_bonus = _coach_bonus(snapshot)
    head_to_head, h2h_summary = _head_to_head_score(entry, matches, peers)
    common_opponents, common_summary = _common_opponent_score(entry, matches, peers, peer_match_map)

    tie_break_hint = h2h_summary if head_to_head > 0 else common_summary
    breakdown = {
        "win_percentage": round(win_percentage, 4),
        "head_to_head": round(head_to_head, 4),
        "common_opponents": round(common_opponents, 4),
        "recent_performance": round(recent_performance, 4),
        "bonus_point_rate": round(bonus_point_rate, 4),
        "tournament_placements": round(placements, 4),
        "ranking_bonus": round(ranking, 4),
        "coach_override_bonus": round(coach_bonus, 4),
        "tie_break_hint": tie_break_hint,
    }
    explanation = (
        f"{entry.athlete.full_name} projects well because the win rate ({round(win_percentage * 100)}%), "
        f"head-to-head value ({round(head_to_head * 100)}%), recent form ({round(recent_performance * 100)}%), "
        f"and bonus finish rate ({round(bonus_point_rate * 100)}%) combine into a strong tournament profile. "
        f"Tie notes: {tie_break_hint}"
    )
    return breakdown, explanation


def _total_seed_score(breakdown: dict) -> float:
    total = 0.0
    for key, weight in SEED_WEIGHTS.items():
        total += float(breakdown.get(key, 0.0)) * weight
    return round(total, 4)


def _apply_seed_numbers(sorted_items: list[tuple[TournamentEntry, float, dict, str]]) -> list[tuple[TournamentEntry, int, float, dict, str]]:
    ranked: list[tuple[TournamentEntry, int, float, dict, str]] = []
    for index, item in enumerate(sorted_items, start=1):
        ranked.append((item[0], index, item[1], item[2], item[3]))
    return ranked


def _sort_seed_candidates(candidates: list[tuple[TournamentEntry, float, dict, str]]) -> list[tuple[TournamentEntry, float, dict, str]]:
    return sorted(
        candidates,
        key=lambda item: (
            -item[1],
            -item[2]["head_to_head"],
            -item[2]["recent_performance"],
            -item[2]["win_percentage"],
            item[0].athlete.full_name.lower(),
            item[0].id,
        ),
    )


def _rebuild_seed_rows(
    db: Session,
    tournament_id: int,
    weight_class: str,
    ranked_items: list[tuple[TournamentEntry, int, float, dict, str]],
) -> list[SeedScore]:
    existing = (
        db.query(SeedScore)
        .filter(SeedScore.tournament_id == tournament_id, SeedScore.weight_class == weight_class)
        .all()
    )
    for row in existing:
        db.delete(row)
    db.flush()

    rows: list[SeedScore] = []
    for entry, seed_number, score, breakdown, explanation in ranked_items:
        entry.seed_number = seed_number
        entry.seeded_at = datetime.utcnow()
        row = SeedScore(
            tournament_id=tournament_id,
            entry_id=entry.id,
            team_id=entry.team_id,
            athlete_id=entry.athlete_id,
            weight_class=entry.weight_class,
            division_name=entry.division_name,
            seed_number=seed_number,
            seed_score=score,
            score_breakdown=breakdown,
            seed_explanation=explanation,
            source=SeedingSource.calculated,
        )
        db.add(row)
        rows.append(row)
    db.flush()
    return rows


def _apply_saved_overrides(db: Session, tournament_id: int, weight_class: str) -> None:
    overrides = (
        db.query(SeedingOverride)
        .join(TournamentEntry, TournamentEntry.id == SeedingOverride.entry_id)
        .filter(
            SeedingOverride.tournament_id == tournament_id,
            TournamentEntry.weight_class == weight_class,
        )
        .order_by(SeedingOverride.created_at.asc(), SeedingOverride.id.asc())
        .all()
    )
    for override in overrides:
        _apply_override_reorder(db, tournament_id=tournament_id, entry_id=override.entry_id, seed_number=override.new_seed_number)


def _apply_override_reorder(db: Session, *, tournament_id: int, entry_id: int, seed_number: int) -> list[SeedScore]:
    rows = (
        db.query(SeedScore)
        .join(TournamentEntry, TournamentEntry.id == SeedScore.entry_id)
        .options(joinedload(SeedScore.entry).joinedload(TournamentEntry.athlete))
        .filter(SeedScore.tournament_id == tournament_id)
        .order_by(SeedScore.weight_class.asc(), SeedScore.seed_number.asc())
        .all()
    )
    target = next((row for row in rows if row.entry_id == entry_id), None)
    if not target:
        raise HTTPException(status_code=404, detail="Seed entry not found")

    same_class = [row for row in rows if row.weight_class == target.weight_class]
    requested = min(max(seed_number, 1), len(same_class))
    same_class.sort(key=lambda row: row.seed_number)
    same_class = [row for row in same_class if row.entry_id != entry_id]
    same_class.insert(requested - 1, target)

    for index, row in enumerate(same_class, start=1):
        row.seed_number = index
        row.entry.seed_number = index
        row.entry.seeded_at = datetime.utcnow()
        if row.entry_id == entry_id:
            row.source = SeedingSource.manual_override
            row.score_breakdown["coach_override_bonus"] = max(
                float(row.score_breakdown.get("coach_override_bonus", 0.0)),
                round((len(same_class) - index + 1) / max(len(same_class), 1), 4),
            )
            row.seed_explanation = (
                f"{row.entry.athlete.full_name} was manually moved to seed {index}. "
                f"Original model context remains preserved in the score breakdown."
            )
    db.flush()
    return same_class


def calculate_seeds(db: Session, tournament_id: int, current_user: User) -> SeedingCalculationResponse:
    tournament = _load_tournament(db, tournament_id)
    _require_director_or_admin(tournament, current_user)

    entries = _load_entries(db, tournament_id)
    if not entries:
        raise HTTPException(status_code=400, detail="No active entries available for seeding")

    by_weight: dict[str, list[TournamentEntry]] = defaultdict(list)
    for entry in entries:
        by_weight[entry.weight_class].append(entry)

    generated_rows: list[SeedScore] = []
    for weight_class, weight_entries in by_weight.items():
        peer_match_map: dict[int, list[Match]] = {}
        for entry in weight_entries:
            peer_match_map[entry.id] = _load_matches_for_athlete(db, entry.athlete_id, entry.weight_class)

        scored_candidates: list[tuple[TournamentEntry, float, dict, str]] = []
        for entry in weight_entries:
            breakdown, explanation = _component_breakdown(
                db,
                entry,
                peer_match_map[entry.id],
                weight_entries,
                peer_match_map,
            )
            score = _total_seed_score(breakdown)
            scored_candidates.append((entry, score, breakdown, explanation))

        ranked_items = _apply_seed_numbers(_sort_seed_candidates(scored_candidates))
        rows = _rebuild_seed_rows(db, tournament_id, weight_class, ranked_items)
        generated_rows.extend(rows)
        _apply_saved_overrides(db, tournament_id, weight_class)

    tournament.status = TournamentStatus.seeding_in_review
    tournament.updated_at = datetime.utcnow()
    db.flush()

    refreshed = (
        db.query(SeedScore)
        .filter(SeedScore.tournament_id == tournament_id)
        .order_by(SeedScore.weight_class.asc(), SeedScore.seed_number.asc())
        .all()
    )
    return SeedingCalculationResponse(
        tournament_id=tournament_id,
        weight_classes=sorted(by_weight.keys()),
        generated_count=len(refreshed),
        status=tournament.status,
        results=[SeedScoreRead.model_validate(row) for row in refreshed],
    )


def get_seeds_for_weight_class(db: Session, tournament_id: int, weight_class: str, current_user: User) -> list[SeedScoreRead]:
    tournament = _load_tournament(db, tournament_id)
    _require_seed_view(db, tournament, current_user)
    rows = (
        db.query(SeedScore)
        .filter(SeedScore.tournament_id == tournament_id, SeedScore.weight_class == weight_class)
        .order_by(SeedScore.seed_number.asc())
        .all()
    )
    return [SeedScoreRead.model_validate(row) for row in rows]


def apply_seeding_override(db: Session, payload: SeedingOverrideCreate, current_user: User):
    tournament = _load_tournament(db, payload.tournament_id)
    _require_director_or_admin(tournament, current_user)

    entry = (
        db.query(TournamentEntry)
        .options(joinedload(TournamentEntry.athlete))
        .filter(TournamentEntry.id == payload.entry_id, TournamentEntry.tournament_id == payload.tournament_id)
        .first()
    )
    if not entry:
        raise HTTPException(status_code=404, detail="Tournament entry not found")

    current_row = (
        db.query(SeedScore)
        .filter(SeedScore.tournament_id == payload.tournament_id, SeedScore.entry_id == payload.entry_id)
        .first()
    )
    if current_row is None:
        calculate_seeds(db, payload.tournament_id, current_user)
        current_row = (
            db.query(SeedScore)
            .filter(SeedScore.tournament_id == payload.tournament_id, SeedScore.entry_id == payload.entry_id)
            .first()
        )
    if current_row is None:
        raise HTTPException(status_code=400, detail="Seeding must be calculated before overrides")

    override = SeedingOverride(
        tournament_id=payload.tournament_id,
        entry_id=payload.entry_id,
        actor_id=current_user.id,
        previous_seed_number=current_row.seed_number,
        new_seed_number=payload.seed_number,
        override_reason=payload.override_reason,
        previous_snapshot={
            "seed_number": current_row.seed_number,
            "seed_score": current_row.seed_score,
            "score_breakdown": current_row.score_breakdown,
            "seed_explanation": current_row.seed_explanation,
        },
    )
    db.add(override)
    db.flush()
    rows = _apply_override_reorder(
        db,
        tournament_id=payload.tournament_id,
        entry_id=payload.entry_id,
        seed_number=payload.seed_number,
    )
    return {
        "override": override,
        "results": [SeedScoreRead.model_validate(row) for row in rows],
    }


def get_seeding_explanations(
    db: Session, tournament_id: int, weight_class: str, current_user: User
) -> SeedingExplanationRead:
    tournament = _load_tournament(db, tournament_id)
    _require_seed_view(db, tournament, current_user)

    rows = (
        db.query(SeedScore)
        .filter(SeedScore.tournament_id == tournament_id, SeedScore.weight_class == weight_class)
        .order_by(SeedScore.seed_number.asc())
        .all()
    )
    overrides = (
        db.query(SeedingOverride)
        .join(TournamentEntry, TournamentEntry.id == SeedingOverride.entry_id)
        .filter(
            SeedingOverride.tournament_id == tournament_id,
            TournamentEntry.weight_class == weight_class,
        )
        .order_by(SeedingOverride.created_at.desc())
        .all()
    )
    return SeedingExplanationRead(
        tournament_id=tournament_id,
        weight_class=weight_class,
        explanations=[SeedScoreRead.model_validate(row) for row in rows],
        overrides=overrides,
    )
