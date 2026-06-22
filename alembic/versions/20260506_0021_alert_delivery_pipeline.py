"""add alert delivery pipeline

Revision ID: 20260506_0021
Revises: 20260505_0020
Create Date: 2026-05-06 12:10:00
"""

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql


revision = "20260506_0021"
down_revision = "20260505_0020"
branch_labels = None
depends_on = None


alert_delivery_channel = postgresql.ENUM("sms", "email", "push", name="alertdeliverychannel", create_type=False)
alert_delivery_status = postgresql.ENUM("sent", "failed", "skipped", name="alertdeliverystatus", create_type=False)


def upgrade() -> None:
    bind = op.get_bind()
    alert_delivery_channel.create(bind, checkfirst=True)
    alert_delivery_status.create(bind, checkfirst=True)

    op.create_table(
        "user_push_devices",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("user_id", sa.Integer(), nullable=False),
        sa.Column("platform", sa.String(length=30), nullable=False),
        sa.Column("device_token", sa.String(length=255), nullable=False),
        sa.Column("push_enabled", sa.Boolean(), nullable=False, server_default=sa.true()),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.Column("updated_at", sa.DateTime(), nullable=False),
        sa.Column("last_seen_at", sa.DateTime(), nullable=False),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"]),
        sa.UniqueConstraint("device_token"),
    )
    op.create_index(op.f("ix_user_push_devices_user_id"), "user_push_devices", ["user_id"], unique=False)
    op.create_index(op.f("ix_user_push_devices_device_token"), "user_push_devices", ["device_token"], unique=True)

    op.create_table(
        "alert_deliveries",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("team_id", sa.Integer(), nullable=False),
        sa.Column("announcement_id", sa.Integer(), nullable=True),
        sa.Column("safety_alert_id", sa.Integer(), nullable=True),
        sa.Column("recipient_user_id", sa.Integer(), nullable=False),
        sa.Column("channel", alert_delivery_channel, nullable=False),
        sa.Column("provider", sa.String(length=40), nullable=False),
        sa.Column("status", alert_delivery_status, nullable=False),
        sa.Column("destination", sa.String(length=255), nullable=True),
        sa.Column("provider_message_id", sa.String(length=255), nullable=True),
        sa.Column("failure_reason", sa.String(length=255), nullable=True),
        sa.Column("delivery_metadata", sa.JSON(), nullable=True),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.Column("updated_at", sa.DateTime(), nullable=False),
        sa.ForeignKeyConstraint(["team_id"], ["teams.id"]),
        sa.ForeignKeyConstraint(["announcement_id"], ["announcements.id"]),
        sa.ForeignKeyConstraint(["safety_alert_id"], ["safety_alerts.id"]),
        sa.ForeignKeyConstraint(["recipient_user_id"], ["users.id"]),
    )
    op.create_index(op.f("ix_alert_deliveries_team_id"), "alert_deliveries", ["team_id"], unique=False)
    op.create_index(op.f("ix_alert_deliveries_announcement_id"), "alert_deliveries", ["announcement_id"], unique=False)
    op.create_index(op.f("ix_alert_deliveries_safety_alert_id"), "alert_deliveries", ["safety_alert_id"], unique=False)
    op.create_index(op.f("ix_alert_deliveries_recipient_user_id"), "alert_deliveries", ["recipient_user_id"], unique=False)
    op.create_index(
        op.f("ix_alert_deliveries_provider_message_id"),
        "alert_deliveries",
        ["provider_message_id"],
        unique=False,
    )


def downgrade() -> None:
    op.drop_index(op.f("ix_alert_deliveries_provider_message_id"), table_name="alert_deliveries")
    op.drop_index(op.f("ix_alert_deliveries_recipient_user_id"), table_name="alert_deliveries")
    op.drop_index(op.f("ix_alert_deliveries_safety_alert_id"), table_name="alert_deliveries")
    op.drop_index(op.f("ix_alert_deliveries_announcement_id"), table_name="alert_deliveries")
    op.drop_index(op.f("ix_alert_deliveries_team_id"), table_name="alert_deliveries")
    op.drop_table("alert_deliveries")

    op.drop_index(op.f("ix_user_push_devices_device_token"), table_name="user_push_devices")
    op.drop_index(op.f("ix_user_push_devices_user_id"), table_name="user_push_devices")
    op.drop_table("user_push_devices")

    bind = op.get_bind()
    alert_delivery_status.drop(bind, checkfirst=True)
    alert_delivery_channel.drop(bind, checkfirst=True)
