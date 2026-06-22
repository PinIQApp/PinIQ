import 'dart:convert';

enum StoreOrderType { individual, teamSupply }

enum StoreOrderStatus {
  pending,
  paid,
  processing,
  shipped,
  delivered,
  cancelled,
}

enum ShippingStatus {
  notApplicable,
  pending,
  packed,
  shipped,
  delivered,
  cancelled,
}

String storeOrderTypeToApi(StoreOrderType value) {
  switch (value) {
    case StoreOrderType.teamSupply:
      return 'team_supply';
    case StoreOrderType.individual:
      return 'individual';
  }
}

StoreOrderType storeOrderTypeFromString(String value) {
  switch (value) {
    case 'team_supply':
      return StoreOrderType.teamSupply;
    case 'individual':
    default:
      return StoreOrderType.individual;
  }
}

StoreOrderStatus storeOrderStatusFromString(String value) {
  switch (value) {
    case 'paid':
      return StoreOrderStatus.paid;
    case 'processing':
      return StoreOrderStatus.processing;
    case 'shipped':
      return StoreOrderStatus.shipped;
    case 'delivered':
      return StoreOrderStatus.delivered;
    case 'cancelled':
      return StoreOrderStatus.cancelled;
    case 'pending':
    default:
      return StoreOrderStatus.pending;
  }
}

ShippingStatus shippingStatusFromString(String value) {
  switch (value) {
    case 'pending':
      return ShippingStatus.pending;
    case 'packed':
      return ShippingStatus.packed;
    case 'shipped':
      return ShippingStatus.shipped;
    case 'delivered':
      return ShippingStatus.delivered;
    case 'cancelled':
      return ShippingStatus.cancelled;
    case 'not_applicable':
    default:
      return ShippingStatus.notApplicable;
  }
}

String storeOrderStatusLabel(StoreOrderStatus value) {
  switch (value) {
    case StoreOrderStatus.pending:
      return 'Pending';
    case StoreOrderStatus.paid:
      return 'Paid';
    case StoreOrderStatus.processing:
      return 'Processing';
    case StoreOrderStatus.shipped:
      return 'Shipped';
    case StoreOrderStatus.delivered:
      return 'Delivered';
    case StoreOrderStatus.cancelled:
      return 'Cancelled';
  }
}

String storeOrderTypeLabel(StoreOrderType value) {
  switch (value) {
    case StoreOrderType.individual:
      return 'Individual';
    case StoreOrderType.teamSupply:
      return 'Team Supply';
  }
}

List<dynamic> decodeStoreList(String body) => jsonDecode(body) as List<dynamic>;
Map<String, dynamic> decodeStoreObject(String body) => jsonDecode(body) as Map<String, dynamic>;

class StoreCategory {
  const StoreCategory({
    required this.id,
    required this.slug,
    required this.name,
    this.description,
    this.iconName,
    required this.sortOrder,
    required this.isActive,
  });

  final int id;
  final String slug;
  final String name;
  final String? description;
  final String? iconName;
  final int sortOrder;
  final bool isActive;

  factory StoreCategory.fromMap(Map<String, dynamic> map) {
    return StoreCategory(
      id: map['id'] as int,
      slug: map['slug'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      iconName: map['icon_name'] as String?,
      sortOrder: (map['sort_order'] as num).toInt(),
      isActive: map['is_active'] as bool? ?? true,
    );
  }
}

class StoreVendor {
  const StoreVendor({
    required this.id,
    required this.name,
    required this.code,
    this.websiteUrl,
    required this.supportsDropship,
  });

  final int id;
  final String name;
  final String code;
  final String? websiteUrl;
  final bool supportsDropship;

  factory StoreVendor.fromMap(Map<String, dynamic> map) {
    return StoreVendor(
      id: map['id'] as int,
      name: map['name'] as String,
      code: map['code'] as String,
      websiteUrl: map['website_url'] as String?,
      supportsDropship: map['supports_dropship'] as bool? ?? false,
    );
  }
}

class StoreProductImage {
  const StoreProductImage({
    required this.id,
    required this.imageUrl,
    this.altText,
    required this.sortOrder,
  });

  final int id;
  final String imageUrl;
  final String? altText;
  final int sortOrder;

