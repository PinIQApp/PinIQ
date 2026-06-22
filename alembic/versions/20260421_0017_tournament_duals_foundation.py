"""tournament duals foundation

Revision ID: 20260421_0017
Revises: 20260415_0016
Create Date: 2026-04-21 22:30:00.000000
"""

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql


revision = "20260421_0017"
down_revision = "20260415_0016"
branch_labels = None
depends_on = None


def upgrade() -> None:
    format_type = postgresql.ENUM(
        "single_elimination",
        "round_robin",
        "pool_to_bracket",
        "dual_pool",
        "dual_bracket",
        "dual_round_robin",
        name="tournamentformattype", create_type=False
    )
    mat_status = postgresql.ENUM("offline", "ready", "live", name="tournamentmatstatus", create_type=False)
    dual_meet_status = postgresql.ENUM(
        "scheduled",
        "on_deck",
        "in_progress",
        "completed",
        name="dualmeetstatus", create_type=False
    )
    dual_bout_result_type = postgresql.ENUM(
        "decision",
        "major_decision",
        "technical_fall",
        "fall",
        "medical_forfeit",
        "forfeit",
        "default",
        "disqualification",
        name="dualboutresulttype", create_type=False
    )

    bind = op.get_bind()
    format_type.create(bind, checkfirst=True)
    mat_status.create(bind, checkfirst=True)
    dual_meet_status.create(bind, checkfirst=True)
    dual_bout_result_type.create(bind, checkfirst=True)

    op.add_column(
        "tournaments",
        sa.Column("format_type", format_type, nullable=False, server_default="single_elimination"),
    )

    op.create_table(
        "tournament_mats",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("tournament_id", sa.Integer(), sa.ForeignKey("tournaments.id"), nullable=False),
        sa.Column("label", sa.String(length=40), nullable=False),
        sa.Column("area_name", sa.String(length=80), nullable=True),
        sa.Column("display_order", sa.Integer(), nullable=True),
        sa.Column("status", mat_status, nullable=False, server_default="ready"),
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default=sa.true()),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.Column("updated_at", sa.DateTime(), nullable=False),
        sa.UniqueConstraint("tournament_id", "label", name="uq_tournament_mat_label"),
    )
    op.create_index("ix_tournament_mats_tournament_id", "tournament_mats", ["tournament_id"])
    op.create_index("ix_tournament_mats_status", "tournament_mats", ["status"])

    op.create_table(
        "tournament_dual_meets",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("tournament_id", sa.Integer(), sa.ForeignKey("tournaments.id"), nullable=False),
        sa.Column("division_name", sa.String(length=80), nullable=True),
        sa.Column("round_label", sa.String(length=80), nullable=True),
        sa.Column("pool_name", sa.String(length=80), nullable=True),
        sa.Column("bracket_slot", sa.String(length=80), nullable=True),
        sa.Column("scheduled_sequence", sa.Integer(), nullable=True),
        sa.Column("queue_position", sa.Integer(), nullable=True),
        sa.Column("mat_id", sa.Integer(), sa.ForeignKey("tournament_mats.id"), nullable=True),
        sa.Column("team_a_id", sa.Integer(), sa.ForeignKey("teams.id"), nullable=False),
        sa.Column("team_b_id", sa.Integer(), sa.ForeignKey("teams.id"), nullable=False),
        sa.Column("team_a_score", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("team_b_score", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("winner_team_id", sa.Integer(), sa.ForeignKey("teams.id"), nullable=True),
        sa.Column("status", dual_meet_status, nullable=False, server_default="scheduled"),
        sa.Column("starts_at", sa.DateTime(), nullable=True),
        sa.Column("completed_at", sa.DateTime(), nullable=True),
        sa.Column("notes", sa.Text(), nullable=True),
        sa.Column("created_by_user_id", sa.Integer(), sa.ForeignKey("users.id"), nullable=False),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.Column("updated_at", sa.DateTime(), nullable=False),
    )
    op.create_index("ix_tournament_dual_meets_tournament_id", "tournament_dual_meets", ["tournament_id"])
    op.create_index("ix_tournament_dual_meets_division_name", "tournament_dual_meets", ["division_name"])
    op.create_index("ix_tournament_dual_meets_pool_name", "tournament_dual_meets", ["pool_name"])
    op.create_index("ix_tournament_dual_meets_scheduled_sequence", "tournament_dual_meets", ["scheduled_sequence"])
    op.create_index("ix_tournament_dual_meets_mat_id", "tournament_dual_meets", ["mat_id"])
    op.create_index("ix_tournament_dual_meets_team_a_id", "tournament_dual_meets", ["team_a_id"])
    op.create_index("ix_tournament_dual_meets_team_b_id", "tournament_dual_meets", ["team_b_id"])
    op.create_index("ix_tournament_dual_meets_winner_team_id", "tournament_dual_meets", ["winner_team_id"])
    op.create_index("ix_tournament_dual_meets_status", "tournament_dual_meets", ["status"])

    op.create_table(
        "tournament_dual_bouts",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("dual_meet_id", sa.Integer(), sa.ForeignKey("tournament_dual_meets.id"), nullable=False),
        sa.Column("weight_class", sa.String(length=30), nullable=False),
        sa.Column("bout_order", sa.Integer(), nullable=True),
        sa.Column("wrestler_a_entry_id", sa.Integer(), sa.ForeignKey("tournament_entries.id"), nullable=True),
        sa.Column("wrestler_b_entry_id", sa.Integer(), sa.ForeignKey("tournament_entries.id"), nullable=True),
        sa.Column("wrestler_a_name", sa.String(length=160), nullable=True),
        sa.Column("wrestler_b_name", sa.String(length=160), nullable=True),
        sa.Column("wrestler_a_team_id", sa.Integer(), sa.ForeignKey("teams.id"), nullable=True),
        sa.Column("wrestler_b_team_id", sa.Integer(), sa.ForeignKey("teams.id"), nullable=True),
        sa.Column("winner_entry_id", sa.Integer(), sa.ForeignKey("tournament_entries.id"), nullable=True),
        sa.Column("winner_team_id", sa.Integer(), sa.ForeignKey("teams.id"), nullable=True),
        sa.Column("result_type", dual_bout_result_type, nullable=True),
        sa.Column("result_summary", sa.String(length=255), nullable=True),
        sa.Column("team_a_points_awarded", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("team_b_points_awarded", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("is_complete", sa.Boolean(), nullable=False, server_default=sa.false()),
        sa.Column("completed_at", sa.DateTime(), nullable=True),
        sa.Column("updated_by_user_id", sa.Integer(), sa.ForeignKey("users.id"), nullable=True),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.Column("updated_at", sa.DateTime(), nullable=False),
        sa.UniqueConstraint("dual_meet_id", "weight_class", name="uq_dual_meet_weight_class"),
    )
    op.create_index("ix_tournament_dual_bouts_dual_meet_id", "tournament_dual_bouts", ["dual_meet_id"])
    op.create_index("ix_tournament_dual_bouts_weight_class", "tournament_dual_bouts", ["weight_class"])
    op.create_index("ix_tournament_dual_bouts_wrestler_a_entry_id", "tournament_dual_bouts", ["wrestler_a_entry_id"])
    op.create_index("ix_tournament_dual_bouts_wrestler_b_entry_id", "tournament_dual_bouts", ["wrestler_b_entry_id"])
    op.create_index("ix_tournament_dual_bouts_wrestler_a_team_id", "tournament_dual_bouts", ["wrestler_a_team_id"])
    op.create_index("ix_tournament_dual_bouts_wrestler_b_team_id", "tournament_dual_bouts", ["wrestler_b_team_id"])
    op.create_index("ix_tournament_dual_bouts_winner_entry_id", "tournament_dual_bouts", ["winner_entry_id"])
    op.create_index("ix_tournament_dual_bouts_winner_team_id", "tournament_dual_bouts", ["winner_team_id"])


def downgrade() -> None:
    op.drop_index("ix_tournament_dual_bouts_winner_team_id", table_name="tournament_dual_bouts")
    op.drop_index("ix_tournament_dual_bouts_winner_entry_id", table_name="tournament_dual_bouts")
    op.drop_index("ix_tournament_dual_bouts_wrestler_b_team_id", table_name="tournament_dual_bouts")
    op.drop_index("ix_tournament_dual_bouts_wrestler_a_team_id", table_name="tournament_dual_bouts")
    op.drop_index("ix_tournament_dual_bouts_wrestler_b_entry_id", table_name="tournament_dual_bouts")
    op.drop_index("ix_tournament_dual_bouts_wrestler_a_entry_id", table_name="tournament_dual_bouts")
    op.drop_index("ix_tournament_dual_bouts_weight_class", table_name="tournament_dual_bouts")
    op.drop_index("ix_tournament_dual_bouts_dual_meet_id", table_name="tournament_dual_bouts")
    op.drop_table("tournament_dual_bouts")

    op.drop_index("ix_tournament_dual_meets_status", table_name="tournament_dual_meets")
    op.drop_index("ix_tournament_dual_meets_winner_team_id", table_name="tournament_dual_meets")
    op.drop_index("ix_tournament_dual_meets_team_b_id", table_name="tournament_dual_meets")
    op.drop_index("ix_tournament_dual_meets_team_a_id", table_name="tournament_dual_meets")
    op.drop_index("ix_tournament_dual_meets_mat_id", table_name="tournament_dual_meets")
    op.drop_index("ix_tournament_dual_meets_scheduled_sequence", table_name="tournament_dual_meets")
    op.drop_index("ix_tournament_dual_meets_pool_name", table_name="tournament_dual_meets")
    op.drop_index("ix_tournament_dual_meets_division_name", table_name="tournament_dual_meets")
    op.drop_index("ix_tournament_dual_meets_tournament_id", table_name="tournament_dual_meets")
    op.drop_table("tournament_dual_meets")

    op.drop_index("ix_tournament_mats_status", table_name="tournament_mats")
    op.drop_index("ix_tournament_mats_tournament_id", table_name="tournament_mats")
    op.drop_table("tournament_mats")

    op.drop_column("tournaments", "format_type")

    dual_bout_result_type = postgresql.ENUM(
        "decision",
        "major_decision",
        "technical_fall",
        "fall",
        "medical_forfeit",
        "forfeit",
        "default",
        "disqualification",
        name="dualboutresulttype", create_type=False
    )
    dual_meet_status = postgresql.ENUM(
        "scheduled",
        "on_deck",
        "in_progress",
        "completed",
        name="dualmeetstatus", create_type=False
    )
    mat_status = postgresql.ENUM("offline", "ready", "live", name="tournamentmatstatus", create_type=False)
    format_type = postgresql.ENUM(
        "single_elimination",
        "round_robin",
        "pool_to_bracket",
        "dual_pool",
        "dual_bracket",
        "dual_round_robin",
        name="tournamentformattype", create_type=False
    )
    bind = op.get_bind()
    dual_bout_result_type.drop(bind, checkfirst=True)
    dual_meet_status.drop(bind, checkfirst=True)
    mat_status.drop(bind, checkfirst=True)
    format_type.drop(bind, checkfirst=True)
