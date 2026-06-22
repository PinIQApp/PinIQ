from __future__ import annotations

from collections import Counter, defaultdict
from datetime import datetime

from fastapi import HTTPException
from sqlalchemy.orm import Session, joinedload

from app.models.messaging import ParentLink
from app.models.stats import (
    AthleteStatSnapshot,
    Match,
    MatchOutcome,
    MatchResultType,
    MatchStats,
    StatAuditAction,
    StatAuditLog,
    TeamStatSnapshot,
)
from app.models.team import Team, TeamMember, TeamMemberStatus
from app.models.user import User, UserRole
from app.schemas.stats import (
    AthleteRecentRead,
    AthleteStatsDashboardRead,
    LeaderEntry,
    MatchCreate,
    MatchRead,
    MatchStatsCreate,
    MatchUpdate,
    RecordSummary,
    ResultTypeBreakdown,
    StatAverages,
    StrengthWeaknessSummary,
    TeamLeadersRead,
    TeamStatsDashboardRead,
    TrendSummary,
    WeightClassBreakdownItem,
)


BONUS_POINT_RESULT_TYPES = {
    MatchResultType.pin,
    MatchResultType.tech_fall,
    MatchResultType.major_decision,
    MatchResultType.forfeit,
    MatchResultType.default,
    MatchResultType.disqualification,
    MatchResultType.medical_forfeit,
}


def _load_team_with_members(db: Session, team_id: int) -> Team:
    team = (
        db.query(Team)
        .options(joinedload(Team.memberships).joinedload(TeamMember.user))
        .filter(Team.id == team_id)
        .first()
    )
    if not team:
        raise HTTPException(status_code=404, detail="Team not found")
    return team


def _approved_membership(team: Team, user_id: int) -> TeamMember | None:
    return next(
        (
            member
            for member in team.memberships
            if member.user_id == user_id and member.status == TeamMemberStatus.approved
        ),
        None,
    )


def _load_athlete_for_team(team: Team, athlete_id: int) -> TeamMember:
    athlete = next(
        (
            member
            for member in team.memberships
            if member.user_id == athlete_id
            and member.status == TeamMemberStatus.approved
            and member.user.role == UserRole.athlete
        ),
        None,
    )
    if athlete is None:
        raise HTTPException(status_code=404, detail="Athlete not found for this team")
    return athlete


def _is_linked_parent(db: Session, *, team_id: int, athlete_id: int, parent_user_id: int) -> bool:
    return (
        db.query(ParentLink)
        .filter(
            ParentLink.team_id == team_id,
            ParentLink.athlete_user_id == athlete_id,
            ParentLink.parent_user_id == parent_user_id,
            ParentLink.is_active.is_(True),
        )
        .first()
        is not None
    )


def _serialize_match(match: Match) -> dict:
    return MatchRead.model_validate(match).model_dump(mode="json")


def _visible_as_for_athlete(
    db: Session,
    *,
    team: Team,
    athlete_id: int,
    current_user: User,
) -> str:
    membership = _approved_membership(team, current_user.id)
    _load_athlete_for_team(team, athlete_id)

    if current_user.role == UserRole.admin:
        return "admin"
    if current_user.id == athlete_id:
        return "athlete"
    if membership and current_user.role in {UserRole.coach, UserRole.assistant_coach}:
        return current_user.role.value
    if current_user.role == UserRole.parent and _is_linked_parent(
        db, team_id=team.id, athlete_id=athlete_id, parent_user_id=current_user.id
    ):
        return "parent"
    raise HTTPException(status_code=403, detail="Not authorized for this athlete")


def _require_staff_editor(team: Team, current_user: User) -> None:
    membership = _approved_membership(team, current_user.id)
    if current_user.role == UserRole.admin:
        return
    if membership and current_user.role in {UserRole.coach, UserRole.assistant_coach}:
        return
    raise HTTPException(status_code=403, detail="Only team staff can create or edit match data")


def _require_team_view(team: Team, current_user: User) -> str:
    membership = _approved_membership(team, current_user.id)
    if current_user.role == UserRole.admin:
        return "admin"
    if membership and current_user.role in {UserRole.coach, UserRole.assistant_coach}:
        return current_user.role.value
    raise HTTPException(status_code=403, detail="Only staff can view team-wide stats")


