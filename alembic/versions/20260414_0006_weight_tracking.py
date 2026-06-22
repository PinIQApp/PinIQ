"""weight tracking

Revision ID: 20260414_0006
Revises: 20260414_0005
Create Date: 2026-04-14 00:06:00.000000
"""

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql


revision = "20260414_0006"
down_revision = "20260414_0005"
branch_labels = None
depends_on = None


def upgrade() -> None:
    plan_status = postgresql.ENUM("green", "yellow", "red", name="weightplanstatus", create_type=False)
    alert_type = postgresql.ENUM(
        "missing_logs",
        "unsafe_cut_pace",
        "approaching_weigh_in",
        "off_target",
        name="weightalerttype", create_type=False
    )
    alert_status = postgresql.ENUM("active", "resolved", name="weightalertstatus", create_type=False)

    bind = op.get_bind()
    plan_status.create(bind, checkfirst=True)
    alert_type.create(bind, checkfirst=True)
    alert_status.create(bind, checkfirst=True)

    op.create_table(
        "weight_logs",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("athlete_id", sa.Integer(), sa.ForeignKey("users.id"), nullable=False),
        sa.Column("team_id", sa.Integer(), sa.ForeignKey("teams.id"), nullable=False),
        sa.Column("created_by_user_id", sa.Integer(), sa.ForeignKey("users.id"), nullable=False),
        sa.Column("logged_at", sa.DateTime(), nullable=False),
        sa.Column("weight", sa.Float(), nullable=False),
        sa.Column("body_fat_percentage", sa.Float(), nullable=True),
        sa.Column("hydration_note", sa.String(length=255), nullable=True),
        sa.Column("comments", sa.Text(), nullable=True),
        sa.Column("created_at", sa.DateTime(), nullable=False),
    )
    op.create_index("ix_weight_logs_athlete_id", "weight_logs", ["athlete_id"])
    op.create_index("ix_weight_logs_team_id", "weight_logs", ["team_id"])
    op.create_index("ix_weight_logs_logged_at", "weight_logs", ["logged_at"])

    op.create_table(
        "hydration_logs",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("athlete_id", sa.Integer(), sa.ForeignKey("users.id"), nullable=False),
        sa.Column("team_id", sa.Integer(), sa.ForeignKey("teams.id"), nullable=False),
        sa.Column("logged_at", sa.DateTime(), nullable=False),
        sa.Column("note", sa.String(length=255), nullable=False),
        sa.Column("status_label", sa.String(length=60), nullable=True),
        sa.Column("created_at", sa.DateTime(), nullable=False),
    )
    op.create_index("ix_hydration_logs_athlete_id", "hydration_logs", ["athlete_id"])
    op.create_index("ix_hydration_logs_team_id", "hydration_logs", ["team_id"])

    op.create_table(
        "athlete_targets",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("athlete_id", sa.Integer(), sa.ForeignKey("users.id"), nullable=False),
        sa.Column("team_id", sa.Integer(), sa.ForeignKey("teams.id"), nullable=False),
        sa.Column("target_weight_class", sa.Float(), nullable=False),
        sa.Column("target_date", sa.Date(), nullable=False),
        sa.Column("body_fat_percentage", sa.Float(), nullable=True),
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default=sa.true()),
        sa.Column("created_by_user_id", sa.Integer(), sa.ForeignKey("users.id"), nullable=False),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.Column("updated_at", sa.DateTime(), nullable=False),
    )
    op.create_index("ix_athlete_targets_athlete_id", "athlete_targets", ["athlete_id"])
    op.create_index("ix_athlete_targets_team_id", "athlete_targets", ["team_id"])

    op.create_table(
        "weight_plans",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("athlete_id", sa.Integer(), sa.ForeignKey("users.id"), nullable=False),
        sa.Column("team_id", sa.Integer(), sa.ForeignKey("teams.id"), nullable=False),
        sa.Column("athlete_target_id", sa.Integer(), sa.ForeignKey("athlete_targets.id"), nullable=True),
        sa.Column("calculated_at", sa.DateTime(), nullable=False),
        sa.Column("current_weight", sa.Float(), nullable=False),
        sa.Column("body_fat_percentage", sa.Float(), nullable=True),
        sa.Column("target_weight_class", sa.Float(), nullable=False),
        sa.Column("target_date", sa.Date(), nullable=False),
        sa.Column("weekly_allowed_loss", sa.Float(), nullable=False),
        sa.Column("required_weekly_loss", sa.Float(), nullable=False),
        sa.Column("projected_reachable_weight", sa.Float(), nullable=False),
        sa.Column("estimated_reachable_class", sa.Float(), nullable=False),
        sa.Column("projected_target_date", sa.Date(), nullable=False),
        sa.Column("status", plan_status, nullable=False),
        sa.Column("warning_message", sa.Text(), nullable=True),
        sa.Column("summary", sa.String(length=255), nullable=False),
        sa.Column("plan_details", sa.JSON(), nullable=True),
    )
    op.create_index("ix_weight_plans_athlete_id", "weight_plans", ["athlete_id"])
    op.create_index("ix_weight_plans_team_id", "weight_plans", ["team_id"])
    op.create_index("ix_weight_plans_athlete_target_id", "weight_plans", ["athlete_target_id"])
    op.create_index("ix_weight_plans_calculated_at", "weight_plans", ["calculated_at"])

    op.create_table(
        "weight_alerts",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("athlete_id", sa.Integer(), sa.ForeignKey("users.id"), nullable=False),
        sa.Column("team_id", sa.Integer(), sa.ForeignKey("teams.id"), nullable=False),
        sa.Column("plan_id", sa.Integer(), sa.ForeignKey("weight_plans.id"), nullable=True),
        sa.Column("alert_type", alert_type, nullable=False),
        sa.Column("alert_message", sa.Text(), nullable=False),
        sa.Column("status", alert_status, nullable=False, server_default="active"),
        sa.Column("severity", plan_status, nullable=False),
        sa.Column("triggered_at", sa.DateTime(), nullable=False),
        sa.Column("resolved_at", sa.DateTime(), nullable=True),
    )
    op.create_index("ix_weight_alerts_athlete_id", "weight_alerts", ["athlete_id"])
    op.create_index("ix_weight_alerts_team_id", "weight_alerts", ["team_id"])
    op.create_index("ix_weight_alerts_plan_id", "weight_alerts", ["plan_id"])


