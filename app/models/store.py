from __future__ import annotations
from typing import Optional

from datetime import datetime
from enum import Enum

from sqlalchemy import Boolean, DateTime, Enum as SqlEnum, ForeignKey, Integer, Numeric, String, Text, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.session import Base


class StockStatus(str, Enum):
    in_stock = "in_stock"
    low_stock = "low_stock"
    backordered = "backordered"
    out_of_stock = "out_of_stock"


class ProductVisibility(str, Enum):
    both = "both"
    team_only = "team_only"
    individual_only = "individual_only"


class OrderStatus(str, Enum):
    pending = "pending"
    paid = "paid"
    processing = "processing"
    shipped = "shipped"
    delivered = "delivered"
    cancelled = "cancelled"


class OrderType(str, Enum):
    individual = "individual"
    team_supply = "team_supply"


class ShippingStatus(str, Enum):
    not_applicable = "not_applicable"
    pending = "pending"
    packed = "packed"
    shipped = "shipped"
    delivered = "delivered"
    cancelled = "cancelled"


class PurchaserRole(str, Enum):
    coach = "coach"
    assistant_coach = "assistant_coach"
    parent = "parent"
    athlete = "athlete"
    admin = "admin"


class PaymentProvider(str, Enum):
    mock = "mock"
    stripe = "stripe"


class PaymentStatus(str, Enum):
    not_required = "not_required"
    pending_checkout = "pending_checkout"
    requires_action = "requires_action"
    paid = "paid"
    failed = "failed"
    refunded = "refunded"


class Vendor(Base):
    __tablename__ = "vendors"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    name: Mapped[str] = mapped_column(String(140), nullable=False, unique=True, index=True)
    code: Mapped[str] = mapped_column(String(40), nullable=False, unique=True, index=True)
    email: Mapped[Optional[str]] = mapped_column(String(255))
    phone: Mapped[Optional[str]] = mapped_column(String(30))
    website_url: Mapped[Optional[str]] = mapped_column(String(500))
    contact_name: Mapped[Optional[str]] = mapped_column(String(120))
    notes: Mapped[Optional[str]] = mapped_column(Text)
    supports_dropship: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False
    )

    products = relationship("Product", back_populates="vendor")


class ProductCategory(Base):
    __tablename__ = "product_categories"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    slug: Mapped[str] = mapped_column(String(60), nullable=False, unique=True, index=True)
    name: Mapped[str] = mapped_column(String(80), nullable=False)
    description: Mapped[Optional[str]] = mapped_column(String(255))
    icon_name: Mapped[Optional[str]] = mapped_column(String(50))
    sort_order: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, nullable=False)

    products = relationship("Product", back_populates="category")


class Product(Base):
    __tablename__ = "products"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    category_id: Mapped[int] = mapped_column(ForeignKey("product_categories.id"), nullable=False, index=True)
    vendor_id: Mapped[Optional[int]] = mapped_column(ForeignKey("vendors.id"), index=True)
    name: Mapped[str] = mapped_column(String(160), nullable=False, index=True)
    description: Mapped[Optional[str]] = mapped_column(Text)
    sku: Mapped[str] = mapped_column(String(80), nullable=False, unique=True, index=True)
    cost_price: Mapped[float] = mapped_column(Numeric(10, 2), nullable=False, default=0)
    sell_price: Mapped[float] = mapped_column(Numeric(10, 2), nullable=False, default=0)
    stock_status: Mapped[StockStatus] = mapped_column(
        SqlEnum(StockStatus), default=StockStatus.in_stock, nullable=False
    )
    visibility: Mapped[ProductVisibility] = mapped_column(
        SqlEnum(ProductVisibility), default=ProductVisibility.both, nullable=False
    )
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    is_featured: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    allow_backorder: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    inventory_count: Mapped[Optional[int]] = mapped_column(Integer)
    inventory_tracked: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    image_url: Mapped[Optional[str]] = mapped_column(String(500))
    brand_name: Mapped[Optional[str]] = mapped_column(String(80))
    unit_label: Mapped[Optional[str]] = mapped_column(String(40))
    shipping_weight_oz: Mapped[Optional[int]] = mapped_column(Integer)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False
    )

    category = relationship("ProductCategory", back_populates="products")
    vendor = relationship("Vendor", back_populates="products")
    images = relationship("ProductImage", back_populates="product", cascade="all, delete-orphan")
    order_items = relationship("OrderItem", back_populates="product")
    cart_items = relationship("CartItem", back_populates="product")


class ProductImage(Base):
    __tablename__ = "product_images"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    product_id: Mapped[int] = mapped_column(ForeignKey("products.id"), nullable=False, index=True)
    image_url: Mapped[str] = mapped_column(String(500), nullable=False)
    alt_text: Mapped[Optional[str]] = mapped_column(String(160))
    sort_order: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, nullable=False)

    product = relationship("Product", back_populates="images")


class TeamStoreConfig(Base):
    __tablename__ = "team_store_configs"
    __table_args__ = (UniqueConstraint("team_id", name="uq_team_store_config_team_id"),)

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    team_id: Mapped[int] = mapped_column(ForeignKey("teams.id"), nullable=False, index=True)
    store_name: Mapped[str] = mapped_column(String(160), nullable=False)
    store_tagline: Mapped[Optional[str]] = mapped_column(String(255))
    is_store_enabled: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    allow_athlete_checkout: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    school_gear_enabled: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    featured_product_ids_csv: Mapped[Optional[str]] = mapped_column(Text)
    enabled_category_ids_csv: Mapped[Optional[str]] = mapped_column(Text)
    announcement_text: Mapped[Optional[str]] = mapped_column(Text)
    created_by_user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), nullable=False)
    updated_by_user_id: Mapped[Optional[int]] = mapped_column(ForeignKey("users.id"))
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False
    )

    team = relationship("Team")
    created_by = relationship("User", foreign_keys=[created_by_user_id])
    updated_by = relationship("User", foreign_keys=[updated_by_user_id])