def _load_match(db: Session, match_id: int) -> Match:
    match = (
        db.query(Match)
        .options(joinedload(Match.stats), joinedload(Match.athlete))
        .filter(Match.id == match_id)
        .first()
    )
    if not match:
        raise HTTPException(status_code=404, detail="Match not found")
    return match


def _query_team_matches(db: Session, team_id: int):
    return (
        db.query(Match)
        .options(joinedload(Match.stats), joinedload(Match.athlete))
        .filter(Match.team_id == team_id)
    )


def _query_athlete_matches(db: Session, team_id: int, athlete_id: int):
    return _query_team_matches(db, team_id).filter(Match.athlete_id == athlete_id)


def _result_type_counts(matches: list[Match]) -> Counter:
    counts = Counter(match.result_type for match in matches)
    return counts


def _safe_rate(value: float, total: int) -> float:
    if total <= 0:
        return 0.0
    return round(value / total, 3)


def _record_summary(matches: list[Match]) -> RecordSummary:
    wins = sum(1 for match in matches if match.result == MatchOutcome.win)
    losses = len(matches) - wins
    return RecordSummary(
        wins=wins,
        losses=losses,
        total_matches=len(matches),
        win_percentage=_safe_rate(wins, len(matches)),
    )


def _result_breakdown(matches: list[Match]) -> ResultTypeBreakdown:
    counts = _result_type_counts(matches)
    total = len(matches)
    return ResultTypeBreakdown(
        pins=counts[MatchResultType.pin],
        tech_falls=counts[MatchResultType.tech_fall],
        major_decisions=counts[MatchResultType.major_decision],
        decisions=counts[MatchResultType.decision],
        forfeits=counts[MatchResultType.forfeit],
        disqualifications=counts[MatchResultType.disqualification],
        medical_forfeits=counts[MatchResultType.medical_forfeit],
        defaults=counts[MatchResultType.default],
        pin_rate=_safe_rate(counts[MatchResultType.pin], total),
        tech_fall_rate=_safe_rate(counts[MatchResultType.tech_fall], total),
        major_decision_rate=_safe_rate(counts[MatchResultType.major_decision], total),
        decision_rate=_safe_rate(counts[MatchResultType.decision], total),
    )


def _trend_summary(matches: list[Match]) -> TrendSummary:
    recent = sorted(matches, key=lambda item: (item.match_date, item.id), reverse=True)[:5]
    outcomes = ["W" if match.result == MatchOutcome.win else "L" for match in recent]
    wins = outcomes.count("W")
    label = "steady"
    if len(outcomes) >= 3 and outcomes[:3] == ["W", "W", "W"]:
        label = "hot streak"
    elif len(outcomes) >= 3 and outcomes[:3] == ["L", "L", "L"]:
        label = "needs reset"
    elif wins >= max(len(outcomes) - 1, 1):
        label = "trending up"
    elif wins <= 1 and len(outcomes) >= 3:
        label = "sliding"
    return TrendSummary(
        last_five=outcomes,
        trend_label=label,
        recent_record=f"{wins}-{len(outcomes) - wins}",
    )


def _stat_averages(matches: list[Match]) -> StatAverages:
    if not matches:
        return StatAverages(
            takedowns_per_match=0,
            escapes_per_match=0,
            reversals_per_match=0,
            nearfall_points_per_match=0,
            stall_calls_per_match=0,
            ride_time_seconds_per_match=0,
            shot_conversion_rate=None,
        )

    total_takedowns = sum((match.stats.takedowns if match.stats else 0) for match in matches)
    total_escapes = sum((match.stats.escapes if match.stats else 0) for match in matches)
    total_reversals = sum((match.stats.reversals if match.stats else 0) for match in matches)
    total_nearfall = sum((match.stats.nearfall_points if match.stats else 0) for match in matches)
    total_stalls = sum((match.stats.stall_calls if match.stats else 0) for match in matches)
    total_ride = sum((match.stats.ride_time_seconds or 0) if match.stats else 0 for match in matches)
    total_attempts = sum((match.stats.shot_attempts or 0) if match.stats else 0 for match in matches)
    total_conversions = sum((match.stats.shot_conversions or 0) if match.stats else 0 for match in matches)
    total = len(matches)
    return StatAverages(
        takedowns_per_match=round(total_takedowns / total, 2),
        escapes_per_match=round(total_escapes / total, 2),
        reversals_per_match=round(total_reversals / total, 2),
        nearfall_points_per_match=round(total_nearfall / total, 2),
        stall_calls_per_match=round(total_stalls / total, 2),
        ride_time_seconds_per_match=round(total_ride / total, 2),
        shot_conversion_rate=round(total_conversions / total_attempts, 3) if total_attempts else None,
    )


