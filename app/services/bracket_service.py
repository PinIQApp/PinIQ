from __future__ import annotations

from datetime import datetime
from math import log2

from fastapi import HTTPException
from sqlalchemy.orm import Session, joinedload

from app.models.tournament import (
    Bracket,
    BracketMatch,
    BracketMatchStatus,
    BracketStatus,
    BracketType,
    SeedScore,
    TournamentEntry,
    TournamentStatus,
)
from app.models.user import User, UserRole
from app.schemas.tournament import BracketGenerateRequest, BracketRead, BracketMatchRead, BracketMatchUpdate
from app.services.tournament_service import _load_tournament, _require_director_or_admin, _require_tournament_view


BRACKET_SIZES = {
    BracketType.four_man: 4,
    BracketType.eight_man: 8,
    BracketType.sixteen_man: 16,
    BracketType.thirty_two_man: 32,
}


def _seed_for_entry(db: Session, tournament_id: int, entry_id: int | None) -> int | None:
    if entry_id is None:
        return None
    return (
        db.query(SeedScore.seed_number)
        .filter(SeedScore.tournament_id == tournament_id, SeedScore.entry_id == entry_id)
        .scalar()
    )


def _push_winner_forward(db: Session, match: BracketMatch, winner_entry_id: int) -> None:
    match.winner_entry_id = winner_entry_id
    match.match_status = BracketMatchStatus.completed
    if not match.next_match_id:
        return

    next_match = db.query(BracketMatch).filter(BracketMatch.id == match.next_match_id).first()
    if not next_match:
        return

    winner_seed = _seed_for_entry(db, match.tournament_id, winner_entry_id)
    if match.next_match_slot == "A":
        next_match.wrestler_a_entry_id = winner_entry_id
        next_match.wrestler_a_seed = winner_seed
    else:
        next_match.wrestler_b_entry_id = winner_entry_id
        next_match.wrestler_b_seed = winner_seed


def _auto_advance_byes(db: Session, bracket_id: int) -> None:
    changed = True
    while changed:
        changed = False
        matches = (
            db.query(BracketMatch)
            .filter(BracketMatch.bracket_id == bracket_id)
            .order_by(BracketMatch.round_number.asc(), BracketMatch.matchup_order.asc())
            .all()
        )
        for match in matches:
            if match.match_status == BracketMatchStatus.completed or match.winner_entry_id is not None:
                continue
            wrestler_a = match.wrestler_a_entry_id
            wrestler_b = match.wrestler_b_entry_id
            if wrestler_a is None and wrestler_b is None:
                continue
            if wrestler_a is not None and wrestler_b is None:
                _push_winner_forward(db, match, wrestler_a)
                changed = True
            elif wrestler_b is not None and wrestler_a is None:
                _push_winner_forward(db, match, wrestler_b)
                changed = True
        if changed:
            db.flush()


def _load_seed_rows(db: Session, tournament_id: int, weight_class: str) -> list[SeedScore]:
    rows = (
        db.query(SeedScore)
        .options(joinedload(SeedScore.entry).joinedload(TournamentEntry.athlete))
        .filter(SeedScore.tournament_id == tournament_id, SeedScore.weight_class == weight_class)
        .order_by(SeedScore.seed_number.asc())
        .all()
    )
    if not rows:
        raise HTTPException(status_code=400, detail="Run seeding before generating brackets")
    return rows


def _seed_order(size: int) -> list[int]:
    order = [1, 2]
    while len(order) < size:
        next_size = len(order) * 2 + 1
        updated: list[int] = []
        for seed in order:
            updated.append(seed)
            updated.append(next_size - seed)
        order = updated
    return order


