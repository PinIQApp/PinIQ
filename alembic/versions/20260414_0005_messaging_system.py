"""add messaging and compliance tables

Revision ID: 20260414_0005
Revises: 20260414_0004
Create Date: 2026-04-14 00:05:00
"""

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql


revision = "20260414_0005"
down_revision = "20260414_0004"
branch_labels = None
depends_on = None


message_thread_type = postgresql.ENUM("announcement", "group", "direct", name="messagethreadtype", create_type=False)
message_participant_type = postgresql.ENUM("member", "parent_visibility", name="messageparticipanttype", create_type=False)
message_type = postgresql.ENUM("text", "announcement", "compliance_note", name="messagetype", create_type=False)
audit_action = postgresql.ENUM(
    "thread_created",
    "announcement_sent",
    "message_sent",
    "message_edited",
    "message_soft_deleted",
    "thread_exported",
    "parent_link_created",
    name="auditaction", create_type=False
)


def upgrade() -> None:
    bind = op.get_bind()
    message_thread_type.create(bind, checkfirst=True)
    message_participant_type.create(bind, checkfirst=True)
    message_type.create(bind, checkfirst=True)
    audit_action.create(bind, checkfirst=True)

    op.create_table(
        "message_threads",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("team_id", sa.Integer(), nullable=False),
        sa.Column("title", sa.String(length=160), nullable=False),
        sa.Column("thread_type", message_thread_type, nullable=False),
        sa.Column("created_by_user_id", sa.Integer(), nullable=False),
        sa.Column("parent_visibility_required", sa.Boolean(), nullable=False, server_default=sa.false()),
        sa.Column("is_compliance_locked", sa.Boolean(), nullable=False, server_default=sa.false()),
        sa.Column("is_deleted", sa.Boolean(), nullable=False, server_default=sa.false()),
        sa.Column("visibility_flags", sa.JSON(), nullable=True),
        sa.Column("audit_version", sa.Integer(), nullable=False, server_default="1"),
        sa.Column("last_message_at", sa.DateTime(), nullable=False),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.Column("updated_at", sa.DateTime(), nullable=False),
        sa.ForeignKeyConstraint(["team_id"], ["teams.id"]),
        sa.ForeignKeyConstraint(["created_by_user_id"], ["users.id"]),
    )
    op.create_index(op.f("ix_message_threads_id"), "message_threads", ["id"], unique=False)
    op.create_index(op.f("ix_message_threads_team_id"), "message_threads", ["team_id"], unique=False)

    op.create_table(
        "message_participants",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("thread_id", sa.Integer(), nullable=False),
        sa.Column("team_id", sa.Integer(), nullable=False),
        sa.Column("user_id", sa.Integer(), nullable=False),
        sa.Column("participant_type", message_participant_type, nullable=False),
        sa.Column("visibility_flags", sa.JSON(), nullable=True),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.ForeignKeyConstraint(["thread_id"], ["message_threads.id"]),
        sa.ForeignKeyConstraint(["team_id"], ["teams.id"]),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"]),
        sa.UniqueConstraint("thread_id", "user_id", name="uq_thread_participant_user"),
    )
    op.create_index(op.f("ix_message_participants_thread_id"), "message_participants", ["thread_id"], unique=False)
    op.create_index(op.f("ix_message_participants_team_id"), "message_participants", ["team_id"], unique=False)
    op.create_index(op.f("ix_message_participants_user_id"), "message_participants", ["user_id"], unique=False)

    op.create_table(
        "messages",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("thread_id", sa.Integer(), nullable=False),
        sa.Column("team_id", sa.Integer(), nullable=False),
        sa.Column("sender_id", sa.Integer(), nullable=False),
        sa.Column("body", sa.Text(), nullable=False),
        sa.Column("message_type", message_type, nullable=False),
        sa.Column("visibility_flags", sa.JSON(), nullable=True),
        sa.Column("audit_version", sa.Integer(), nullable=False, server_default="1"),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.Column("updated_at", sa.DateTime(), nullable=False),
        sa.Column("edited_at", sa.DateTime(), nullable=True),
        sa.Column("deleted_at", sa.DateTime(), nullable=True),
        sa.Column("deleted_by_user_id", sa.Integer(), nullable=True),
        sa.ForeignKeyConstraint(["thread_id"], ["message_threads.id"]),
        sa.ForeignKeyConstraint(["team_id"], ["teams.id"]),
        sa.ForeignKeyConstraint(["sender_id"], ["users.id"]),
        sa.ForeignKeyConstraint(["deleted_by_user_id"], ["users.id"]),
    )
    op.create_index(op.f("ix_messages_thread_id"), "messages", ["thread_id"], unique=False)
    op.create_index(op.f("ix_messages_team_id"), "messages", ["team_id"], unique=False)
    op.create_index(op.f("ix_messages_sender_id"), "messages", ["sender_id"], unique=False)

    op.create_table(
        "announcements",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("thread_id", sa.Integer(), nullable=False),
        sa.Column("team_id", sa.Integer(), nullable=False),
        sa.Column("sender_id", sa.Integer(), nullable=False),
        sa.Column("title", sa.String(length=160), nullable=False),
        sa.Column("body", sa.Text(), nullable=False),
        sa.Column("audience_label", sa.String(length=60), nullable=False),
        sa.Column("visibility_flags", sa.JSON(), nullable=True),
        sa.Column("audit_version", sa.Integer(), nullable=False, server_default="1"),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.Column("updated_at", sa.DateTime(), nullable=False),
        sa.ForeignKeyConstraint(["thread_id"], ["message_threads.id"]),
        sa.ForeignKeyConstraint(["team_id"], ["teams.id"]),
        sa.ForeignKeyConstraint(["sender_id"], ["users.id"]),
        sa.UniqueConstraint("thread_id"),
    )
    op.create_index(op.f("ix_announcements_thread_id"), "announcements", ["thread_id"], unique=True)
    op.create_index(op.f("ix_announcements_team_id"), "announcements", ["team_id"], unique=False)
    op.create_index(op.f("ix_announcements_sender_id"), "announcements", ["sender_id"], unique=False)

    op.create_table(
        "message_audit_logs",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("team_id", sa.Integer(), nullable=False),
        sa.Column("thread_id", sa.Integer(), nullable=True),
        sa.Column("message_id", sa.Integer(), nullable=True),
        sa.Column("announcement_id", sa.Integer(), nullable=True),
        sa.Column("actor_id", sa.Integer(), nullable=False),
        sa.Column("action", audit_action, nullable=False),
        sa.Column("entity_type", sa.String(length=40), nullable=False),
        sa.Column("entity_id", sa.Integer(), nullable=False),
        sa.Column("before_state", sa.JSON(), nullable=True),
        sa.Column("after_state", sa.JSON(), nullable=True),
        sa.Column("visibility_flags", sa.JSON(), nullable=True),
        sa.Column("compliance_note", sa.String(length=255), nullable=True),
        sa.Column("audit_version", sa.Integer(), nullable=False, server_default="1"),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.ForeignKeyConstraint(["team_id"], ["teams.id"]),
        sa.ForeignKeyConstraint(["thread_id"], ["message_threads.id"]),
        sa.ForeignKeyConstraint(["message_id"], ["messages.id"]),
        sa.ForeignKeyConstraint(["announcement_id"], ["announcements.id"]),
        sa.ForeignKeyConstraint(["actor_id"], ["users.id"]),
    )
    op.create_index(op.f("ix_message_audit_logs_team_id"), "message_audit_logs", ["team_id"], unique=False)
    op.create_index(op.f("ix_message_audit_logs_thread_id"), "message_audit_logs", ["thread_id"], unique=False)
    op.create_index(op.f("ix_message_audit_logs_message_id"), "message_audit_logs", ["message_id"], unique=False)
    op.create_index(op.f("ix_message_audit_logs_announcement_id"), "message_audit_logs", ["announcement_id"], unique=False)
    op.create_index(op.f("ix_message_audit_logs_actor_id"), "message_audit_logs", ["actor_id"], unique=False)

    op.create_table(
        "parent_links",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("team_id", sa.Integer(), nullable=False),
        sa.Column("parent_user_id", sa.Integer(), nullable=False),
        sa.Column("athlete_user_id", sa.Integer(), nullable=False),
        sa.Column("relationship_label", sa.String(length=60), nullable=False),
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default=sa.true()),
        sa.Column("visibility_flags", sa.JSON(), nullable=True),
        sa.Column("audit_version", sa.Integer(), nullable=False, server_default="1"),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.Column("updated_at", sa.DateTime(), nullable=False),
        sa.ForeignKeyConstraint(["team_id"], ["teams.id"]),
        sa.ForeignKeyConstraint(["parent_user_id"], ["users.id"]),
        sa.ForeignKeyConstraint(["athlete_user_id"], ["users.id"]),
        sa.UniqueConstraint("team_id", "parent_user_id", "athlete_user_id", name="uq_parent_link"),
    )
    op.create_index(op.f("ix_parent_links_team_id"), "parent_links", ["team_id"], unique=False)
    op.create_index(op.f("ix_parent_links_parent_user_id"), "parent_links", ["parent_user_id"], unique=False)
    op.create_index(op.f("ix_parent_links_athlete_user_id"), "parent_links", ["athlete_user_id"], unique=False)


