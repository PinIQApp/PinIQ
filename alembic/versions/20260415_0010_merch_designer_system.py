"""merch designer system

Revision ID: 20260415_0010
Revises: 20260415_0009
Create Date: 2026-04-15 00:10:00.000000
"""

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql


revision = "20260415_0010"
down_revision = "20260415_0009"
branch_labels = None
depends_on = None


def upgrade() -> None:
    merch_product_type = postgresql.ENUM(
        "hoodie",
        "t_shirt",
        "joggers",
        "quarter_zip",
        "warm_up_set",
        "singlet",
        "fight_shorts",
        "compression_shirt",
        "fan_merch",
        name="merchproducttype", create_type=False
    )
    merch_layer_type = postgresql.ENUM("logo", "mascot", "text", "sponsor", "accent", name="merchlayertype", create_type=False)
    merch_placement = postgresql.ENUM(
        "front",
        "back",
        "left_sleeve",
        "right_sleeve",
        "left_leg",
        "right_leg",
        "side",
        "chest",
        "lower_back",
        name="merchplacement", create_type=False
    )
    merch_export_status = postgresql.ENUM("draft", "queued", "ready", "failed", name="merchexportstatus", create_type=False)
    merch_export_type = postgresql.ENUM(
        "preview_image",
        "print_layout",
        "manufacturer_sheet",
        name="merchexporttype", create_type=False
    )

    bind = op.get_bind()
    merch_product_type.create(bind, checkfirst=True)
    merch_layer_type.create(bind, checkfirst=True)
    merch_placement.create(bind, checkfirst=True)
    merch_export_status.create(bind, checkfirst=True)
    merch_export_type.create(bind, checkfirst=True)

    op.create_table(
        "merch_products",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("product_type", merch_product_type, nullable=False),
        sa.Column("slug", sa.String(length=80), nullable=False),
        sa.Column("name", sa.String(length=120), nullable=False),
        sa.Column("description", sa.Text(), nullable=True),
        sa.Column("base_price", sa.Numeric(10, 2), nullable=False, server_default="0"),
        sa.Column("supported_views_csv", sa.String(length=120), nullable=False, server_default="front,back,side"),
        sa.Column("colorways_csv", sa.Text(), nullable=True),
        sa.Column("supports_sleeve_print", sa.Boolean(), nullable=False, server_default=sa.false()),
        sa.Column("supports_back_print", sa.Boolean(), nullable=False, server_default=sa.true()),
        sa.Column("supports_sponsor_area", sa.Boolean(), nullable=False, server_default=sa.true()),
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default=sa.true()),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.Column("updated_at", sa.DateTime(), nullable=False),
        sa.UniqueConstraint("product_type", name="uq_merch_products_product_type"),
    )
    op.create_index("ix_merch_products_slug", "merch_products", ["slug"], unique=True)

    op.create_table(
        "merch_templates",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("key", sa.String(length=80), nullable=False),
        sa.Column("name", sa.String(length=120), nullable=False),
        sa.Column("description", sa.Text(), nullable=False),
        sa.Column("style_notes", sa.Text(), nullable=True),
        sa.Column("recommended_product_types_csv", sa.Text(), nullable=True),
        sa.Column("default_primary_color", sa.String(length=7), nullable=True),
        sa.Column("default_secondary_color", sa.String(length=7), nullable=True),
        sa.Column("default_accent_color", sa.String(length=7), nullable=True),
        sa.Column("default_layer_schema", sa.Text(), nullable=True),
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default=sa.true()),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.Column("updated_at", sa.DateTime(), nullable=False),
    )
    op.create_index("ix_merch_templates_key", "merch_templates", ["key"], unique=True)

    op.create_table(
        "team_merch_configs",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("team_id", sa.Integer(), sa.ForeignKey("teams.id"), nullable=False),
        sa.Column("school_name", sa.String(length=140), nullable=False),
        sa.Column("mascot", sa.String(length=120), nullable=False),
        sa.Column("school_colors_csv", sa.Text(), nullable=True),
        sa.Column("primary_logo_url", sa.String(length=500), nullable=True),
        sa.Column("secondary_logo_url", sa.String(length=500), nullable=True),
        sa.Column("alternate_wordmark_url", sa.String(length=500), nullable=True),
        sa.Column("sponsor_text_default", sa.String(length=120), nullable=True),
        sa.Column("gallery_title", sa.String(length=160), nullable=True),
        sa.Column("coach_notes", sa.Text(), nullable=True),
        sa.Column("created_by_user_id", sa.Integer(), sa.ForeignKey("users.id"), nullable=False),
        sa.Column("updated_by_user_id", sa.Integer(), sa.ForeignKey("users.id"), nullable=True),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.Column("updated_at", sa.DateTime(), nullable=False),
        sa.UniqueConstraint("team_id", name="uq_team_merch_config_team_id"),
    )
    op.create_index("ix_team_merch_configs_team_id", "team_merch_configs", ["team_id"])

    op.create_table(
        "merch_designs",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("team_id", sa.Integer(), sa.ForeignKey("teams.id"), nullable=False),
        sa.Column("created_by_user_id", sa.Integer(), sa.ForeignKey("users.id"), nullable=False),
        sa.Column("merch_product_id", sa.Integer(), sa.ForeignKey("merch_products.id"), nullable=False),
        sa.Column("merch_template_id", sa.Integer(), sa.ForeignKey("merch_templates.id"), nullable=True),
        sa.Column("team_merch_config_id", sa.Integer(), sa.ForeignKey("team_merch_configs.id"), nullable=True),
        sa.Column("design_name", sa.String(length=160), nullable=False),
        sa.Column("template_name", sa.String(length=120), nullable=True),
        sa.Column("primary_color", sa.String(length=7), nullable=False),
        sa.Column("secondary_color", sa.String(length=7), nullable=False),
        sa.Column("accent_color", sa.String(length=7), nullable=True),
        sa.Column("colorway_name", sa.String(length=80), nullable=True),
        sa.Column("front_logo_url", sa.String(length=500), nullable=True),
        sa.Column("back_logo_url", sa.String(length=500), nullable=True),
        sa.Column("front_text", sa.String(length=120), nullable=True),
        sa.Column("back_text", sa.String(length=120), nullable=True),
        sa.Column("sleeve_text", sa.String(length=80), nullable=True),
        sa.Column("sponsor_text", sa.String(length=120), nullable=True),
        sa.Column("notes", sa.Text(), nullable=True),
        sa.Column("preview_state", sa.Text(), nullable=True),
        sa.Column("preview_image_url", sa.String(length=500), nullable=True),
        sa.Column("print_layout_url", sa.String(length=500), nullable=True),
        sa.Column("manufacturer_sheet_url", sa.String(length=500), nullable=True),
        sa.Column("export_status", merch_export_status, nullable=False, server_default="draft"),
        sa.Column("is_published", sa.Boolean(), nullable=False, server_default=sa.false()),
        sa.Column("published_at", sa.DateTime(), nullable=True),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.Column("updated_at", sa.DateTime(), nullable=False),
    )
    op.create_index("ix_merch_designs_team_id", "merch_designs", ["team_id"])
    op.create_index("ix_merch_designs_created_by_user_id", "merch_designs", ["created_by_user_id"])
    op.create_index("ix_merch_designs_merch_product_id", "merch_designs", ["merch_product_id"])
    op.create_index("ix_merch_designs_merch_template_id", "merch_designs", ["merch_template_id"])
    op.create_index("ix_merch_designs_team_merch_config_id", "merch_designs", ["team_merch_config_id"])

    op.create_table(
        "merch_design_layers",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("merch_design_id", sa.Integer(), sa.ForeignKey("merch_designs.id"), nullable=False),
        sa.Column("layer_type", merch_layer_type, nullable=False),
        sa.Column("placement", merch_placement, nullable=False),
        sa.Column("asset_url", sa.String(length=500), nullable=True),
        sa.Column("text_content", sa.String(length=160), nullable=True),
        sa.Column("text_style", sa.String(length=80), nullable=True),
        sa.Column("color_hex", sa.String(length=7), nullable=True),
        sa.Column("sort_order", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("visible", sa.Boolean(), nullable=False, server_default=sa.true()),
        sa.Column("layer_metadata", sa.Text(), nullable=True),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.Column("updated_at", sa.DateTime(), nullable=False),
    )
    op.create_index("ix_merch_design_layers_merch_design_id", "merch_design_layers", ["merch_design_id"])

    op.create_table(
        "merch_exports",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("merch_design_id", sa.Integer(), sa.ForeignKey("merch_designs.id"), nullable=False),
        sa.Column("requested_by_user_id", sa.Integer(), sa.ForeignKey("users.id"), nullable=False),
        sa.Column("export_type", merch_export_type, nullable=False),
        sa.Column("status", merch_export_status, nullable=False, server_default="queued"),
        sa.Column("file_url", sa.String(length=500), nullable=True),
        sa.Column("notes", sa.Text(), nullable=True),
        sa.Column("requested_at", sa.DateTime(), nullable=False),
        sa.Column("completed_at", sa.DateTime(), nullable=True),
    )
    op.create_index("ix_merch_exports_merch_design_id", "merch_exports", ["merch_design_id"])


def downgrade() -> None:
    op.drop_index("ix_merch_exports_merch_design_id", table_name="merch_exports")
    op.drop_table("merch_exports")

    op.drop_index("ix_merch_design_layers_merch_design_id", table_name="merch_design_layers")
    op.drop_table("merch_design_layers")

    op.drop_index("ix_merch_designs_team_merch_config_id", table_name="merch_designs")
    op.drop_index("ix_merch_designs_merch_template_id", table_name="merch_designs")
    op.drop_index("ix_merch_designs_merch_product_id", table_name="merch_designs")
    op.drop_index("ix_merch_designs_created_by_user_id", table_name="merch_designs")
    op.drop_index("ix_merch_designs_team_id", table_name="merch_designs")
    op.drop_table("merch_designs")

    op.drop_index("ix_team_merch_configs_team_id", table_name="team_merch_configs")
    op.drop_table("team_merch_configs")

    op.drop_index("ix_merch_templates_key", table_name="merch_templates")
    op.drop_table("merch_templates")

    op.drop_index("ix_merch_products_slug", table_name="merch_products")
    op.drop_table("merch_products")

    bind = op.get_bind()
    postgresql.ENUM(name="merchexporttype", create_type=False).drop(bind, checkfirst=True)
    postgresql.ENUM(name="merchexportstatus", create_type=False).drop(bind, checkfirst=True)
    postgresql.ENUM(name="merchplacement", create_type=False).drop(bind, checkfirst=True)
    postgresql.ENUM(name="merchlayertype", create_type=False).drop(bind, checkfirst=True)
    postgresql.ENUM(name="merchproducttype", create_type=False).drop(bind, checkfirst=True)