def _strengths_and_weaknesses(matches: list[Match], averages: StatAverages) -> StrengthWeaknessSummary:
    strengths: list[str] = []
    weaknesses: list[str] = []
    win_pct = _record_summary(matches).win_percentage
    bonus_wins = sum(
        1
        for match in matches
        if match.result == MatchOutcome.win and match.result_type in BONUS_POINT_RESULT_TYPES
    )

    if win_pct >= 0.7:
        strengths.append("Consistent match finisher with a strong win rate.")
    if averages.takedowns_per_match >= 3:
        strengths.append("Creates offense from neutral with frequent takedowns.")
    if averages.nearfall_points_per_match >= 2:
        strengths.append("Turns points into back exposure and nearfall pressure.")
    if averages.shot_conversion_rate is not None and averages.shot_conversion_rate >= 0.45:
        strengths.append("Efficient on shot selection and conversion.")
    if bonus_wins >= max(2, len(matches) // 3):
        strengths.append("Produces bonus-point wins at a high clip.")

    if win_pct <= 0.4 and matches:
        weaknesses.append("Needs better match-closing consistency late in bouts.")
    if averages.escapes_per_match < 0.8 and matches:
        weaknesses.append("Bottom work needs more reliable first-move escapes.")
    if averages.stall_calls_per_match >= 1:
        weaknesses.append("Giving away stall calls that can swing tight matches.")
    if averages.shot_conversion_rate is not None and averages.shot_conversion_rate < 0.3:
        weaknesses.append("Taking shots without enough clean finishes.")
    if averages.takedowns_per_match < 1.5 and matches:
        weaknesses.append("Neutral offense volume is lower than ideal.")

    if not strengths:
        strengths.append("Building a usable baseline with enough data for coaching review.")
    if not weaknesses:
        weaknesses.append("No major red flags yet, but more logged matches will sharpen the read.")

    coach_summary = f"Strengths: {strengths[0]} Weakness focus: {weaknesses[0]}"
    return StrengthWeaknessSummary(strengths=strengths[:3], weaknesses=weaknesses[:3], coach_summary=coach_summary)


def _bonus_point_wins(matches: list[Match]) -> int:
    return sum(
        1
        for match in matches
        if match.result == MatchOutcome.win and match.result_type in BONUS_POINT_RESULT_TYPES
    )


def _upsert_athlete_snapshot(db: Session, *, team_id: int, athlete_id: int) -> AthleteStatSnapshot:
    matches = _query_athlete_matches(db, team_id, athlete_id).order_by(Match.match_date.desc(), Match.id.desc()).all()
    record = _record_summary(matches)
    averages = _stat_averages(matches)
    summary = _strengths_and_weaknesses(matches, averages)
    trend = _trend_summary(matches)
    snapshot = (
        db.query(AthleteStatSnapshot)
        .filter(AthleteStatSnapshot.team_id == team_id, AthleteStatSnapshot.athlete_id == athlete_id)
        .first()
    )
    if snapshot is None:
        snapshot = AthleteStatSnapshot(team_id=team_id, athlete_id=athlete_id)
        db.add(snapshot)

    snapshot.total_matches = record.total_matches
    snapshot.wins = record.wins
    snapshot.losses = record.losses
    snapshot.win_percentage = record.win_percentage
    snapshot.bonus_point_rate = _safe_rate(_bonus_point_wins(matches), len(matches))
    snapshot.recent_trend = "-".join(trend.last_five)
    snapshot.strengths_summary = "; ".join(summary.strengths[:2])
    snapshot.weaknesses_summary = "; ".join(summary.weaknesses[:2])
    snapshot.summary_payload = {
        "record": record.model_dump(),
        "stat_averages": averages.model_dump(),
        "trend": trend.model_dump(),
        "strengths_weaknesses": summary.model_dump(),
    }
    db.flush()
    return snapshot


def _upsert_team_snapshot(db: Session, *, team_id: int) -> TeamStatSnapshot:
    matches = _query_team_matches(db, team_id).order_by(Match.match_date.desc(), Match.id.desc()).all()
    record = _record_summary(matches)
    trend = _trend_summary(matches)
    snapshot = db.query(TeamStatSnapshot).filter(TeamStatSnapshot.team_id == team_id).first()
    if snapshot is None:
        snapshot = TeamStatSnapshot(team_id=team_id)
        db.add(snapshot)
    snapshot.total_matches = record.total_matches
    snapshot.wins = record.wins
    snapshot.losses = record.losses
    snapshot.win_percentage = record.win_percentage
    snapshot.recent_trend = "-".join(trend.last_five)
    snapshot.summary_payload = {
        "record": record.model_dump(),
        "trend": trend.model_dump(),
        "bonus_point_rate": _safe_rate(_bonus_point_wins(matches), len(matches)),
    }
    db.flush()
    return snapshot


def _audit(
    db: Session,
    *,
    team_id: int,
    athlete_id: int | None,
    match_id: int | None,
    actor_id: int,
    action: StatAuditAction,
    entity_type: str,
    entity_id: int,
    before_state: dict | None,
    after_state: dict | None,
) -> None:
    db.add(
        StatAuditLog(
            team_id=team_id,
            athlete_id=athlete_id,
            match_id=match_id,
            actor_id=actor_id,
            action=action,
            entity_type=entity_type,
            entity_id=entity_id,
            before_state=before_state,
            after_state=after_state,
        )
    )
    db.flush()


def create_match(db: Session, *, payload: MatchCreate, current_user: User) -> Match:
    team = _load_team_with_members(db, payload.team_id)
    _require_staff_editor(team, current_user)
    _load_athlete_for_team(team, payload.athlete_id)

    match = Match(**payload.model_dump(), created_by_user_id=current_user.id)
    db.add(match)
    db.flush()
    match = _load_match(db, match.id)
    _audit(
        db,
        team_id=match.team_id,
        athlete_id=match.athlete_id,
        match_id=match.id,
        actor_id=current_user.id,
        action=StatAuditAction.match_created,
        entity_type="match",
        entity_id=match.id,
        before_state=None,
        after_state=_serialize_match(match),
    )
    _upsert_athlete_snapshot(db, team_id=match.team_id, athlete_id=match.athlete_id)
    _upsert_team_snapshot(db, team_id=match.team_id)
    return match


def update_match(db: Session, *, match_id: int, payload: MatchUpdate, current_user: User) -> Match:
    match = _load_match(db, match_id)
    team = _load_team_with_members(db, match.team_id)
    _require_staff_editor(team, current_user)
    before_state = _serialize_match(match)

    changes = payload.model_dump(exclude_unset=True)
    athlete_id = changes.get("athlete_id", match.athlete_id)
    _load_athlete_for_team(team, athlete_id)
    for field, value in changes.items():
        setattr(match, field, value)
    match.updated_by_user_id = current_user.id
    db.flush()
    match = _load_match(db, match.id)
    _audit(
        db,
        team_id=match.team_id,
        athlete_id=match.athlete_id,
        match_id=match.id,
        actor_id=current_user.id,
        action=StatAuditAction.match_updated,
        entity_type="match",
        entity_id=match.id,
        before_state=before_state,
        after_state=_serialize_match(match),
    )
    _upsert_athlete_snapshot(db, team_id=match.team_id, athlete_id=match.athlete_id)
    _upsert_team_snapshot(db, team_id=match.team_id)
    return match


def upsert_match_stats(db: Session, *, match_id: int, payload: MatchStatsCreate, current_user: User) -> MatchStats:
    match = _load_match(db, match_id)
    team = _load_team_with_members(db, match.team_id)
    _require_staff_editor(team, current_user)

    stats = match.stats
    before_state = stats and {
        "id": stats.id,
        "takedowns": stats.takedowns,
        "escapes": stats.escapes,
        "reversals": stats.reversals,
        "nearfall_points": stats.nearfall_points,
        "stall_calls": stats.stall_calls,
        "ride_time_seconds": stats.ride_time_seconds,
        "shot_attempts": stats.shot_attempts,
        "shot_conversions": stats.shot_conversions,
    }
    if stats is None:
        stats = MatchStats(match_id=match.id, athlete_id=match.athlete_id, team_id=match.team_id, **payload.model_dump())
        db.add(stats)
        action = StatAuditAction.match_stats_created
    else:
        for field, value in payload.model_dump().items():
            setattr(stats, field, value)
        action = StatAuditAction.match_stats_updated

    db.flush()
    _audit(
        db,
        team_id=match.team_id,
        athlete_id=match.athlete_id,
        match_id=match.id,
        actor_id=current_user.id,
        action=action,
        entity_type="match_stats",
        entity_id=stats.id,
        before_state=before_state,
        after_state={
            "id": stats.id,
            "takedowns": stats.takedowns,
            "escapes": stats.escapes,
            "reversals": stats.reversals,
            "nearfall_points": stats.nearfall_points,
            "stall_calls": stats.stall_calls,
            "ride_time_seconds": stats.ride_time_seconds,
            "shot_attempts": stats.shot_attempts,
            "shot_conversions": stats.shot_conversions,
        },
    )
    _upsert_athlete_snapshot(db, team_id=match.team_id, athlete_id=match.athlete_id)
    _upsert_team_snapshot(db, team_id=match.team_id)
    return stats


def list_team_matches(
    db: Session,
    *,
    team_id: int,
    current_user: User,
    athlete_id: int | None = None,
    event_name: str | None = None,
    weight_class: str | None = None,
    date_from=None,
    date_to=None,
) -> list[Match]:
    team = _load_team_with_members(db, team_id)
    _require_team_view(team, current_user)
    query = _query_team_matches(db, team_id)
    if athlete_id is not None:
        query = query.filter(Match.athlete_id == athlete_id)
    if event_name:
        query = query.filter(Match.event_name.ilike(f"%{event_name.strip()}%"))
    if weight_class:
        query = query.filter(Match.weight_class == weight_class)
    if date_from is not None:
        query = query.filter(Match.match_date >= date_from)
    if date_to is not None:
        query = query.filter(Match.match_date <= date_to)
    return query.order_by(Match.match_date.desc(), Match.id.desc()).all()


def list_athlete_matches(
    db: Session,
    *,
    athlete_id: int,
    team_id: int,
    current_user: User,
) -> list[Match]:
    team = _load_team_with_members(db, team_id)
    _visible_as_for_athlete(db, team=team, athlete_id=athlete_id, current_user=current_user)
    return _query_athlete_matches(db, team_id, athlete_id).order_by(Match.match_date.desc(), Match.id.desc()).all()


def get_athlete_stats_dashboard(
    db: Session,
    *,
    athlete_id: int,
    team_id: int,
    current_user: User,
) -> AthleteStatsDashboardRead:
    team = _load_team_with_members(db, team_id)
    visible_as = _visible_as_for_athlete(db, team=team, athlete_id=athlete_id, current_user=current_user)
    athlete_membership = _load_athlete_for_team(team, athlete_id)
    matches = list_athlete_matches(db, athlete_id=athlete_id, team_id=team_id, current_user=current_user)
    record = _record_summary(matches)
    result_types = _result_breakdown(matches)
    averages = _stat_averages(matches)
    strengths = _strengths_and_weaknesses(matches, averages)
    trend = _trend_summary(matches)
    snapshot = _upsert_athlete_snapshot(db, team_id=team_id, athlete_id=athlete_id)
    return AthleteStatsDashboardRead(
        athlete_id=athlete_id,
        athlete_name=athlete_membership.user.full_name,
        team_id=team_id,
        record=record,
        result_types=result_types,
        bonus_point_wins=_bonus_point_wins(matches),
        bonus_point_rate=_safe_rate(_bonus_point_wins(matches), len(matches)),
        recent_trend=trend,
        last_five_matches=matches[:5],
        stat_averages=averages,
        strengths_weaknesses=strengths,
        visible_as=visible_as,
        snapshot_updated_at=snapshot.updated_at,
    )


def get_athlete_recent(
    db: Session,
    *,
    athlete_id: int,
    team_id: int,
    current_user: User,
) -> AthleteRecentRead:
    matches = list_athlete_matches(db, athlete_id=athlete_id, team_id=team_id, current_user=current_user)
    return AthleteRecentRead(
        athlete_id=athlete_id,
        team_id=team_id,
        trend=_trend_summary(matches),
        matches=matches[:5],
    )


def _leader_entries(
    team: Team,
    matches: list[Match],
) -> TeamLeadersRead:
    athlete_name_by_id = {
        member.user_id: member.user.full_name
        for member in team.memberships
        if member.status == TeamMemberStatus.approved and member.user.role == UserRole.athlete
    }
    grouped: dict[int, list[Match]] = defaultdict(list)
    for match in matches:
        grouped[match.athlete_id].append(match)

    pins: list[LeaderEntry] = []
    win_pct: list[LeaderEntry] = []
    bonus: list[LeaderEntry] = []
    for athlete_id, athlete_matches in grouped.items():
        name = athlete_name_by_id.get(athlete_id, f"Athlete {athlete_id}")
        pin_count = sum(1 for match in athlete_matches if match.result_type == MatchResultType.pin)
        record = _record_summary(athlete_matches)
        bonus_wins = _bonus_point_wins(athlete_matches)
        pins.append(
            LeaderEntry(
                athlete_id=athlete_id,
                athlete_name=name,
                metric_label="Pins",
                metric_value=pin_count,
                subtitle=f"{record.wins}-{record.losses} record",
            )
        )
        if len(athlete_matches) >= 3:
            win_pct.append(
                LeaderEntry(
                    athlete_id=athlete_id,
                    athlete_name=name,
                    metric_label="Win %",
                    metric_value=record.win_percentage,
                    subtitle=f"{record.wins}-{record.losses} in {record.total_matches} matches",
                )
            )
        bonus.append(
            LeaderEntry(
                athlete_id=athlete_id,
                athlete_name=name,
                metric_label="Bonus Wins",
                metric_value=bonus_wins,
                subtitle=f"{round(_safe_rate(bonus_wins, len(athlete_matches)) * 100)}% bonus rate",
            )
        )

    return TeamLeadersRead(
        team_id=team.id,
        most_pins=sorted(pins, key=lambda item: (-item.metric_value, item.athlete_name))[:5],
        best_win_percentage=sorted(win_pct, key=lambda item: (-item.metric_value, item.athlete_name))[:5],
        bonus_point_leaders=sorted(bonus, key=lambda item: (-item.metric_value, item.athlete_name))[:5],
    )


def get_team_stats_dashboard(db: Session, *, team_id: int, current_user: User) -> TeamStatsDashboardRead:
    team = _load_team_with_members(db, team_id)
    visible_as = _require_team_view(team, current_user)
    matches = _query_team_matches(db, team_id).order_by(Match.match_date.desc(), Match.id.desc()).all()
    record = _record_summary(matches)
    leaders = _leader_entries(team, matches)
    by_weight: dict[str, list[Match]] = defaultdict(list)
    for match in matches:
        by_weight[match.weight_class].append(match)
    snapshot = _upsert_team_snapshot(db, team_id=team_id)
    return TeamStatsDashboardRead(
        team_id=team.id,
        team_name=team.name,
        record=record,
        bonus_point_wins=_bonus_point_wins(matches),
        bonus_point_rate=_safe_rate(_bonus_point_wins(matches), len(matches)),
        total_pins=sum(1 for match in matches if match.result_type == MatchResultType.pin),
        recent_trend=_trend_summary(matches),
        leaders=[
            *(leaders.most_pins[:2]),
            *(leaders.best_win_percentage[:2]),
            *(leaders.bonus_point_leaders[:2]),
        ][:6],
        weight_class_breakdown=[
            WeightClassBreakdownItem(
                weight_class=weight_class,
                total_matches=len(weight_matches),
                wins=sum(1 for match in weight_matches if match.result == MatchOutcome.win),
                losses=sum(1 for match in weight_matches if match.result == MatchOutcome.loss),
                win_percentage=_record_summary(weight_matches).win_percentage,
            )
            for weight_class, weight_matches in sorted(by_weight.items())
        ],
        recent_matches=matches[:8],
        visible_as=visible_as,
        snapshot_updated_at=snapshot.updated_at,
    )


def get_team_leaders(db: Session, *, team_id: int, current_user: User) -> TeamLeadersRead:
    team = _load_team_with_members(db, team_id)
    _require_team_view(team, current_user)
    matches = _query_team_matches(db, team_id).order_by(Match.match_date.desc(), Match.id.desc()).all()
    return _leader_entries(team, matches)
