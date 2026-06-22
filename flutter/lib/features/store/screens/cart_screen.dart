import 'package:flutter/material.dart';

import '../models/store_models.dart';
import '../services/store_api_service.dart';
import '../widgets/store_ui.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({
    super.key,
    required this.api,
    required this.userId,
    required this.teamId,
    required this.schoolPrimaryColor,
    required this.schoolAccentColor,
  });

  final StoreApiService api;
  final int userId;
  final int teamId;
  final Color schoolPrimaryColor;
  final Color schoolAccentColor;

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _notesController = TextEditingController();
  final _addressController = TextEditingController();
  late Future<StoreCart> _cartFuture;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _notesController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _reload() {
    _cartFuture = widget.api.fetchCart(userId: widget.userId, teamId: widget.teamId);
  }

  @override
  Widget build(BuildContext context) {
    return StoreShell(
      title: 'Cart',
      child: RefreshIndicator(
        onRefresh: () async {
          setState(_reload);
          await _cartFuture;
        },
        child: FutureBuilder<StoreCart>(
          future: _cartFuture,
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

            final cart = snapshot.data!;
            final orderType = cart.items.isEmpty ? StoreOrderType.individual : cart.items.first.orderType;
            final shippingCost = orderType == StoreOrderType.teamSupply ? 0.0 : 7.50;
            final total = cart.subtotal + shippingCost;

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                ...cart.items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ProductCard(
                      product: item.product,
                      accentColor: widget.schoolAccentColor,
                      trailing: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'x${item.quantity}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '\$${item.lineTotal.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: widget.schoolAccentColor,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          TextButton(
                            onPressed: () async {
                              await widget.api.removeCartItem(itemId: item.id);
                              setState(_reload);
                            },
                            child: const Text('Remove'),
                          ),
                        ],
                      ),
                      onTap: () {},
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                StorePanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Checkout',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _notesController,
                        maxLines: 3,
                        style: const TextStyle(color: Colors.white),
                        decoration: _fieldDecoration('Order notes'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _addressController,
                        maxLines: 3,
                        style: const TextStyle(color: Colors.white),
                        decoration: _fieldDecoration(
                          orderType == StoreOrderType.teamSupply
                              ? 'Practice room delivery note'
                              : 'Shipping address',
                        ),
                      ),
                      const SizedBox(height: 18),
                      _summaryRow('Subtotal', cart.subtotal),
                      _summaryRow('Shipping', shippingCost),
                      _summaryRow('Total', total, highlight: true),
                      const SizedBox(height: 18),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: widget.schoolAccentColor,
                          foregroundColor: Colors.black,
                          minimumSize: const Size.fromHeight(52),
                        ),
                        onPressed: cart.items.isEmpty || _busy
                            ? null
                            : () async {
                                setState(() => _busy = true);
                                try {
                                  final order = await widget.api.createOrderFromCart(
                                    teamId: widget.teamId,
                                    purchaserId: widget.userId,
                                    orderType: orderType,
                                    cartItemIds: cart.items.map((item) => item.id).toList(growable: false),
                                    notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
                                    shippingAddress: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
                                    shippingCost: shippingCost,
                                  );
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Order #${order.id} created')),
                                  );
                                  setState(_reload);
                                } finally {
                                  if (mounted) {
                                    setState(() => _busy = false);
                                  }
                                }
                              },
                        child: const Text('Checkout'),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

Widget _summaryRow(String label, double value, {bool highlight = false}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: highlight ? Colors.white : const Color(0xFF97A1B4),
            fontWeight: highlight ? FontWeight.w800 : FontWeight.w500,
          ),
        ),
        Text(
          '\$${value.toStringAsFixed(2)}',
          style: TextStyle(
            color: Colors.white,
            fontWeight: highlight ? FontWeight.w900 : FontWeight.w700,
            fontSize: highlight ? 18 : 15,
          ),
        ),
      ],
    ),
  );
}

InputDecoration _fieldDecoration(String label) {
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
