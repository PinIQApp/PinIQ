"""storage and payment groundwork

Revision ID: 20260415_0016
Revises: 20260415_0015
Create Date: 2026-04-15 14:30:00.000000
"""

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql


revision = "20260415_0016"
down_revision = "20260415_0015"
branch_labels = None
depends_on = None


def upgrade() -> None:
    payment_provider = postgresql.ENUM("mock", "stripe", name="paymentprovider", create_type=False)
    payment_status = postgresql.ENUM(
        "not_required",
        "pending_checkout",
        "requires_action",
        "paid",
        "failed",
        "refunded",
        name="paymentstatus", create_type=False
    )
    bind = op.get_bind()
    payment_provider.create(bind, checkfirst=True)
    payment_status.create(bind, checkfirst=True)

    op.add_column("orders", sa.Column("payment_provider", payment_provider, nullable=False, server_default="mock"))
    op.add_column(
        "orders",
        sa.Column("payment_status", payment_status, nullable=False, server_default="pending_checkout"),
    )
    op.add_column("orders", sa.Column("payment_reference", sa.String(length=255), nullable=True))
    op.add_column("orders", sa.Column("payment_checkout_url", sa.String(length=500), nullable=True))
    op.add_column("orders", sa.Column("payment_client_secret", sa.String(length=255), nullable=True))
    op.add_column("orders", sa.Column("paid_at", sa.DateTime(), nullable=True))

    op.create_table(
        "payment_webhook_events",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("order_id", sa.Integer(), sa.ForeignKey("orders.id"), nullable=True),
        sa.Column("provider", payment_provider, nullable=False),
        sa.Column("event_id", sa.String(length=255), nullable=False),
        sa.Column("event_type", sa.String(length=120), nullable=False),
        sa.Column("payload_json", sa.Text(), nullable=True),
        sa.Column("processed_at", sa.DateTime(), nullable=False),
        sa.UniqueConstraint("provider", "event_id", name="uq_payment_webhook_provider_event"),
    )
    op.create_index("ix_payment_webhook_events_order_id", "payment_webhook_events", ["order_id"])
    op.create_index("ix_payment_webhook_events_provider", "payment_webhook_events", ["provider"])


def downgrade() -> None:
    op.drop_index("ix_payment_webhook_events_provider", table_name="payment_webhook_events")
    op.drop_index("ix_payment_webhook_events_order_id", table_name="payment_webhook_events")
    op.drop_table("payment_webhook_events")

    op.drop_column("orders", "paid_at")
    op.drop_column("orders", "payment_client_secret")
    op.drop_column("orders", "payment_checkout_url")
    op.drop_column("orders", "payment_reference")
    op.drop_column("orders", "payment_status")
    op.drop_column("orders", "payment_provider")

    payment_status = postgresql.ENUM(
        "not_required",
        "pending_checkout",
        "requires_action",
        "paid",
        "failed",
        "refunded",
        name="paymentstatus", create_type=False
    )
    payment_provider = postgresql.ENUM("mock", "stripe", name="paymentprovider", create_type=False)
    bind = op.get_bind()
    payment_status.drop(bind, checkfirst=True)
    payment_provider.drop(bind, checkfirst=True)
