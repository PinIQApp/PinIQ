"""store and equipment ordering system

Revision ID: 20260415_0009
Revises: 20260415_0008
Create Date: 2026-04-15 00:09:00.000000
"""

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql


revision = "20260415_0009"
down_revision = "20260415_0008"
branch_labels = None
depends_on = None


def upgrade() -> None:
    stock_status = postgresql.ENUM("in_stock", "low_stock", "backordered", "out_of_stock", name="stockstatus", create_type=False)
    product_visibility = postgresql.ENUM("both", "team_only", "individual_only", name="productvisibility", create_type=False)
    order_status = postgresql.ENUM("pending", "paid", "processing", "shipped", "delivered", "cancelled", name="orderstatus", create_type=False)
    order_type = postgresql.ENUM("individual", "team_supply", name="ordertype", create_type=False)
    shipping_status = postgresql.ENUM(
        "not_applicable", "pending", "packed", "shipped", "delivered", "cancelled", name="shippingstatus", create_type=False
    )
    purchaser_role = postgresql.ENUM(
        "coach", "assistant_coach", "parent", "athlete", "admin", name="purchaserrole", create_type=False
    )

    bind = op.get_bind()
    stock_status.create(bind, checkfirst=True)
    product_visibility.create(bind, checkfirst=True)
    order_status.create(bind, checkfirst=True)
    order_type.create(bind, checkfirst=True)
    shipping_status.create(bind, checkfirst=True)
    purchaser_role.create(bind, checkfirst=True)

    op.create_table(
        "vendors",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("name", sa.String(length=140), nullable=False),
        sa.Column("code", sa.String(length=40), nullable=False),
        sa.Column("email", sa.String(length=255), nullable=True),
        sa.Column("phone", sa.String(length=30), nullable=True),
        sa.Column("website_url", sa.String(length=500), nullable=True),
        sa.Column("contact_name", sa.String(length=120), nullable=True),
        sa.Column("notes", sa.Text(), nullable=True),
        sa.Column("supports_dropship", sa.Boolean(), nullable=False, server_default=sa.true()),
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default=sa.true()),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.Column("updated_at", sa.DateTime(), nullable=False),
    )
    op.create_index("ix_vendors_name", "vendors", ["name"], unique=True)
    op.create_index("ix_vendors_code", "vendors", ["code"], unique=True)

    op.create_table(
        "product_categories",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("slug", sa.String(length=60), nullable=False),
        sa.Column("name", sa.String(length=80), nullable=False),
        sa.Column("description", sa.String(length=255), nullable=True),
        sa.Column("icon_name", sa.String(length=50), nullable=True),
        sa.Column("sort_order", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default=sa.true()),
        sa.Column("created_at", sa.DateTime(), nullable=False),
    )
    op.create_index("ix_product_categories_slug", "product_categories", ["slug"], unique=True)

    op.create_table(
        "products",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("category_id", sa.Integer(), sa.ForeignKey("product_categories.id"), nullable=False),
        sa.Column("vendor_id", sa.Integer(), sa.ForeignKey("vendors.id"), nullable=True),
        sa.Column("name", sa.String(length=160), nullable=False),
        sa.Column("description", sa.Text(), nullable=True),
        sa.Column("sku", sa.String(length=80), nullable=False),
        sa.Column("cost_price", sa.Numeric(10, 2), nullable=False, server_default="0"),
        sa.Column("sell_price", sa.Numeric(10, 2), nullable=False, server_default="0"),
        sa.Column("stock_status", stock_status, nullable=False),
        sa.Column("visibility", product_visibility, nullable=False),
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default=sa.true()),
        sa.Column("is_featured", sa.Boolean(), nullable=False, server_default=sa.false()),
        sa.Column("allow_backorder", sa.Boolean(), nullable=False, server_default=sa.false()),
        sa.Column("inventory_count", sa.Integer(), nullable=True),
        sa.Column("inventory_tracked", sa.Boolean(), nullable=False, server_default=sa.false()),
        sa.Column("image_url", sa.String(length=500), nullable=True),
        sa.Column("brand_name", sa.String(length=80), nullable=True),
        sa.Column("unit_label", sa.String(length=40), nullable=True),
        sa.Column("shipping_weight_oz", sa.Integer(), nullable=True),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.Column("updated_at", sa.DateTime(), nullable=False),
    )
    op.create_index("ix_products_category_id", "products", ["category_id"])
    op.create_index("ix_products_vendor_id", "products", ["vendor_id"])
    op.create_index("ix_products_name", "products", ["name"])
    op.create_index("ix_products_sku", "products", ["sku"], unique=True)

    op.create_table(
        "product_images",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("product_id", sa.Integer(), sa.ForeignKey("products.id"), nullable=False),
        sa.Column("image_url", sa.String(length=500), nullable=False),
        sa.Column("alt_text", sa.String(length=160), nullable=True),
        sa.Column("sort_order", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("created_at", sa.DateTime(), nullable=False),
    )
    op.create_index("ix_product_images_product_id", "product_images", ["product_id"])

    op.create_table(
        "team_store_configs",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("team_id", sa.Integer(), sa.ForeignKey("teams.id"), nullable=False),
        sa.Column("store_name", sa.String(length=160), nullable=False),
        sa.Column("store_tagline", sa.String(length=255), nullable=True),
        sa.Column("is_store_enabled", sa.Boolean(), nullable=False, server_default=sa.true()),
        sa.Column("allow_athlete_checkout", sa.Boolean(), nullable=False, server_default=sa.false()),
        sa.Column("school_gear_enabled", sa.Boolean(), nullable=False, server_default=sa.false()),
        sa.Column("featured_product_ids_csv", sa.Text(), nullable=True),
        sa.Column("enabled_category_ids_csv", sa.Text(), nullable=True),
        sa.Column("announcement_text", sa.Text(), nullable=True),
        sa.Column("created_by_user_id", sa.Integer(), sa.ForeignKey("users.id"), nullable=False),
        sa.Column("updated_by_user_id", sa.Integer(), sa.ForeignKey("users.id"), nullable=True),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.Column("updated_at", sa.DateTime(), nullable=False),
        sa.UniqueConstraint("team_id", name="uq_team_store_config_team_id"),
    )
    op.create_index("ix_team_store_configs_team_id", "team_store_configs", ["team_id"])

    op.create_table(
        "orders",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("team_id", sa.Integer(), sa.ForeignKey("teams.id"), nullable=False),
        sa.Column("purchaser_id", sa.Integer(), sa.ForeignKey("users.id"), nullable=False),
        sa.Column("purchaser_role", purchaser_role, nullable=False),
        sa.Column("order_type", order_type, nullable=False),
        sa.Column("status", order_status, nullable=False),
        sa.Column("shipping_status", shipping_status, nullable=False),
        sa.Column("subtotal", sa.Numeric(10, 2), nullable=False, server_default="0"),
        sa.Column("shipping_cost", sa.Numeric(10, 2), nullable=False, server_default="0"),
        sa.Column("total", sa.Numeric(10, 2), nullable=False, server_default="0"),
        sa.Column("notes", sa.Text(), nullable=True),
        sa.Column("shipping_address", sa.Text(), nullable=True),
        sa.Column("shipping_carrier", sa.String(length=80), nullable=True),
        sa.Column("tracking_number", sa.String(length=120), nullable=True),
        sa.Column("vendor_reference", sa.String(length=120), nullable=True),
        sa.Column("reordered_from_order_id", sa.Integer(), sa.ForeignKey("orders.id"), nullable=True),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.Column("updated_at", sa.DateTime(), nullable=False),
    )
    op.create_index("ix_orders_team_id", "orders", ["team_id"])
    op.create_index("ix_orders_purchaser_id", "orders", ["purchaser_id"])
    op.create_index("ix_orders_order_type", "orders", ["order_type"])

    op.create_table(
        "order_items",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("order_id", sa.Integer(), sa.ForeignKey("orders.id"), nullable=False),
        sa.Column("product_id", sa.Integer(), sa.ForeignKey("products.id"), nullable=False),
        sa.Column("vendor_id", sa.Integer(), sa.ForeignKey("vendors.id"), nullable=True),
        sa.Column("product_name_snapshot", sa.String(length=160), nullable=False),
        sa.Column("sku_snapshot", sa.String(length=80), nullable=False),
        sa.Column("quantity", sa.Integer(), nullable=False, server_default="1"),
        sa.Column("unit_cost_price", sa.Numeric(10, 2), nullable=False, server_default="0"),
        sa.Column("unit_sell_price", sa.Numeric(10, 2), nullable=False, server_default="0"),
        sa.Column("line_total", sa.Numeric(10, 2), nullable=False, server_default="0"),
        sa.Column("shipping_status", shipping_status, nullable=False),
        sa.Column("created_at", sa.DateTime(), nullable=False),
    )
    op.create_index("ix_order_items_order_id", "order_items", ["order_id"])
    op.create_index("ix_order_items_product_id", "order_items", ["product_id"])
    op.create_index("ix_order_items_vendor_id", "order_items", ["vendor_id"])

    op.create_table(
        "cart_items",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("team_id", sa.Integer(), sa.ForeignKey("teams.id"), nullable=False),
        sa.Column("user_id", sa.Integer(), sa.ForeignKey("users.id"), nullable=False),
        sa.Column("product_id", sa.Integer(), sa.ForeignKey("products.id"), nullable=False),
        sa.Column("order_type", order_type, nullable=False),
        sa.Column("quantity", sa.Integer(), nullable=False, server_default="1"),
        sa.Column("notes", sa.Text(), nullable=True),
        sa.Column("created_at", sa.DateTime(), nullable=False),
        sa.Column("updated_at", sa.DateTime(), nullable=False),
    )
    op.create_index("ix_cart_items_team_id", "cart_items", ["team_id"])
    op.create_index("ix_cart_items_user_id", "cart_items", ["user_id"])
    op.create_index("ix_cart_items_product_id", "cart_items", ["product_id"])
    op.create_index("ix_cart_items_order_type", "cart_items", ["order_type"])


def downgrade() -> None:
    op.drop_index("ix_cart_items_order_type", table_name="cart_items")
    op.drop_index("ix_cart_items_product_id", table_name="cart_items")
    op.drop_index("ix_cart_items_user_id", table_name="cart_items")
    op.drop_index("ix_cart_items_team_id", table_name="cart_items")
    op.drop_table("cart_items")

    op.drop_index("ix_order_items_vendor_id", table_name="order_items")
    op.drop_index("ix_order_items_product_id", table_name="order_items")
    op.drop_index("ix_order_items_order_id", table_name="order_items")
    op.drop_table("order_items")

    op.drop_index("ix_orders_order_type", table_name="orders")
    op.drop_index("ix_orders_purchaser_id", table_name="orders")
    op.drop_index("ix_orders_team_id", table_name="orders")
    op.drop_table("orders")

    op.drop_index("ix_team_store_configs_team_id", table_name="team_store_configs")
    op.drop_table("team_store_configs")

    op.drop_index("ix_product_images_product_id", table_name="product_images")
    op.drop_table("product_images")

    op.drop_index("ix_products_sku", table_name="products")
    op.drop_index("ix_products_name", table_name="products")
    op.drop_index("ix_products_vendor_id", table_name="products")
    op.drop_index("ix_products_category_id", table_name="products")
    op.drop_table("products")

    op.drop_index("ix_product_categories_slug", table_name="product_categories")
    op.drop_table("product_categories")

    op.drop_index("ix_vendors_code", table_name="vendors")
    op.drop_index("ix_vendors_name", table_name="vendors")
    op.drop_table("vendors")

    bind = op.get_bind()
    postgresql.ENUM(name="purchaserrole", create_type=False).drop(bind, checkfirst=True)
    postgresql.ENUM(name="shippingstatus", create_type=False).drop(bind, checkfirst=True)
    postgresql.ENUM(name="ordertype", create_type=False).drop(bind, checkfirst=True)
    postgresql.ENUM(name="orderstatus", create_type=False).drop(bind, checkfirst=True)
    postgresql.ENUM(name="productvisibility", create_type=False).drop(bind, checkfirst=True)
    postgresql.ENUM(name="stockstatus", create_type=False).drop(bind, checkfirst=True)
