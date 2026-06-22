"""add athlete profile fields

Revision ID: 20260414_0004
Revises: 20260414_0003
Create Date: 2026-04-14 00:04:00
"""

from alembic import op
import sqlalchemy as sa


revision = "20260414_0004"
down_revision = "20260414_0003"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column("users", sa.Column("profile_image_url", sa.String(length=500), nullable=True))
    op.add_column("users", sa.Column("hometown", sa.String(length=120), nullable=True))
    op.add_column("users", sa.Column("graduation_year", sa.Integer(), nullable=True))
    op.add_column("users", sa.Column("weight_class", sa.String(length=30), nullable=True))
    op.add_column("users", sa.Column("bio", sa.String(length=500), nullable=True))


def downgrade() -> None:
    op.drop_column("users", "bio")
    op.drop_column("users", "weight_class")
    op.drop_column("users", "graduation_year")
    op.drop_column("users", "hometown")
    op.drop_column("users", "profile_image_url")
