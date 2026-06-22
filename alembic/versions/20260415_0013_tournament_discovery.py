"""tournament discovery aggregation

Revision ID: 20260415_0013
Revises: 20260415_0012
Create Date: 2026-04-15 00:12:00.000000
"""

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql


revision = "20260415_0013"
down_revision = "20260415_0012"
branch_labels = None
depends_on = None


def upgrade() -> None:
    tournament_source_type = postgresql.ENUM("manual", "track", "flo", "usa", name="tournamentsourcetype", create_type=False)
    tournament_ingestion_mode = postgresql.ENUM(
        "manual_entry",
        "scraping_placeholder",
        "api_placeholder",
        "hybrid_placeholder",
        name="tournamentingestionmode", create_type=False
    )
    tournament_external_status = postgresql.ENUM(
        "draft",
        "normalized",
        "needs_review",
        "archived",
        name="tournamentexternalstatus", create_type=False
    )
    bind = op.get_bind()
    for enum in (tournament_source_type, tournament_ingestion_mode, tournament_external_status):
        enum.create(bind, checkfirst=True)

    op.create_table(
        "tournament_sources",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("source_key", tournament_source_type, nullable=False, unique=True),
        sa.Column("display_name", sa.String(length=60), nullable=False),
        sa.Column("ingestion_mode", tournament_ingestion_mode, nullable=False, server_default="manual_entry"),
        sa.Column("base_url", sa.String(length=255), nullable=True),
        sa.Column("supports_scraping", sa.Boolean(), nullable=False, server_default=sa.false()),
        sa.Column("supports_api", sa.Boolean(), nullable=False, server_default=sa.false()),
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default=sa.true()),
        sa.Column("notes", sa.Text(), nullable=True),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.Column("updated_at", sa.DateTime(), nullable=False),
    )

    op.create_table(
        "tournaments_external",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("source_id", sa.Integer(), sa.ForeignKey("tournament_sources.id"), nullable=False),
        sa.Column("created_by_user_id", sa.Integer(), sa.ForeignKey("users.id"), nullable=True),
        sa.Column("external_id", sa.String(length=120), nullable=True),
        sa.Column("name", sa.String(length=180), nullable=False),
        sa.Column("start_date", sa.Date(), nullable=False),
        sa.Column("end_date", sa.Date(), nullable=False),
        sa.Column("location_name", sa.String(length=180), nullable=True),
        sa.Column("city", sa.String(length=120), nullable=True),
        sa.Column("state", sa.String(length=40), nullable=True),
        sa.Column("latitude", sa.Float(), nullable=True),
        sa.Column("longitude", sa.Float(), nullable=True),
        sa.Column("age_divisions", sa.JSON(), nullable=False),
        sa.Column("weight_classes", sa.JSON(), nullable=True),
        sa.Column("event_type", sa.String(length=60), nullable=False),
        sa.Column("registration_link", sa.Text(), nullable=True),
        sa.Column("event_page_link", sa.Text(), nullable=True),
        sa.Column("source_label", sa.String(length=40), nullable=False),
        sa.Column("contact_name", sa.String(length=120), nullable=True),
        sa.Column("contact_email", sa.String(length=160), nullable=True),
        sa.Column("contact_phone", sa.String(length=40), nullable=True),
        sa.Column("description", sa.Text(), nullable=True),
        sa.Column("deadline", sa.Date(), nullable=True),
        sa.Column("cost", sa.String(length=80), nullable=True),
        sa.Column("raw_payload", sa.JSON(), nullable=True),
        sa.Column("normalized_payload", sa.JSON(), nullable=True),
        sa.Column("ingestion_status", tournament_external_status, nullable=False, server_default="normalized"),
        sa.Column("ingestion_notes", sa.Text(), nullable=True),
        sa.Column("last_seen_at", sa.DateTime(), nullable=True),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.Column("updated_at", sa.DateTime(), nullable=False),
        sa.UniqueConstraint("source_id", "external_id", name="uq_external_source_external_id"),
    )
    op.create_index("ix_tournaments_external_source_id", "tournaments_external", ["source_id"])
    op.create_index("ix_tournaments_external_created_by_user_id", "tournaments_external", ["created_by_user_id"])
    op.create_index("ix_tournaments_external_external_id", "tournaments_external", ["external_id"])
    op.create_index("ix_tournaments_external_name", "tournaments_external", ["name"])
    op.create_index("ix_tournaments_external_start_date", "tournaments_external", ["start_date"])
    op.create_index("ix_tournaments_external_end_date", "tournaments_external", ["end_date"])
    op.create_index("ix_tournaments_external_city", "tournaments_external", ["city"])
    op.create_index("ix_tournaments_external_state", "tournaments_external", ["state"])
    op.create_index("ix_tournaments_external_event_type", "tournaments_external", ["event_type"])
    op.create_index("ix_tournaments_external_deadline", "tournaments_external", ["deadline"])
    op.create_index("ix_tournaments_external_ingestion_status", "tournaments_external", ["ingestion_status"])
    op.create_index("ix_tournaments_external_last_seen_at", "tournaments_external", ["last_seen_at"])

    op.create_table(
        "saved_tournaments",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("team_id", sa.Integer(), sa.ForeignKey("teams.id"), nullable=False),
        sa.Column("tournament_external_id", sa.Integer(), sa.ForeignKey("tournaments_external.id"), nullable=False),
        sa.Column("saved_by_user_id", sa.Integer(), sa.ForeignKey("users.id"), nullable=False),
        sa.Column("notes", sa.Text(), nullable=True),
        sa.Column("added_to_schedule_at", sa.DateTime(), nullable=True),
        sa.Column("shared_to_team_at", sa.DateTime(), nullable=True),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.Column("updated_at", sa.DateTime(), nullable=False),
        sa.UniqueConstraint("team_id", "tournament_external_id", name="uq_saved_tournament_team"),
    )
    op.create_index("ix_saved_tournaments_team_id", "saved_tournaments", ["team_id"])
    op.create_index("ix_saved_tournaments_tournament_external_id", "saved_tournaments", ["tournament_external_id"])
    op.create_index("ix_saved_tournaments_saved_by_user_id", "saved_tournaments", ["saved_by_user_id"])

    op.create_table(
        "tournament_filters",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("team_id", sa.Integer(), sa.ForeignKey("teams.id"), nullable=True),
        sa.Column("user_id", sa.Integer(), sa.ForeignKey("users.id"), nullable=True),
        sa.Column("filter_name", sa.String(length=80), nullable=False),
        sa.Column("start_date", sa.Date(), nullable=True),
        sa.Column("end_date", sa.Date(), nullable=True),
        sa.Column("radius_miles", sa.Integer(), nullable=True),
        sa.Column("origin_city", sa.String(length=120), nullable=True),
        sa.Column("origin_state", sa.String(length=40), nullable=True),
        sa.Column("origin_latitude", sa.Float(), nullable=True),
        sa.Column("origin_longitude", sa.Float(), nullable=True),
        sa.Column("age_group", sa.String(length=60), nullable=True),
        sa.Column("weight_class", sa.String(length=30), nullable=True),
        sa.Column("event_type", sa.String(length=60), nullable=True),
        sa.Column("is_default", sa.Boolean(), nullable=False, server_default=sa.false()),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.Column("updated_at", sa.DateTime(), nullable=False),
    )
    op.create_index("ix_tournament_filters_team_id", "tournament_filters", ["team_id"])
    op.create_index("ix_tournament_filters_user_id", "tournament_filters", ["user_id"])

    with op.batch_alter_table("events") as batch_op:
        batch_op.add_column(sa.Column("external_tournament_id", sa.Integer(), nullable=True))
        batch_op.create_foreign_key(
            "fk_events_external_tournament_id",
            "tournaments_external",
            ["external_tournament_id"],
            ["id"],
        )
    op.create_index("ix_events_external_tournament_id", "events", ["external_tournament_id"])