  factory StoreProductImage.fromMap(Map<String, dynamic> map) {
    return StoreProductImage(
      id: map['id'] as int,
      imageUrl: map['image_url'] as String,
      altText: map['alt_text'] as String?,
      sortOrder: (map['sort_order'] as num?)?.toInt() ?? 0,
    );
  }
}

class StoreProduct {
  const StoreProduct({
    required this.id,
    required this.categoryId,
    this.vendorId,
    required this.name,
    this.description,
    required this.sku,
    required this.costPrice,
    required this.sellPrice,
    required this.stockStatus,
    required this.visibility,
    required this.isActive,
    required this.isFeatured,
    required this.allowBackorder,
    this.inventoryCount,
    required this.inventoryTracked,
    this.imageUrl,
    this.brandName,
    this.unitLabel,
    this.shippingWeightOz,
    required this.createdAt,
    required this.updatedAt,
    this.category,
    this.vendor,
    required this.images,
    required this.marginAmount,
  });

  final int id;
  final int categoryId;
  final int? vendorId;
  final String name;
  final String? description;
  final String sku;
  final double costPrice;
  final double sellPrice;
  final String stockStatus;
  final String visibility;
  final bool isActive;
  final bool isFeatured;
  final bool allowBackorder;
  final int? inventoryCount;
  final bool inventoryTracked;
  final String? imageUrl;
  final String? brandName;
  final String? unitLabel;
  final int? shippingWeightOz;
  final DateTime createdAt;
  final DateTime updatedAt;
  final StoreCategory? category;
  final StoreVendor? vendor;
  final List<StoreProductImage> images;
  final double marginAmount;

  factory StoreProduct.fromMap(Map<String, dynamic> map) {
    return StoreProduct(
      id: map['id'] as int,
      categoryId: map['category_id'] as int,
      vendorId: map['vendor_id'] as int?,
      name: map['name'] as String,
      description: map['description'] as String?,
      sku: map['sku'] as String,
      costPrice: (map['cost_price'] as num).toDouble(),
      sellPrice: (map['sell_price'] as num).toDouble(),
      stockStatus: map['stock_status'] as String,
      visibility: map['visibility'] as String,
      isActive: map['is_active'] as bool? ?? true,
      isFeatured: map['is_featured'] as bool? ?? false,
      allowBackorder: map['allow_backorder'] as bool? ?? false,
      inventoryCount: (map['inventory_count'] as num?)?.toInt(),
      inventoryTracked: map['inventory_tracked'] as bool? ?? false,
      imageUrl: map['image_url'] as String?,
      brandName: map['brand_name'] as String?,
      unitLabel: map['unit_label'] as String?,
      shippingWeightOz: (map['shipping_weight_oz'] as num?)?.toInt(),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      category: map['category'] is Map<String, dynamic>
          ? StoreCategory.fromMap(map['category'] as Map<String, dynamic>)
          : null,
      vendor: map['vendor'] is Map<String, dynamic>
          ? StoreVendor.fromMap(map['vendor'] as Map<String, dynamic>)
          : null,
      images: ((map['images'] as List<dynamic>?) ?? const [])
          .map((item) => StoreProductImage.fromMap(item as Map<String, dynamic>))
          .toList(growable: false),
      marginAmount: (map['margin_amount'] as num?)?.toDouble() ??
          ((map['sell_price'] as num).toDouble() - (map['cost_price'] as num).toDouble()),
    );
  }
}

class TeamStoreConfig {
  const TeamStoreConfig({
    required this.id,
    required this.teamId,
    required this.storeName,
    this.storeTagline,
    required this.isStoreEnabled,
    required this.allowAthleteCheckout,
    required this.schoolGearEnabled,
    required this.featuredProductIds,
    required this.enabledCategoryIds,
    this.announcementText,
  });

  final int id;
  final int teamId;
  final String storeName;
  final String? storeTagline;
  final bool isStoreEnabled;
  final bool allowAthleteCheckout;
  final bool schoolGearEnabled;
  final List<int> featuredProductIds;
  final List<int> enabledCategoryIds;
  final String? announcementText;

