"""add phone-based athlete invitations

Revision ID: 20260815_0023
Revises: 20260810_0022
Create Date: 2026-08-15 12:00:00
"""

from alembic import op
import sqlalchemy as sa


revision = "20260815_0023"
down_revision = "20260810_0022"
branch_labels = None
depends_on = None


def upgrade() -> None:
    with op.batch_alter_table("athlete_parent_invitations") as batch_op:
        batch_op.add_column(sa.Column("parent_phone", sa.String(length=30), nullable=True))
        batch_op.create_index(
            op.f("ix_athlete_parent_invitations_parent_phone"),
            ["parent_phone"],
            unique=False,
        )
        batch_op.create_unique_constraint(
            "uq_athlete_parent_phone_invitation",
            ["team_id", "athlete_user_id", "parent_phone"],
        )


def downgrade() -> None:
    with op.batch_alter_table("athlete_parent_invitations") as batch_op:
        batch_op.drop_constraint(
            "uq_athlete_parent_phone_invitation",
            type_="unique",
        )
        batch_op.drop_index(op.f("ix_athlete_parent_invitations_parent_phone"))
        batch_op.drop_column("parent_phone")
