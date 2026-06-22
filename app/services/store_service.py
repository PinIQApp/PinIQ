from __future__ import annotations

from decimal import Decimal

from fastapi import HTTPException
from sqlalchemy import or_
from sqlalchemy.orm import Session, joinedload

from app.models.messaging import ParentLink
from app.models.store import (
    CartItem,
    Order,
    OrderItem,
    OrderStatus,
    OrderType,
    PaymentProvider,
    PaymentStatus,
    Product,
    ProductCategory,
    ProductVisibility,
    PurchaserRole,
    ShippingStatus,
    StockStatus,
    TeamStoreConfig,
    Vendor,
)
from app.models.team import Team, TeamMember, TeamMemberStatus
from app.models.user import User, UserRole
from app.core.config import settings
from app.schemas.store import (
    CartAddRequest,
    CartRead,
    OrderCreate,
    OrderRead,
    OrderStatusUpdate,
    PermissionSummary,
    ProductRead,
    ReorderRequest,
    StoreCategoryRead,
    TeamStoreConfigRead,
    TeamStoreConfigUpsert,
    TeamStoreRead,
)


DEFAULT_CATEGORY_SLUGS = [
    "medical",
    "mat-tape",
    "sanitizing",
    "equipment",
    "scoring-supplies",
    "training-accessories",
    "apparel-basics",
]


def _csv_to_int_list(value: str | None) -> list[int]:
    if not value:
        return []
    items: list[int] = []
    for part in value.split(","):
        part = part.strip()
        if part:
            items.append(int(part))
    return items


def _int_list_to_csv(values: list[int]) -> str | None:
    if not values:
        return None
    unique_values = list(dict.fromkeys(values))
    return ",".join(str(value) for value in unique_values)


def _money(value: Decimal | float | int) -> float:
    return round(float(value), 2)


def _approved_membership(team: Team, user_id: int) -> TeamMember | None:
    return next(
        (
            member
            for member in team.memberships
            if member.user_id == user_id and member.status == TeamMemberStatus.approved
        ),
        None,
    )


def _load_team(db: Session, team_id: int) -> Team:
    team = (
        db.query(Team)
        .options(joinedload(Team.memberships).joinedload(TeamMember.user))
        .filter(Team.id == team_id)
        .first()
    )
    if not team:
        raise HTTPException(status_code=404, detail="Team not found")
    return team


def _enabled_category_ids(config: TeamStoreConfig) -> set[int]:
    return set(_csv_to_int_list(config.enabled_category_ids_csv))


def _ensure_product_enabled_for_team_store(product: Product, config: TeamStoreConfig) -> None:
    enabled_ids = _enabled_category_ids(config)
    if enabled_ids and product.category_id not in enabled_ids:
        raise HTTPException(status_code=400, detail=f"{product.name} is not enabled for this team store")


def _validate_team_store_config_payload(db: Session, payload: TeamStoreConfigUpsert) -> None:
    if payload.enabled_category_ids:
        found_categories = (
            db.query(ProductCategory.id)
            .filter(ProductCategory.id.in_(payload.enabled_category_ids), ProductCategory.is_active.is_(True))
            .all()
        )
        found_ids = {row[0] for row in found_categories}
        missing = sorted(set(payload.enabled_category_ids) - found_ids)
        if missing:
            raise HTTPException(status_code=400, detail=f"Unknown category ids: {missing}")

    if payload.featured_product_ids:
        found_products = (
            db.query(Product.id, Product.category_id)
            .filter(Product.id.in_(payload.featured_product_ids), Product.is_active.is_(True))
            .all()
        )
        found_ids = {row[0] for row in found_products}
        missing = sorted(set(payload.featured_product_ids) - found_ids)
        if missing:
            raise HTTPException(status_code=400, detail=f"Unknown product ids: {missing}")

        enabled_ids = set(payload.enabled_category_ids)
        if enabled_ids:
            disallowed = sorted(row[0] for row in found_products if row[1] not in enabled_ids)
            if disallowed:
                raise HTTPException(
                    status_code=400,
                    detail=f"Featured products must belong to enabled categories: {disallowed}",
                )


