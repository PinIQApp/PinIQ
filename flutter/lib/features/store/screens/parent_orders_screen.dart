import 'package:flutter/material.dart';

import '../models/store_models.dart';
import '../services/store_api_service.dart';
import '../widgets/store_ui.dart';

class ParentOrdersScreen extends StatefulWidget {
  const ParentOrdersScreen({
    super.key,
    required this.api,
    required this.userId,
    required this.schoolPrimaryColor,
    required this.schoolAccentColor,
  });

  final StoreApiService api;
  final int userId;
  final Color schoolPrimaryColor;
  final Color schoolAccentColor;

  @override
  State<ParentOrdersScreen> createState() => _ParentOrdersScreenState();
}

class _ParentOrdersScreenState extends State<ParentOrdersScreen> {
  late Future<List<StoreOrder>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _ordersFuture = widget.api.fetchUserOrders(userId: widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    return StoreShell(
      title: 'My Orders',
      child: FutureBuilder<List<StoreOrder>>(
        future: _ordersFuture,
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

          final orders = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: orders
                .map(
                  (order) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: StorePanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Order #${order.id}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              OrderStatusChip(status: order.status),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Total \$${order.total.toStringAsFixed(2)} • ${order.items.length} items',
                            style: const TextStyle(color: Color(0xFFD7E0EF)),
                          ),
                          if ((order.trackingNumber ?? '').isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Tracking: ${order.trackingNumber}',
                              style: const TextStyle(color: Color(0xFF97A1B4)),
                            ),
                          ],
                          const SizedBox(height: 10),
                          ...order.items.map(
                            (item) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Text(
                                '${item.quantity}x ${item.productNameSnapshot}',
                                style: const TextStyle(color: Color(0xFF97A1B4)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
                .toList(growable: false),
          );
        },
      ),
    );
  }
}
