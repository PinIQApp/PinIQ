from __future__ import annotations

from dataclasses import dataclass
from datetime import date, datetime
from html import unescape
import re
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen

from app.core.config import settings
from app.models.tournament import TournamentSourceType
from app.schemas.tournament import TournamentScanIngestItem


@dataclass
class TournamentSourceScanResult:
    source_key: TournamentSourceType
    items: list[TournamentScanIngestItem]
    note: str | None = None
    query_snapshot: dict | None = None


class TournamentSourceScannerError(Exception):
    pass


class BaseTournamentSourceScanner:
    source_key: TournamentSourceType
    _street_suffixes = {
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
        "hwy",
        "highway",
        "way",
        "parkway",
        "pkwy",
        "cir",
        "circle",
    }

    def fetch(self, *, search: str | None = None) -> TournamentSourceScanResult:
        raise NotImplementedError

    def _fetch_html(self, url: str) -> str:
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
            raise TournamentSourceScannerError(f"HTTP {exc.code} while scanning {self.source_key.value}") from exc
        except URLError as exc:
            raise TournamentSourceScannerError(f"Network error while scanning {self.source_key.value}: {exc.reason}") from exc

    def _visible_lines(self, html: str) -> list[str]:
        # Public event pages vary a lot, so we flatten them into readable text lines
        # before we try to infer title/date/location groupings.
        text = re.sub(r"(?is)<(script|style).*?>.*?</\\1>", " ", html)
        text = re.sub(r"(?i)<br\\s*/?>", "\n", text)
        text = re.sub(r"(?i)</(div|p|li|tr|td|h1|h2|h3|h4|h5|h6|section|article)>", "\n", text)
        text = re.sub(r"(?s)<[^>]+>", " ", text)
        text = unescape(text)
        text = text.replace("\xa0", " ")
        text = re.sub(r"[ \t]+", " ", text)
        lines = [line.strip(" -|\t") for line in text.splitlines()]
        return [line for line in lines if len(line) >= 3]

    @staticmethod
    def _title_case_words(value: str) -> str:
        return " ".join(part.capitalize() for part in value.split())

    def _clean_city_name(self, value: str | None) -> str | None:
        if not value:
            return None
        cleaned = " ".join(value.split()).strip(" ,")
        if not cleaned:
            return None
        tokens = cleaned.split()
        lower_tokens = [token.lower().strip(".,") for token in tokens]
        suffix_indexes = [index for index, token in enumerate(lower_tokens) if token in self._street_suffixes]
        if suffix_indexes:
            last_suffix_index = suffix_indexes[-1]
            trailing_tokens = tokens[last_suffix_index + 1 :]
            if trailing_tokens:
                return " ".join(trailing_tokens)
        return cleaned


class FloWrestlingSourceScanner(BaseTournamentSourceScanner):
    source_key = TournamentSourceType.flo

    _month_map = {
        "jan": 1,
        "feb": 2,
        "mar": 3,
        "apr": 4,
        "may": 5,
        "jun": 6,
        "jul": 7,
        "aug": 8,
        "sep": 9,
        "oct": 10,
        "nov": 11,
        "dec": 12,
    }

    _event_card_pattern = re.compile(
        r'href="https://www\.flowrestling\.org/nextgen/events/(?P<event_id>\d+)"[^>]*?>'
        r'.*?textcontent="(?P<display_date>[A-Za-z]{3}\s+\d{1,2})"'
        r'.*?<h4[^>]*textcontent="(?P<title>[^"]+)"'
        r'.*?<span[^>]*textcontent="(?P<location>[^"]+)"',
        re.IGNORECASE | re.DOTALL,
    )

    def fetch(self, *, search: str | None = None) -> TournamentSourceScanResult:
        source_url = settings.flo_events_url
        if "nav_id=" not in source_url:
            source_url = f"{source_url}?nav_id=578"

        html = self._fetch_html(source_url)
        items: list[TournamentScanIngestItem] = []
        seen: set[str] = set()
        current_year = datetime.utcnow().year

        for match in self._event_card_pattern.finditer(html):
            title = " ".join(match.group("title").split())
            if not title or len(title) < 4:
                continue
            if search and search.strip().lower() not in title.lower():
                continue

            month_name, start_day_text = match.group("display_date").split()
            month = self._month_map[month_name.lower()]
            start_day = int(start_day_text)
            end_day = start_day
            start_date = date(current_year, month, start_day)
            end_date = date(current_year, month, end_day)
            key = f"{start_date.isoformat()}::{title.lower()}"
            if key in seen:
                continue
            seen.add(key)

            raw_location = " ".join(match.group("location").split())
            venue = None
            city = None
            state = None
            if "·" in raw_location:
                venue_part, locale_part = [part.strip() for part in raw_location.split("·", 1)]
                venue = venue_part or None
                if "," in locale_part:
                    city_part, state_part = [part.strip() for part in locale_part.rsplit(",", 1)]
                    city = city_part or None
                    state = state_part[:2] if state_part else None
                else:
                    city = locale_part or None
            else:
                venue = raw_location or None

            event_id = match.group("event_id")
            event_page_link = f"https://www.flowrestling.org/nextgen/events/{event_id}"

            items.append(
                TournamentScanIngestItem(
                    external_id=key,
                    source_id_hint=event_id,
                    source_label="FloWrestling",
                    name=title,
                    start_date=start_date,
                    end_date=end_date,
                    city=city,
                    state=state,
                    age_divisions=[],
                    weight_classes=None,
                    event_type="individual_tournament",
                    event_page_link=event_page_link,
                    description="Discovered from FloWrestling public event listings.",
                    ingestion_notes="Public source scan from FloWrestling schedule/results page.",
                    normalized_payload={
                        "discovered_from": "flo_public_results_nav_page",
                        "venue_hint": venue,
                        "event_id": event_id,
                    },
                )
            )

        return TournamentSourceScanResult(
            source_key=self.source_key,
            items=items,
            note="FloWrestling public schedule scan completed.",
            query_snapshot={"search": search, "source_url": source_url},
        )


