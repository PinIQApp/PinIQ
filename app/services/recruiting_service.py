from __future__ import annotations

from datetime import datetime, timedelta

from fastapi import HTTPException
from sqlalchemy.orm import Session, joinedload

from app.models.messaging import ParentLink
from app.models.recruiting import (
    RecruitingContactVisibility,
    RecruitingHighlight,
    RecruitingNote,
    RecruitingProfile,
    RecruitingTag,
    RecruitingVisibility,
    RecruitingVisibilityLevel,
    RecruitingWatchlist,
)
from app.models.stats import AthleteStatSnapshot, Match
from app.models.user import User, UserRole
from app.schemas.recruiting import (
    RecruitingAthleteCardRead,
    RecruitingBoardRead,
    RecruitingContactRead,
    RecruitingHighlightCreate,
    RecruitingHighlightRead,
    RecruitingNoteCreate,
    RecruitingNoteRead,
    RecruitingPinIqRankingRead,
    RecruitingProfileCreate,
    RecruitingProfileRead,
    RecruitingProfileUpdate,
    RecruitingProfileWriteResponse,
    RecruitingRecentMatchRead,
    RecruitingSchoolBoardRowRead,
    RecruitingSchoolRankingRead,
    RecruitingSearchParams,
    RecruitingSearchResponse,
    RecruitingSavedSourceScanResponse,
    RecruitingSourceLink,
    RecruitingSourceLinksRead,
    RecruitingSourceLinksUpsert,
    RecruitingSourceRankingRead,
    RecruitingSourceScanRequest,
    RecruitingSourceScanResponse,
    RecruitingSourceScanResultRead,
    RecruitingStatsMetricRead,
    RecruitingTrendingRead,
    RecruitingVisibilityRead,
    RecruitingWatchlistCreate,
    RecruitingWatchlistRead,
    RecruitingWatchlistResponse,
)
from app.services.recruiting_source_scanners import RecruitingSourceScannerError, scan_public_recruiting_source


COACH_ROLES = {UserRole.coach, UserRole.assistant_coach, UserRole.admin}
SCAN_ROLES = COACH_ROLES | {UserRole.athlete, UserRole.parent}
RECRUITING_SOURCE_LABELS = {
    "usa bracketing": "USA Bracketing",
    "flowrestling": "FloWrestling",
    "flow wrestling": "FloWrestling",
    "flo wrestling": "FloWrestling",
    "trackwrestling": "TrackWrestling",
    "track wrestling": "TrackWrestling",
    "kentuckymat": "KentuckyMat",
    "kentucky mat": "KentuckyMat",
}


def _query_profile(db: Session, athlete_id: int) -> RecruitingProfile | None:
    return (
        db.query(RecruitingProfile)
        .options(
            joinedload(RecruitingProfile.athlete),
            joinedload(RecruitingProfile.visibility),
            joinedload(RecruitingProfile.highlights),
            joinedload(RecruitingProfile.tags),
        )
        .filter(RecruitingProfile.athlete_id == athlete_id)
        .first()
    )


def _get_profile_or_404(db: Session, athlete_id: int) -> RecruitingProfile:
    profile = _query_profile(db, athlete_id)
    if not profile:
        raise HTTPException(status_code=404, detail="Recruiting profile not found")
    return profile


def _get_user_or_404(db: Session, user_id: int) -> User:
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user


def _is_linked_parent(db: Session, athlete_id: int, parent_id: int) -> bool:
    return (
        db.query(ParentLink)
        .filter(
            ParentLink.athlete_user_id == athlete_id,
            ParentLink.parent_user_id == parent_id,
            ParentLink.is_active.is_(True),
        )
        .first()
        is not None
    )


def _resolve_visibility_context(db: Session, profile: RecruitingProfile, current_user: User) -> str:
    if current_user.role == UserRole.admin:
        return "admin"
    if current_user.id == profile.athlete_id:
        return "athlete"
    if current_user.role == UserRole.parent and _is_linked_parent(db, profile.athlete_id, current_user.id):
        return "parent"
    if current_user.role in {UserRole.coach, UserRole.assistant_coach}:
        return "coach"
    return "public"


def _assert_profile_visible(db: Session, profile: RecruitingProfile, current_user: User) -> str:
    visible_as = _resolve_visibility_context(db, profile, current_user)
    if visible_as in {"admin", "athlete", "parent"}:
        return visible_as
    if profile.visibility_level == RecruitingVisibilityLevel.private:
        raise HTTPException(status_code=403, detail="This recruiting profile is private")
    if profile.visibility_level == RecruitingVisibilityLevel.coaches_only and visible_as != "coach":
        raise HTTPException(status_code=403, detail="This recruiting profile is only visible to coaches")
    return visible_as


def _assert_profile_editor(db: Session, athlete_id: int, current_user: User) -> None:
    if current_user.role == UserRole.admin or current_user.id == athlete_id:
        return
    if current_user.role == UserRole.parent and _is_linked_parent(db, athlete_id, current_user.id):
        return
    raise HTTPException(status_code=403, detail="Not allowed to edit this recruiting profile")


def _assert_coach_access(requested_coach_id: int, current_user: User) -> None:
    if current_user.role not in COACH_ROLES:
        raise HTTPException(status_code=403, detail="Only coaches can use watchlists and recruiting notes")
    if current_user.role != UserRole.admin and current_user.id != requested_coach_id:
        raise HTTPException(status_code=403, detail="You can only manage your own watchlist")


def _normalize_highlights(highlights: list[RecruitingHighlightCreate] | None) -> list[dict]:
    normalized: list[dict] = []
    for index, item in enumerate(highlights or []):
        normalized.append(
            {
                "title": item.title.strip(),
                "highlight_url": item.highlight_url.strip(),
                "sort_order": item.sort_order if item.sort_order is not None else index,
            }
        )
    return normalized