class Order(Base):
    __tablename__ = "orders"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    team_id: Mapped[int] = mapped_column(ForeignKey("teams.id"), nullable=False, index=True)
    purchaser_id: Mapped[int] = mapped_column(ForeignKey("users.id"), nullable=False, index=True)
    purchaser_role: Mapped[PurchaserRole] = mapped_column(SqlEnum(PurchaserRole), nullable=False)
    order_type: Mapped[OrderType] = mapped_column(SqlEnum(OrderType), nullable=False, index=True)
    status: Mapped[OrderStatus] = mapped_column(SqlEnum(OrderStatus), default=OrderStatus.pending, nullable=False)
    shipping_status: Mapped[ShippingStatus] = mapped_column(
        SqlEnum(ShippingStatus), default=ShippingStatus.pending, nullable=False
    )
    subtotal: Mapped[float] = mapped_column(Numeric(10, 2), nullable=False, default=0)
    shipping_cost: Mapped[float] = mapped_column(Numeric(10, 2), nullable=False, default=0)
    total: Mapped[float] = mapped_column(Numeric(10, 2), nullable=False, default=0)
    notes: Mapped[Optional[str]] = mapped_column(Text)
    shipping_address: Mapped[Optional[str]] = mapped_column(Text)
    shipping_carrier: Mapped[Optional[str]] = mapped_column(String(80))
    tracking_number: Mapped[Optional[str]] = mapped_column(String(120))
    vendor_reference: Mapped[Optional[str]] = mapped_column(String(120))
    payment_provider: Mapped[PaymentProvider] = mapped_column(
        SqlEnum(PaymentProvider), default=PaymentProvider.mock, nullable=False
    )
    payment_status: Mapped[PaymentStatus] = mapped_column(
        SqlEnum(PaymentStatus), default=PaymentStatus.pending_checkout, nullable=False
    )
    payment_reference: Mapped[Optional[str]] = mapped_column(String(255))
    payment_checkout_url: Mapped[Optional[str]] = mapped_column(String(500))
    payment_client_secret: Mapped[Optional[str]] = mapped_column(String(255))
    paid_at: Mapped[Optional[datetime]] = mapped_column(DateTime)
    reordered_from_order_id: Mapped[Optional[int]] = mapped_column(ForeignKey("orders.id"))
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False
    )

    team = relationship("Team")
    purchaser = relationship("User", foreign_keys=[purchaser_id])
    items = relationship("OrderItem", back_populates="order", cascade="all, delete-orphan")
    reordered_from = relationship("Order", remote_side=[id])
    webhook_events = relationship("PaymentWebhookEvent", back_populates="order", cascade="all, delete-orphan")


class OrderItem(Base):
    __tablename__ = "order_items"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    order_id: Mapped[int] = mapped_column(ForeignKey("orders.id"), nullable=False, index=True)
    product_id: Mapped[int] = mapped_column(ForeignKey("products.id"), nullable=False, index=True)
    vendor_id: Mapped[Optional[int]] = mapped_column(ForeignKey("vendors.id"), index=True)
    product_name_snapshot: Mapped[str] = mapped_column(String(160), nullable=False)
    sku_snapshot: Mapped[str] = mapped_column(String(80), nullable=False)
    quantity: Mapped[int] = mapped_column(Integer, nullable=False, default=1)
    unit_cost_price: Mapped[float] = mapped_column(Numeric(10, 2), nullable=False, default=0)
    unit_sell_price: Mapped[float] = mapped_column(Numeric(10, 2), nullable=False, default=0)
    line_total: Mapped[float] = mapped_column(Numeric(10, 2), nullable=False, default=0)
    shipping_status: Mapped[ShippingStatus] = mapped_column(
        SqlEnum(ShippingStatus), default=ShippingStatus.pending, nullable=False
    )
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, nullable=False)

    order = relationship("Order", back_populates="items")
    product = relationship("Product", back_populates="order_items")
    vendor = relationship("Vendor")


class CartItem(Base):
    __tablename__ = "cart_items"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    team_id: Mapped[int] = mapped_column(ForeignKey("teams.id"), nullable=False, index=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), nullable=False, index=True)
    product_id: Mapped[int] = mapped_column(ForeignKey("products.id"), nullable=False, index=True)
    order_type: Mapped[OrderType] = mapped_column(SqlEnum(OrderType), nullable=False, index=True)
    quantity: Mapped[int] = mapped_column(Integer, nullable=False, default=1)
    notes: Mapped[Optional[str]] = mapped_column(Text)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False
    )

    team = relationship("Team")
    user = relationship("User")
    product = relationship("Product", back_populates="cart_items")


class PaymentWebhookEvent(Base):
    __tablename__ = "payment_webhook_events"
    __table_args__ = (UniqueConstraint("provider", "event_id", name="uq_payment_webhook_provider_event"),)

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    order_id: Mapped[Optional[int]] = mapped_column(ForeignKey("orders.id"), nullable=True, index=True)
    provider: Mapped[PaymentProvider] = mapped_column(SqlEnum(PaymentProvider), nullable=False, index=True)
    event_id: Mapped[str] = mapped_column(String(255), nullable=False)
    event_type: Mapped[str] = mapped_column(String(120), nullable=False)
    payload_json: Mapped[Optional[str]] = mapped_column(Text)
    processed_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, nullable=False)

    order = relationship("Order", back_populates="webhook_events")
