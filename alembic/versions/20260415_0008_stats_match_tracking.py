"""stats and match tracking

Revision ID: 20260415_0008
Revises: 20260415_0007
Create Date: 2026-04-15 00:08:00.000000
"""

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql


revision = "20260415_0008"
down_revision = "20260415_0007"
branch_labels = None
depends_on = None


def upgrade() -> None:
    match_outcome = postgresql.ENUM("win", "loss", name="matchoutcome", create_type=False)
    match_result_type = postgresql.ENUM(
        "pin",
        "tech_fall",
        "major_decision",
        "decision",
        "medical_forfeit",
        "forfeit",
        "default",
        "disqualification",
        name="matchresulttype", create_type=False
    )
    stat_audit_action = postgresql.ENUM(
        "match_created",
        "match_updated",
        "match_stats_created",
        "match_stats_updated",
        name="statauditaction", create_type=False
    )

    bind = op.get_bind()
    match_outcome.create(bind, checkfirst=True)
    match_result_type.create(bind, checkfirst=True)
    stat_audit_action.create(bind, checkfirst=True)

    op.create_table(
        "matches",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("athlete_id", sa.Integer(), sa.ForeignKey("users.id"), nullable=False),
        sa.Column("team_id", sa.Integer(), sa.ForeignKey("teams.id"), nullable=False),
        sa.Column("created_by_user_id", sa.Integer(), sa.ForeignKey("users.id"), nullable=False),
        sa.Column("updated_by_user_id", sa.Integer(), sa.ForeignKey("users.id"), nullable=True),
        sa.Column("opponent_name", sa.String(length=120), nullable=False),
        sa.Column("opponent_school", sa.String(length=140), nullable=True),
        sa.Column("event_name", sa.String(length=160), nullable=True),
        sa.Column("match_date", sa.Date(), nullable=False),
        sa.Column("weight_class", sa.String(length=30), nullable=False),
        sa.Column("result", match_outcome, nullable=False),
        sa.Column("result_type", match_result_type, nullable=False),
        sa.Column("score_for", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("score_against", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("pin_time", sa.String(length=12), nullable=True),
        sa.Column("notes", sa.Text(), nullable=True),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.Column("updated_at", sa.DateTime(), nullable=False),
    )
    op.create_index("ix_matches_athlete_id", "matches", ["athlete_id"])
    op.create_index("ix_matches_team_id", "matches", ["team_id"])
    op.create_index("ix_matches_match_date", "matches", ["match_date"])
    op.create_index("ix_matches_weight_class", "matches", ["weight_class"])
    op.create_index("ix_matches_result", "matches", ["result"])
    op.create_index("ix_matches_result_type", "matches", ["result_type"])

    op.create_table(
        "match_stats",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("match_id", sa.Integer(), sa.ForeignKey("matches.id"), nullable=False),
        sa.Column("athlete_id", sa.Integer(), sa.ForeignKey("users.id"), nullable=False),
        sa.Column("team_id", sa.Integer(), sa.ForeignKey("teams.id"), nullable=False),
        sa.Column("takedowns", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("escapes", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("reversals", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("nearfall_points", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("stall_calls", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("ride_time_seconds", sa.Integer(), nullable=True),
        sa.Column("shot_attempts", sa.Integer(), nullable=True),
        sa.Column("shot_conversions", sa.Integer(), nullable=True),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.Column("updated_at", sa.DateTime(), nullable=False),
        sa.UniqueConstraint("match_id", name="uq_match_stats_match_id"),
    )
    op.create_index("ix_match_stats_match_id", "match_stats", ["match_id"])
    op.create_index("ix_match_stats_athlete_id", "match_stats", ["athlete_id"])
    op.create_index("ix_match_stats_team_id", "match_stats", ["team_id"])

    op.create_table(
        "athlete_stat_snapshots",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("team_id", sa.Integer(), sa.ForeignKey("teams.id"), nullable=False),
        sa.Column("athlete_id", sa.Integer(), sa.ForeignKey("users.id"), nullable=False),
        sa.Column("total_matches", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("wins", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("losses", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("win_percentage", sa.Float(), nullable=False, server_default="0"),
        sa.Column("bonus_point_rate", sa.Float(), nullable=False, server_default="0"),
        sa.Column("recent_trend", sa.String(length=60), nullable=True),
        sa.Column("strengths_summary", sa.String(length=255), nullable=True),
        sa.Column("weaknesses_summary", sa.String(length=255), nullable=True),
        sa.Column("summary_payload", sa.JSON(), nullable=True),
        sa.Column("updated_at", sa.DateTime(), nullable=False),
        sa.UniqueConstraint("team_id", "athlete_id", name="uq_athlete_stat_snapshot"),
    )
    op.create_index("ix_athlete_stat_snapshots_team_id", "athlete_stat_snapshots", ["team_id"])
    op.create_index("ix_athlete_stat_snapshots_athlete_id", "athlete_stat_snapshots", ["athlete_id"])

    op.create_table(
        "team_stat_snapshots",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("team_id", sa.Integer(), sa.ForeignKey("teams.id"), nullable=False),
        sa.Column("total_matches", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("wins", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("losses", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("win_percentage", sa.Float(), nullable=False, server_default="0"),
        sa.Column("recent_trend", sa.String(length=120), nullable=True),
        sa.Column("summary_payload", sa.JSON(), nullable=True),
        sa.Column("updated_at", sa.DateTime(), nullable=False),
        sa.UniqueConstraint("team_id", name="uq_team_stat_snapshot"),
    )
    op.create_index("ix_team_stat_snapshots_team_id", "team_stat_snapshots", ["team_id"])

    op.create_table(
        "stat_audit_logs",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("team_id", sa.Integer(), sa.ForeignKey("teams.id"), nullable=False),
        sa.Column("athlete_id", sa.Integer(), sa.ForeignKey("users.id"), nullable=True),
        sa.Column("match_id", sa.Integer(), sa.ForeignKey("matches.id"), nullable=True),
        sa.Column("actor_id", sa.Integer(), sa.ForeignKey("users.id"), nullable=False),
        sa.Column("action", stat_audit_action, nullable=False),
        sa.Column("entity_type", sa.String(length=40), nullable=False),
        sa.Column("entity_id", sa.Integer(), nullable=False),
        sa.Column("before_state", sa.JSON(), nullable=True),
        sa.Column("after_state", sa.JSON(), nullable=True),
        sa.Column("created_at", sa.DateTime(), nullable=False),
    )
    op.create_index("ix_stat_audit_logs_team_id", "stat_audit_logs", ["team_id"])
    op.create_index("ix_stat_audit_logs_athlete_id", "stat_audit_logs", ["athlete_id"])
    op.create_index("ix_stat_audit_logs_match_id", "stat_audit_logs", ["match_id"])
    op.create_index("ix_stat_audit_logs_actor_id", "stat_audit_logs", ["actor_id"])


def downgrade() -> None:
    op.drop_index("ix_stat_audit_logs_actor_id", table_name="stat_audit_logs")
    op.drop_index("ix_stat_audit_logs_match_id", table_name="stat_audit_logs")
    op.drop_index("ix_stat_audit_logs_athlete_id", table_name="stat_audit_logs")
    op.drop_index("ix_stat_audit_logs_team_id", table_name="stat_audit_logs")
    op.drop_table("stat_audit_logs")

    op.drop_index("ix_team_stat_snapshots_team_id", table_name="team_stat_snapshots")
    op.drop_table("team_stat_snapshots")

    op.drop_index("ix_athlete_stat_snapshots_athlete_id", table_name="athlete_stat_snapshots")
    op.drop_index("ix_athlete_stat_snapshots_team_id", table_name="athlete_stat_snapshots")
    op.drop_table("athlete_stat_snapshots")

    op.drop_index("ix_match_stats_team_id", table_name="match_stats")
    op.drop_index("ix_match_stats_athlete_id", table_name="match_stats")
    op.drop_index("ix_match_stats_match_id", table_name="match_stats")
    op.drop_table("match_stats")

    op.drop_index("ix_matches_result_type", table_name="matches")
    op.drop_index("ix_matches_result", table_name="matches")
    op.drop_index("ix_matches_weight_class", table_name="matches")
    op.drop_index("ix_matches_match_date", table_name="matches")
    op.drop_index("ix_matches_team_id", table_name="matches")
    op.drop_index("ix_matches_athlete_id", table_name="matches")
    op.drop_table("matches")

    bind = op.get_bind()
    postgresql.ENUM(name="statauditaction", create_type=False).drop(bind, checkfirst=True)
    postgresql.ENUM(name="matchresulttype", create_type=False).drop(bind, checkfirst=True)
    postgresql.ENUM(name="matchoutcome", create_type=False).drop(bind, checkfirst=True)