  factory TeamStoreConfig.fromMap(Map<String, dynamic> map) {
    return TeamStoreConfig(
      id: map['id'] as int,
      teamId: map['team_id'] as int,
      storeName: map['store_name'] as String,
      storeTagline: map['store_tagline'] as String?,
      isStoreEnabled: map['is_store_enabled'] as bool? ?? true,
      allowAthleteCheckout: map['allow_athlete_checkout'] as bool? ?? false,
      schoolGearEnabled: map['school_gear_enabled'] as bool? ?? false,
      featuredProductIds: ((map['featured_product_ids'] as List<dynamic>?) ?? const [])
          .map((item) => (item as num).toInt())
          .toList(growable: false),
      enabledCategoryIds: ((map['enabled_category_ids'] as List<dynamic>?) ?? const [])
          .map((item) => (item as num).toInt())
          .toList(growable: false),
      announcementText: map['announcement_text'] as String?,
    );
  }
}

class TeamStoreBundle {
  const TeamStoreBundle({
    required this.teamId,
    required this.schoolName,
    this.schoolAbbreviation,
    required this.mascotName,
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
    required this.surfaceColor,
    this.logoUrl,
    required this.store,
    required this.categories,
    required this.featuredProducts,
    required this.products,
    required this.canPurchaseAsAthlete,
    required this.canManageStore,
    required this.visibilityRole,
    this.schoolGearPlaceholder,
  });

  final int teamId;
  final String schoolName;
  final String? schoolAbbreviation;
  final String mascotName;
  final String primaryColor;
  final String secondaryColor;
  final String accentColor;
  final String surfaceColor;
  final String? logoUrl;
  final TeamStoreConfig store;
  final List<StoreCategory> categories;
  final List<StoreProduct> featuredProducts;
  final List<StoreProduct> products;
  final bool canPurchaseAsAthlete;
  final bool canManageStore;
  final String visibilityRole;
  final String? schoolGearPlaceholder;

  factory TeamStoreBundle.fromMap(Map<String, dynamic> map) {
    return TeamStoreBundle(
      teamId: map['team_id'] as int,
      schoolName: map['school_name'] as String,
      schoolAbbreviation: map['school_abbreviation'] as String?,
      mascotName: map['mascot_name'] as String,
      primaryColor: map['primary_color'] as String,
      secondaryColor: map['secondary_color'] as String,
      accentColor: map['accent_color'] as String,
      surfaceColor: map['surface_color'] as String,
      logoUrl: map['logo_url'] as String?,
      store: TeamStoreConfig.fromMap(map['store'] as Map<String, dynamic>),
      categories: ((map['categories'] as List<dynamic>?) ?? const [])
          .map((item) => StoreCategory.fromMap(item as Map<String, dynamic>))
          .toList(growable: false),
      featuredProducts: ((map['featured_products'] as List<dynamic>?) ?? const [])
          .map((item) => StoreProduct.fromMap(item as Map<String, dynamic>))
          .toList(growable: false),
      products: ((map['products'] as List<dynamic>?) ?? const [])
          .map((item) => StoreProduct.fromMap(item as Map<String, dynamic>))
          .toList(growable: false),
      canPurchaseAsAthlete: map['can_purchase_as_athlete'] as bool? ?? false,
      canManageStore: map['can_manage_store'] as bool? ?? false,
      visibilityRole: map['visibility_role'] as String? ?? 'viewer',
      schoolGearPlaceholder: map['school_gear_placeholder'] as String?,
    );
  }
}

class StoreCartItem {
  const StoreCartItem({
    required this.id,
    required this.teamId,
    required this.userId,
    required this.productId,
    required this.orderType,
    required this.quantity,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    required this.product,
    required this.lineTotal,
  });

  final int id;
  final int teamId;
  final int userId;
  final int productId;
  final StoreOrderType orderType;
  final int quantity;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final StoreProduct product;
  final double lineTotal;

  factory StoreCartItem.fromMap(Map<String, dynamic> map) {
    return StoreCartItem(
      id: map['id'] as int,
      teamId: map['team_id'] as int,
      userId: map['user_id'] as int,
      productId: map['product_id'] as int,
      orderType: storeOrderTypeFromString(map['order_type'] as String),
      quantity: (map['quantity'] as num).toInt(),
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      product: StoreProduct.fromMap(map['product'] as Map<String, dynamic>),
      lineTotal: (map['line_total'] as num).toDouble(),
    );
  }
}

class StoreCart {
  const StoreCart({
    required this.userId,
    required this.teamId,
    required this.items,
    required this.subtotal,
    required this.itemCount,
  });

  final int userId;
  final int teamId;
  final List<StoreCartItem> items;
  final double subtotal;
  final int itemCount;