def _replace_highlights(profile: RecruitingProfile, highlights: list[RecruitingHighlightCreate] | None) -> None:
    if highlights is None:
        return
    profile.highlights.clear()
    for item in _normalize_highlights(highlights):
        profile.highlights.append(
            RecruitingHighlight(
                athlete_id=profile.athlete_id,
                title=item["title"],
                highlight_url=item["highlight_url"],
                sort_order=item["sort_order"],
            )
        )


def _upsert_visibility(profile: RecruitingProfile, payload) -> None:
    if profile.visibility is None:
        profile.visibility = RecruitingVisibility(
            show_contact_to_coaches=payload.show_contact_to_coaches,
            show_gpa=payload.show_gpa,
            show_location=payload.show_location,
            show_profile_photo=payload.show_profile_photo,
            parent_visibility_required=payload.parent_visibility_required,
            allow_direct_contact_request=payload.allow_direct_contact_request,
        )
        return
    profile.visibility.show_contact_to_coaches = payload.show_contact_to_coaches
    profile.visibility.show_gpa = payload.show_gpa
    profile.visibility.show_location = payload.show_location
    profile.visibility.show_profile_photo = payload.show_profile_photo
    profile.visibility.parent_visibility_required = payload.parent_visibility_required
    profile.visibility.allow_direct_contact_request = payload.allow_direct_contact_request


def _recent_matches(db: Session, athlete_id: int, limit: int = 5) -> list[Match]:
    return (
        db.query(Match)
        .filter(Match.athlete_id == athlete_id)
        .order_by(Match.match_date.desc(), Match.id.desc())
        .limit(limit)
        .all()
    )


def _stats_snapshot(db: Session, athlete_id: int, team_id: int | None) -> AthleteStatSnapshot | None:
    query = db.query(AthleteStatSnapshot).filter(AthleteStatSnapshot.athlete_id == athlete_id)
    if team_id is not None:
        query = query.filter(AthleteStatSnapshot.team_id == team_id)
    return query.order_by(AthleteStatSnapshot.updated_at.desc()).first()


def _record_string(profile: RecruitingProfile, snapshot: AthleteStatSnapshot | None) -> str:
    if profile.match_record_override:
        return profile.match_record_override
    if snapshot is None:
        return "0-0"
    return f"{snapshot.wins}-{snapshot.losses}"


def _recent_activity_score(db: Session, athlete_id: int) -> float:
    since = datetime.utcnow() - timedelta(days=21)
    recent_match_count = (
        db.query(Match)
        .filter(Match.athlete_id == athlete_id, Match.match_date >= since.date())
        .count()
    )
    return min(recent_match_count * 4.0, 20.0)


def _trending_score(profile: RecruitingProfile, snapshot: AthleteStatSnapshot | None, db: Session) -> float:
    win_pct = snapshot.win_percentage if snapshot else 0
    bonus_rate = snapshot.bonus_point_rate if snapshot else 0
    wins = snapshot.wins if snapshot else 0
    recent_bonus = _recent_activity_score(db, profile.athlete_id)
    featured_bonus = 12 if profile.is_featured else 0
    open_bonus = 10 if profile.is_open else 0
    looking_bonus = 8 if profile.is_actively_looking else 0
    updated_bonus = max(0, 10 - min((datetime.utcnow() - profile.updated_at).days, 10))
    return round((win_pct * 100) + (bonus_rate * 35) + (wins * 1.5) + recent_bonus + featured_bonus + open_bonus + looking_bonus + updated_bonus, 2)


def _stats_metrics(profile: RecruitingProfile, snapshot: AthleteStatSnapshot | None) -> list[RecruitingStatsMetricRead]:
    metrics: list[RecruitingStatsMetricRead] = []
    summary = profile.stats_summary or {}
    if snapshot is not None:
        metrics.extend(
            [
                RecruitingStatsMetricRead(
                    label="Win %",
                    value=f"{round(snapshot.win_percentage * 100)}%",
                    numeric_value=snapshot.win_percentage,
                ),
                RecruitingStatsMetricRead(
                    label="Bonus Rate",
                    value=f"{round(snapshot.bonus_point_rate * 100)}%",
                    numeric_value=snapshot.bonus_point_rate,
                ),
            ]
        )
    takedowns = summary.get("takedowns_per_match")
    if takedowns is not None:
        metrics.append(
            RecruitingStatsMetricRead(
                label="TD / Match",
                value=f"{float(takedowns):.1f}",
                numeric_value=float(takedowns),
            )
        )
    shot_conversion = summary.get("shot_conversion_rate")
    if shot_conversion is not None:
        metrics.append(
            RecruitingStatsMetricRead(
                label="Shot Conv.",
                value=f"{round(float(shot_conversion) * 100)}%",
                numeric_value=float(shot_conversion),
            )
        )
    return metrics


def _source_rankings(profile: RecruitingProfile) -> list[RecruitingSourceRankingRead]:
    summary = profile.stats_summary or {}
    rows = summary.get("source_rankings") or []
    rankings: list[RecruitingSourceRankingRead] = []
    if not isinstance(rows, list):
        return rankings

    for row in rows:
        if not isinstance(row, dict):
            continue
        source = str(row.get("source") or "").strip()
        source_label = RECRUITING_SOURCE_LABELS.get(source.lower())
        if source_label is None:
            continue
        rankings.append(
            RecruitingSourceRankingRead(
                source=source_label,
                record=row.get("record"),
                ranking=row.get("ranking"),
                weight_class=row.get("weight_class"),
                season=row.get("season"),
                profile_url=row.get("profile_url"),
                last_checked=row.get("last_checked"),
            )
        )
    return rankings