def downgrade() -> None:
    op.drop_index(op.f("ix_parent_links_athlete_user_id"), table_name="parent_links")
    op.drop_index(op.f("ix_parent_links_parent_user_id"), table_name="parent_links")
    op.drop_index(op.f("ix_parent_links_team_id"), table_name="parent_links")
    op.drop_table("parent_links")

    op.drop_index(op.f("ix_message_audit_logs_actor_id"), table_name="message_audit_logs")
    op.drop_index(op.f("ix_message_audit_logs_announcement_id"), table_name="message_audit_logs")
    op.drop_index(op.f("ix_message_audit_logs_message_id"), table_name="message_audit_logs")
    op.drop_index(op.f("ix_message_audit_logs_thread_id"), table_name="message_audit_logs")
    op.drop_index(op.f("ix_message_audit_logs_team_id"), table_name="message_audit_logs")
    op.drop_table("message_audit_logs")

    op.drop_index(op.f("ix_announcements_sender_id"), table_name="announcements")
    op.drop_index(op.f("ix_announcements_team_id"), table_name="announcements")
    op.drop_index(op.f("ix_announcements_thread_id"), table_name="announcements")
    op.drop_table("announcements")

    op.drop_index(op.f("ix_messages_sender_id"), table_name="messages")
    op.drop_index(op.f("ix_messages_team_id"), table_name="messages")
    op.drop_index(op.f("ix_messages_thread_id"), table_name="messages")
    op.drop_table("messages")

    op.drop_index(op.f("ix_message_participants_user_id"), table_name="message_participants")
    op.drop_index(op.f("ix_message_participants_team_id"), table_name="message_participants")
    op.drop_index(op.f("ix_message_participants_thread_id"), table_name="message_participants")
    op.drop_table("message_participants")

    op.drop_index(op.f("ix_message_threads_team_id"), table_name="message_threads")
    op.drop_index(op.f("ix_message_threads_id"), table_name="message_threads")
    op.drop_table("message_threads")

    bind = op.get_bind()
    audit_action.drop(bind, checkfirst=True)
    message_type.drop(bind, checkfirst=True)
    message_participant_type.drop(bind, checkfirst=True)
    message_thread_type.drop(bind, checkfirst=True)
