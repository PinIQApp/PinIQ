from __future__ import annotations

import argparse

from app.db.session import SessionLocal
from app.services.recruiting_service import run_saved_recruiting_source_scans


def main() -> None:
    parser = argparse.ArgumentParser(description="Scan saved public recruiting ranking source links.")
    parser.add_argument("--limit", type=int, default=100, help="Maximum number of recruiting profiles to check.")
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


if __name__ == "__main__":
    main()