def _school_rankings(profile: RecruitingProfile) -> list[RecruitingSchoolRankingRead]:
    summary = profile.stats_summary or {}
    rows = summary.get("school_rankings") or []
    rankings: list[RecruitingSchoolRankingRead] = []
    if not isinstance(rows, list):
        return rankings

    for row in rows:
        if not isinstance(row, dict):
            continue
        source = str(row.get("source") or "").strip()
        school_name = str(row.get("school_name") or profile.school_team or "").strip()
        if not source or not school_name:
            continue
        rankings.append(
            RecruitingSchoolRankingRead(
                source=source,
                school_name=school_name,
                state=row.get("state"),
                state_rank=row.get("state_rank"),
                national_rank=row.get("national_rank"),
                division=row.get("division"),
                season=row.get("season"),
                profile_url=row.get("profile_url"),
                last_checked=row.get("last_checked"),
            )
        )
    return rankings


def _source_rank_score(rankings: list[RecruitingSourceRankingRead]) -> tuple[float, int | None, int | None]:
    best_state_rank: int | None = None
    best_national_rank: int | None = None
    score = 0.0
    for ranking in rankings:
        if ranking.ranking:
            digits = "".join(char for char in ranking.ranking if char.isdigit())
            if digits:
                rank = int(digits)
                best_state_rank = rank if best_state_rank is None else min(best_state_rank, rank)
                score = max(score, max(0.0, 18.0 - min(rank, 50) * 0.25))
        if ranking.record:
            parts = [int(part) for part in ranking.record.replace(" ", "").split("-") if part.isdigit()]
            if len(parts) >= 2:
                wins, losses = parts[0], parts[1]
                total = wins + losses
                if total:
                    score = max(score, min(12.0, (wins / total) * 12.0))
    return score, best_state_rank, best_national_rank


def _school_strength_score(rankings: list[RecruitingSchoolRankingRead]) -> tuple[float, int | None, int | None]:
    score = 0.0
    best_state_rank: int | None = None
    best_national_rank: int | None = None
    for ranking in rankings:
        if ranking.state_rank:
            best_state_rank = ranking.state_rank if best_state_rank is None else min(best_state_rank, ranking.state_rank)
            score = max(score, max(0.0, 8.0 - min(ranking.state_rank, 50) * 0.12))
        if ranking.national_rank:
            best_national_rank = ranking.national_rank if best_national_rank is None else min(best_national_rank, ranking.national_rank)
            score = max(score, max(0.0, 10.0 - min(ranking.national_rank, 150) * 0.04))
    return score, best_state_rank, best_national_rank


def _piniq_ranking(
    db: Session,
    profile: RecruitingProfile,
    snapshot: AthleteStatSnapshot | None,
) -> RecruitingPinIqRankingRead:
    source_rankings = _source_rankings(profile)
    school_rankings = _school_rankings(profile)
    source_score, source_state_rank, source_national_rank = _source_rank_score(source_rankings)
    school_score, school_state_rank, school_national_rank = _school_strength_score(school_rankings)
    activity_score = _recent_activity_score(db, profile.athlete_id)
    win_score = (snapshot.win_percentage * 35.0) if snapshot else 0.0
    bonus_score = (snapshot.bonus_point_rate * 15.0) if snapshot else 0.0
    volume_score = min((snapshot.total_matches if snapshot else 0) * 0.55, 10.0)
    profile_score = min(len(profile.highlights) * 2.0, 6.0) + (4.0 if profile.achievements else 0.0)
    score = round(min(100.0, win_score + bonus_score + volume_score + activity_score + source_score + school_score + profile_score), 2)

    if score >= 85:
        tier = "Elite"
    elif score >= 70:
        tier = "High Watch"
    elif score >= 55:
        tier = "Watch"
    else:
        tier = "Developing"

    evidence_count = sum(
        [
            1 if snapshot and snapshot.total_matches else 0,
            1 if source_rankings else 0,
            1 if school_rankings else 0,
            1 if profile.highlights else 0,
        ]
    )
    confidence = "high" if evidence_count >= 3 else "medium" if evidence_count == 2 else "low"
    factors = [
        RecruitingStatsMetricRead(label="Win profile", value=f"{win_score:.1f}", numeric_value=round(win_score, 2)),
        RecruitingStatsMetricRead(label="Bonus wins", value=f"{bonus_score:.1f}", numeric_value=round(bonus_score, 2)),
        RecruitingStatsMetricRead(label="Activity", value=f"{activity_score:.1f}", numeric_value=round(activity_score, 2)),
        RecruitingStatsMetricRead(label="Source rank", value=f"{source_score:.1f}", numeric_value=round(source_score, 2)),
        RecruitingStatsMetricRead(label="School strength", value=f"{school_score:.1f}", numeric_value=round(school_score, 2)),
    ]
    return RecruitingPinIqRankingRead(
        score=score,
        tier=tier,
        state_rank_hint=source_state_rank or school_state_rank,
        national_rank_hint=source_national_rank or school_national_rank,
        confidence=confidence,
        factors=factors,
    )