def downgrade() -> None:
    op.drop_index("ix_events_external_tournament_id", table_name="events")
    with op.batch_alter_table("events") as batch_op:
        batch_op.drop_constraint("fk_events_external_tournament_id", type_="foreignkey")
        batch_op.drop_column("external_tournament_id")

    op.drop_index("ix_tournament_filters_user_id", table_name="tournament_filters")
    op.drop_index("ix_tournament_filters_team_id", table_name="tournament_filters")
    op.drop_table("tournament_filters")

    op.drop_index("ix_saved_tournaments_saved_by_user_id", table_name="saved_tournaments")
    op.drop_index("ix_saved_tournaments_tournament_external_id", table_name="saved_tournaments")
    op.drop_index("ix_saved_tournaments_team_id", table_name="saved_tournaments")
    op.drop_table("saved_tournaments")

    op.drop_index("ix_tournaments_external_last_seen_at", table_name="tournaments_external")
    op.drop_index("ix_tournaments_external_ingestion_status", table_name="tournaments_external")
    op.drop_index("ix_tournaments_external_deadline", table_name="tournaments_external")
    op.drop_index("ix_tournaments_external_event_type", table_name="tournaments_external")
    op.drop_index("ix_tournaments_external_state", table_name="tournaments_external")
    op.drop_index("ix_tournaments_external_city", table_name="tournaments_external")
    op.drop_index("ix_tournaments_external_end_date", table_name="tournaments_external")
    op.drop_index("ix_tournaments_external_start_date", table_name="tournaments_external")
    op.drop_index("ix_tournaments_external_name", table_name="tournaments_external")
    op.drop_index("ix_tournaments_external_external_id", table_name="tournaments_external")
    op.drop_index("ix_tournaments_external_created_by_user_id", table_name="tournaments_external")
    op.drop_index("ix_tournaments_external_source_id", table_name="tournaments_external")
    op.drop_table("tournaments_external")

    op.drop_table("tournament_sources")

    bind = op.get_bind()
    postgresql.ENUM(name="tournamentexternalstatus", create_type=False).drop(bind, checkfirst=True)
    postgresql.ENUM(name="tournamentingestionmode", create_type=False).drop(bind, checkfirst=True)
    postgresql.ENUM(name="tournamentsourcetype", create_type=False).drop(bind, checkfirst=True)
