from __future__ import annotations

import argparse
from pathlib import Path
import sys

ROOT_DIR = Path(__file__).resolve().parents[1]
if str(ROOT_DIR) not in sys.path:
    sys.path.insert(0, str(ROOT_DIR))

from app.db.session import SessionLocal
from app.services.recruiting_service import run_saved_recruiting_source_scans


def main() -> None:
    parser = argparse.ArgumentParser(description="Scan saved public recruiting ranking source links.")
    parser.add_argument("--limit", type=int, default=100, help="Maximum number of recruiting profiles to check.")
    parser.add_argument(
        "--show-failures",
        action="store_true",
        help="Print individual scan failures after the summary.",
    )
    args = parser.parse_args()

    with SessionLocal() as db:
        result = run_saved_recruiting_source_scans(db, limit=args.limit)
        db.commit()

    print(
        "recruiting_source_scan "
        f"profiles_checked={result.profiles_checked} "
        f"profiles_updated={result.profiles_updated} "
        f"source_rankings_found={result.source_rankings_found} "
        f"school_rankings_found={result.school_rankings_found} "
        f"failures={len(result.failures)}"
    )
    if args.show_failures:
        for failure in result.failures:
            print(f"recruiting_source_scan_failure {failure}")


if __name__ == "__main__":
    main()
