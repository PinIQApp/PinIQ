"""practice planner and schedule

Revision ID: 20260415_0007
Revises: 20260414_0006
Create Date: 2026-04-15 00:07:00.000000
"""

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql


revision = "20260415_0007"
down_revision = "20260414_0006"
branch_labels = None
depends_on = None


def upgrade() -> None:
    event_type = postgresql.ENUM(
        "practice",
        "dual_meet",
        "tournament",
        "travel",
        "team_meeting",
        "fundraiser",
        name="eventtype", create_type=False
    )
    practice_block_type = postgresql.ENUM(
        "warm_up",
        "stance_and_motion",
        "drilling",
        "live_goes",
        "top_bottom",
        "neutral",
        "conditioning",
        "cool_down",
        "film_review",
        "recovery",
        name="practiceblocktype", create_type=False
    )

    bind = op.get_bind()
    event_type.create(bind, checkfirst=True)
    practice_block_type.create(bind, checkfirst=True)

    op.create_table(
        "practice_templates",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("team_id", sa.Integer(), sa.ForeignKey("teams.id"), nullable=False),
        sa.Column("created_by_user_id", sa.Integer(), sa.ForeignKey("users.id"), nullable=False),
        sa.Column("template_name", sa.String(length=120), nullable=False),
        sa.Column("description", sa.Text(), nullable=True),
        sa.Column("focus", sa.String(length=180), nullable=True),
        sa.Column("total_duration_minutes", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("is_system_template", sa.Boolean(), nullable=False, server_default=sa.false()),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.Column("updated_at", sa.DateTime(), nullable=False),
    )
    op.create_index("ix_practice_templates_team_id", "practice_templates", ["team_id"])

    op.create_table(
        "practice_plans",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("team_id", sa.Integer(), sa.ForeignKey("teams.id"), nullable=False),
        sa.Column("created_by_user_id", sa.Integer(), sa.ForeignKey("users.id"), nullable=False),
        sa.Column("template_id", sa.Integer(), sa.ForeignKey("practice_templates.id"), nullable=True),
        sa.Column("title", sa.String(length=160), nullable=False),
        sa.Column("description", sa.Text(), nullable=True),
        sa.Column("focus", sa.String(length=180), nullable=True),
        sa.Column("practice_date", sa.Date(), nullable=True),
        sa.Column("notes", sa.Text(), nullable=True),
        sa.Column("total_duration_minutes", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("template_name_snapshot", sa.String(length=120), nullable=True),
        sa.Column("is_template_based", sa.Boolean(), nullable=False, server_default=sa.false()),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.Column("updated_at", sa.DateTime(), nullable=False),
    )
    op.create_index("ix_practice_plans_team_id", "practice_plans", ["team_id"])
    op.create_index("ix_practice_plans_template_id", "practice_plans", ["template_id"])
    op.create_index("ix_practice_plans_practice_date", "practice_plans", ["practice_date"])

    op.create_table(
        "practice_template_blocks",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("practice_template_id", sa.Integer(), sa.ForeignKey("practice_templates.id"), nullable=False),
        sa.Column("block_order", sa.Integer(), nullable=False),
        sa.Column("block_type", practice_block_type, nullable=False),
        sa.Column("title", sa.String(length=160), nullable=True),
        sa.Column("notes", sa.Text(), nullable=True),
        sa.Column("duration_minutes", sa.Integer(), nullable=False),
    )
    op.create_index(
        "ix_practice_template_blocks_practice_template_id",
        "practice_template_blocks",
        ["practice_template_id"],
    )

    op.create_table(
        "practice_blocks",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("practice_plan_id", sa.Integer(), sa.ForeignKey("practice_plans.id"), nullable=False),
        sa.Column("block_order", sa.Integer(), nullable=False),
        sa.Column("block_type", practice_block_type, nullable=False),
        sa.Column("title", sa.String(length=160), nullable=True),
        sa.Column("notes", sa.Text(), nullable=True),
        sa.Column("duration_minutes", sa.Integer(), nullable=False),
    )
    op.create_index("ix_practice_blocks_practice_plan_id", "practice_blocks", ["practice_plan_id"])

    op.create_table(
        "events",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("team_id", sa.Integer(), sa.ForeignKey("teams.id"), nullable=False),
        sa.Column("created_by_user_id", sa.Integer(), sa.ForeignKey("users.id"), nullable=False),
        sa.Column("practice_plan_id", sa.Integer(), sa.ForeignKey("practice_plans.id"), nullable=True),
        sa.Column("title", sa.String(length=160), nullable=False),
        sa.Column("description", sa.Text(), nullable=True),
        sa.Column("event_type", event_type, nullable=False),
        sa.Column("starts_at", sa.DateTime(), nullable=False),
        sa.Column("ends_at", sa.DateTime(), nullable=False),
        sa.Column("location", sa.String(length=180), nullable=True),
        sa.Column("notes", sa.Text(), nullable=True),
        sa.Column("checklist", sa.JSON(), nullable=True),
        sa.Column("bus_departure_note", sa.String(length=255), nullable=True),
        sa.Column("weigh_in_note", sa.String(length=255), nullable=True),
        sa.Column("is_cancelled", sa.Boolean(), nullable=False, server_default=sa.false()),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.Column("updated_at", sa.DateTime(), nullable=False),
    )
    op.create_index("ix_events_team_id", "events", ["team_id"])
    op.create_index("ix_events_practice_plan_id", "events", ["practice_plan_id"])
    op.create_index("ix_events_event_type", "events", ["event_type"])
    op.create_index("ix_events_starts_at", "events", ["starts_at"])
    op.create_index("ix_events_ends_at", "events", ["ends_at"])


def downgrade() -> None:
    op.drop_index("ix_events_ends_at", table_name="events")
    op.drop_index("ix_events_starts_at", table_name="events")
    op.drop_index("ix_events_event_type", table_name="events")
    op.drop_index("ix_events_practice_plan_id", table_name="events")
    op.drop_index("ix_events_team_id", table_name="events")
    op.drop_table("events")

    op.drop_index("ix_practice_blocks_practice_plan_id", table_name="practice_blocks")
    op.drop_table("practice_blocks")

    op.drop_index("ix_practice_template_blocks_practice_template_id", table_name="practice_template_blocks")
    op.drop_table("practice_template_blocks")

    op.drop_index("ix_practice_plans_practice_date", table_name="practice_plans")
    op.drop_index("ix_practice_plans_template_id", table_name="practice_plans")
    op.drop_index("ix_practice_plans_team_id", table_name="practice_plans")
    op.drop_table("practice_plans")

    op.drop_index("ix_practice_templates_team_id", table_name="practice_templates")
    op.drop_table("practice_templates")

    bind = op.get_bind()
    postgresql.ENUM(name="practiceblocktype", create_type=False).drop(bind, checkfirst=True)
    postgresql.ENUM(name="eventtype", create_type=False).drop(bind, checkfirst=True)