class TrackWrestlingSourceScanner(BaseTournamentSourceScanner):
    source_key = TournamentSourceType.track

    _event_row_pattern = re.compile(
        r"<li class='(?:evenRow|oddRow)'>\s*(?P<row>.*?)</li>",
        re.IGNORECASE | re.DOTALL,
    )
    _event_selected_pattern = re.compile(
        r"eventSelected\((?P<event_id>\d+),'(?P<title>[^']+)',(?P<event_type>\d+),\s*'(?P<logo_url>[^']*)',\s*(?P<anchor_id>\d+)\)",
        re.IGNORECASE,
    )
    _track_link_pattern = re.compile(
        r"<a[^>]+href=(?P<quote>['\"])(?P<link>https?://[^'\"]+)(?P=quote)[^>]*>(?P<label>.*?)</a>",
        re.IGNORECASE | re.DOTALL,
    )

    _date_pattern = re.compile(
        r"(?P<month>\d{2})/(?P<day>\d{2})"
        r"(?:\s*-\s*(?:(?P<end_month>\d{2})/)?(?P<end_day>\d{2}))?"
        r"/(?P<year>\d{4})",
        re.IGNORECASE,
    )
    _city_state_pattern = re.compile(r"([A-Za-z .'\-]+),\s*([A-Z]{2})\s+\d{5}")
    _ignored_titles = {
        "login",
        "results",
        "brackets",
        "trackcast",
        "pre-register",
        "registration",
        "event info",
        "weigh-ins",
        "trackwrestling",
        "my track",
        "upgrade",
        "search",
    }
    _blocked_title_fragments = (
        "template",
        "registration",
        "pre-registration",
    )

    def _looks_like_title(self, line: str) -> bool:
        cleaned = line.strip().lower()
        if cleaned in self._ignored_titles:
            return False
        if any(fragment in cleaned for fragment in self._blocked_title_fragments):
            return False
        if len(cleaned) < 4 or len(cleaned) > 140:
            return False
        if self._date_pattern.search(cleaned):
            return False
        if cleaned.startswith("http") or cleaned.endswith(".com"):
            return False
        if re.fullmatch(r"[0-9/ \-]+", cleaned):
            return False
        return any(char.isalpha() for char in cleaned)

    def fetch(self, *, search: str | None = None) -> TournamentSourceScanResult:
        if not settings.track_events_url:
            raise TournamentSourceScannerError("TrackWrestling scanner URL is not configured")

        html = self._fetch_html(settings.track_events_url)
        row_items = self._parse_event_rows(html=html, search=search)
        if row_items:
            return TournamentSourceScanResult(
                source_key=self.source_key,
                items=row_items,
                note="TrackWrestling public event scan completed.",
                query_snapshot={"search": search, "source_url": settings.track_events_url},
            )

        lines = self._visible_lines(html)
        items: list[TournamentScanIngestItem] = []
        seen: set[str] = set()
        current_year = datetime.utcnow().year

        for index, line in enumerate(lines):
            match = self._date_pattern.search(line)
            if not match:
                continue

            title = line[: match.start()].strip(" -|")
            if not self._looks_like_title(title):
                title = ""
                lookback = index - 1
                while lookback >= 0 and index - lookback <= 3:
                    candidate = lines[lookback]
                    if self._looks_like_title(candidate):
                        title = candidate
                        break
                    lookback -= 1

            if not title:
                continue
            if search and search.strip().lower() not in title.lower():
                continue

            year = int(match.group("year") or current_year)
            month = int(match.group("month"))
            day = int(match.group("day"))
            start_date = date(year, month, day)
            end_month = int(match.group("end_month") or month)
            end_day = int(match.group("end_day") or day)
            end_date = date(year, end_month, end_day)

            context_lines = lines[index + 1 : index + 5]
            city = None
            state = None
            venue = None
            for context_line in context_lines:
                location_match = self._city_state_pattern.search(context_line)
                if location_match:
                    city = self._clean_city_name(location_match.group(1).strip())
                    state = location_match.group(2).strip()
                elif venue is None and context_line.lower() not in self._ignored_titles and not self._date_pattern.search(context_line):
                    venue = context_line

            key = f"{start_date.isoformat()}::{title.lower()}"
            if key in seen:
                continue
            seen.add(key)

            items.append(
                TournamentScanIngestItem(
                    external_id=key,
                    source_id_hint=key,
                    source_label="TrackWrestling",
                    name=title,
                    start_date=start_date,
                    end_date=end_date,
                    city=city,
                    state=state,
                    age_divisions=[],
                    weight_classes=None,
                    event_type="individual_tournament",
                    registration_link=settings.track_events_url,
                    event_page_link=settings.track_events_url,
                    description="Discovered from the public TrackWrestling event search page.",
                    ingestion_notes="Public source scan from TrackWrestling event listings.",
                    normalized_payload={
                        "discovered_from": "track_public_event_search",
                        "venue_hint": venue,
                    },
                )
            )

        return TournamentSourceScanResult(
            source_key=self.source_key,
            items=items,
            note="TrackWrestling public event scan completed.",
            query_snapshot={"search": search, "source_url": settings.track_events_url},
        )

    def _parse_event_rows(self, *, html: str, search: str | None) -> list[TournamentScanIngestItem]:
        items: list[TournamentScanIngestItem] = []
        seen: set[str] = set()

        for match in self._event_row_pattern.finditer(html):
            row_html = match.group("row")
            header_match = self._event_selected_pattern.search(row_html)
            if not header_match:
                continue

            title = " ".join(unescape(header_match.group("title")).split()).strip(" -")
            if not self._looks_like_title(title):
                continue
            if search and search.strip().lower() not in title.lower():
                continue

            date_match = self._date_pattern.search(row_html)
            if not date_match:
                continue

            year = int(date_match.group("year"))
            month = int(date_match.group("month"))
            day = int(date_match.group("day"))
            start_date = date(year, month, day)
            end_month = int(date_match.group("end_month") or month)
            end_day = int(date_match.group("end_day") or day)
            end_date = date(year, end_month, end_day)

            location_match = self._city_state_pattern.search(row_html)
            city = self._clean_city_name(location_match.group(1).strip()) if location_match else None
            state = location_match.group(2).strip() if location_match else None

            venue = None
            venue_match = re.search(
                r"<td>\s*<span>(?P<venue>[^<]+)<br>",
                row_html,
                re.IGNORECASE,
            )
            if venue_match:
                venue = " ".join(unescape(venue_match.group("venue")).split()).strip()

            external_links: dict[str, str] = {}
            for link_match in self._track_link_pattern.finditer(row_html):
                link = link_match.group("link").strip()
                label = re.sub(r"<[^>]+>", " ", link_match.group("label"))
                label = " ".join(unescape(label).split()).lower()
                if not label:
                    continue
                external_links[label] = link

            registration_link = external_links.get("pre-register")
            website_link = external_links.get("website")
            flyer_link = external_links.get("event flyer")
            event_page_link = website_link or registration_link or flyer_link

            event_id = header_match.group("event_id")
            key = f"{start_date.isoformat()}::{title.lower()}"
            if key in seen:
                continue
            seen.add(key)

            items.append(
                TournamentScanIngestItem(
                    external_id=key,
                    source_id_hint=event_id,
                    source_label="TrackWrestling",
                    name=title,
                    start_date=start_date,
                    end_date=end_date,
                    city=city,
                    state=state,
                    age_divisions=[],
                    weight_classes=None,
                    event_type="individual_tournament",
                    registration_link=registration_link,
                    event_page_link=event_page_link,
                    description="Discovered from the public TrackWrestling event search page.",
                    ingestion_notes="Public source scan from TrackWrestling event listings.",
                    normalized_payload={
                        "discovered_from": "track_public_event_search",
                        "venue_hint": venue,
                        "event_id": event_id,
                        "event_type_hint": header_match.group("event_type"),
                        "website_link": website_link,
                        "flyer_link": flyer_link,
                    },
                )
            )

        return items


