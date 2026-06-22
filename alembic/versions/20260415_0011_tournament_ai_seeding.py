"""tournament ai seeding

Revision ID: 20260415_0011
Revises: 20260415_0010
Create Date: 2026-04-15 00:11:00.000000
"""

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql


revision = "20260415_0011"
down_revision = "20260415_0010"
branch_labels = None
depends_on = None


def upgrade() -> None:
    tournament_event_type = postgresql.ENUM(
        "dual_event",
        "individual_tournament",
        "round_robin_pool",
        "bracket_style_event",
        name="tournamenteventtype", create_type=False
    )
    tournament_status = postgresql.ENUM(
        "draft",
        "entries_open",
        "seeding_in_review",
        "bracket_finalized",
        "published",
        name="tournamentstatus", create_type=False
    )
    entry_status = postgresql.ENUM("entered", "scratched", "replaced", "late_update", name="entrystatus", create_type=False)
    seeding_source = postgresql.ENUM("calculated", "manual_override", name="seedingsource", create_type=False)
    bracket_type = postgresql.ENUM("4_man", "8_man", "16_man", "32_man", "round_robin", name="brackettype", create_type=False)
    bracket_status = postgresql.ENUM("draft", "finalized", "published", name="bracketstatus", create_type=False)
    bracket_match_status = postgresql.ENUM("pending", "completed", "bye", name="bracketmatchstatus", create_type=False)

    bind = op.get_bind()
    for enum in (
        tournament_event_type,
        tournament_status,
        entry_status,
        seeding_source,
        bracket_type,
        bracket_status,
        bracket_match_status,
    ):
        enum.create(bind, checkfirst=True)

    op.create_table(
        "tournaments",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("name", sa.String(length=160), nullable=False),
        sa.Column("host_team_id", sa.Integer(), sa.ForeignKey("teams.id"), nullable=True),
        sa.Column("director_user_id", sa.Integer(), sa.ForeignKey("users.id"), nullable=False),
        sa.Column("event_type", tournament_event_type, nullable=False),
        sa.Column("status", tournament_status, nullable=False, server_default="draft"),
        sa.Column("start_date", sa.Date(), nullable=False),
        sa.Column("end_date", sa.Date(), nullable=False),
        sa.Column("location", sa.String(length=180), nullable=True),
        sa.Column("notes", sa.Text(), nullable=True),
        sa.Column("is_public", sa.Boolean(), nullable=False, server_default=sa.false()),
        sa.Column("finalized_at", sa.DateTime(), nullable=True),
        sa.Column("published_at", sa.DateTime(), nullable=True),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.Column("updated_at", sa.DateTime(), nullable=False),
    )
    op.create_index("ix_tournaments_host_team_id", "tournaments", ["host_team_id"])
    op.create_index("ix_tournaments_director_user_id", "tournaments", ["director_user_id"])
    op.create_index("ix_tournaments_event_type", "tournaments", ["event_type"])
    op.create_index("ix_tournaments_status", "tournaments", ["status"])

    op.create_table(
        "tournament_divisions",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("tournament_id", sa.Integer(), sa.ForeignKey("tournaments.id"), nullable=False),
        sa.Column("name", sa.String(length=80), nullable=False),
        sa.Column("min_weight_class", sa.String(length=30), nullable=True),
        sa.Column("max_weight_class", sa.String(length=30), nullable=True),
        sa.Column("notes", sa.String(length=255), nullable=True),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.UniqueConstraint("tournament_id", "name", name="uq_tournament_division_name"),
    )
    op.create_index("ix_tournament_divisions_tournament_id", "tournament_divisions", ["tournament_id"])

    op.create_table(
        "tournament_teams",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("tournament_id", sa.Integer(), sa.ForeignKey("tournaments.id"), nullable=False),
        sa.Column("team_id", sa.Integer(), sa.ForeignKey("teams.id"), nullable=False),
        sa.Column("invited_by_user_id", sa.Integer(), sa.ForeignKey("users.id"), nullable=True),
        sa.Column("notes", sa.String(length=255), nullable=True),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.UniqueConstraint("tournament_id", "team_id", name="uq_tournament_team"),
    )
    op.create_index("ix_tournament_teams_tournament_id", "tournament_teams", ["tournament_id"])
    op.create_index("ix_tournament_teams_team_id", "tournament_teams", ["team_id"])

    op.create_table(
        "tournament_entries",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("tournament_id", sa.Integer(), sa.ForeignKey("tournaments.id"), nullable=False),
        sa.Column("team_id", sa.Integer(), sa.ForeignKey("teams.id"), nullable=False),
        sa.Column("athlete_id", sa.Integer(), sa.ForeignKey("users.id"), nullable=False),
        sa.Column("division_name", sa.String(length=80), nullable=False),
        sa.Column("weight_class", sa.String(length=30), nullable=False),
        sa.Column("entry_status", entry_status, nullable=False, server_default="entered"),
        sa.Column("seed_number", sa.Integer(), nullable=True),
        sa.Column("seed_locked", sa.Boolean(), nullable=False, server_default=sa.false()),
        sa.Column("seeded_at", sa.DateTime(), nullable=True),
        sa.Column("notes", sa.Text(), nullable=True),
        sa.Column("created_by_user_id", sa.Integer(), sa.ForeignKey("users.id"), nullable=False),
        sa.Column("updated_by_user_id", sa.Integer(), sa.ForeignKey("users.id"), nullable=True),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.Column("updated_at", sa.DateTime(), nullable=False),
    )
    op.create_index("ix_tournament_entries_tournament_id", "tournament_entries", ["tournament_id"])
    op.create_index("ix_tournament_entries_team_id", "tournament_entries", ["team_id"])
    op.create_index("ix_tournament_entries_athlete_id", "tournament_entries", ["athlete_id"])
    op.create_index("ix_tournament_entries_division_name", "tournament_entries", ["division_name"])
    op.create_index("ix_tournament_entries_weight_class", "tournament_entries", ["weight_class"])
    op.create_index("ix_tournament_entries_entry_status", "tournament_entries", ["entry_status"])

    op.create_table(
        "seed_scores",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("tournament_id", sa.Integer(), sa.ForeignKey("tournaments.id"), nullable=False),
        sa.Column("entry_id", sa.Integer(), sa.ForeignKey("tournament_entries.id"), nullable=False),
        sa.Column("team_id", sa.Integer(), sa.ForeignKey("teams.id"), nullable=False),
        sa.Column("athlete_id", sa.Integer(), sa.ForeignKey("users.id"), nullable=False),
        sa.Column("weight_class", sa.String(length=30), nullable=False),
        sa.Column("division_name", sa.String(length=80), nullable=False),
        sa.Column("seed_number", sa.Integer(), nullable=False),
        sa.Column("seed_score", sa.Float(), nullable=False),
        sa.Column("score_breakdown", sa.JSON(), nullable=False),
        sa.Column("seed_explanation", sa.Text(), nullable=False),
        sa.Column("source", seeding_source, nullable=False, server_default="calculated"),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.Column("updated_at", sa.DateTime(), nullable=False),
        sa.UniqueConstraint("tournament_id", "entry_id", name="uq_seed_score_entry"),
    )
    op.create_index("ix_seed_scores_tournament_id", "seed_scores", ["tournament_id"])
    op.create_index("ix_seed_scores_entry_id", "seed_scores", ["entry_id"])
    op.create_index("ix_seed_scores_team_id", "seed_scores", ["team_id"])
    op.create_index("ix_seed_scores_athlete_id", "seed_scores", ["athlete_id"])
    op.create_index("ix_seed_scores_weight_class", "seed_scores", ["weight_class"])
    op.create_index("ix_seed_scores_division_name", "seed_scores", ["division_name"])

    op.create_table(
        "seeding_overrides",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("tournament_id", sa.Integer(), sa.ForeignKey("tournaments.id"), nullable=False),
        sa.Column("entry_id", sa.Integer(), sa.ForeignKey("tournament_entries.id"), nullable=False),
        sa.Column("actor_id", sa.Integer(), sa.ForeignKey("users.id"), nullable=False),
        sa.Column("previous_seed_number", sa.Integer(), nullable=True),
        sa.Column("new_seed_number", sa.Integer(), nullable=False),
        sa.Column("override_reason", sa.Text(), nullable=False),
        sa.Column("previous_snapshot", sa.JSON(), nullable=True),
        sa.Column("created_at", sa.DateTime(), nullable=False),
    )
    op.create_index("ix_seeding_overrides_tournament_id", "seeding_overrides", ["tournament_id"])
    op.create_index("ix_seeding_overrides_entry_id", "seeding_overrides", ["entry_id"])
    op.create_index("ix_seeding_overrides_actor_id", "seeding_overrides", ["actor_id"])

    op.create_table(
        "brackets",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("tournament_id", sa.Integer(), sa.ForeignKey("tournaments.id"), nullable=False),
        sa.Column("division_name", sa.String(length=80), nullable=False),
        sa.Column("weight_class", sa.String(length=30), nullable=False),
        sa.Column("bracket_type", bracket_type, nullable=False),
        sa.Column("bracket_size", sa.Integer(), nullable=False),
        sa.Column("status", bracket_status, nullable=False, server_default="draft"),
        sa.Column("preview_payload", sa.JSON(), nullable=False),
        sa.Column("created_by_user_id", sa.Integer(), sa.ForeignKey("users.id"), nullable=False),
        sa.Column("finalized_by_user_id", sa.Integer(), sa.ForeignKey("users.id"), nullable=True),
        sa.Column("finalized_at", sa.DateTime(), nullable=True),
        sa.Column("published_at", sa.DateTime(), nullable=True),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.Column("updated_at", sa.DateTime(), nullable=False),
        sa.UniqueConstraint("tournament_id", "weight_class", name="uq_bracket_weight_class"),
    )
    op.create_index("ix_brackets_tournament_id", "brackets", ["tournament_id"])
    op.create_index("ix_brackets_division_name", "brackets", ["division_name"])
    op.create_index("ix_brackets_weight_class", "brackets", ["weight_class"])
    op.create_index("ix_brackets_bracket_type", "brackets", ["bracket_type"])
    op.create_index("ix_brackets_status", "brackets", ["status"])

    op.create_table(
        "bracket_matches",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("bracket_id", sa.Integer(), sa.ForeignKey("brackets.id"), nullable=False),
        sa.Column("tournament_id", sa.Integer(), sa.ForeignKey("tournaments.id"), nullable=False),
        sa.Column("round_number", sa.Integer(), nullable=False),
        sa.Column("matchup_order", sa.Integer(), nullable=False),
        sa.Column("wrestler_a_entry_id", sa.Integer(), sa.ForeignKey("tournament_entries.id"), nullable=True),
        sa.Column("wrestler_b_entry_id", sa.Integer(), sa.ForeignKey("tournament_entries.id"), nullable=True),
        sa.Column("wrestler_a_seed", sa.Integer(), nullable=True),
        sa.Column("wrestler_b_seed", sa.Integer(), nullable=True),
        sa.Column("winner_entry_id", sa.Integer(), sa.ForeignKey("tournament_entries.id"), nullable=True),
        sa.Column("next_match_id", sa.Integer(), sa.ForeignKey("bracket_matches.id"), nullable=True),
        sa.Column("next_match_slot", sa.String(length=1), nullable=True),
        sa.Column("match_status", bracket_match_status, nullable=False, server_default="pending"),
        sa.Column("scheduled_at", sa.DateTime(), nullable=True),
        sa.Column("mat_label", sa.String(length=40), nullable=True),
        sa.Column("result_summary", sa.String(length=255), nullable=True),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.Column("updated_at", sa.DateTime(), nullable=False),
    )
    op.create_index("ix_bracket_matches_bracket_id", "bracket_matches", ["bracket_id"])
    op.create_index("ix_bracket_matches_tournament_id", "bracket_matches", ["tournament_id"])
    op.create_index("ix_bracket_matches_round_number", "bracket_matches", ["round_number"])
    op.create_index("ix_bracket_matches_match_status", "bracket_matches", ["match_status"])


