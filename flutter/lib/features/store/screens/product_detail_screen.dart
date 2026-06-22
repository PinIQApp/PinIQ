import 'package:flutter/material.dart';

import '../models/store_models.dart';
import '../services/store_api_service.dart';
import '../widgets/store_ui.dart';
import 'cart_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({
    super.key,
    required this.api,
    required this.productId,
    required this.currentUserId,
    required this.teamId,
    required this.schoolPrimaryColor,
    required this.schoolAccentColor,
  });

  final StoreApiService api;
  final int productId;
  final int currentUserId;
  final int teamId;
  final Color schoolPrimaryColor;
  final Color schoolAccentColor;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late Future<StoreProduct> _productFuture;
  int _quantity = 1;
  StoreOrderType _orderType = StoreOrderType.individual;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _productFuture = widget.api.fetchProduct(
      productId: widget.productId,
      teamId: widget.teamId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return StoreShell(
      title: 'Product Details',
      child: FutureBuilder<StoreProduct>(
        future: _productFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                snapshot.error.toString(),
                style: const TextStyle(color: Colors.redAccent),
              ),
            );
          }

          final product = snapshot.data!;
          final availableOrderTypes = _availableOrderTypes(product.visibility);
          if (!availableOrderTypes.contains(_orderType)) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() => _orderType = availableOrderTypes.first);
              }
            });
          }
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Image.network(
                  product.imageUrl ?? 'https://placehold.co/1200x900/png?text=WrestleTech',
                  height: 260,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      widget.schoolPrimaryColor.withOpacity(0.38),
                      widget.schoolAccentColor.withOpacity(0.14),
                      const Color(0xFF121821),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      product.description ?? 'WrestleTech store product',
                      style: const TextStyle(color: Color(0xFFD7E0EF), height: 1.45),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        StoreMetricPill(label: 'SKU', value: product.sku),
                        StoreMetricPill(label: 'visibility', value: product.visibility.replaceAll('_', ' ')),
                        StoreMetricPill(label: 'stock', value: product.stockStatus.replaceAll('_', ' ')),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(
                      '\$${product.sellPrice.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: widget.schoolAccentColor,
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              StorePanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Add To Cart',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<StoreOrderType>(
                      value: availableOrderTypes.contains(_orderType) ? _orderType : availableOrderTypes.first,
                      dropdownColor: const Color(0xFF1A2230),
                      style: const TextStyle(color: Colors.white),
                      decoration: _decoration('Order type'),
                      items: availableOrderTypes
                          .map(
                            (type) => DropdownMenuItem(
                              value: type,
                              child: Text(storeOrderTypeLabel(type)),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (value) => setState(() => _orderType = value ?? StoreOrderType.individual),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        IconButton(
                          onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                          color: Colors.white,
                          icon: const Icon(Icons.remove_circle_outline_rounded),
                        ),
                        Text(
                          '$_quantity',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        IconButton(
                          onPressed: () => setState(() => _quantity++),
                          color: Colors.white,
                          icon: const Icon(Icons.add_circle_outline_rounded),
                        ),
                        const Spacer(),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: widget.schoolAccentColor,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          ),
                          onPressed: _busy
                              ? null
                              : () async {
                                  setState(() => _busy = true);
                                  try {
                                    await widget.api.addToCart(
                                      teamId: widget.teamId,
                                      userId: widget.currentUserId,
                                      productId: product.id,
                                      orderType: _orderType,
                                      quantity: _quantity,
                                    );
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Added to cart')),
                                    );
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => CartScreen(
                                          api: widget.api,
                                          userId: widget.currentUserId,
                                          teamId: widget.teamId,
                                          schoolPrimaryColor: widget.schoolPrimaryColor,
                                          schoolAccentColor: widget.schoolAccentColor,
                                        ),
                                      ),
                                    );
                                  } finally {
                                    if (mounted) {
                                      setState(() => _busy = false);
                                    }
                                  }
                                },
                          child: const Text('Add To Cart'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

InputDecoration _decoration(String label) {
  return InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: Color(0xFF97A1B4)),
    filled: true,
    fillColor: const Color(0xFF1A2230),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide.none,
    ),
  );
}

List<StoreOrderType> _availableOrderTypes(String visibility) {
  switch (visibility) {
    case 'team_only':
      return const [StoreOrderType.teamSupply];
    case 'individual_only':
      return const [StoreOrderType.individual];
    default:
      return StoreOrderType.values;
  }
}