def _school_board_rows(
    cards: list[RecruitingAthleteCardRead],
) -> tuple[list[RecruitingSchoolBoardRowRead], list[RecruitingSchoolBoardRowRead]]:
    rows: dict[tuple[str, str, str | None, str | None, str | None], RecruitingSchoolBoardRowRead] = {}
    for card in cards:
        for ranking in card.school_rankings:
            if ranking.state_rank is None and ranking.national_rank is None:
                continue
            key = (
                ranking.source,
                ranking.school_name.strip().lower(),
                ranking.state,
                ranking.division,
                ranking.season,
            )
            existing = rows.get(key)
            if existing is None:
                existing = RecruitingSchoolBoardRowRead(
                    school_name=ranking.school_name,
                    source=ranking.source,
                    state=ranking.state,
                    state_rank=ranking.state_rank,
                    national_rank=ranking.national_rank,
                    division=ranking.division,
                    season=ranking.season,
                    profile_url=ranking.profile_url,
                    last_checked=ranking.last_checked,
                    athlete_names=[],
                )
                rows[key] = existing
            else:
                if ranking.state_rank is not None:
                    existing.state_rank = (
                        ranking.state_rank
                        if existing.state_rank is None
                        else min(existing.state_rank, ranking.state_rank)
                    )
                if ranking.national_rank is not None:
                    existing.national_rank = (
                        ranking.national_rank
                        if existing.national_rank is None
                        else min(existing.national_rank, ranking.national_rank)
                    )
                if ranking.profile_url and not existing.profile_url:
                    existing.profile_url = ranking.profile_url
                if ranking.last_checked and (
                    existing.last_checked is None or ranking.last_checked > existing.last_checked
                ):
                    existing.last_checked = ranking.last_checked
            if card.athlete_name not in existing.athlete_names:
                existing.athlete_names.append(card.athlete_name)
            existing.athlete_count = len(existing.athlete_names)

    state_rows = [row for row in rows.values() if row.state_rank is not None]
    state_rows.sort(key=lambda row: (row.state or "", row.state_rank or 9999, row.school_name))
    national_rows = [row for row in rows.values() if row.national_rank is not None]
    national_rows.sort(key=lambda row: (row.national_rank or 9999, row.school_name))
    return state_rows[:50], national_rows[:50]


def _merge_rankings(existing: list[dict], incoming: list[dict], *, key_fields: tuple[str, ...]) -> list[dict]:
    merged: dict[tuple[str, ...], dict] = {}
    for row in existing:
        if not isinstance(row, dict):
            continue
        key = tuple(str(row.get(field) or "").strip().lower() for field in key_fields)
        if any(not part for part in key):
            continue
        merged[key] = row
    for row in incoming:
        key = tuple(str(row.get(field) or "").strip().lower() for field in key_fields)
        if any(not part for part in key):
            continue
        merged[key] = row
    return list(merged.values())


def _source_links(profile: RecruitingProfile) -> list[RecruitingSourceLink]:
    summary = profile.stats_summary or {}
    rows = summary.get("source_links") or []
    links: list[RecruitingSourceLink] = []
    if not isinstance(rows, list):
        return links
    for row in rows:
        if not isinstance(row, dict):
            continue
        source = str(row.get("source") or "").strip()
        url = str(row.get("url") or "").strip()
        if not source or not url:
            continue
        links.append(RecruitingSourceLink(source=source, url=url))
    return links


def _mask_value(value: str | None) -> str | None:
    if not value:
        return None
    if "@" in value:
        local, domain = value.split("@", 1)
        if len(local) <= 2:
            local = f"{local[0]}*"
        else:
            local = f"{local[:2]}***"
        return f"{local}@{domain}"
    if len(value) <= 4:
        return "*" * len(value)
    return f"{value[:2]}***{value[-2:]}"


def _contact_read(db: Session, profile: RecruitingProfile, visible_as: str) -> RecruitingContactRead:
    visibility = profile.visibility or RecruitingVisibility()
    message = "Use the compliant messaging flow from Chat 2 before direct outreach."

    if visible_as in {"admin", "athlete", "parent"}:
        return RecruitingContactRead(
            email=profile.contact_email or profile.athlete.email,
            phone=profile.contact_phone or profile.athlete.phone,
            visible_to_viewer=True,
            compliance_message=message,
        )

    if visible_as == "coach":
        if not visibility.show_contact_to_coaches:
            return RecruitingContactRead(
                visible_to_viewer=False,
                compliance_message="Athlete has hidden direct contact details. Use compliant messaging workflow.",
            )
        if visibility.parent_visibility_required:
            return RecruitingContactRead(
                email=_mask_value(profile.contact_email or profile.athlete.email),
                phone=_mask_value(profile.contact_phone or profile.athlete.phone),
                visible_to_viewer=False,
                compliance_message="Parent visibility is required for coach outreach. Use the Chat 2 compliance flow.",
            )
        if profile.contact_visibility == RecruitingContactVisibility.hidden:
            return RecruitingContactRead(
                visible_to_viewer=False,
                compliance_message="Direct contact is hidden for this profile.",
            )
        return RecruitingContactRead(
            email=profile.contact_email or profile.athlete.email,
            phone=profile.contact_phone or profile.athlete.phone,
            visible_to_viewer=True,
            compliance_message=message,
        )

    return RecruitingContactRead(
        email=None,
        phone=None,
        visible_to_viewer=False,
        compliance_message="Contact details are hidden on public recruiting views.",
    )