def downgrade() -> None:
    op.drop_index("ix_bracket_matches_match_status", table_name="bracket_matches")
    op.drop_index("ix_bracket_matches_round_number", table_name="bracket_matches")
    op.drop_index("ix_bracket_matches_tournament_id", table_name="bracket_matches")
    op.drop_index("ix_bracket_matches_bracket_id", table_name="bracket_matches")
    op.drop_table("bracket_matches")

    op.drop_index("ix_brackets_status", table_name="brackets")
    op.drop_index("ix_brackets_bracket_type", table_name="brackets")
    op.drop_index("ix_brackets_weight_class", table_name="brackets")
    op.drop_index("ix_brackets_division_name", table_name="brackets")
    op.drop_index("ix_brackets_tournament_id", table_name="brackets")
    op.drop_table("brackets")

    op.drop_index("ix_seeding_overrides_actor_id", table_name="seeding_overrides")
    op.drop_index("ix_seeding_overrides_entry_id", table_name="seeding_overrides")
    op.drop_index("ix_seeding_overrides_tournament_id", table_name="seeding_overrides")
    op.drop_table("seeding_overrides")

    op.drop_index("ix_seed_scores_division_name", table_name="seed_scores")
    op.drop_index("ix_seed_scores_weight_class", table_name="seed_scores")
    op.drop_index("ix_seed_scores_athlete_id", table_name="seed_scores")
    op.drop_index("ix_seed_scores_team_id", table_name="seed_scores")
    op.drop_index("ix_seed_scores_entry_id", table_name="seed_scores")
    op.drop_index("ix_seed_scores_tournament_id", table_name="seed_scores")
    op.drop_table("seed_scores")

    op.drop_index("ix_tournament_entries_entry_status", table_name="tournament_entries")
    op.drop_index("ix_tournament_entries_weight_class", table_name="tournament_entries")
    op.drop_index("ix_tournament_entries_division_name", table_name="tournament_entries")
    op.drop_index("ix_tournament_entries_athlete_id", table_name="tournament_entries")
    op.drop_index("ix_tournament_entries_team_id", table_name="tournament_entries")
    op.drop_index("ix_tournament_entries_tournament_id", table_name="tournament_entries")
    op.drop_table("tournament_entries")

    op.drop_index("ix_tournament_teams_team_id", table_name="tournament_teams")
    op.drop_index("ix_tournament_teams_tournament_id", table_name="tournament_teams")
    op.drop_table("tournament_teams")

    op.drop_index("ix_tournament_divisions_tournament_id", table_name="tournament_divisions")
    op.drop_table("tournament_divisions")

    op.drop_index("ix_tournaments_status", table_name="tournaments")
    op.drop_index("ix_tournaments_event_type", table_name="tournaments")
    op.drop_index("ix_tournaments_director_user_id", table_name="tournaments")
    op.drop_index("ix_tournaments_host_team_id", table_name="tournaments")
    op.drop_table("tournaments")

    bind = op.get_bind()
    postgresql.ENUM(name="bracketmatchstatus", create_type=False).drop(bind, checkfirst=True)
    postgresql.ENUM(name="bracketstatus", create_type=False).drop(bind, checkfirst=True)
    postgresql.ENUM(name="brackettype", create_type=False).drop(bind, checkfirst=True)
    postgresql.ENUM(name="seedingsource", create_type=False).drop(bind, checkfirst=True)
    postgresql.ENUM(name="entrystatus", create_type=False).drop(bind, checkfirst=True)
    postgresql.ENUM(name="tournamentstatus", create_type=False).drop(bind, checkfirst=True)
    postgresql.ENUM(name="tournamenteventtype", create_type=False).drop(bind, checkfirst=True)