def _get_or_create_team_store_config(db: Session, team: Team, current_user: User) -> TeamStoreConfig:
    config = db.query(TeamStoreConfig).filter(TeamStoreConfig.team_id == team.id).first()
    if config:
        return config

    categories = (
        db.query(ProductCategory)
        .filter(ProductCategory.slug.in_(DEFAULT_CATEGORY_SLUGS), ProductCategory.is_active.is_(True))
        .order_by(ProductCategory.sort_order.asc(), ProductCategory.id.asc())
        .all()
    )
    config = TeamStoreConfig(
        team_id=team.id,
        store_name=f"{team.school_name} Team Store",
        store_tagline=f"{team.mascot_name} wrestling essentials and supply ordering.",
        is_store_enabled=True,
        allow_athlete_checkout=False,
        school_gear_enabled=False,
        enabled_category_ids_csv=_int_list_to_csv([category.id for category in categories]),
        created_by_user_id=current_user.id,
        updated_by_user_id=current_user.id,
    )
    db.add(config)
    db.flush()
    return config


def _team_manager_role(team: Team, current_user: User) -> str | None:
    membership = _approved_membership(team, current_user.id)
    if current_user.role == UserRole.admin:
        return "admin"
    if membership and current_user.role in {UserRole.coach, UserRole.assistant_coach}:
        return current_user.role.value
    return None


def _ensure_store_view_access(team: Team, config: TeamStoreConfig, current_user: User) -> str:
    membership = _approved_membership(team, current_user.id)
    if current_user.role == UserRole.admin:
        return "admin"
    if not config.is_store_enabled:
        raise HTTPException(status_code=403, detail="This team store is currently disabled")
    if membership:
        return current_user.role.value
    raise HTTPException(status_code=403, detail="You are not allowed to view this team store")


def _is_linked_parent(db: Session, *, team_id: int, parent_user_id: int) -> bool:
    return (
        db.query(ParentLink)
        .filter(
            ParentLink.team_id == team_id,
            ParentLink.parent_user_id == parent_user_id,
            ParentLink.is_active.is_(True),
        )
        .first()
        is not None
    )


def _permissions_for(team: Team, config: TeamStoreConfig, current_user: User, db: Session) -> PermissionSummary:
    manager_role = _team_manager_role(team, current_user)
    membership = _approved_membership(team, current_user.id)
    is_parent = current_user.role == UserRole.parent and (membership is not None or _is_linked_parent(db, team_id=team.id, parent_user_id=current_user.id))
    is_athlete = membership is not None and current_user.role == UserRole.athlete

    return PermissionSummary(
        can_manage_store=manager_role is not None,
        can_view_team_supply_orders=manager_role is not None,
        can_place_team_supply_orders=manager_role is not None,
        can_place_individual_orders=(
            current_user.role == UserRole.admin
            or manager_role is not None
            or is_parent
            or (is_athlete and config.allow_athlete_checkout)
        ),
        athlete_checkout_enabled=config.allow_athlete_checkout,
        role=(manager_role or current_user.role.value),
    )


def _serialize_config(config: TeamStoreConfig) -> TeamStoreConfigRead:
    return TeamStoreConfigRead(
        id=config.id,
        team_id=config.team_id,
        store_name=config.store_name,
        store_tagline=config.store_tagline,
        is_store_enabled=config.is_store_enabled,
        allow_athlete_checkout=config.allow_athlete_checkout,
        school_gear_enabled=config.school_gear_enabled,
        featured_product_ids=_csv_to_int_list(config.featured_product_ids_csv),
        enabled_category_ids=_csv_to_int_list(config.enabled_category_ids_csv),
        announcement_text=config.announcement_text,
        created_by_user_id=config.created_by_user_id,
        updated_by_user_id=config.updated_by_user_id,
        created_at=config.created_at,
        updated_at=config.updated_at,
    )


def _query_products(db: Session):
    return db.query(Product).options(
        joinedload(Product.category),
        joinedload(Product.vendor),
        joinedload(Product.images),
    )


