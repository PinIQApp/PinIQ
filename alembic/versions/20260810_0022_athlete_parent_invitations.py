"""add athlete parent invitations

Revision ID: 20260810_0022
Revises: 20260506_0021
Create Date: 2026-08-10 16:10:00
"""

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql


revision = "20260810_0022"
down_revision = "20260506_0021"
branch_labels = None
depends_on = None


athlete_invitation_status = postgresql.ENUM(
    "pending",
    "accepted",
    "declined",
    "revoked",
    name="athleteinvitationstatus",
    create_type=False,
)


def upgrade() -> None:
    bind = op.get_bind()
    athlete_invitation_status.create(bind, checkfirst=True)

    op.create_table(
        "athlete_parent_invitations",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("team_id", sa.Integer(), nullable=False),
        sa.Column("athlete_user_id", sa.Integer(), nullable=False),
        sa.Column("parent_email", sa.String(length=255), nullable=False),
        sa.Column("relationship_label", sa.String(length=60), nullable=False, server_default="parent"),
        sa.Column("status", athlete_invitation_status, nullable=False, server_default="pending"),
        sa.Column("invited_by_user_id", sa.Integer(), nullable=False),
        sa.Column("accepted_by_user_id", sa.Integer(), nullable=True),
        sa.Column("expires_at", sa.DateTime(), nullable=False),
        sa.Column("accepted_at", sa.DateTime(), nullable=True),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.Column("updated_at", sa.DateTime(), nullable=False),
        sa.ForeignKeyConstraint(["team_id"], ["teams.id"]),
        sa.ForeignKeyConstraint(["athlete_user_id"], ["users.id"]),
        sa.ForeignKeyConstraint(["invited_by_user_id"], ["users.id"]),
        sa.ForeignKeyConstraint(["accepted_by_user_id"], ["users.id"]),
        sa.UniqueConstraint(
            "team_id",
            "athlete_user_id",
            "parent_email",
            name="uq_athlete_parent_invitation",
        ),
    )
    op.create_index(
        op.f("ix_athlete_parent_invitations_team_id"),
        "athlete_parent_invitations",
        ["team_id"],
        unique=False,
    )
    op.create_index(
        op.f("ix_athlete_parent_invitations_athlete_user_id"),
        "athlete_parent_invitations",
        ["athlete_user_id"],
        unique=False,
    )
    op.create_index(
        op.f("ix_athlete_parent_invitations_parent_email"),
        "athlete_parent_invitations",
        ["parent_email"],
        unique=False,
    )
    op.create_index(
        op.f("ix_athlete_parent_invitations_status"),
        "athlete_parent_invitations",
        ["status"],
        unique=False,
    )


def downgrade() -> None:
    op.drop_index(op.f("ix_athlete_parent_invitations_status"), table_name="athlete_parent_invitations")
    op.drop_index(op.f("ix_athlete_parent_invitations_parent_email"), table_name="athlete_parent_invitations")
    op.drop_index(op.f("ix_athlete_parent_invitations_athlete_user_id"), table_name="athlete_parent_invitations")
    op.drop_index(op.f("ix_athlete_parent_invitations_team_id"), table_name="athlete_parent_invitations")
    op.drop_table("athlete_parent_invitations")

    bind = op.get_bind()
    athlete_invitation_status.drop(bind, checkfirst=True)
