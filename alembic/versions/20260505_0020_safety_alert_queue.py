"""add safety alert queue

Revision ID: 20260505_0020
Revises: 20260503_0019
Create Date: 2026-05-05 22:20:00
"""

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql


revision = "20260505_0020"
down_revision = "20260503_0019"
branch_labels = None
depends_on = None


safety_alert_severity = postgresql.ENUM("info", "concern", "urgent", name="safetyalertseverity", create_type=False)
safety_alert_status = postgresql.ENUM("open", "acknowledged", name="safetyalertstatus", create_type=False)


def upgrade() -> None:
    bind = op.get_bind()
    safety_alert_severity.create(bind, checkfirst=True)
    safety_alert_status.create(bind, checkfirst=True)

    op.create_table(
        "safety_alerts",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("team_id", sa.Integer(), nullable=False),
        sa.Column("source_thread_id", sa.Integer(), nullable=False),
        sa.Column("source_message_id", sa.Integer(), nullable=False),
        sa.Column("alert_thread_id", sa.Integer(), nullable=False),
        sa.Column("source_sender_id", sa.Integer(), nullable=False),
        sa.Column("severity", safety_alert_severity, nullable=False, server_default="concern"),
        sa.Column("status", safety_alert_status, nullable=False, server_default="open"),
        sa.Column("score", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("categories", sa.JSON(), nullable=True),
        sa.Column("repeated_trigger_count", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("subject_athlete_ids", sa.JSON(), nullable=True),
        sa.Column("summary", sa.String(length=255), nullable=False),
        sa.Column("source_excerpt", sa.String(length=500), nullable=False),
        sa.Column("metadata", sa.JSON(), nullable=True),
        sa.Column("acknowledged_by_user_id", sa.Integer(), nullable=True),
        sa.Column("acknowledged_at", sa.DateTime(), nullable=True),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.Column("updated_at", sa.DateTime(), nullable=False),
        sa.ForeignKeyConstraint(["team_id"], ["teams.id"]),
        sa.ForeignKeyConstraint(["source_thread_id"], ["message_threads.id"]),
        sa.ForeignKeyConstraint(["source_message_id"], ["messages.id"]),
        sa.ForeignKeyConstraint(["alert_thread_id"], ["message_threads.id"]),
        sa.ForeignKeyConstraint(["source_sender_id"], ["users.id"]),
        sa.ForeignKeyConstraint(["acknowledged_by_user_id"], ["users.id"]),
        sa.UniqueConstraint("source_message_id"),
        sa.UniqueConstraint("alert_thread_id"),
    )
    op.create_index(op.f("ix_safety_alerts_team_id"), "safety_alerts", ["team_id"], unique=False)
    op.create_index(op.f("ix_safety_alerts_source_thread_id"), "safety_alerts", ["source_thread_id"], unique=False)
    op.create_index(op.f("ix_safety_alerts_source_message_id"), "safety_alerts", ["source_message_id"], unique=True)
    op.create_index(op.f("ix_safety_alerts_alert_thread_id"), "safety_alerts", ["alert_thread_id"], unique=True)
    op.create_index(op.f("ix_safety_alerts_source_sender_id"), "safety_alerts", ["source_sender_id"], unique=False)
    op.create_index(
        op.f("ix_safety_alerts_acknowledged_by_user_id"),
        "safety_alerts",
        ["acknowledged_by_user_id"],
        unique=False,
    )


def downgrade() -> None:
    op.drop_index(op.f("ix_safety_alerts_acknowledged_by_user_id"), table_name="safety_alerts")
    op.drop_index(op.f("ix_safety_alerts_source_sender_id"), table_name="safety_alerts")
    op.drop_index(op.f("ix_safety_alerts_alert_thread_id"), table_name="safety_alerts")
    op.drop_index(op.f("ix_safety_alerts_source_message_id"), table_name="safety_alerts")
    op.drop_index(op.f("ix_safety_alerts_source_thread_id"), table_name="safety_alerts")
    op.drop_index(op.f("ix_safety_alerts_team_id"), table_name="safety_alerts")
    op.drop_table("safety_alerts")

    bind = op.get_bind()
    safety_alert_status.drop(bind, checkfirst=True)
    safety_alert_severity.drop(bind, checkfirst=True)