def list_categories(
    db: Session,
    *,
    team_id: int | None = None,
    limit: int | None = None,
    offset: int | None = None,
) -> list[StoreCategoryRead]:
    category_query = db.query(ProductCategory).filter(ProductCategory.is_active.is_(True))
    category_query = category_query.order_by(ProductCategory.sort_order.asc(), ProductCategory.id.asc())
    if offset is not None:
        category_query = category_query.offset(offset)
    if limit is not None:
        category_query = category_query.limit(limit)
    categories = category_query.all()
    if team_id is None:
        return [StoreCategoryRead.model_validate(category) for category in categories]

    config = db.query(TeamStoreConfig).filter(TeamStoreConfig.team_id == team_id).first()
    enabled_ids = set(_csv_to_int_list(config.enabled_category_ids_csv) if config else [])
    filtered = [category for category in categories if not enabled_ids or category.id in enabled_ids]
    return [StoreCategoryRead.model_validate(category) for category in filtered]


def list_products(
    db: Session,
    *,
    current_user: User,
    team_id: int | None = None,
    category_id: int | None = None,
    search: str | None = None,
    featured: bool = False,
    order_type: OrderType | None = None,
    limit: int | None = None,
    offset: int | None = None,
) -> list[Product]:
    query = _query_products(db).filter(Product.is_active.is_(True))

    if category_id is not None:
        query = query.filter(Product.category_id == category_id)
    if featured:
        query = query.filter(Product.is_featured.is_(True))
    if search:
        like = f"%{search.strip()}%"
        query = query.filter(or_(Product.name.ilike(like), Product.description.ilike(like), Product.sku.ilike(like)))
    if order_type == OrderType.team_supply:
        query = query.filter(Product.visibility != ProductVisibility.individual_only)
    elif order_type == OrderType.individual:
        query = query.filter(Product.visibility != ProductVisibility.team_only)

    query = query.order_by(Product.is_featured.desc(), Product.name.asc())
    if offset is not None:
        query = query.offset(offset)
    if limit is not None:
        query = query.limit(limit)
    products = query.all()
    if team_id is None:
        return products

    team = _load_team(db, team_id)
    config = _get_or_create_team_store_config(db, team, current_user)
    _ensure_store_view_access(team, config, current_user)
    enabled_ids = set(_csv_to_int_list(config.enabled_category_ids_csv))
    if enabled_ids:
        products = [product for product in products if product.category_id in enabled_ids]
    return products


def get_product(db: Session, *, product_id: int) -> Product:
    product = _query_products(db).filter(Product.id == product_id, Product.is_active.is_(True)).first()
    if not product:
        raise HTTPException(status_code=404, detail="Product not found")
    return product


def get_product_for_team(db: Session, *, product_id: int, team_id: int, current_user: User) -> Product:
    team = _load_team(db, team_id)
    config = _get_or_create_team_store_config(db, team, current_user)
    _ensure_store_view_access(team, config, current_user)
    product = get_product(db, product_id=product_id)
    _ensure_product_enabled_for_team_store(product, config)
    return product


def upsert_team_store_config(
    db: Session,
    *,
    team_id: int,
    payload: TeamStoreConfigUpsert,
    current_user: User,
) -> TeamStoreConfigRead:
    team = _load_team(db, team_id)
    if _team_manager_role(team, current_user) is None:
        raise HTTPException(status_code=403, detail="Only coaches and admins can manage the team store")
    _validate_team_store_config_payload(db, payload)

    config = db.query(TeamStoreConfig).filter(TeamStoreConfig.team_id == team_id).first()
    if config is None:
        config = TeamStoreConfig(team_id=team_id, created_by_user_id=current_user.id)
        db.add(config)

    config.store_name = payload.store_name
    config.store_tagline = payload.store_tagline
    config.is_store_enabled = payload.is_store_enabled
    config.allow_athlete_checkout = payload.allow_athlete_checkout
    config.school_gear_enabled = payload.school_gear_enabled
    config.featured_product_ids_csv = _int_list_to_csv(payload.featured_product_ids)
    config.enabled_category_ids_csv = _int_list_to_csv(payload.enabled_category_ids)
    config.announcement_text = payload.announcement_text
    config.updated_by_user_id = current_user.id
    db.flush()
    return _serialize_config(config)