def _card_read(
    db: Session,
    profile: RecruitingProfile,
    current_user: User | None = None,
    coach_id: int | None = None,
) -> RecruitingAthleteCardRead:
    snapshot = _stats_snapshot(db, profile.athlete_id, profile.team_id)
    saved = False
    tag_labels: list[str] = []
    if coach_id is not None:
        watchlist = (
            db.query(RecruitingWatchlist)
            .filter(RecruitingWatchlist.coach_user_id == coach_id, RecruitingWatchlist.athlete_id == profile.athlete_id)
            .first()
        )
        saved = watchlist is not None
        tag_labels = [
            item.tag
            for item in db.query(RecruitingTag)
            .filter(RecruitingTag.coach_user_id == coach_id, RecruitingTag.athlete_id == profile.athlete_id)
            .order_by(RecruitingTag.tag.asc())
            .all()
        ]

    return RecruitingAthleteCardRead(
        athlete_id=profile.athlete_id,
        profile_id=profile.id,
        athlete_name=profile.athlete.full_name,
        school_team=profile.school_team,
        location_label=profile.location_label if (profile.visibility and profile.visibility.show_location) else None,
        graduation_year=profile.graduation_year,
        weight_class=profile.weight_class,
        height=profile.height,
        profile_image_url=profile.profile_image_url if (profile.visibility and profile.visibility.show_profile_photo) else None,
        is_open=profile.is_open,
        is_actively_looking=profile.is_actively_looking,
        is_featured=profile.is_featured,
        visibility_level=profile.visibility_level,
        record=_record_string(profile, snapshot),
        trend_label=snapshot.recent_trend if snapshot else None,
        win_percentage=snapshot.win_percentage if snapshot else None,
        bonus_point_rate=snapshot.bonus_point_rate if snapshot else None,
        stats_metrics=_stats_metrics(profile, snapshot),
        source_rankings=_source_rankings(profile),
        school_rankings=_school_rankings(profile),
        piniq_ranking=_piniq_ranking(db, profile, snapshot),
        achievements=list(profile.achievements or []),
        highlight_count=len(profile.highlights),
        updated_at=profile.updated_at,
        trending_score=_trending_score(profile, snapshot, db),
        saved_by_coach=saved,
        tags=tag_labels,
    )


def _recent_match_read(match: Match) -> RecruitingRecentMatchRead:
    return RecruitingRecentMatchRead(
        id=match.id,
        opponent_name=match.opponent_name,
        opponent_school=match.opponent_school,
        event_name=match.event_name,
        match_date=match.match_date,
        weight_class=match.weight_class,
        result=match.result.value,
        result_type=match.result_type.value,
        score_display=f"{match.score_for}-{match.score_against}",
    )


def _profile_read(db: Session, profile: RecruitingProfile, current_user: User) -> RecruitingProfileRead:
    visible_as = _assert_profile_visible(db, profile, current_user)
    snapshot = _stats_snapshot(db, profile.athlete_id, profile.team_id)
    visibility = profile.visibility
    if visibility is None:
        raise HTTPException(status_code=500, detail="Recruiting visibility settings are missing")
    visible_gpa = profile.gpa if (visible_as in {"admin", "athlete", "parent"} or visibility.show_gpa) else None
    return RecruitingProfileRead(
        athlete_id=profile.athlete_id,
        profile_id=profile.id,
        athlete_name=profile.athlete.full_name,
        team_id=profile.team_id,
        school_team=profile.school_team,
        graduation_year=profile.graduation_year,
        weight_class=profile.weight_class,
        height=profile.height,
        gpa=visible_gpa,
        bio=profile.bio,
        achievements=list(profile.achievements or []),
        location_label=profile.location_label if visibility.show_location or visible_as in {"athlete", "parent", "admin"} else None,
        profile_image_url=profile.profile_image_url if visibility.show_profile_photo or visible_as in {"athlete", "parent", "admin"} else None,
        is_open=profile.is_open,
        is_actively_looking=profile.is_actively_looking,
        is_featured=profile.is_featured,
        boost_requested=profile.boost_requested,
        visibility_level=profile.visibility_level,
        contact_visibility=profile.contact_visibility,
        stats_metrics=_stats_metrics(profile, snapshot),
        source_rankings=_source_rankings(profile),
        school_rankings=_school_rankings(profile),
        piniq_ranking=_piniq_ranking(db, profile, snapshot),
        record=_record_string(profile, snapshot),
        recent_matches=[_recent_match_read(item) for item in _recent_matches(db, profile.athlete_id)],
        highlights=[
            RecruitingHighlightRead.model_validate(item)
            for item in sorted(profile.highlights, key=lambda highlight: (highlight.sort_order, highlight.id))
        ],
        contact=_contact_read(db, profile, visible_as),
        visibility=RecruitingVisibilityRead.model_validate(visibility),
        visible_as=visible_as,
        parent_visibility_required=visibility.parent_visibility_required,
        updated_at=profile.updated_at,
    )


def _apply_search_filters(
    db: Session,
    profiles: list[RecruitingProfile],
    params: RecruitingSearchParams,
    current_user: User,
) -> list[RecruitingProfile]:
    results: list[RecruitingProfile] = []
    lower_query = params.query.lower().strip() if params.query else None
    lower_location = params.location.lower().strip() if params.location else None

    for profile in profiles:
        try:
            _assert_profile_visible(db, profile, current_user)
        except HTTPException:
            continue

        snapshot = _stats_snapshot(db, profile.athlete_id, profile.team_id)
        summary = profile.stats_summary or {}

        if params.weight_class and profile.weight_class != params.weight_class:
            continue
        if params.graduation_year and profile.graduation_year != params.graduation_year:
            continue
        if lower_location and lower_location not in (profile.location_label or "").lower():
            continue
        if params.is_open is not None and profile.is_open != params.is_open:
            continue
        if params.is_actively_looking is not None and profile.is_actively_looking != params.is_actively_looking:
            continue
        if params.min_win_percentage is not None and (snapshot is None or snapshot.win_percentage < params.min_win_percentage):
            continue
        if params.min_bonus_rate is not None and (snapshot is None or snapshot.bonus_point_rate < params.min_bonus_rate):
            continue
        if params.min_takedowns_per_match is not None:
            takedowns = float(summary.get("takedowns_per_match") or 0)
            if takedowns < params.min_takedowns_per_match:
                continue
        if lower_query:
            haystacks = [
                profile.athlete.full_name,
                profile.school_team or "",
                profile.bio or "",
                " ".join(profile.achievements or []),
                profile.location_label or "",
            ]
            if not any(lower_query in item.lower() for item in haystacks):
                continue
        results.append(profile)
    return results


