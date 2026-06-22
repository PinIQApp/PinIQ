from fastapi.testclient import TestClient


def test_team_store_allows_coach_access(
    client: TestClient,
    coach_auth_headers: dict[str, str],
    store_product,
):
    response = client.get("/api/v1/store/team/1", headers=coach_auth_headers)

    assert response.status_code == 200
    body = response.json()
    assert body["team_id"] == 1
    assert body["can_manage_store"] is True
    assert len(body["products"]) >= 1


def test_team_store_blocks_outsider_access(
    client: TestClient,
    coach_auth_headers: dict[str, str],
    outsider_auth_headers: dict[str, str],
    store_product,
):
    response = client.get("/api/v1/store/team/1", headers=outsider_auth_headers)

    assert response.status_code == 403
    assert response.json()["detail"] == "You are not allowed to view this team store"


def test_store_products_endpoint_respects_limit_and_offset(
    client: TestClient,
    coach_auth_headers: dict[str, str],
    db_session,
    store_product,
):
    from app.models.store import Product, ProductVisibility, StockStatus

    second_product = Product(
        category_id=store_product.category_id,
        name="Headgear",
        description="Protective gear",
        sku="HEADGEAR-1",
        cost_price=12,
        sell_price=20,
        stock_status=StockStatus.in_stock,
        visibility=ProductVisibility.both,
        is_active=True,
        is_featured=False,
        allow_backorder=False,
        inventory_count=5,
        inventory_tracked=True,
    )
    db_session.add(second_product)
    db_session.commit()

    response = client.get(
        "/api/v1/store/products?limit=1&offset=0",
        headers=coach_auth_headers,
    )

    assert response.status_code == 200
    assert len(response.json()) == 1


def test_mock_checkout_session_and_webhook_flow(
    client: TestClient,
    coach_auth_headers: dict[str, str],
    store_product,
):
    order_response = client.post(
        "/api/v1/store/orders",
        headers=coach_auth_headers,
        json={
            "team_id": 1,
            "purchaser_id": 1,
            "order_type": "team_supply",
            "items": [{"product_id": store_product.id, "quantity": 2}],
            "shipping_cost": 0,
        },
    )

    assert order_response.status_code == 201
    order_id = order_response.json()["id"]

    checkout_response = client.post(
        f"/api/v1/store/orders/{order_id}/checkout-session",
        headers=coach_auth_headers,
    )

    assert checkout_response.status_code == 200
    assert checkout_response.json()["provider"] == "mock"
    assert checkout_response.json()["checkout_url"]

    webhook_response = client.post(
        "/api/v1/store/payments/webhook/mock",
        json={"event_id": "evt_mock_paid_1", "order_id": order_id, "payment_status": "paid"},
    )

    assert webhook_response.status_code == 200
    refreshed_order = client.get(
        "/api/v1/store/orders/user/1",
        headers=coach_auth_headers,
    )
    assert refreshed_order.status_code == 200
    assert refreshed_order.json()[0]["payment_status"] == "paid"


def test_checkout_session_reuses_existing_pending_session(
    client: TestClient,
    coach_auth_headers: dict[str, str],
    db_session,
    store_product,
):
    order_response = client.post(
        "/api/v1/store/orders",
        headers=coach_auth_headers,
        json={
            "team_id": 1,
            "purchaser_id": 1,
            "order_type": "team_supply",
            "items": [{"product_id": store_product.id, "quantity": 1}],
            "shipping_cost": 0,
        },
    )
    order_id = order_response.json()["id"]

    from app.models.store import Order, PaymentProvider, PaymentStatus

    order = db_session.query(Order).filter(Order.id == order_id).first()
    order.payment_provider = PaymentProvider.mock
    order.payment_status = PaymentStatus.requires_action
    order.payment_reference = "existing-ref"
    order.payment_checkout_url = "/existing-checkout"
    order.payment_client_secret = "existing-secret"
    db_session.commit()

    checkout_response = client.post(
        f"/api/v1/store/orders/{order_id}/checkout-session",
        headers=coach_auth_headers,
    )

    assert checkout_response.status_code == 200
    assert checkout_response.json()["checkout_url"] == "/existing-checkout"
    assert checkout_response.json()["client_secret"] == "existing-secret"


def test_mock_webhook_without_event_id_is_idempotent(
    client: TestClient,
    coach_auth_headers: dict[str, str],
    db_session,
    store_product,
):
    order_response = client.post(
        "/api/v1/store/orders",
        headers=coach_auth_headers,
        json={
            "team_id": 1,
            "purchaser_id": 1,
            "order_type": "team_supply",
            "items": [{"product_id": store_product.id, "quantity": 1}],
            "shipping_cost": 0,
        },
    )
    order_id = order_response.json()["id"]

    first_response = client.post(
        "/api/v1/store/payments/webhook/mock",
        json={"order_id": order_id, "payment_status": "paid"},
    )
    second_response = client.post(
        "/api/v1/store/payments/webhook/mock",
        json={"order_id": order_id, "payment_status": "paid"},
    )

    from app.models.store import PaymentWebhookEvent

    assert first_response.status_code == 200
    assert first_response.json()["processed"] is True
    assert second_response.status_code == 200
    assert second_response.json()["processed"] is False
    assert db_session.query(PaymentWebhookEvent).count() == 1