def get_team_store(db: Session, *, team_id: int, current_user: User) -> TeamStoreRead:
    team = _load_team(db, team_id)
    config = _get_or_create_team_store_config(db, team, current_user)
    visibility_role = _ensure_store_view_access(team, config, current_user)
    permissions = _permissions_for(team, config, current_user, db)

    enabled_ids = set(_csv_to_int_list(config.enabled_category_ids_csv))
    featured_ids = set(_csv_to_int_list(config.featured_product_ids_csv))

    categories_query = db.query(ProductCategory).filter(ProductCategory.is_active.is_(True))
    categories = categories_query.order_by(ProductCategory.sort_order.asc(), ProductCategory.id.asc()).all()
    if enabled_ids:
        categories = [category for category in categories if category.id in enabled_ids]

    products = list_products(db, current_user=current_user, team_id=team_id)
    featured_products = [product for product in products if product.id in featured_ids]
    if not featured_products:
        featured_products = [product for product in products if product.is_featured][:6]

    return TeamStoreRead(
        team_id=team.id,
        school_name=team.school_name,
        school_abbreviation=team.school_abbreviation,
        mascot_name=team.mascot_name,
        primary_color=team.primary_color,
        secondary_color=team.secondary_color,
        accent_color=team.accent_color,
        surface_color=team.surface_color,
        logo_url=team.logo_url,
        store=_serialize_config(config),
        categories=[StoreCategoryRead.model_validate(category) for category in categories],
        featured_products=[ProductRead.model_validate(product) for product in featured_products],
        products=[ProductRead.model_validate(product) for product in products],
        can_purchase_as_athlete=permissions.athlete_checkout_enabled,
        can_manage_store=permissions.can_manage_store,
        visibility_role=visibility_role,
        school_gear_placeholder=(
            "School gear designer placeholder is enabled for a future merch builder."
            if config.school_gear_enabled
            else None
        ),
    )


def _ensure_cart_access(current_user: User, user_id: int) -> None:
    if current_user.role == UserRole.admin:
        return
    if current_user.id != user_id:
        raise HTTPException(status_code=403, detail="You may only access your own cart")


def _validate_purchase_access(
    db: Session,
    *,
    current_user: User,
    team: Team,
    config: TeamStoreConfig,
    purchaser_id: int,
    order_type: OrderType,
) -> None:
    permissions = _permissions_for(team, config, current_user, db)
    owns_order = current_user.id == purchaser_id
    is_admin = current_user.role == UserRole.admin
    can_place_for_team = order_type == OrderType.team_supply and permissions.can_place_team_supply_orders

    if not is_admin and not owns_order and not can_place_for_team:
        raise HTTPException(status_code=403, detail="You may only place orders for your own account")

    if order_type == OrderType.team_supply and not permissions.can_place_team_supply_orders:
        raise HTTPException(status_code=403, detail="Only coaches and admins can place team supply orders")
    if order_type == OrderType.individual and not permissions.can_place_individual_orders:
        raise HTTPException(status_code=403, detail="You are not allowed to place individual store orders")


def _ensure_product_orderable(product: Product, *, order_type: OrderType) -> None:
    if not product.is_active:
        raise HTTPException(status_code=400, detail=f"{product.name} is not active")
    if product.stock_status == StockStatus.out_of_stock and not product.allow_backorder:
        raise HTTPException(status_code=400, detail=f"{product.name} is currently out of stock")
    if order_type == OrderType.team_supply and product.visibility == ProductVisibility.individual_only:
        raise HTTPException(status_code=400, detail=f"{product.name} is not available for team supply orders")
    if order_type == OrderType.individual and product.visibility == ProductVisibility.team_only:
        raise HTTPException(status_code=400, detail=f"{product.name} is only available for team supply orders")


