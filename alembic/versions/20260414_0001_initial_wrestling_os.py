"""initial wrestling os schema

Revision ID: 20260414_0001
Revises:
Create Date: 2026-04-14 00:00:00
"""

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql


revision = "20260414_0001"
down_revision = None
branch_labels = None
depends_on = None


user_role_enum = postgresql.ENUM(
    "coach",
    "assistant_coach",
    "athlete",
    "parent",
    "admin",
    name="userrole", create_type=False
)


def upgrade() -> None:
    user_role_enum.create(op.get_bind(), checkfirst=True)

    op.create_table(
        "users",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("email", sa.String(length=255), nullable=False),
        sa.Column("password_hash", sa.String(length=255), nullable=False),
        sa.Column("full_name", sa.String(length=120), nullable=False),
        sa.Column("role", user_role_enum, nullable=False),
        sa.Column("phone", sa.String(length=30), nullable=True),
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default=sa.true()),
        sa.Column("primary_team_id", sa.Integer(), nullable=True),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.Column("updated_at", sa.DateTime(), nullable=False),
    )
    op.create_index(op.f("ix_users_email"), "users", ["email"], unique=True)
    op.create_index(op.f("ix_users_id"), "users", ["id"], unique=False)

    op.create_table(
        "teams",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("name", sa.String(length=120), nullable=False),
        sa.Column("slug", sa.String(length=120), nullable=False),
        sa.Column("school_name", sa.String(length=140), nullable=False),
        sa.Column("school_abbreviation", sa.String(length=12), nullable=True),
        sa.Column("mascot_name", sa.String(length=120), nullable=False),
        sa.Column("division", sa.String(length=50), nullable=True),
        sa.Column("season_label", sa.String(length=30), nullable=True),
        sa.Column("dark_mode", sa.Boolean(), nullable=False, server_default=sa.true()),
        sa.Column("primary_color", sa.String(length=7), nullable=False),
        sa.Column("secondary_color", sa.String(length=7), nullable=False),
        sa.Column("accent_color", sa.String(length=7), nullable=False),
        sa.Column("surface_color", sa.String(length=7), nullable=False),
        sa.Column("logo_url", sa.Text(), nullable=True),
        sa.Column("tagline", sa.String(length=180), nullable=True),
        sa.Column("created_by_user_id", sa.Integer(), nullable=False),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.Column("updated_at", sa.DateTime(), nullable=False),
        sa.ForeignKeyConstraint(["created_by_user_id"], ["users.id"]),
    )
    op.create_index(op.f("ix_teams_id"), "teams", ["id"], unique=False)
    op.create_index(op.f("ix_teams_slug"), "teams", ["slug"], unique=True)

    with op.batch_alter_table("users") as batch_op:
        batch_op.create_foreign_key(
            "fk_users_primary_team_id_teams",
            "teams",
            ["primary_team_id"],
            ["id"],
        )

    op.create_table(
        "team_members",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("team_id", sa.Integer(), nullable=False),
        sa.Column("user_id", sa.Integer(), nullable=False),
        sa.Column("role_label", sa.String(length=60), nullable=False),
        sa.Column("is_staff", sa.Boolean(), nullable=False, server_default=sa.false()),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.ForeignKeyConstraint(["team_id"], ["teams.id"]),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"]),
        sa.UniqueConstraint("team_id", "user_id", name="uq_team_user"),
    )


def downgrade() -> None:
    op.drop_table("team_members")
    with op.batch_alter_table("users") as batch_op:
        batch_op.drop_constraint("fk_users_primary_team_id_teams", type_="foreignkey")
    op.drop_index(op.f("ix_teams_slug"), table_name="teams")
    op.drop_index(op.f("ix_teams_id"), table_name="teams")
    op.drop_table("teams")
    op.drop_index(op.f("ix_users_id"), table_name="users")
    op.drop_index(op.f("ix_users_email"), table_name="users")
    op.drop_table("users")
    user_role_enum.drop(op.get_bind(), checkfirst=True)
