import 'package:flutter/material.dart';

import '../models/store_models.dart';
import '../services/store_api_service.dart';
import '../widgets/store_ui.dart';
import 'category_product_list_screen.dart';
import 'coach_orders_screen.dart';
import 'coach_store_settings_screen.dart';
import 'parent_orders_screen.dart';
import 'product_detail_screen.dart';

class StoreHomeScreen extends StatefulWidget {
  const StoreHomeScreen({
    super.key,
    required this.api,
    required this.teamId,
    required this.currentUserId,
  });

  final StoreApiService api;
  final int teamId;
  final int currentUserId;

  @override
  State<StoreHomeScreen> createState() => _StoreHomeScreenState();
}

class _StoreHomeScreenState extends State<StoreHomeScreen> {
  late Future<TeamStoreBundle> _storeFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _storeFuture = widget.api.fetchTeamStore(teamId: widget.teamId);
  }

  @override
  Widget build(BuildContext context) {
    return StoreShell(
      title: 'Team Store',
      child: RefreshIndicator(
        onRefresh: () async {
          setState(_reload);
          await _storeFuture;
        },
        child: FutureBuilder<TeamStoreBundle>(
          future: _storeFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    snapshot.error.toString(),
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ],
              );
            }

            final store = snapshot.data!;
            final accent = _colorFromHex(store.accentColor);
            final primary = _colorFromHex(store.primaryColor);

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        primary.withOpacity(0.6),
                        accent.withOpacity(0.2),
                        const Color(0xFF101721),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        store.store.storeName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        store.store.storeTagline ??
                            'WrestleTech store for parents, coaches, and athletes.',
                        style: const TextStyle(color: Color(0xFFD7E0EF), height: 1.45),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          StoreMetricPill(label: 'categories', value: '${store.categories.length}'),
                          StoreMetricPill(label: 'featured', value: '${store.featuredProducts.length}'),
                          StoreMetricPill(label: 'role', value: store.visibilityRole.replaceAll('_', ' ')),
                        ],
                      ),
                      if ((store.store.announcementText ?? '').isNotEmpty) ...[
                        const SizedBox(height: 18),
                        Text(
                          store.store.announcementText!,
                          style: const TextStyle(color: Colors.white, height: 1.45),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => CategoryProductListScreen(
                              api: widget.api,
                              teamId: widget.teamId,
                              currentUserId: widget.currentUserId,
                              initialCategory: null,
                              schoolPrimaryColor: primary,
                              schoolAccentColor: accent,
                            ),
                          ),
                        );
                      },
                      child: const Text('Browse Store'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(color: accent.withOpacity(0.5)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: () {
                        final screen = store.canManageStore
                            ? CoachOrdersScreen(
                                api: widget.api,
                                teamId: widget.teamId,
                                schoolPrimaryColor: primary,
                                schoolAccentColor: accent,
                              )
                            : ParentOrdersScreen(
                                api: widget.api,
                                userId: widget.currentUserId,
                                schoolPrimaryColor: primary,
                                schoolAccentColor: accent,
                              );
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => screen),
                        );
                      },
                      child: Text(store.canManageStore ? 'Coach Orders' : 'My Orders'),
                    ),
                    if (store.canManageStore) ...[
                      const SizedBox(height: 12),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: accent,
                          side: BorderSide(color: accent.withOpacity(0.5)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: () async {
                          final refreshed = await Navigator.of(context).push<bool>(
                            MaterialPageRoute(
                              builder: (_) => CoachStoreSettingsScreen(
                                api: widget.api,
                                teamId: widget.teamId,
                                bundle: store,
                                schoolPrimaryColor: primary,
                                schoolAccentColor: accent,
                              ),
                            ),
                          );
                          if (refreshed == true && mounted) {
                            setState(_reload);
                          }
                        },
                        child: const Text('Manage Store'),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 22),
                const Text(
                  'Shop By Category',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 130,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: store.categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final category = store.categories[index];
                      return InkWell(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => CategoryProductListScreen(
                                api: widget.api,
                                teamId: widget.teamId,
                                currentUserId: widget.currentUserId,
                                initialCategory: category,
                                schoolPrimaryColor: primary,
                                schoolAccentColor: accent,
                              ),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(22),
                        child: Ink(
                          width: 180,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: const Color(0xFF121821),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: accent.withOpacity(0.16),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(
                                  _iconForCategory(category.slug),
                                  color: accent,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                category.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                category.description ?? '',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF97A1B4),
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 22),
                const Text(
                  'Featured Products',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                ...store.featuredProducts.map(
                  (product) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ProductCard(
                      product: product,
                      accentColor: accent,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ProductDetailScreen(
                              api: widget.api,
                              productId: product.id,
                              currentUserId: widget.currentUserId,
                              teamId: widget.teamId,
                              schoolPrimaryColor: primary,
                              schoolAccentColor: accent,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                if (store.schoolGearPlaceholder != null) ...[
                  const SizedBox(height: 22),
                  StorePanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'School Gear',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          store.schoolGearPlaceholder!,
                          style: const TextStyle(color: Color(0xFFD7E0EF), height: 1.45),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

Color _colorFromHex(String value) {
  final hex = value.replaceAll('#', '');
  return Color(int.parse('FF$hex', radix: 16));
}

IconData _iconForCategory(String slug) {
  switch (slug) {
    case 'medical':
      return Icons.medical_services_rounded;
    case 'mat-tape':
      return Icons.construction_rounded;
    case 'sanitizing':
      return Icons.cleaning_services_rounded;
    case 'equipment':
      return Icons.sports_mma;
    case 'scoring-supplies':
      return Icons.timer_rounded;
    case 'training-accessories':
      return Icons.fitness_center_rounded;
    case 'apparel-basics':
      return Icons.checkroom_rounded;
    default:
      return Icons.storefront_rounded;
  }
}
