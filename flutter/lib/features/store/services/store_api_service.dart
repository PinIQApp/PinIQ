import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/store_models.dart';

class StoreApiService {
  StoreApiService({
    required this.baseUrl,
    required this.authToken,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final String authToken;
  final http.Client _client;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      };

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    return Uri.parse('$baseUrl$path').replace(
      queryParameters: query?.map(
        (key, value) => MapEntry(key, value?.toString()),
      ),
    );
  }

  Future<TeamStoreBundle> fetchTeamStore({required int teamId}) async {
    final response = await _client.get(
      _uri('/api/v1/store/team/$teamId'),
      headers: _headers,
    );
    _throwIfNeeded(response);
    return TeamStoreBundle.fromMap(decodeStoreObject(response.body));
  }

  Future<List<StoreProduct>> fetchProducts({
    int? teamId,
    int? categoryId,
    String? search,
    bool featured = false,
    StoreOrderType? orderType,
  }) async {
    final response = await _client.get(
      _uri('/api/v1/store/products', {
        if (teamId != null) 'team_id': teamId,
        if (categoryId != null) 'category_id': categoryId,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        if (featured) 'featured': featured,
        if (orderType != null) 'order_type': storeOrderTypeToApi(orderType),
      }),
      headers: _headers,
    );
    _throwIfNeeded(response);
    return decodeStoreList(response.body)
        .map((item) => StoreProduct.fromMap(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<StoreProduct> fetchProduct({
    required int productId,
    int? teamId,
  }) async {
    final response = await _client.get(
      _uri('/api/v1/store/products/$productId', {
        if (teamId != null) 'team_id': teamId,
      }),
      headers: _headers,
    );
    _throwIfNeeded(response);
    return StoreProduct.fromMap(decodeStoreObject(response.body));
  }

  Future<TeamStoreConfig> updateTeamStoreConfig({
    required int teamId,
    required String storeName,
    String? storeTagline,
    required bool isStoreEnabled,
    required bool allowAthleteCheckout,
    required bool schoolGearEnabled,
    required List<int> featuredProductIds,
    required List<int> enabledCategoryIds,
    String? announcementText,
  }) async {
    final response = await _client.post(
      _uri('/api/v1/store/team-config/$teamId'),
      headers: _headers,
      body: jsonEncode({
        'store_name': storeName,
        'store_tagline': storeTagline,
        'is_store_enabled': isStoreEnabled,
        'allow_athlete_checkout': allowAthleteCheckout,
        'school_gear_enabled': schoolGearEnabled,
        'featured_product_ids': featuredProductIds,
        'enabled_category_ids': enabledCategoryIds,
        'announcement_text': announcementText,
      }),
    );
    _throwIfNeeded(response);
    return TeamStoreConfig.fromMap(decodeStoreObject(response.body));
  }

  Future<StoreCart> addToCart({
    required int teamId,
    required int userId,
    required int productId,
    required StoreOrderType orderType,
    int quantity = 1,
    String? notes,
  }) async {
    final response = await _client.post(
      _uri('/api/v1/store/cart/add'),
      headers: _headers,
      body: jsonEncode({
        'team_id': teamId,
        'user_id': userId,
        'product_id': productId,
        'order_type': storeOrderTypeToApi(orderType),
        'quantity': quantity,
        'notes': notes,
      }),
    );
    _throwIfNeeded(response);
    return StoreCart.fromMap(decodeStoreObject(response.body));
  }

  Future<StoreCart> fetchCart({
    required int userId,
    required int teamId,
  }) async {
    final response = await _client.get(
      _uri('/api/v1/store/cart/$userId', {'team_id': teamId}),
      headers: _headers,
    );
    _throwIfNeeded(response);
    return StoreCart.fromMap(decodeStoreObject(response.body));
  }

  Future<void> removeCartItem({required int itemId}) async {
    final response = await _client.delete(
      _uri('/api/v1/store/cart/item/$itemId'),
      headers: _headers,
    );
    _throwIfNeeded(response);
  }

  Future<StoreOrder> createOrderFromCart({
    required int teamId,
    required int purchaserId,
    required StoreOrderType orderType,
    required List<int> cartItemIds,
    String? notes,
    String? shippingAddress,
    double shippingCost = 0,
  }) async {
    final response = await _client.post(
      _uri('/api/v1/store/orders'),
      headers: _headers,
      body: jsonEncode({
        'team_id': teamId,
        'purchaser_id': purchaserId,
        'order_type': storeOrderTypeToApi(orderType),
        'cart_item_ids': cartItemIds,
        'notes': notes,
        'shipping_address': shippingAddress,
        'shipping_cost': shippingCost,
      }),
    );
    _throwIfNeeded(response);
    return StoreOrder.fromMap(decodeStoreObject(response.body));
  }

  Future<List<StoreOrder>> fetchTeamOrders({
    required int teamId,
    StoreOrderStatus? status,
  }) async {
    final response = await _client.get(
      _uri('/api/v1/store/orders/team/$teamId', {
        if (status != null) 'status_filter': status.name,
      }),
      headers: _headers,
    );
    _throwIfNeeded(response);
    return decodeStoreList(response.body)
        .map((item) => StoreOrder.fromMap(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<List<StoreOrder>> fetchUserOrders({required int userId}) async {
    final response = await _client.get(
      _uri('/api/v1/store/orders/user/$userId'),
      headers: _headers,
    );
    _throwIfNeeded(response);
    return decodeStoreList(response.body)
        .map((item) => StoreOrder.fromMap(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<StoreOrder> reorder({
    required int orderId,
    String? notes,
  }) async {
    final response = await _client.post(
      _uri('/api/v1/store/orders/$orderId/reorder'),
      headers: _headers,
      body: jsonEncode({'notes': notes}),
    );
    _throwIfNeeded(response);
    return StoreOrder.fromMap(decodeStoreObject(response.body));
  }

  Future<StoreOrder> updateOrderStatus({
    required int orderId,
    required StoreOrderStatus status,
    String? shippingStatus,
    String? trackingNumber,
    String? shippingCarrier,
    String? vendorReference,
  }) async {
    final response = await _client.patch(
      _uri('/api/v1/store/orders/$orderId/status'),
      headers: _headers,
      body: jsonEncode({
        'status': status.name,
        'shipping_status': shippingStatus,
        'tracking_number': trackingNumber,
        'shipping_carrier': shippingCarrier,
        'vendor_reference': vendorReference,
      }),
    );
    _throwIfNeeded(response);
    return StoreOrder.fromMap(decodeStoreObject(response.body));
  }

  void _throwIfNeeded(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }
    String message = 'Store request failed.';
    try {
      final json = decodeStoreObject(response.body);
      message = json['detail']?.toString() ?? message;
    } catch (_) {
      message = response.body.isNotEmpty ? response.body : message;
    }
    throw Exception(message);
  }
}