def downgrade() -> None:
    op.drop_index("ix_weight_alerts_plan_id", table_name="weight_alerts")
    op.drop_index("ix_weight_alerts_team_id", table_name="weight_alerts")
    op.drop_index("ix_weight_alerts_athlete_id", table_name="weight_alerts")
    op.drop_table("weight_alerts")

    op.drop_index("ix_weight_plans_calculated_at", table_name="weight_plans")
    op.drop_index("ix_weight_plans_athlete_target_id", table_name="weight_plans")
    op.drop_index("ix_weight_plans_team_id", table_name="weight_plans")
    op.drop_index("ix_weight_plans_athlete_id", table_name="weight_plans")
    op.drop_table("weight_plans")

    op.drop_index("ix_athlete_targets_team_id", table_name="athlete_targets")
    op.drop_index("ix_athlete_targets_athlete_id", table_name="athlete_targets")
    op.drop_table("athlete_targets")

    op.drop_index("ix_hydration_logs_team_id", table_name="hydration_logs")
    op.drop_index("ix_hydration_logs_athlete_id", table_name="hydration_logs")
    op.drop_table("hydration_logs")

    op.drop_index("ix_weight_logs_logged_at", table_name="weight_logs")
    op.drop_index("ix_weight_logs_team_id", table_name="weight_logs")
    op.drop_index("ix_weight_logs_athlete_id", table_name="weight_logs")
    op.drop_table("weight_logs")

    bind = op.get_bind()
    postgresql.ENUM(name="weightalertstatus", create_type=False).drop(bind, checkfirst=True)
    postgresql.ENUM(name="weightalerttype", create_type=False).drop(bind, checkfirst=True)
    postgresql.ENUM(name="weightplanstatus", create_type=False).drop(bind, checkfirst=True)