def add_to_cart(db: Session, *, payload: CartAddRequest, current_user: User) -> CartRead:
    _ensure_cart_access(current_user, payload.user_id)
    team = _load_team(db, payload.team_id)
    config = _get_or_create_team_store_config(db, team, current_user)
    _ensure_store_view_access(team, config, current_user)
    _validate_purchase_access(
        db,
        current_user=current_user,
        team=team,
        config=config,
        purchaser_id=payload.user_id,
        order_type=payload.order_type,
    )

    product = get_product(db, product_id=payload.product_id)
    _ensure_product_orderable(product, order_type=payload.order_type)
    _ensure_product_enabled_for_team_store(product, config)

    existing = (
        db.query(CartItem)
        .filter(
            CartItem.team_id == payload.team_id,
            CartItem.user_id == payload.user_id,
            CartItem.product_id == payload.product_id,
            CartItem.order_type == payload.order_type,
        )
        .first()
    )
    if existing:
        existing.quantity += payload.quantity
        existing.notes = payload.notes or existing.notes
    else:
        existing = CartItem(
            team_id=payload.team_id,
            user_id=payload.user_id,
            product_id=payload.product_id,
            order_type=payload.order_type,
            quantity=payload.quantity,
            notes=payload.notes,
        )
        db.add(existing)
    db.flush()
    return get_cart(db, user_id=payload.user_id, team_id=payload.team_id, current_user=current_user)


def get_cart(db: Session, *, user_id: int, team_id: int, current_user: User) -> CartRead:
    _ensure_cart_access(current_user, user_id)
    items = (
        db.query(CartItem)
        .options(
            joinedload(CartItem.product).joinedload(Product.category),
            joinedload(CartItem.product).joinedload(Product.vendor),
            joinedload(CartItem.product).joinedload(Product.images),
        )
        .filter(CartItem.user_id == user_id, CartItem.team_id == team_id)
        .order_by(CartItem.created_at.asc(), CartItem.id.asc())
        .all()
    )
    subtotal = sum(_money(item.product.sell_price) * item.quantity for item in items)
    return CartRead(
        user_id=user_id,
        team_id=team_id,
        items=items,
        subtotal=round(subtotal, 2),
        item_count=sum(item.quantity for item in items),
    )


def remove_cart_item(db: Session, *, item_id: int, current_user: User) -> None:
    item = db.query(CartItem).filter(CartItem.id == item_id).first()
    if not item:
        raise HTTPException(status_code=404, detail="Cart item not found")
    _ensure_cart_access(current_user, item.user_id)
    db.delete(item)
    db.flush()


def _load_cart_items_for_checkout(
    db: Session,
    *,
    team_id: int,
    purchaser_id: int,
    order_type: OrderType,
    cart_item_ids: list[int],
) -> list[CartItem]:
    items = (
        db.query(CartItem)
        .options(joinedload(CartItem.product).joinedload(Product.vendor))
        .filter(
            CartItem.id.in_(cart_item_ids),
            CartItem.team_id == team_id,
            CartItem.user_id == purchaser_id,
            CartItem.order_type == order_type,
        )
        .all()
    )
    if len(items) != len(cart_item_ids):
        raise HTTPException(status_code=400, detail="Some cart items were not found for checkout")
    return items


def _build_order_items_from_payload(
    db: Session,
    *,
    items_payload,
    order_type: OrderType,
    config: TeamStoreConfig,
) -> list[tuple[Product, int]]:
    rows: list[tuple[Product, int]] = []
    for item in items_payload:
        product = get_product(db, product_id=item.product_id)
        _ensure_product_orderable(product, order_type=order_type)
        _ensure_product_enabled_for_team_store(product, config)
        rows.append((product, item.quantity))
    return rows


def _ensure_valid_purchaser_for_order(*, purchaser: User, order_type: OrderType) -> None:
    if order_type == OrderType.team_supply and purchaser.role not in {
        UserRole.coach,
        UserRole.assistant_coach,
        UserRole.admin,
    }:
        raise HTTPException(
            status_code=400,
            detail="Team supply orders must be placed by a coach or admin account",
        )


