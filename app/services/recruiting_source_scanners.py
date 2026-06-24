from __future__ import annotations

from dataclasses import dataclass
from datetime import date
from html import unescape
import re
from urllib.error import HTTPError, URLError
from urllib.parse import urlparse
from urllib.request import Request, urlopen

from app.core.config import settings
from app.schemas.recruiting import RecruitingSchoolRankingRead, RecruitingSourceRankingRead


class RecruitingSourceScannerError(Exception):
    pass


@dataclass
class RecruitingSourceScanResult:
    source: str
    url: str
    source_rankings: list[RecruitingSourceRankingRead]
    school_rankings: list[RecruitingSchoolRankingRead]
    message: str | None = None


_ALLOWED_HOST_SUFFIXES = (
    "trackwrestling.com",
    "flowrestling.org",
    "flosports.tv",
    "usawmembership.com",
    "usabracketing.com",
    "kentuckymat.com",
)

_SOURCE_ALIASES = {
    "track": "TrackWrestling",
    "trackwrestling": "TrackWrestling",
    "track wrestling": "TrackWrestling",
    "flo": "FloWrestling",
    "flowrestling": "FloWrestling",
    "flo wrestling": "FloWrestling",
    "usa": "USA Bracketing",
    "usa bracketing": "USA Bracketing",
    "usawmembership": "USA Bracketing",
    "usa wrestling": "USA Bracketing",
    "kentuckymat": "KentuckyMat",
    "kentucky mat": "KentuckyMat",
}


def normalize_recruiting_source(source: str) -> str:
    normalized = " ".join(source.strip().split()).lower()
    return _SOURCE_ALIASES.get(normalized, source.strip())


def _assert_public_ranking_url(url: str) -> None:
    parsed = urlparse(url)
    if parsed.scheme not in {"https", "http"}:
        raise RecruitingSourceScannerError("Source URL must be an http or https page")
    host = (parsed.hostname or "").lower()
    if not any(host == suffix or host.endswith(f".{suffix}") for suffix in _ALLOWED_HOST_SUFFIXES):
        raise RecruitingSourceScannerError("Source URL is not on an approved wrestling rankings domain")


def _fetch_html(url: str) -> str:
    _assert_public_ranking_url(url)
    request = Request(
        url,
        headers={
            "User-Agent": settings.tournament_scan_user_agent,
            "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
        },
    )
    try:
        with urlopen(request, timeout=settings.tournament_scan_timeout_seconds) as response:
            return response.read().decode("utf-8", errors="ignore")
    except HTTPError as exc:
        raise RecruitingSourceScannerError(f"HTTP {exc.code} while scanning recruiting source") from exc
    except URLError as exc:
        raise RecruitingSourceScannerError(f"Network error while scanning recruiting source: {exc.reason}") from exc


def _visible_lines(html: str) -> list[str]:
    text = re.sub(r"(?is)<(script|style).*?>.*?</\1>", " ", html)
    text = re.sub(r"(?i)<br\s*/?>", "\n", text)
    text = re.sub(r"(?i)</(div|p|li|tr|td|th|h1|h2|h3|h4|h5|h6|section|article)>", "\n", text)
    text = re.sub(r"(?s)<[^>]+>", " ", text)
    text = unescape(text).replace("\xa0", " ")
    text = re.sub(r"[ \t]+", " ", text)
    lines = [line.strip(" -|\t") for line in text.splitlines()]
    return [line for line in lines if len(line) >= 3]


def _clean_text(value: str) -> str:
    text = re.sub(r"(?is)<(script|style).*?>.*?</\1>", " ", value)
    text = re.sub(r"(?s)<[^>]+>", " ", text)
    text = unescape(text).replace("\xa0", " ")
    return re.sub(r"\s+", " ", text).strip()


def _table_rows(html: str) -> list[list[str]]:
    rows: list[list[str]] = []
    for row_match in re.finditer(r"(?is)<tr\b[^>]*>(?P<row>.*?)</tr>", html):
        row_html = row_match.group("row")
        cells = [
            _clean_text(cell_match.group("cell"))
            for cell_match in re.finditer(r"(?is)<t[dh]\b[^>]*>(?P<cell>.*?)</t[dh]>", row_html)
        ]
        cells = [cell for cell in cells if cell]
        if cells:
            rows.append(cells)
    return rows


def _contains_all_name_tokens(line: str, name: str | None) -> bool:
    if not name:
        return False
    line_lower = line.lower()
    tokens = [token.lower() for token in re.split(r"\s+", name.strip()) if len(token) > 1]
    return bool(tokens) and all(token in line_lower for token in tokens)


def _record_from_line(line: str) -> str | None:
    match = re.search(r"\b\d{1,3}\s*-\s*\d{1,3}(?:\s*-\s*\d{1,3})?\b", line)
    if not match:
        return None
    return re.sub(r"\s+", "", match.group(0))


