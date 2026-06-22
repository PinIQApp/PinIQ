"""add team join code

Revision ID: 20260414_0002
Revises: 20260414_0001
Create Date: 2026-04-14 00:05:00
"""

from alembic import op
import sqlalchemy as sa


revision = "20260414_0002"
down_revision = "20260414_0001"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column("teams", sa.Column("join_code", sa.String(length=12), nullable=True))
    op.execute("UPDATE teams SET join_code = 'RHS2026' WHERE join_code IS NULL")
    with op.batch_alter_table("teams") as batch_op:
        batch_op.alter_column("join_code", nullable=False)
    op.create_index(op.f("ix_teams_join_code"), "teams", ["join_code"], unique=True)


def downgrade() -> None:
    op.drop_index(op.f("ix_teams_join_code"), table_name="teams")
    with op.batch_alter_table("teams") as batch_op:
        batch_op.drop_column("join_code")