def _create_order_record(
    db: Session,
    *,
    team_id: int,
    purchaser: User,
    order_type: OrderType,
    rows: list[tuple[Product, int]],
    notes: str | None,
    shipping_address: str | None,
    shipping_cost: float,
    reordered_from_order_id: int | None = None,
) -> Order:
    subtotal = round(sum(_money(product.sell_price) * quantity for product, quantity in rows), 2)
    order = Order(
        team_id=team_id,
        purchaser_id=purchaser.id,
        purchaser_role=PurchaserRole(purchaser.role.value),
        order_type=order_type,
        status=OrderStatus.pending,
        shipping_status=ShippingStatus.pending if shipping_address else ShippingStatus.not_applicable,
        subtotal=subtotal,
        shipping_cost=round(shipping_cost, 2),
        total=round(subtotal + shipping_cost, 2),
        notes=notes,
        shipping_address=shipping_address,
        payment_provider=PaymentProvider(settings.payment_provider),
        payment_status=PaymentStatus.not_required if round(subtotal + shipping_cost, 2) == 0 else PaymentStatus.pending_checkout,
        reordered_from_order_id=reordered_from_order_id,
    )
    db.add(order)
    db.flush()

    for product, quantity in rows:
        db.add(
            OrderItem(
                order_id=order.id,
                product_id=product.id,
                vendor_id=product.vendor_id,
                product_name_snapshot=product.name,
                sku_snapshot=product.sku,
                quantity=quantity,
                unit_cost_price=_money(product.cost_price),
                unit_sell_price=_money(product.sell_price),
                line_total=round(_money(product.sell_price) * quantity, 2),
                shipping_status=ShippingStatus.pending if shipping_address else ShippingStatus.not_applicable,
            )
        )
    db.flush()
    return order


def _load_order(db: Session, order_id: int) -> Order:
    order = (
        db.query(Order)
        .options(
            joinedload(Order.items).joinedload(OrderItem.product).joinedload(Product.category),
            joinedload(Order.items).joinedload(OrderItem.product).joinedload(Product.images),
            joinedload(Order.items).joinedload(OrderItem.product).joinedload(Product.vendor),
            joinedload(Order.items).joinedload(OrderItem.vendor),
        )
        .filter(Order.id == order_id)
        .first()
    )
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")
    return order


def create_order(db: Session, *, payload: OrderCreate, current_user: User) -> Order:
    team = _load_team(db, payload.team_id)
    config = _get_or_create_team_store_config(db, team, current_user)
    _ensure_store_view_access(team, config, current_user)
    _validate_purchase_access(
        db,
        current_user=current_user,
        team=team,
        config=config,
        purchaser_id=payload.purchaser_id,
        order_type=payload.order_type,
    )

    purchaser = db.query(User).filter(User.id == payload.purchaser_id).first()
    if not purchaser:
        raise HTTPException(status_code=404, detail="Purchaser not found")
    _ensure_valid_purchaser_for_order(purchaser=purchaser, order_type=payload.order_type)

    rows: list[tuple[Product, int]]
    if payload.cart_item_ids:
        cart_items = _load_cart_items_for_checkout(
            db,
            team_id=payload.team_id,
            purchaser_id=payload.purchaser_id,
            order_type=payload.order_type,
            cart_item_ids=payload.cart_item_ids,
        )
        rows = []
        for cart_item in cart_items:
            _ensure_product_orderable(cart_item.product, order_type=payload.order_type)
            _ensure_product_enabled_for_team_store(cart_item.product, config)
            rows.append((cart_item.product, cart_item.quantity))
    elif payload.items:
        rows = _build_order_items_from_payload(
            db,
            items_payload=payload.items,
            order_type=payload.order_type,
            config=config,
        )
    else:
        raise HTTPException(status_code=400, detail="Provide cart_item_ids or order items to create an order")

    order = _create_order_record(
        db,
        team_id=payload.team_id,
        purchaser=purchaser,
        order_type=payload.order_type,
        rows=rows,
        notes=payload.notes,
        shipping_address=payload.shipping_address,
        shipping_cost=payload.shipping_cost,
    )

    if payload.cart_item_ids:
        for cart_item in cart_items:
            db.delete(cart_item)
        db.flush()

    return _load_order(db, order.id)


