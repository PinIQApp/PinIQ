from __future__ import annotations

from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field, computed_field

from app.models.store import (
    OrderStatus,
    OrderType,
    PaymentProvider,
    PaymentStatus,
    ProductVisibility,
    PurchaserRole,
    ShippingStatus,
    StockStatus,
)


class StoreCategoryRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    slug: str
    name: str
    description: str | None
    icon_name: str | None
    sort_order: int
    is_active: bool


class ProductImageRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    image_url: str
    alt_text: str | None
    sort_order: int


class VendorRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    name: str
    code: str
    website_url: str | None
    supports_dropship: bool


class ProductRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    category_id: int
    vendor_id: int | None
    name: str
    description: str | None
    sku: str
    cost_price: float
    sell_price: float
    stock_status: StockStatus
    visibility: ProductVisibility
    is_active: bool
    is_featured: bool
    allow_backorder: bool
    inventory_count: int | None
    inventory_tracked: bool
    image_url: str | None
    brand_name: str | None
    unit_label: str | None
    shipping_weight_oz: int | None
    created_at: datetime
    updated_at: datetime
    category: StoreCategoryRead | None = None
    vendor: VendorRead | None = None
    images: list[ProductImageRead] = []

    @computed_field
    @property
    def margin_amount(self) -> float:
        return round(self.sell_price - self.cost_price, 2)


class TeamStoreConfigUpsert(BaseModel):
    store_name: str = Field(min_length=2, max_length=160)
    store_tagline: str | None = Field(default=None, max_length=255)
    is_store_enabled: bool = True
    allow_athlete_checkout: bool = False
    school_gear_enabled: bool = False
    featured_product_ids: list[int] = Field(default_factory=list)
    enabled_category_ids: list[int] = Field(default_factory=list)
    announcement_text: str | None = Field(default=None, max_length=4000)


class TeamStoreConfigRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    team_id: int
    store_name: str
    store_tagline: str | None
    is_store_enabled: bool
    allow_athlete_checkout: bool
    school_gear_enabled: bool
    featured_product_ids: list[int]
    enabled_category_ids: list[int]
    announcement_text: str | None
    created_by_user_id: int
    updated_by_user_id: int | None
    created_at: datetime
    updated_at: datetime


class TeamStoreRead(BaseModel):
    team_id: int
    school_name: str
    school_abbreviation: str | None
    mascot_name: str
    primary_color: str
    secondary_color: str
    accent_color: str
    surface_color: str
    logo_url: str | None
    store: TeamStoreConfigRead
    categories: list[StoreCategoryRead]
    featured_products: list[ProductRead]
    products: list[ProductRead]
    can_purchase_as_athlete: bool
    can_manage_store: bool
    visibility_role: str
    school_gear_placeholder: str | None = None


class CartAddRequest(BaseModel):
    team_id: int
    user_id: int
    product_id: int
    order_type: OrderType
    quantity: int = Field(default=1, ge=1, le=500)
    notes: str | None = Field(default=None, max_length=4000)


class CartItemRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    team_id: int
    user_id: int
    product_id: int
    order_type: OrderType
    quantity: int
    notes: str | None
    created_at: datetime
    updated_at: datetime
    product: ProductRead

    @computed_field
    @property
    def line_total(self) -> float:
        return round(self.product.sell_price * self.quantity, 2)


class CartRead(BaseModel):
    user_id: int
    team_id: int
    items: list[CartItemRead]
    subtotal: float
    item_count: int


class OrderItemCreate(BaseModel):
    product_id: int
    quantity: int = Field(default=1, ge=1, le=500)
    notes: str | None = Field(default=None, max_length=2000)


class OrderCreate(BaseModel):
    team_id: int
    purchaser_id: int
    order_type: OrderType
    items: list[OrderItemCreate] = Field(default_factory=list)
    cart_item_ids: list[int] = Field(default_factory=list)
    notes: str | None = Field(default=None, max_length=4000)
    shipping_address: str | None = Field(default=None, max_length=4000)
    shipping_cost: float = Field(default=0, ge=0, le=10000)


class OrderStatusUpdate(BaseModel):
    status: OrderStatus
    shipping_status: ShippingStatus | None = None
    tracking_number: str | None = Field(default=None, max_length=120)
    shipping_carrier: str | None = Field(default=None, max_length=80)
    vendor_reference: str | None = Field(default=None, max_length=120)


class OrderItemRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    order_id: int
    product_id: int
    vendor_id: int | None
    product_name_snapshot: str
    sku_snapshot: str
    quantity: int
    unit_cost_price: float
    unit_sell_price: float
    line_total: float
    shipping_status: ShippingStatus
    created_at: datetime
    product: ProductRead | None = None
    vendor: VendorRead | None = None


class OrderRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    team_id: int
    purchaser_id: int
    purchaser_role: PurchaserRole
    order_type: OrderType
    status: OrderStatus
    shipping_status: ShippingStatus
    subtotal: float
    shipping_cost: float
    total: float
    notes: str | None
    shipping_address: str | None
    shipping_carrier: str | None
    tracking_number: str | None
    vendor_reference: str | None
    payment_provider: PaymentProvider
    payment_status: PaymentStatus
    payment_reference: str | None
    payment_checkout_url: str | None
    payment_client_secret: str | None
    paid_at: datetime | None
    reordered_from_order_id: int | None
    created_at: datetime
    updated_at: datetime
    items: list[OrderItemRead] = []

    @computed_field
    @property
    def total_units(self) -> int:
        return sum(item.quantity for item in self.items)


class ReorderRequest(BaseModel):
    notes: str | None = Field(default=None, max_length=4000)


class PermissionSummary(BaseModel):
    can_manage_store: bool
    can_view_team_supply_orders: bool
    can_place_team_supply_orders: bool
    can_place_individual_orders: bool
    athlete_checkout_enabled: bool
    role: str


class CheckoutSessionResponse(BaseModel):
    order_id: int
    provider: PaymentProvider
    payment_status: PaymentStatus
    checkout_url: str | None = None
    client_secret: str | None = None
    publishable_key: str | None = None


class PaymentWebhookResponse(BaseModel):
    processed: bool
    provider: PaymentProvider
    event_id: str
    order_id: int | None = None
