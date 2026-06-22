"""add tournament bracket preferences

Revision ID: 20260421_0018
Revises: 20260421_0017
Create Date: 2026-04-21 13:40:00
"""

from __future__ import annotations

from alembic import op
import sqlalchemy as sa


revision = "20260421_0018"
down_revision = "20260421_0017"
branch_labels = None
depends_on = None


def upgrade() -> None:
    with op.batch_alter_table("tournaments") as batch_op:
        batch_op.add_column(sa.Column("elimination_style", sa.String(length=40), nullable=True))
        batch_op.add_column(sa.Column("bracket_size", sa.Integer(), nullable=True))
        batch_op.create_index("ix_tournaments_elimination_style", ["elimination_style"], unique=False)


def downgrade() -> None:
    with op.batch_alter_table("tournaments") as batch_op:
        batch_op.drop_index("ix_tournaments_elimination_style")
        batch_op.drop_column("bracket_size")
        batch_op.drop_column("elimination_style")
