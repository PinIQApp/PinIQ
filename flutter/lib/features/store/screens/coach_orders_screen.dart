import 'package:flutter/material.dart';

import '../models/store_models.dart';
import '../services/store_api_service.dart';
import '../widgets/store_ui.dart';

class CoachOrdersScreen extends StatefulWidget {
  const CoachOrdersScreen({
    super.key,
    required this.api,
    required this.teamId,
    required this.schoolPrimaryColor,
    required this.schoolAccentColor,
  });

  final StoreApiService api;
  final int teamId;
  final Color schoolPrimaryColor;
  final Color schoolAccentColor;

  @override
  State<CoachOrdersScreen> createState() => _CoachOrdersScreenState();
}

class _CoachOrdersScreenState extends State<CoachOrdersScreen> {
  StoreOrderStatus? _filter;
  late Future<List<StoreOrder>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _ordersFuture = widget.api.fetchTeamOrders(
      teamId: widget.teamId,
      status: _filter,
    );
  }

  @override
  Widget build(BuildContext context) {
    return StoreShell(
      title: 'Coach Orders',
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
            children: [
              SizedBox(
                height: 42,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: StoreOrderStatus.values.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final value = index == 0 ? null : StoreOrderStatus.values[index - 1];
                    final selected = value == _filter;
                    return ChoiceChip(
                      selected: selected,
                      label: Text(value == null ? 'All' : storeOrderStatusLabel(value)),
                      backgroundColor: const Color(0xFF121821),
                      selectedColor: widget.schoolAccentColor,
                      side: const BorderSide(color: Colors.white10),
                      labelStyle: TextStyle(
                        color: selected ? Colors.black : Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                      onSelected: (_) {
                        setState(() {
                          _filter = value;
                          _reload();
                        });
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 18),
              ...orders.map(
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
                          '${storeOrderTypeLabel(order.orderType)} • ${order.totalUnits} units • \$${order.total.toStringAsFixed(2)}',
                          style: const TextStyle(color: Color(0xFFD7E0EF)),
                        ),
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
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: widget.schoolAccentColor,
                                foregroundColor: Colors.black,
                              ),
                              onPressed: () async {
                                await widget.api.reorder(
                                  orderId: order.id,
                                  notes: 'Quick reorder from coach dashboard',
                                );
                                setState(_reload);
                              },
                              child: const Text('Reorder'),
                            ),
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                              ),
                              onPressed: order.status == StoreOrderStatus.processing
                                  ? () async {
                                      await widget.api.updateOrderStatus(
                                        orderId: order.id,
                                        status: StoreOrderStatus.shipped,
                                        shippingStatus: 'shipped',
                                      );
                                      setState(_reload);
                                    }
                                  : null,
                              child: const Text('Mark Shipped'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
