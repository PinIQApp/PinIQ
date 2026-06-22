"""add auth rate limit events

Revision ID: 20260503_0019
Revises: 20260421_0018
Create Date: 2026-05-03 23:35:00
"""

from __future__ import annotations

from alembic import op
import sqlalchemy as sa


revision = "20260503_0019"
down_revision = "20260421_0018"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "auth_rate_limit_events",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("key", sa.String(length=255), nullable=False),
        sa.Column("occurred_at", sa.DateTime(), nullable=False),
    )
    op.create_index("ix_auth_rate_limit_events_key", "auth_rate_limit_events", ["key"])
    op.create_index("ix_auth_rate_limit_events_occurred_at", "auth_rate_limit_events", ["occurred_at"])


def downgrade() -> None:
    op.drop_index("ix_auth_rate_limit_events_occurred_at", table_name="auth_rate_limit_events")
    op.drop_index("ix_auth_rate_limit_events_key", table_name="auth_rate_limit_events")
    op.drop_table("auth_rate_limit_events")