def list_recruiting_athletes(
    db: Session,
    current_user: User,
    *,
    featured_only: bool = False,
    open_only: bool = False,
    sort_by: str = "updated",
    limit: int = 50,
) -> list[RecruitingAthleteCardRead]:
    query = (
        db.query(RecruitingProfile)
        .options(
            joinedload(RecruitingProfile.athlete),
            joinedload(RecruitingProfile.visibility),
            joinedload(RecruitingProfile.highlights),
        )
    )
    if featured_only:
        query = query.filter(RecruitingProfile.is_featured.is_(True))
    if open_only:
        query = query.filter(RecruitingProfile.is_open.is_(True))
    profiles = query.all()
    visible_profiles = _apply_search_filters(db, profiles, RecruitingSearchParams(), current_user)
    cards = [_card_read(db, profile, current_user=current_user, coach_id=current_user.id if current_user.role in COACH_ROLES else None) for profile in visible_profiles]
    if sort_by == "trending":
        cards.sort(key=lambda item: item.trending_score, reverse=True)
    else:
        cards.sort(key=lambda item: item.updated_at, reverse=True)
    return cards[:limit]


def search_recruiting_athletes(
    db: Session,
    current_user: User,
    params: RecruitingSearchParams,
) -> RecruitingSearchResponse:
    profiles = (
        db.query(RecruitingProfile)
        .options(
            joinedload(RecruitingProfile.athlete),
            joinedload(RecruitingProfile.visibility),
            joinedload(RecruitingProfile.highlights),
        )
        .all()
    )
    filtered = _apply_search_filters(db, profiles, params, current_user)
    cards = [_card_read(db, profile, current_user=current_user, coach_id=current_user.id if current_user.role in COACH_ROLES else None) for profile in filtered]
    cards.sort(key=lambda item: (item.trending_score, item.updated_at), reverse=True)
    return RecruitingSearchResponse(
        results=cards,
        total=len(cards),
        filters_applied=params.model_dump(exclude_none=True),
    )


def get_recruiting_profile(db: Session, athlete_id: int, current_user: User) -> RecruitingProfileRead:
    profile = _get_profile_or_404(db, athlete_id)
    return _profile_read(db, profile, current_user)


def get_recruiting_source_links(db: Session, athlete_id: int, current_user: User) -> RecruitingSourceLinksRead:
    profile = _get_profile_or_404(db, athlete_id)
    _assert_profile_visible(db, profile, current_user)
    return RecruitingSourceLinksRead(athlete_id=athlete_id, source_links=_source_links(profile))


def save_recruiting_source_links(
    db: Session,
    athlete_id: int,
    payload: RecruitingSourceLinksUpsert,
    current_user: User,
) -> RecruitingSourceLinksRead:
    _assert_profile_editor(db, athlete_id, current_user)
    profile = _get_profile_or_404(db, athlete_id)
    summary = dict(profile.stats_summary or {})
    seen: set[tuple[str, str]] = set()
    rows: list[dict] = []
    for source_link in payload.source_links:
        key = (source_link.source.strip().lower(), source_link.url.strip())
        if key in seen:
            continue
        seen.add(key)
        rows.append(source_link.model_dump())
    summary["source_links"] = rows
    profile.stats_summary = summary
    db.flush()
    return RecruitingSourceLinksRead(athlete_id=athlete_id, source_links=_source_links(profile))


def create_recruiting_profile(
    db: Session,
    payload: RecruitingProfileCreate,
    current_user: User,
) -> RecruitingProfileWriteResponse:
    _assert_profile_editor(db, payload.athlete_id, current_user)
    athlete = _get_user_or_404(db, payload.athlete_id)
    if athlete.role != UserRole.athlete:
        raise HTTPException(status_code=400, detail="Recruiting profiles can only be created for athletes")
    existing = _query_profile(db, payload.athlete_id)
    if existing:
        raise HTTPException(status_code=400, detail="Recruiting profile already exists")

    profile = RecruitingProfile(
        athlete_id=payload.athlete_id,
        team_id=payload.team_id or athlete.primary_team_id,
        graduation_year=payload.graduation_year,
        school_team=payload.school_team,
        weight_class=payload.weight_class,
        height=payload.height,
        gpa=payload.gpa,
        bio=payload.bio,
        achievements=payload.achievements,
        contact_email=payload.contact_email,
        contact_phone=payload.contact_phone,
        location_label=payload.location_label or athlete.hometown,
        stats_summary=payload.stats_summary,
        match_record_override=payload.match_record_override,
        profile_image_url=payload.profile_image_url or athlete.profile_image_url,
        is_open=payload.is_open,
        is_actively_looking=payload.is_actively_looking,
        is_featured=payload.is_featured,
        boost_requested=payload.boost_requested,
        visibility_level=payload.visibility_level,
        contact_visibility=payload.contact_visibility,
    )
    db.add(profile)
    db.flush()
    _upsert_visibility(profile, payload.visibility)
    _replace_highlights(profile, payload.highlights)
    db.flush()

    profile = _get_profile_or_404(db, payload.athlete_id)
    return RecruitingProfileWriteResponse(message="Recruiting profile created", profile=_profile_read(db, profile, current_user))


