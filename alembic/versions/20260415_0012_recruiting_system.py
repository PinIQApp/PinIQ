"""recruiting system

Revision ID: 20260415_0012
Revises: 20260415_0011
Create Date: 2026-04-15 00:12:00.000000
"""

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql


revision = "20260415_0012"
down_revision = "20260415_0011"
branch_labels = None
depends_on = None


def upgrade() -> None:
    visibility_level = postgresql.ENUM("public", "coaches_only", "private", name="recruitingvisibilitylevel", create_type=False)
    contact_visibility = postgresql.ENUM("hidden", "coaches_only", "full", name="recruitingcontactvisibility", create_type=False)

    bind = op.get_bind()
    visibility_level.create(bind, checkfirst=True)
    contact_visibility.create(bind, checkfirst=True)

    op.create_table(
        "recruiting_profiles",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("athlete_id", sa.Integer(), sa.ForeignKey("users.id"), nullable=False),
        sa.Column("team_id", sa.Integer(), sa.ForeignKey("teams.id"), nullable=True),
        sa.Column("graduation_year", sa.Integer(), nullable=False),
        sa.Column("school_team", sa.String(length=160), nullable=True),
        sa.Column("weight_class", sa.String(length=30), nullable=False),
        sa.Column("height", sa.String(length=20), nullable=True),
        sa.Column("gpa", sa.String(length=10), nullable=True),
        sa.Column("bio", sa.Text(), nullable=True),
        sa.Column("achievements", sa.JSON(), nullable=True),
        sa.Column("contact_email", sa.String(length=255), nullable=True),
        sa.Column("contact_phone", sa.String(length=30), nullable=True),
        sa.Column("location_label", sa.String(length=140), nullable=True),
        sa.Column("stats_summary", sa.JSON(), nullable=True),
        sa.Column("match_record_override", sa.String(length=40), nullable=True),
        sa.Column("profile_image_url", sa.String(length=500), nullable=True),
        sa.Column("is_open", sa.Boolean(), nullable=False, server_default=sa.true()),
        sa.Column("is_actively_looking", sa.Boolean(), nullable=False, server_default=sa.false()),
        sa.Column("is_featured", sa.Boolean(), nullable=False, server_default=sa.false()),
        sa.Column("boost_requested", sa.Boolean(), nullable=False, server_default=sa.false()),
        sa.Column("visibility_level", visibility_level, nullable=False),
        sa.Column("contact_visibility", contact_visibility, nullable=False),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.Column("updated_at", sa.DateTime(), nullable=False),
        sa.UniqueConstraint("athlete_id", name="uq_recruiting_profile_athlete"),
    )
    op.create_index("ix_recruiting_profiles_athlete_id", "recruiting_profiles", ["athlete_id"])
    op.create_index("ix_recruiting_profiles_team_id", "recruiting_profiles", ["team_id"])
    op.create_index("ix_recruiting_profiles_graduation_year", "recruiting_profiles", ["graduation_year"])
    op.create_index("ix_recruiting_profiles_weight_class", "recruiting_profiles", ["weight_class"])
    op.create_index("ix_recruiting_profiles_location_label", "recruiting_profiles", ["location_label"])
    op.create_index("ix_recruiting_profiles_is_open", "recruiting_profiles", ["is_open"])
    op.create_index("ix_recruiting_profiles_is_actively_looking", "recruiting_profiles", ["is_actively_looking"])
    op.create_index("ix_recruiting_profiles_is_featured", "recruiting_profiles", ["is_featured"])

    op.create_table(
        "recruiting_visibility",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("profile_id", sa.Integer(), sa.ForeignKey("recruiting_profiles.id"), nullable=False),
        sa.Column("show_contact_to_coaches", sa.Boolean(), nullable=False, server_default=sa.false()),
        sa.Column("show_gpa", sa.Boolean(), nullable=False, server_default=sa.false()),
        sa.Column("show_location", sa.Boolean(), nullable=False, server_default=sa.true()),
        sa.Column("show_profile_photo", sa.Boolean(), nullable=False, server_default=sa.true()),
        sa.Column("parent_visibility_required", sa.Boolean(), nullable=False, server_default=sa.true()),
        sa.Column("allow_direct_contact_request", sa.Boolean(), nullable=False, server_default=sa.true()),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.Column("updated_at", sa.DateTime(), nullable=False),
        sa.UniqueConstraint("profile_id", name="uq_recruiting_visibility_profile"),
    )
    op.create_index("ix_recruiting_visibility_profile_id", "recruiting_visibility", ["profile_id"])

    op.create_table(
        "recruiting_watchlists",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("coach_user_id", sa.Integer(), sa.ForeignKey("users.id"), nullable=False),
        sa.Column("athlete_id", sa.Integer(), sa.ForeignKey("users.id"), nullable=False),
        sa.Column("team_id", sa.Integer(), sa.ForeignKey("teams.id"), nullable=True),
        sa.Column("profile_id", sa.Integer(), sa.ForeignKey("recruiting_profiles.id"), nullable=True),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.Column("updated_at", sa.DateTime(), nullable=False),
        sa.UniqueConstraint("coach_user_id", "athlete_id", name="uq_recruiting_watchlist_coach_athlete"),
    )
    op.create_index("ix_recruiting_watchlists_coach_user_id", "recruiting_watchlists", ["coach_user_id"])
    op.create_index("ix_recruiting_watchlists_athlete_id", "recruiting_watchlists", ["athlete_id"])
    op.create_index("ix_recruiting_watchlists_team_id", "recruiting_watchlists", ["team_id"])
    op.create_index("ix_recruiting_watchlists_profile_id", "recruiting_watchlists", ["profile_id"])

    op.create_table(
        "recruiting_notes",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("coach_user_id", sa.Integer(), sa.ForeignKey("users.id"), nullable=False),
        sa.Column("athlete_id", sa.Integer(), sa.ForeignKey("users.id"), nullable=False),
        sa.Column("team_id", sa.Integer(), sa.ForeignKey("teams.id"), nullable=True),
        sa.Column("profile_id", sa.Integer(), sa.ForeignKey("recruiting_profiles.id"), nullable=True),
        sa.Column("note", sa.Text(), nullable=False),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.Column("updated_at", sa.DateTime(), nullable=False),
        sa.UniqueConstraint("coach_user_id", "athlete_id", name="uq_recruiting_note_coach_athlete"),
    )
    op.create_index("ix_recruiting_notes_coach_user_id", "recruiting_notes", ["coach_user_id"])
    op.create_index("ix_recruiting_notes_athlete_id", "recruiting_notes", ["athlete_id"])
    op.create_index("ix_recruiting_notes_team_id", "recruiting_notes", ["team_id"])
    op.create_index("ix_recruiting_notes_profile_id", "recruiting_notes", ["profile_id"])

    op.create_table(
        "recruiting_tags",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("coach_user_id", sa.Integer(), sa.ForeignKey("users.id"), nullable=False),
        sa.Column("athlete_id", sa.Integer(), sa.ForeignKey("users.id"), nullable=False),
        sa.Column("team_id", sa.Integer(), sa.ForeignKey("teams.id"), nullable=True),
        sa.Column("profile_id", sa.Integer(), sa.ForeignKey("recruiting_profiles.id"), nullable=True),
        sa.Column("tag", sa.String(length=50), nullable=False),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.UniqueConstraint("coach_user_id", "athlete_id", "tag", name="uq_recruiting_tag_coach_athlete"),
    )
    op.create_index("ix_recruiting_tags_coach_user_id", "recruiting_tags", ["coach_user_id"])
    op.create_index("ix_recruiting_tags_athlete_id", "recruiting_tags", ["athlete_id"])
    op.create_index("ix_recruiting_tags_team_id", "recruiting_tags", ["team_id"])
    op.create_index("ix_recruiting_tags_profile_id", "recruiting_tags", ["profile_id"])

    op.create_table(
        "recruiting_highlights",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("athlete_id", sa.Integer(), sa.ForeignKey("users.id"), nullable=False),
        sa.Column("profile_id", sa.Integer(), sa.ForeignKey("recruiting_profiles.id"), nullable=False),
        sa.Column("title", sa.String(length=120), nullable=False),
        sa.Column("highlight_url", sa.String(length=500), nullable=False),
        sa.Column("sort_order", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.Column("updated_at", sa.DateTime(), nullable=False),
    )
    op.create_index("ix_recruiting_highlights_athlete_id", "recruiting_highlights", ["athlete_id"])
    op.create_index("ix_recruiting_highlights_profile_id", "recruiting_highlights", ["profile_id"])


def downgrade() -> None:
    op.drop_index("ix_recruiting_highlights_profile_id", table_name="recruiting_highlights")
    op.drop_index("ix_recruiting_highlights_athlete_id", table_name="recruiting_highlights")
    op.drop_table("recruiting_highlights")

    op.drop_index("ix_recruiting_tags_profile_id", table_name="recruiting_tags")
    op.drop_index("ix_recruiting_tags_team_id", table_name="recruiting_tags")
    op.drop_index("ix_recruiting_tags_athlete_id", table_name="recruiting_tags")
    op.drop_index("ix_recruiting_tags_coach_user_id", table_name="recruiting_tags")
    op.drop_table("recruiting_tags")

    op.drop_index("ix_recruiting_notes_profile_id", table_name="recruiting_notes")
    op.drop_index("ix_recruiting_notes_team_id", table_name="recruiting_notes")
    op.drop_index("ix_recruiting_notes_athlete_id", table_name="recruiting_notes")
    op.drop_index("ix_recruiting_notes_coach_user_id", table_name="recruiting_notes")
    op.drop_table("recruiting_notes")

    op.drop_index("ix_recruiting_watchlists_profile_id", table_name="recruiting_watchlists")
    op.drop_index("ix_recruiting_watchlists_team_id", table_name="recruiting_watchlists")
    op.drop_index("ix_recruiting_watchlists_athlete_id", table_name="recruiting_watchlists")
    op.drop_index("ix_recruiting_watchlists_coach_user_id", table_name="recruiting_watchlists")
    op.drop_table("recruiting_watchlists")

    op.drop_index("ix_recruiting_visibility_profile_id", table_name="recruiting_visibility")
    op.drop_table("recruiting_visibility")

    op.drop_index("ix_recruiting_profiles_is_featured", table_name="recruiting_profiles")
    op.drop_index("ix_recruiting_profiles_is_actively_looking", table_name="recruiting_profiles")
    op.drop_index("ix_recruiting_profiles_is_open", table_name="recruiting_profiles")
    op.drop_index("ix_recruiting_profiles_location_label", table_name="recruiting_profiles")
    op.drop_index("ix_recruiting_profiles_weight_class", table_name="recruiting_profiles")
    op.drop_index("ix_recruiting_profiles_graduation_year", table_name="recruiting_profiles")
    op.drop_index("ix_recruiting_profiles_team_id", table_name="recruiting_profiles")
    op.drop_index("ix_recruiting_profiles_athlete_id", table_name="recruiting_profiles")
    op.drop_table("recruiting_profiles")

    bind = op.get_bind()
    postgresql.ENUM(name="recruitingcontactvisibility", create_type=False).drop(bind, checkfirst=True)
    postgresql.ENUM(name="recruitingvisibilitylevel", create_type=False).drop(bind, checkfirst=True)