def _build_single_elimination_preview(rows: list[SeedScore], bracket_size: int) -> tuple[dict, list[dict]]:
    slots = {row.seed_number: row for row in rows}
    seed_order = _seed_order(bracket_size)
    first_round_slots = []
    first_round_matches = []
    for index in range(0, len(seed_order), 2):
        seed_a = seed_order[index]
        seed_b = seed_order[index + 1]
        row_a = slots.get(seed_a)
        row_b = slots.get(seed_b)
        first_round_slots.append(
            {
                "matchup_order": index // 2 + 1,
                "seed_a": seed_a,
                "seed_b": seed_b,
                "athlete_a": row_a.entry.athlete.full_name if row_a else "BYE",
                "athlete_b": row_b.entry.athlete.full_name if row_b else "BYE",
                "entry_a_id": row_a.entry_id if row_a else None,
                "entry_b_id": row_b.entry_id if row_b else None,
            }
        )
        first_round_matches.append(
            {
                "round_number": 1,
                "matchup_order": index // 2 + 1,
                "wrestler_a_entry_id": row_a.entry_id if row_a else None,
                "wrestler_b_entry_id": row_b.entry_id if row_b else None,
                "wrestler_a_seed": seed_a if row_a else None,
                "wrestler_b_seed": seed_b if row_b else None,
                "match_status": BracketMatchStatus.bye if not row_a or not row_b else BracketMatchStatus.pending,
            }
        )

    rounds = [
        {
            "round_number": 1,
            "label": "Opening Round",
            "matches": first_round_slots,
        }
    ]
    total_rounds = int(log2(bracket_size))
    for round_number in range(2, total_rounds + 1):
        rounds.append(
            {
                "round_number": round_number,
                "label": "Championship" if round_number == total_rounds else f"Round {round_number}",
                "matches": [
                    {
                        "matchup_order": matchup_order,
                        "seed_a": None,
                        "seed_b": None,
                        "athlete_a": "Winner TBD",
                        "athlete_b": "Winner TBD",
                    }
                    for matchup_order in range(1, (bracket_size // (2**round_number)) + 1)
                ],
            }
        )
    return {"rounds": rounds, "format": "single_elimination"}, first_round_matches


def _build_round_robin_preview(rows: list[SeedScore]) -> tuple[dict, list[dict]]:
    matches: list[dict] = []
    display_matches: list[dict] = []
    matchup_order = 1
    for index, row_a in enumerate(rows):
        for row_b in rows[index + 1 :]:
            matches.append(
                {
                    "round_number": 1,
                    "matchup_order": matchup_order,
                    "wrestler_a_entry_id": row_a.entry_id,
                    "wrestler_b_entry_id": row_b.entry_id,
                    "wrestler_a_seed": row_a.seed_number,
                    "wrestler_b_seed": row_b.seed_number,
                    "match_status": BracketMatchStatus.pending,
                }
            )
            display_matches.append(
                {
                    "matchup_order": matchup_order,
                    "seed_a": row_a.seed_number,
                    "seed_b": row_b.seed_number,
                    "athlete_a": row_a.entry.athlete.full_name,
                    "athlete_b": row_b.entry.athlete.full_name,
                    "entry_a_id": row_a.entry_id,
                    "entry_b_id": row_b.entry_id,
                }
            )
            matchup_order += 1
    return {"rounds": [{"round_number": 1, "label": "Pool Matches", "matches": display_matches}], "format": "round_robin"}, matches


def generate_bracket(
    db: Session,
    tournament_id: int,
    weight_class: str,
    payload: BracketGenerateRequest,
    current_user: User,
) -> Bracket:
    tournament = _load_tournament(db, tournament_id)
    _require_director_or_admin(tournament, current_user)
    rows = _load_seed_rows(db, tournament_id, weight_class)

    existing = db.query(Bracket).filter(Bracket.tournament_id == tournament_id, Bracket.weight_class == weight_class).first()
    if existing:
        db.delete(existing)
        db.flush()

    if payload.bracket_type == BracketType.round_robin:
        preview_payload, match_defs = _build_round_robin_preview(rows)
        bracket_size = len(rows)
    else:
        bracket_size = BRACKET_SIZES[payload.bracket_type]
        preview_payload, match_defs = _build_single_elimination_preview(rows, bracket_size)

    status = BracketStatus.finalized if payload.finalize_now else BracketStatus.draft
    if payload.publish_now:
        status = BracketStatus.published

    bracket = Bracket(
        tournament_id=tournament_id,
        division_name=payload.division_name,
        weight_class=weight_class,
        bracket_type=payload.bracket_type,
        bracket_size=bracket_size,
        status=status,
        preview_payload=preview_payload,
        created_by_user_id=current_user.id,
        finalized_by_user_id=current_user.id if status in {BracketStatus.finalized, BracketStatus.published} else None,
        finalized_at=None if status == BracketStatus.draft else datetime.utcnow(),
        published_at=datetime.utcnow() if status == BracketStatus.published else None,
    )
    db.add(bracket)
    db.flush()

    created_matches: list[BracketMatch] = []
    for match_def in match_defs:
        match = BracketMatch(bracket_id=bracket.id, tournament_id=tournament_id, **match_def)
        db.add(match)
        db.flush()
        created_matches.append(match)

    if payload.bracket_type != BracketType.round_robin:
        future_rounds: dict[tuple[int, int], BracketMatch] = {}
        total_rounds = int(log2(bracket_size))
        for round_number in range(2, total_rounds + 1):
            for matchup_order in range(1, (bracket_size // (2**round_number)) + 1):
                match = BracketMatch(
                    bracket_id=bracket.id,
                    tournament_id=tournament_id,
                    round_number=round_number,
                    matchup_order=matchup_order,
                    match_status=BracketMatchStatus.pending,
                )
                db.add(match)
                db.flush()
                future_rounds[(round_number, matchup_order)] = match

        all_matches: list[BracketMatch] = [*created_matches, *future_rounds.values()]
        for match in all_matches:
            next_round = match.round_number + 1
            if next_round > total_rounds:
                continue
            next_order = (match.matchup_order + 1) // 2
            next_match = future_rounds[(next_round, next_order)]
            match.next_match_id = next_match.id
            match.next_match_slot = "A" if match.matchup_order % 2 == 1 else "B"

    if status in {BracketStatus.finalized, BracketStatus.published}:
        tournament.status = TournamentStatus.bracket_finalized if status == BracketStatus.finalized else TournamentStatus.published

    _auto_advance_byes(db, bracket.id)
    db.flush()
    return get_bracket(db, tournament_id=tournament_id, weight_class=weight_class, current_user=current_user)


def get_bracket(db: Session, tournament_id: int, weight_class: str, current_user: User) -> Bracket:
    tournament = _load_tournament(db, tournament_id)
    bracket = (
        db.query(Bracket)
        .options(joinedload(Bracket.matches))
        .filter(Bracket.tournament_id == tournament_id, Bracket.weight_class == weight_class)
        .first()
    )
    if not bracket:
        raise HTTPException(status_code=404, detail="Bracket not found")

    visibility = _require_tournament_view(db, tournament, current_user)
    if visibility in {"athlete", "parent"} and bracket.status != BracketStatus.published:
        raise HTTPException(
            status_code=403,
            detail="Only finalized and published brackets are visible to athletes and parents",
        )
    return bracket


def update_bracket_match(db: Session, match_id: int, payload: BracketMatchUpdate, current_user: User) -> BracketMatch:
    match = (
        db.query(BracketMatch)
        .options(joinedload(BracketMatch.bracket))
        .filter(BracketMatch.id == match_id)
        .first()
    )
    if not match:
        raise HTTPException(status_code=404, detail="Bracket match not found")

    tournament = _load_tournament(db, match.tournament_id)
    _require_director_or_admin(tournament, current_user)

    updates = payload.model_dump(exclude_unset=True)
    for field, value in updates.items():
        setattr(match, field, value)

    if payload.winner_entry_id:
        _push_winner_forward(db, match, payload.winner_entry_id)
        _auto_advance_byes(db, match.bracket_id)

    db.flush()
    return match