def update_recruiting_profile(
    db: Session,
    athlete_id: int,
    payload: RecruitingProfileUpdate,
    current_user: User,
) -> RecruitingProfileWriteResponse:
    _assert_profile_editor(db, athlete_id, current_user)
    profile = _get_profile_or_404(db, athlete_id)

    for field, value in payload.model_dump(exclude_unset=True, exclude={"visibility", "highlights"}).items():
        setattr(profile, field, value)
    if payload.visibility is not None:
        _upsert_visibility(profile, payload.visibility)
    if payload.highlights is not None:
        _replace_highlights(profile, payload.highlights)
    db.flush()

    profile = _get_profile_or_404(db, athlete_id)
    return RecruitingProfileWriteResponse(message="Recruiting profile updated", profile=_profile_read(db, profile, current_user))


def get_recruiting_board(db: Session, current_user: User) -> RecruitingBoardRead:
    cards = list_recruiting_athletes(db, current_user, open_only=True, limit=200)
    trending = sorted(cards, key=lambda item: item.trending_score, reverse=True)[:8]
    featured = [item for item in cards if item.is_featured][:8]
    recently_updated = sorted(cards, key=lambda item: item.updated_at, reverse=True)[:8]
    top_performers = sorted(cards, key=lambda item: ((item.win_percentage or 0), (item.bonus_point_rate or 0)), reverse=True)[:8]
    state_school_rankings, national_school_rankings = _school_board_rows(cards)
    return RecruitingBoardRead(
        trending_athletes=trending,
        featured_athletes=featured,
        recently_updated=recently_updated,
        top_performers=top_performers,
        state_school_rankings=state_school_rankings,
        national_school_rankings=national_school_rankings,
    )


def get_trending_athletes(db: Session, current_user: User, limit: int = 10) -> RecruitingTrendingRead:
    athletes = list_recruiting_athletes(db, current_user, open_only=True, sort_by="trending", limit=limit)
    return RecruitingTrendingRead(generated_at=datetime.utcnow(), athletes=athletes)


def _set_tags(db: Session, coach_id: int, athlete_id: int, profile_id: int | None, team_id: int | None, tag_labels: list[str]) -> list[RecruitingTag]:
    db.query(RecruitingTag).filter(
        RecruitingTag.coach_user_id == coach_id,
        RecruitingTag.athlete_id == athlete_id,
    ).delete()
    created: list[RecruitingTag] = []
    for label in sorted({item.strip() for item in tag_labels if item.strip()}):
        tag = RecruitingTag(
            coach_user_id=coach_id,
            athlete_id=athlete_id,
            team_id=team_id,
            profile_id=profile_id,
            tag=label,
        )
        db.add(tag)
        created.append(tag)
    db.flush()
    return created


def save_watchlist_entry(
    db: Session,
    payload: RecruitingWatchlistCreate,
    current_user: User,
) -> RecruitingWatchlistResponse:
    _assert_coach_access(payload.coach_id, current_user)
    athlete = _get_user_or_404(db, payload.athlete_id)
    if athlete.role != UserRole.athlete:
        raise HTTPException(status_code=400, detail="Only athletes can be saved to a recruiting watchlist")
    profile = _get_profile_or_404(db, payload.athlete_id)
    _assert_profile_visible(db, profile, current_user)

    entry = (
        db.query(RecruitingWatchlist)
        .filter(
            RecruitingWatchlist.coach_user_id == payload.coach_id,
            RecruitingWatchlist.athlete_id == payload.athlete_id,
        )
        .first()
    )
    if entry is None:
        entry = RecruitingWatchlist(
            coach_user_id=payload.coach_id,
            athlete_id=payload.athlete_id,
            team_id=profile.team_id,
            profile_id=profile.id,
        )
        db.add(entry)
        db.flush()

    _set_tags(db, payload.coach_id, payload.athlete_id, profile.id, profile.team_id, payload.tag_labels)
    db.flush()
    return RecruitingWatchlistResponse(message="Athlete saved to watchlist", entry=_watchlist_entry_read(db, entry, payload.coach_id))


def _watchlist_entry_read(db: Session, entry: RecruitingWatchlist, coach_id: int) -> RecruitingWatchlistRead:
    profile = _get_profile_or_404(db, entry.athlete_id)
    note = (
        db.query(RecruitingNote)
        .filter(RecruitingNote.coach_user_id == coach_id, RecruitingNote.athlete_id == entry.athlete_id)
        .first()
    )
    tags = [
        item.tag
        for item in db.query(RecruitingTag)
        .filter(RecruitingTag.coach_user_id == coach_id, RecruitingTag.athlete_id == entry.athlete_id)
        .order_by(RecruitingTag.tag.asc())
        .all()
    ]
    return RecruitingWatchlistRead(
        id=entry.id,
        coach_id=entry.coach_user_id,
        athlete_id=entry.athlete_id,
        created_at=entry.created_at,
        athlete=_card_read(db, profile, coach_id=coach_id),
        note=note.note if note else None,
        tags=tags,
    )


def get_watchlist(db: Session, coach_id: int, current_user: User) -> list[RecruitingWatchlistRead]:
    _assert_coach_access(coach_id, current_user)
    entries = (
        db.query(RecruitingWatchlist)
        .filter(RecruitingWatchlist.coach_user_id == coach_id)
        .order_by(RecruitingWatchlist.updated_at.desc(), RecruitingWatchlist.id.desc())
        .all()
    )
    return [_watchlist_entry_read(db, entry, coach_id) for entry in entries]