def _rank_from_line(line: str, *, national: bool = False, state: bool = False) -> int | None:
    if national or state:
        label = "national" if national else "state"
        patterns = [rf"{label}\s*(?:rank|ranking)?\s*#?\s*(\d{{1,4}})"]
    else:
        patterns = [
            r"(?:rank|ranking)\s*#?\s*(\d{1,4})\b",
            r"#\s*(\d{1,4})\b",
        ]
    for pattern in patterns:
        match = re.search(pattern, line, re.IGNORECASE)
        if match:
            return int(match.group(1))
    return None


def _ranking_label(line: str) -> str | None:
    rank = _rank_from_line(line)
    return f"#{rank}" if rank else None


def _weight_from_line(line: str) -> str | None:
    match = re.search(r"\b(10[0-9]|11[0-9]|12[0-9]|13[0-9]|14[0-9]|15[0-9]|16[0-9]|17[0-9]|18[0-9]|19[0-9]|2[0-9]{2}|285)\s*(?:lb|lbs|pounds)?\b", line, re.IGNORECASE)
    if not match:
        return None
    return match.group(1)


def _season_from_line(line: str) -> str | None:
    match = re.search(r"\b(20\d{2})(?:\s*-\s*(\d{2}|20\d{2}))?\b", line)
    if not match:
        return None
    if match.group(2):
        return f"{match.group(1)}-{match.group(2)}"
    return match.group(1)


def _state_from_line(line: str, requested_state: str | None) -> str | None:
    if requested_state and re.search(rf"\b{re.escape(requested_state)}\b", line, re.IGNORECASE):
        return requested_state
    match = re.search(r"\b(AL|AK|AZ|AR|CA|CO|CT|DE|FL|GA|HI|IA|ID|IL|IN|KS|KY|LA|MA|MD|ME|MI|MN|MO|MS|MT|NC|ND|NE|NH|NJ|NM|NV|NY|OH|OK|OR|PA|RI|SC|SD|TN|TX|UT|VA|VT|WA|WI|WV|WY)\b", line)
    return match.group(1) if match else requested_state


def _is_kentuckymat_url(url: str) -> bool:
    host = (urlparse(url).hostname or "").lower()
    return host == "kentuckymat.com" or host.endswith(".kentuckymat.com")


def _is_trackwrestling_url(url: str) -> bool:
    host = (urlparse(url).hostname or "").lower()
    return host == "trackwrestling.com" or host.endswith(".trackwrestling.com")


def _rank_from_cells(cells: list[str]) -> int | None:
    if len(cells) == 1:
        return _rank_from_line(cells[0])
    for cell in cells[:3]:
        match = re.search(r"#?\s*(\d{1,4})\b", cell)
        if match:
            return int(match.group(1))
    return _rank_from_line(" ".join(cells))


def _record_from_cells(cells: list[str]) -> str | None:
    for cell in cells:
        record = _record_from_line(cell)
        if record:
            return record
    return None


def _weight_from_cells(cells: list[str]) -> str | None:
    for cell in cells:
        weight = _weight_from_line(cell)
        if weight:
            return weight
    return None


def _parse_kentuckymat_rankings(
    *,
    html: str,
    url: str,
    athlete_name: str | None,
    school_name: str | None,
    state: str | None,
) -> tuple[list[RecruitingSourceRankingRead], list[RecruitingSchoolRankingRead]]:
    source_rankings: list[RecruitingSourceRankingRead] = []
    school_rankings: list[RecruitingSchoolRankingRead] = []

    for cells in _table_rows(html):
        joined = " ".join(cells)
        lowered = joined.lower()
        if any(header in lowered for header in {"rank wrestler school", "weight wrestler", "team points"}):
            continue

        if _contains_all_name_tokens(joined, athlete_name):
            rank = _rank_from_cells(cells)
            source_rankings.append(
                RecruitingSourceRankingRead(
                    source="KentuckyMat",
                    record=_record_from_cells(cells),
                    ranking=f"#{rank}" if rank else _ranking_label(joined),
                    weight_class=_weight_from_cells(cells),
                    season=_season_from_line(joined),
                    profile_url=url,
                    last_checked=date.today(),
                )
            )
            continue

        if not school_name or school_name.lower() not in lowered:
            continue

        rank = _rank_from_cells(cells)
        national_rank = _rank_from_line(joined, national=True)
        state_rank = _rank_from_line(joined, state=True)
        if state_rank is None and rank != national_rank:
            state_rank = rank
        if national_rank is None and "national" in lowered:
            national_rank = rank

        school_rankings.append(
            RecruitingSchoolRankingRead(
                source="KentuckyMat",
                school_name=school_name,
                state=_state_from_line(joined, state) or "KY",
                state_rank=state_rank,
                national_rank=national_rank,
                season=_season_from_line(joined),
                profile_url=url,
                last_checked=date.today(),
            )
        )

    return source_rankings, school_rankings


