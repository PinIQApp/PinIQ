from app.core.config import settings
from app.services.tournament_source_scanners import (
    FloWrestlingSourceScanner,
    TrackWrestlingSourceScanner,
    UsaBracketingSourceScanner,
)


def test_trackwrestling_source_scanner_extracts_public_event_row(monkeypatch):
    html = """
    <ul>
      <li class='evenRow'>
        <div onclick="eventSelected(12345,'Kentucky Girls Folkstyle Classic',1, '', 99)"></div>
        <td><span>Central High<br>Lexington, KY 40502</span></td>
        12/05-12/06/2026
        <a href="https://www.trackwrestling.com/pre-register">Pre-Register</a>
        <a href="https://example.com/flyer.pdf">Event Flyer</a>
      </li>
    </ul>
    """
    monkeypatch.setattr(settings, "track_events_url", "https://www.trackwrestling.com/events")
    scanner = TrackWrestlingSourceScanner()
    monkeypatch.setattr(scanner, "_fetch_html", lambda url: html)

    result = scanner.fetch(search="Girls")

    assert len(result.items) == 1
    item = result.items[0]
    assert item.name == "Kentucky Girls Folkstyle Classic"
    assert item.start_date.isoformat() == "2026-12-05"
    assert item.end_date.isoformat() == "2026-12-06"
    assert item.city == "Lexington"
    assert item.state == "KY"
    assert item.registration_link == "https://www.trackwrestling.com/pre-register"


def test_flowrestling_source_scanner_extracts_public_event_card(monkeypatch):
    html = """
    <a href="https://www.flowrestling.org/nextgen/events/987654">
      <span textcontent="Dec 12"></span>
      <h4 textcontent="Bluegrass National Duals"></h4>
      <span textcontent="Alltech Arena · Lexington, KY"></span>
    </a>
    """
    monkeypatch.setattr(settings, "flo_events_url", "https://www.flowrestling.org/events")
    scanner = FloWrestlingSourceScanner()
    monkeypatch.setattr(scanner, "_fetch_html", lambda url: html)

    result = scanner.fetch(search="Bluegrass")

    assert len(result.items) == 1
    item = result.items[0]
    assert item.name == "Bluegrass National Duals"
    assert item.city == "Lexington"
    assert item.state == "KY"
    assert item.event_page_link == "https://www.flowrestling.org/nextgen/events/987654"


def test_usa_bracketing_source_scanner_extracts_public_results_row(monkeypatch):
    html = """
    <table>
      <tr>
        <td>Kentucky Freestyle State Qualifier</td>
        <td>07/18/2026</td>
        <td>
          <a href="/usaw_results/555/results">Results</a>
          <a href="/usaw_results/555/placements">Placements</a>
        </td>
      </tr>
    </table>
    """
    monkeypatch.setattr(
        settings,
        "usa_bracketing_events_url",
        "https://www.usawmembership.com/usaw_events",
    )
    scanner = UsaBracketingSourceScanner()
    monkeypatch.setattr(scanner, "_fetch_html", lambda url: html)

    result = scanner.fetch(search="Freestyle")

    assert len(result.items) == 1
    item = result.items[0]
    assert item.name == "Kentucky Freestyle State Qualifier"
    assert item.start_date.isoformat() == "2026-07-18"
    assert item.source_label == "USA Bracketing"
    assert item.event_page_link == "https://www.usawmembership.com/usaw_results/555/results"
    assert (
        item.normalized_payload["placements_link"]
        == "https://www.usawmembership.com/usaw_results/555/placements"
    )