def save_recruiting_note(
    db: Session,
    payload: RecruitingNoteCreate,
    current_user: User,
) -> RecruitingNoteRead:
    _assert_coach_access(payload.coach_id, current_user)
    profile = _get_profile_or_404(db, payload.athlete_id)
    _assert_profile_visible(db, profile, current_user)

    note = (
        db.query(RecruitingNote)
        .filter(
            RecruitingNote.coach_user_id == payload.coach_id,
            RecruitingNote.athlete_id == payload.athlete_id,
        )
        .first()
    )
    if note is None:
        note = RecruitingNote(
            coach_user_id=payload.coach_id,
            athlete_id=payload.athlete_id,
            team_id=profile.team_id,
            profile_id=profile.id,
            note=payload.note,
        )
        db.add(note)
    else:
        note.note = payload.note
        note.team_id = profile.team_id
        note.profile_id = profile.id
    db.flush()

    tags = _set_tags(db, payload.coach_id, payload.athlete_id, profile.id, profile.team_id, payload.tag_labels)
    note_read = RecruitingNoteRead.model_validate(note)
    note_read.tags = [tag.tag for tag in tags]
    return note_read


def scan_recruiting_sources(
    db: Session,
    payload: RecruitingSourceScanRequest,
    current_user: User,
) -> RecruitingSourceScanResponse:
    if current_user.role not in SCAN_ROLES:
        raise HTTPException(status_code=403, detail="Not allowed to scan recruiting sources")

    profile: RecruitingProfile | None = None
    athlete_name = payload.athlete_name
    school_name = payload.school_name
    state = payload.state
    if payload.athlete_id is not None:
        profile = _get_profile_or_404(db, payload.athlete_id)
        _assert_profile_visible(db, profile, current_user)
        athlete_name = athlete_name or profile.athlete.full_name
        school_name = school_name or profile.school_team
        state = state or profile.location_label

    all_source_rankings: list[RecruitingSourceRankingRead] = []
    all_school_rankings: list[RecruitingSchoolRankingRead] = []
    result_reads: list[RecruitingSourceScanResultRead] = []

    for source_link in payload.source_links:
        try:
            result = scan_public_recruiting_source(
                source=source_link.source,
                url=source_link.url,
                athlete_name=athlete_name,
                school_name=school_name,
                state=state,
            )
            all_source_rankings.extend(result.source_rankings)
            all_school_rankings.extend(result.school_rankings)
            result_reads.append(
                RecruitingSourceScanResultRead(
                    source=result.source,
                    url=result.url,
                    success=True,
                    message=result.message,
                    source_rankings=result.source_rankings,
                    school_rankings=result.school_rankings,
                )
            )
        except RecruitingSourceScannerError as exc:
            result_reads.append(
                RecruitingSourceScanResultRead(
                    source=source_link.source,
                    url=source_link.url,
                    success=False,
                    message=str(exc),
                )
            )

    updated_profile = False
    if payload.update_profile and profile is not None:
        summary = dict(profile.stats_summary or {})
        source_rows = [item.model_dump(mode="json", exclude_none=True) for item in all_source_rankings]
        school_rows = [item.model_dump(mode="json", exclude_none=True) for item in all_school_rankings]
        summary["source_rankings"] = _merge_rankings(
            summary.get("source_rankings") or [],
            source_rows,
            key_fields=("source", "profile_url", "weight_class"),
        )
        summary["school_rankings"] = _merge_rankings(
            summary.get("school_rankings") or [],
            school_rows,
            key_fields=("source", "profile_url", "school_name"),
        )
        profile.stats_summary = summary
        db.flush()
        updated_profile = True

    return RecruitingSourceScanResponse(
        scanned_at=datetime.utcnow(),
        updated_profile=updated_profile,
        source_rankings=all_source_rankings,
        school_rankings=all_school_rankings,
        results=result_reads,
    )


def run_saved_recruiting_source_scans(db: Session, *, limit: int = 100) -> RecruitingSavedSourceScanResponse:
    profiles = (
        db.query(RecruitingProfile)
        .options(joinedload(RecruitingProfile.athlete))
        .filter(RecruitingProfile.stats_summary.isnot(None))
        .order_by(RecruitingProfile.updated_at.asc(), RecruitingProfile.id.asc())
        .limit(limit)
        .all()
    )
    checked = 0
    updated = 0
    source_found = 0
    school_found = 0
    failures: list[str] = []

    for profile in profiles:
        links = _source_links(profile)
        if not links:
            continue
        checked += 1
        summary = dict(profile.stats_summary or {})
        incoming_source_rows: list[dict] = []
        incoming_school_rows: list[dict] = []

        for source_link in links:
            try:
                result = scan_public_recruiting_source(
                    source=source_link.source,
                    url=source_link.url,
                    athlete_name=profile.athlete.full_name,
                    school_name=profile.school_team,
                    state=profile.location_label,
                )
            except RecruitingSourceScannerError as exc:
                failures.append(f"{profile.athlete_id}:{source_link.source}: {exc}")
                continue
            incoming_source_rows.extend(
                item.model_dump(mode="json", exclude_none=True) for item in result.source_rankings
            )
            incoming_school_rows.extend(
                item.model_dump(mode="json", exclude_none=True) for item in result.school_rankings
            )

        if incoming_source_rows or incoming_school_rows:
            summary["source_rankings"] = _merge_rankings(
                summary.get("source_rankings") or [],
                incoming_source_rows,
                key_fields=("source", "profile_url", "weight_class"),
            )
            summary["school_rankings"] = _merge_rankings(
                summary.get("school_rankings") or [],
                incoming_school_rows,
                key_fields=("source", "profile_url", "school_name"),
            )
            profile.stats_summary = summary
            updated += 1
            source_found += len(incoming_source_rows)
            school_found += len(incoming_school_rows)

    db.flush()
    return RecruitingSavedSourceScanResponse(
        scanned_at=datetime.utcnow(),
        profiles_checked=checked,
        profiles_updated=updated,
        source_rankings_found=source_found,
        school_rankings_found=school_found,
        failures=failures[:50],
    )