class UsaBracketingSourceScanner(BaseTournamentSourceScanner):
    source_key = TournamentSourceType.usa

    _row_pattern = re.compile(
        r"<tr>\s*<td>(?P<title>.*?)</td>\s*<td[^>]*>(?P<date>\d{2}/\d{2}/\d{4})</td>\s*<td>(?P<actions>.*?)</td>\s*</tr>",
        re.IGNORECASE | re.DOTALL,
    )
    _ignored_lines = {"results", "events", "search", "usa wrestling", "usa bracketing"}

    def fetch(self, *, search: str | None = None) -> TournamentSourceScanResult:
        if not settings.usa_bracketing_events_url:
            raise TournamentSourceScannerError("USA Bracketing scanner URL is not configured")

        html = self._fetch_html(settings.usa_bracketing_events_url)
        items: list[TournamentScanIngestItem] = []
        seen: set[str] = set()

        for match in self._row_pattern.finditer(html):
            title = re.sub(r"<[^>]+>", " ", match.group("title"))
            title = " ".join(unescape(title).split()).strip(" -")
            if not title or len(title) < 4:
                continue
            if title.lower() in self._ignored_lines:
                continue
            if search and search.strip().lower() not in title.lower():
                continue

            month_text, day_text, year_text = match.group("date").split("/")
            start_date = date(int(year_text), int(month_text), int(day_text))
            key = f"{start_date.isoformat()}::{title.lower()}"
            if key in seen:
                continue
            seen.add(key)

            results_match = re.search(r'href="(?P<link>/usaw_results/\d+/results)"', match.group("actions"), re.IGNORECASE)
            placements_match = re.search(
                r'href="(?P<link>/usaw_results/\d+/placements)"', match.group("actions"), re.IGNORECASE
            )
            event_page_link = (
                f"https://www.usawmembership.com{results_match.group('link')}"
                if results_match
                else settings.usa_bracketing_events_url
            )

            items.append(
                TournamentScanIngestItem(
                    external_id=key,
                    source_id_hint=key,
                    source_label="USA Bracketing",
                    name=title,
                    start_date=start_date,
                    end_date=start_date,
                    age_divisions=[],
                    weight_classes=None,
                    event_type="individual_tournament",
                    event_page_link=event_page_link,
                    description="Discovered from the public USA Wrestling / USA Bracketing results surface.",
                    ingestion_notes="Public source scan from USA Wrestling event/results listings.",
                    normalized_payload={
                        "discovered_from": "usa_public_results_page",
                        "placements_link": (
                            f"https://www.usawmembership.com{placements_match.group('link')}"
                            if placements_match
                            else None
                        ),
                    },
                )
            )

        return TournamentSourceScanResult(
            source_key=self.source_key,
            items=items,
            note="USA Bracketing public event scan completed.",
            query_snapshot={"search": search, "source_url": settings.usa_bracketing_events_url},
        )


class ConfigBackedPlaceholderScanner(BaseTournamentSourceScanner):
    def __init__(self, *, source_key: TournamentSourceType, url: str | None, label: str):
        self.source_key = source_key
        self._url = url
        self._label = label

    def fetch(self, *, search: str | None = None) -> TournamentSourceScanResult:
        note = (
            f"{self._label} live scanner is not configured yet."
            if not self._url
            else f"{self._label} scanner endpoint is configured but parser implementation still needs to be finalized."
        )
        return TournamentSourceScanResult(
            source_key=self.source_key,
            items=[],
            note=note,
            query_snapshot={"search": search, "source_url": self._url},
        )


def scanner_for_source(source_key: TournamentSourceType) -> BaseTournamentSourceScanner:
    if source_key == TournamentSourceType.flo:
        return FloWrestlingSourceScanner()
    if source_key == TournamentSourceType.track:
        return TrackWrestlingSourceScanner()
    if source_key == TournamentSourceType.usa:
        return UsaBracketingSourceScanner()
    raise TournamentSourceScannerError(f"No scanner registered for {source_key.value}")
