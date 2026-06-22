"""add team member status

Revision ID: 20260414_0003
Revises: 20260414_0002
Create Date: 2026-04-14 00:12:00
"""

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql


revision = "20260414_0003"
down_revision = "20260414_0002"
branch_labels = None
depends_on = None


team_member_status_enum = postgresql.ENUM("pending", "approved", name="teammemberstatus", create_type=False)


def upgrade() -> None:
    team_member_status_enum.create(op.get_bind(), checkfirst=True)
    op.add_column("team_members", sa.Column("status", team_member_status_enum, nullable=True))
    op.execute("UPDATE team_members SET status = 'approved' WHERE status IS NULL")
    with op.batch_alter_table("team_members") as batch_op:
        batch_op.alter_column("status", nullable=False)


def downgrade() -> None:
    with op.batch_alter_table("team_members") as batch_op:
        batch_op.drop_column("status")
    team_member_status_enum.drop(op.get_bind(), checkfirst=True)
