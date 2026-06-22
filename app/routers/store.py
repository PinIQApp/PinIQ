from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, Query, Request, status
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.models.store import OrderStatus, OrderType, PaymentProvider
from app.routers.deps import get_current_user
from app.schemas.store import (
    CartAddRequest,
    CartRead,
    CheckoutSessionResponse,
    OrderCreate,
    OrderRead,
    OrderStatusUpdate,
    PaymentWebhookResponse,
    ProductRead,
    ReorderRequest,
    StoreCategoryRead,
    TeamStoreConfigRead,
    TeamStoreConfigUpsert,
    TeamStoreRead,
)
from app.services.pagination import normalize_pagination
from app.services.payments import create_checkout_session, process_payment_webhook
from app.services.store_service import (
    _load_order,
    add_to_cart,
    create_order,
    get_cart,
    get_product,
    get_product_for_team,
    get_team_store,
    list_categories,
    list_products,
    list_team_orders,
    list_user_orders,
    remove_cart_item,
    reorder_order,
    update_order_status,
    upsert_team_store_config,
)


router = APIRouter(prefix="/store", tags=["store"])


@router.get("/categories", response_model=list[StoreCategoryRead])
def get_store_categories(
    team_id: int | None = Query(default=None),
    limit: int | None = Query(default=None, ge=1),
    offset: int | None = Query(default=None, ge=0),
    db: Session = Depends(get_db),
):
    limit, offset = normalize_pagination(limit=limit, offset=offset)
    return list_categories(db, team_id=team_id, limit=limit, offset=offset)


@router.get("/products", response_model=list[ProductRead])
def get_store_products(
    team_id: int | None = Query(default=None),
    category_id: int | None = Query(default=None),
    search: str | None = Query(default=None),
    featured: bool = Query(default=False),
    order_type: OrderType | None = Query(default=None),
    limit: int | None = Query(default=None, ge=1),
    offset: int | None = Query(default=None, ge=0),
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    limit, offset = normalize_pagination(limit=limit, offset=offset)
    return list_products(
        db,
        current_user=current_user,
        team_id=team_id,
        category_id=category_id,
        search=search,
        featured=featured,
        order_type=order_type,
        limit=limit,
        offset=offset,
    )


@router.get("/products/{product_id}", response_model=ProductRead)
def get_store_product(
    product_id: int,
    team_id: int | None = Query(default=None),
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    if team_id is not None:
        return get_product_for_team(db, product_id=product_id, team_id=team_id, current_user=current_user)
    return get_product(db, product_id=product_id)


@router.post("/team-config/{team_id}", response_model=TeamStoreConfigRead)
def save_team_store_config(
    team_id: int,
    payload: TeamStoreConfigUpsert,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    config = upsert_team_store_config(db, team_id=team_id, payload=payload, current_user=current_user)
    db.commit()
    return config


@router.get("/team/{team_id}", response_model=TeamStoreRead)
def get_team_store_view(
    team_id: int,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    store = get_team_store(db, team_id=team_id, current_user=current_user)
    db.commit()
    return store


@router.post("/orders", response_model=OrderRead, status_code=status.HTTP_201_CREATED)
def submit_store_order(
    payload: OrderCreate,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    order = create_order(db, payload=payload, current_user=current_user)
    db.commit()
    return order


@router.post("/orders/{order_id}/checkout-session", response_model=CheckoutSessionResponse)
def create_order_checkout_session(
    order_id: int,
    request: Request,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    order = _load_order(db, order_id)
    if current_user.role.value != "admin" and current_user.id != order.purchaser_id:
        raise HTTPException(status_code=403, detail="You are not allowed to start checkout for this order")
    session = create_checkout_session(db, order=order, idempotency_key=request.headers.get("Idempotency-Key"))
    db.commit()
    return session


@router.get("/orders/team/{team_id}", response_model=list[OrderRead])
def get_team_store_orders(
    team_id: int,
    status_filter: OrderStatus | None = Query(default=None),
    limit: int | None = Query(default=None, ge=1),
    offset: int | None = Query(default=None, ge=0),
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    limit, offset = normalize_pagination(limit=limit, offset=offset)
    orders = list_team_orders(db, team_id=team_id, current_user=current_user, limit=limit, offset=offset)
    if status_filter is not None:
        orders = [order for order in orders if order.status == status_filter]
    return orders


@router.get("/orders/user/{user_id}", response_model=list[OrderRead])
def get_user_store_orders(
    user_id: int,
    limit: int | None = Query(default=None, ge=1),
    offset: int | None = Query(default=None, ge=0),
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    limit, offset = normalize_pagination(limit=limit, offset=offset)
    return list_user_orders(db, user_id=user_id, current_user=current_user, limit=limit, offset=offset)


@router.patch("/orders/{order_id}/status", response_model=OrderRead)
def patch_order_status(
    order_id: int,
    payload: OrderStatusUpdate,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    order = update_order_status(db, order_id=order_id, payload=payload, current_user=current_user)
    db.commit()
    return order


@router.post("/payments/webhook/{provider}", response_model=PaymentWebhookResponse)
async def receive_payment_webhook(
    provider: str,
    request: Request,
    db: Session = Depends(get_db),
):
    try:
        provider_enum = PaymentProvider(provider)
    except Exception:  # noqa: BLE001
        raise HTTPException(status_code=400, detail="Unknown payment provider")
    payload = await request.json()
    signature = request.headers.get("Stripe-Signature")
    response = process_payment_webhook(
        db,
        provider=provider_enum,
        payload=payload,
        signature=signature,
    )
    return response


@router.post("/orders/{order_id}/reorder", response_model=OrderRead, status_code=status.HTTP_201_CREATED)
def create_reorder(
    order_id: int,
    payload: ReorderRequest,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    order = reorder_order(db, order_id=order_id, payload=payload, current_user=current_user)
    db.commit()
    return order


@router.post("/cart/add", response_model=CartRead)
def add_item_to_cart(
    payload: CartAddRequest,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    cart = add_to_cart(db, payload=payload, current_user=current_user)
    db.commit()
    return cart


@router.get("/cart/{user_id}", response_model=CartRead)
def get_user_cart(
    user_id: int,
    team_id: int = Query(...),
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    return get_cart(db, user_id=user_id, team_id=team_id, current_user=current_user)


@router.delete("/cart/item/{item_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_cart_item(
    item_id: int,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    remove_cart_item(db, item_id=item_id, current_user=current_user)
    db.commit()