  factory StoreCart.fromMap(Map<String, dynamic> map) {
    return StoreCart(
      userId: map['user_id'] as int,
      teamId: map['team_id'] as int,
      items: ((map['items'] as List<dynamic>?) ?? const [])
          .map((item) => StoreCartItem.fromMap(item as Map<String, dynamic>))
          .toList(growable: false),
      subtotal: (map['subtotal'] as num).toDouble(),
      itemCount: (map['item_count'] as num).toInt(),
    );
  }
}

class StoreOrderItem {
  const StoreOrderItem({
    required this.id,
    required this.orderId,
    required this.productId,
    this.vendorId,
    required this.productNameSnapshot,
    required this.skuSnapshot,
    required this.quantity,
    required this.unitCostPrice,
    required this.unitSellPrice,
    required this.lineTotal,
    required this.shippingStatus,
    required this.createdAt,
    this.product,
    this.vendor,
  });

  final int id;
  final int orderId;
  final int productId;
  final int? vendorId;
  final String productNameSnapshot;
  final String skuSnapshot;
  final int quantity;
  final double unitCostPrice;
  final double unitSellPrice;
  final double lineTotal;
  final ShippingStatus shippingStatus;
  final DateTime createdAt;
  final StoreProduct? product;
  final StoreVendor? vendor;

  factory StoreOrderItem.fromMap(Map<String, dynamic> map) {
    return StoreOrderItem(
      id: map['id'] as int,
      orderId: map['order_id'] as int,
      productId: map['product_id'] as int,
      vendorId: map['vendor_id'] as int?,
      productNameSnapshot: map['product_name_snapshot'] as String,
      skuSnapshot: map['sku_snapshot'] as String,
      quantity: (map['quantity'] as num).toInt(),
      unitCostPrice: (map['unit_cost_price'] as num).toDouble(),
      unitSellPrice: (map['unit_sell_price'] as num).toDouble(),
      lineTotal: (map['line_total'] as num).toDouble(),
      shippingStatus: shippingStatusFromString(map['shipping_status'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
      product: map['product'] is Map<String, dynamic>
          ? StoreProduct.fromMap(map['product'] as Map<String, dynamic>)
          : null,
      vendor: map['vendor'] is Map<String, dynamic>
          ? StoreVendor.fromMap(map['vendor'] as Map<String, dynamic>)
          : null,
    );
  }
}

class StoreOrder {
  const StoreOrder({
    required this.id,
    required this.teamId,
    required this.purchaserId,
    required this.purchaserRole,
    required this.orderType,
    required this.status,
    required this.shippingStatus,
    required this.subtotal,
    required this.shippingCost,
    required this.total,
    this.notes,
    this.shippingAddress,
    this.shippingCarrier,
    this.trackingNumber,
    this.vendorReference,
    this.reorderedFromOrderId,
    required this.createdAt,
    required this.updatedAt,
    required this.items,
    required this.totalUnits,
  });

  final int id;
  final int teamId;
  final int purchaserId;
  final String purchaserRole;
  final StoreOrderType orderType;
  final StoreOrderStatus status;
  final ShippingStatus shippingStatus;
  final double subtotal;
  final double shippingCost;
  final double total;
  final String? notes;
  final String? shippingAddress;
  final String? shippingCarrier;
  final String? trackingNumber;
  final String? vendorReference;
  final int? reorderedFromOrderId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<StoreOrderItem> items;
  final int totalUnits;

  factory StoreOrder.fromMap(Map<String, dynamic> map) {
    return StoreOrder(
      id: map['id'] as int,
      teamId: map['team_id'] as int,
      purchaserId: map['purchaser_id'] as int,
      purchaserRole: map['purchaser_role'] as String,
      orderType: storeOrderTypeFromString(map['order_type'] as String),
      status: storeOrderStatusFromString(map['status'] as String),
      shippingStatus: shippingStatusFromString(map['shipping_status'] as String),
      subtotal: (map['subtotal'] as num).toDouble(),
      shippingCost: (map['shipping_cost'] as num).toDouble(),
      total: (map['total'] as num).toDouble(),
      notes: map['notes'] as String?,
      shippingAddress: map['shipping_address'] as String?,
      shippingCarrier: map['shipping_carrier'] as String?,
      trackingNumber: map['tracking_number'] as String?,
      vendorReference: map['vendor_reference'] as String?,
      reorderedFromOrderId: map['reordered_from_order_id'] as int?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      items: ((map['items'] as List<dynamic>?) ?? const [])
          .map((item) => StoreOrderItem.fromMap(item as Map<String, dynamic>))
          .toList(growable: false),
      totalUnits: (map['total_units'] as num?)?.toInt() ??
          ((map['items'] as List<dynamic>?) ?? const [])
              .map((item) => ((item as Map<String, dynamic>)['quantity'] as num).toInt())
              .fold(0, (a, b) => a + b),
    );
  }
}