def list_team_orders(
    db: Session,
    *,
    team_id: int,
    current_user: User,
    limit: int | None = None,
    offset: int | None = None,
) -> list[Order]:
    team = _load_team(db, team_id)
    if _team_manager_role(team, current_user) is None:
        raise HTTPException(status_code=403, detail="Only coaches and admins can view team supply orders")
    query = (
        db.query(Order)
        .options(
            joinedload(Order.items).joinedload(OrderItem.product).joinedload(Product.category),
            joinedload(Order.items).joinedload(OrderItem.product).joinedload(Product.vendor),
            joinedload(Order.items).joinedload(OrderItem.vendor),
        )
        .filter(Order.team_id == team_id, Order.order_type == OrderType.team_supply)
        .order_by(Order.created_at.desc(), Order.id.desc())
    )
    if offset is not None:
        query = query.offset(offset)
    if limit is not None:
        query = query.limit(limit)
    return query.all()


def list_user_orders(
    db: Session,
    *,
    user_id: int,
    current_user: User,
    limit: int | None = None,
    offset: int | None = None,
) -> list[Order]:
    if current_user.role != UserRole.admin and current_user.id != user_id:
        raise HTTPException(status_code=403, detail="You may only view your own orders")
    query = (
        db.query(Order)
        .options(
            joinedload(Order.items).joinedload(OrderItem.product).joinedload(Product.category),
            joinedload(Order.items).joinedload(OrderItem.product).joinedload(Product.vendor),
            joinedload(Order.items).joinedload(OrderItem.vendor),
        )
        .filter(Order.purchaser_id == user_id)
        .order_by(Order.created_at.desc(), Order.id.desc())
    )
    if offset is not None:
        query = query.offset(offset)
    if limit is not None:
        query = query.limit(limit)
    return query.all()


def update_order_status(db: Session, *, order_id: int, payload: OrderStatusUpdate, current_user: User) -> Order:
    order = _load_order(db, order_id)
    team = _load_team(db, order.team_id)
    if _team_manager_role(team, current_user) is None:
        raise HTTPException(status_code=403, detail="Only coaches and admins can update order statuses")

    order.status = payload.status
    if payload.shipping_status is not None:
        order.shipping_status = payload.shipping_status
        for item in order.items:
            item.shipping_status = payload.shipping_status
    elif payload.status in {OrderStatus.cancelled, OrderStatus.delivered}:
        derived_status = ShippingStatus.cancelled if payload.status == OrderStatus.cancelled else ShippingStatus.delivered
        order.shipping_status = derived_status
        for item in order.items:
            item.shipping_status = derived_status

    if payload.tracking_number is not None:
        order.tracking_number = payload.tracking_number
    if payload.shipping_carrier is not None:
        order.shipping_carrier = payload.shipping_carrier
    if payload.vendor_reference is not None:
        order.vendor_reference = payload.vendor_reference
    db.flush()
    return _load_order(db, order.id)


def reorder_order(db: Session, *, order_id: int, payload: ReorderRequest, current_user: User) -> Order:
    prior = _load_order(db, order_id)
    team = _load_team(db, prior.team_id)
    config = _get_or_create_team_store_config(db, team, current_user)

    if current_user.role != UserRole.admin and current_user.id != prior.purchaser_id and _team_manager_role(team, current_user) is None:
        raise HTTPException(status_code=403, detail="You are not allowed to reorder this order")

    purchaser = db.query(User).filter(User.id == prior.purchaser_id).first()
    _ensure_valid_purchaser_for_order(purchaser=purchaser, order_type=prior.order_type)
    rows: list[tuple[Product, int]] = []
    for item in prior.items:
        product = get_product(db, product_id=item.product_id)
        _ensure_product_orderable(product, order_type=prior.order_type)
        _ensure_product_enabled_for_team_store(product, config)
        rows.append((product, item.quantity))

    _validate_purchase_access(
        db,
        current_user=current_user,
        team=team,
        config=config,
        purchaser_id=prior.purchaser_id,
        order_type=prior.order_type,
    )

    order = _create_order_record(
        db,
        team_id=prior.team_id,
        purchaser=purchaser,
        order_type=prior.order_type,
        rows=rows,
        notes=payload.notes or f"Reordered from order #{prior.id}",
        shipping_address=prior.shipping_address,
        shipping_cost=_money(prior.shipping_cost),
        reordered_from_order_id=prior.id,
    )
    return _load_order(db, order.id)
