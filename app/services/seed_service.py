from __future__ import annotations

from sqlalchemy.orm import Session

from app.seed.demo_seed import seed_demo_data


def run_seed(db: Session) -> None:
    seed_demo_data(db)