def _parse_trackwrestling_rankings(
    *,
    html: str,
    url: str,
    athlete_name: str | None,
    school_name: str | None,
    state: str | None,
) -> tuple[list[RecruitingSourceRankingRead], list[RecruitingSchoolRankingRead]]:
    source_rankings: list[RecruitingSourceRankingRead] = []
    school_rankings: list[RecruitingSchoolRankingRead] = []

    for cells in _table_rows(html):
        joined = " ".join(cells)
        lowered = joined.lower()
        if any(header in lowered for header in {"rank name school", "rank wrestler team", "weight name team"}):
            continue

        if _contains_all_name_tokens(joined, athlete_name):
            rank = _rank_from_cells(cells)
            source_rankings.append(
                RecruitingSourceRankingRead(
                    source="TrackWrestling",
                    record=_record_from_cells(cells),
                    ranking=f"#{rank}" if rank else _ranking_label(joined),
                    weight_class=_weight_from_cells(cells),
                    season=_season_from_line(joined),
                    profile_url=url,
                    last_checked=date.today(),
                )
            )
            continue

        if not school_name or school_name.lower() not in lowered:
            continue

        rank = _rank_from_cells(cells)
        national_rank = _rank_from_line(joined, national=True)
        state_rank = _rank_from_line(joined, state=True)
        if state_rank is None and rank != national_rank:
            state_rank = rank
        if national_rank is None and "national" in lowered:
            national_rank = rank

        school_rankings.append(
            RecruitingSchoolRankingRead(
                source="TrackWrestling",
                school_name=school_name,
                state=_state_from_line(joined, state),
                state_rank=state_rank,
                national_rank=national_rank,
                season=_season_from_line(joined),
                profile_url=url,
                last_checked=date.today(),
            )
        )

    return source_rankings, school_rankings


def scan_public_recruiting_source(
    *,
    source: str,
    url: str,
    athlete_name: str | None = None,
    school_name: str | None = None,
    state: str | None = None,
) -> RecruitingSourceScanResult:
    source_label = normalize_recruiting_source(source)
    html = _fetch_html(url)
    lines = _visible_lines(html)

    source_rankings: list[RecruitingSourceRankingRead] = []
    school_rankings: list[RecruitingSchoolRankingRead] = []

    if source_label == "KentuckyMat" or _is_kentuckymat_url(url):
        source_rankings, school_rankings = _parse_kentuckymat_rankings(
            html=html,
            url=url,
            athlete_name=athlete_name,
            school_name=school_name,
            state=state,
        )
        if source_rankings or school_rankings:
            return RecruitingSourceScanResult(
                source="KentuckyMat",
                url=url,
                source_rankings=source_rankings,
                school_rankings=school_rankings,
                message=f"Scanned {len(_table_rows(html))} KentuckyMat table rows from public source.",
            )

    if source_label == "TrackWrestling" or _is_trackwrestling_url(url):
        source_rankings, school_rankings = _parse_trackwrestling_rankings(
            html=html,
            url=url,
            athlete_name=athlete_name,
            school_name=school_name,
            state=state,
        )
        if source_rankings or school_rankings:
            return RecruitingSourceScanResult(
                source="TrackWrestling",
                url=url,
                source_rankings=source_rankings,
                school_rankings=school_rankings,
                message=f"Scanned {len(_table_rows(html))} TrackWrestling table rows from public source.",
            )

    for line in lines:
        if _contains_all_name_tokens(line, athlete_name):
            source_rankings.append(
                RecruitingSourceRankingRead(
                    source=source_label,
                    record=_record_from_line(line),
                    ranking=_ranking_label(line),
                    weight_class=_weight_from_line(line),
                    season=_season_from_line(line),
                    profile_url=url,
                    last_checked=date.today(),
                )
            )

        if school_name and school_name.lower() in line.lower() and not _contains_all_name_tokens(line, athlete_name):
            state_rank = _rank_from_line(line, state=True)
            national_rank = _rank_from_line(line, national=True)
            if state_rank is None and national_rank is None:
                rank = _rank_from_line(line)
                if "national" in line.lower():
                    national_rank = rank
                else:
                    state_rank = rank
            school_rankings.append(
                RecruitingSchoolRankingRead(
                    source=source_label,
                    school_name=school_name,
                    state=_state_from_line(line, state),
                    state_rank=state_rank,
                    national_rank=national_rank,
                    season=_season_from_line(line),
                    profile_url=url,
                    last_checked=date.today(),
                )
            )

    return RecruitingSourceScanResult(
        source=source_label,
        url=url,
        source_rankings=source_rankings,
        school_rankings=school_rankings,
        message=f"Scanned {len(lines)} visible lines from public source.",
    )
