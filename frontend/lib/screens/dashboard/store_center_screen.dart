import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../models/operator_models.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/section_header.dart';
import '../../widgets/subpage_header.dart';
import 'operator_editor_screens.dart';
import 'subscription_center_screen.dart';
import 'vendor_center_screen.dart';

class StoreCenterScreen extends StatefulWidget {
  const StoreCenterScreen({super.key});

  @override
  State<StoreCenterScreen> createState() => _StoreCenterScreenState();
}

class _StoreCenterScreenState extends State<StoreCenterScreen> {
  String _tab = 'storefront';
  String _filter = 'all';
  String _searchQuery = '';
  String? _selectedProductId;

  static const List<_BrandService> _brandServices = [
    _BrandService(
      title: 'School logo package',
      audience: 'Coach + school',
      summary:
          'Refine the official logo system used across the app, flyers, merch, and team materials.',
      bullets: [
        'Primary logo cleanup and export package',
        'Mascot mark variations for print and screen',
        'Ready for merch, flyers, and digital use',
      ],
    ),
    _BrandService(
      title: 'Mascot + color refresh',
      audience: 'Coach + school',
      summary:
          'Set primary and secondary colors, mascot naming, and a more polished branded look across the product.',
      bullets: [
        'Live visual preview',
        'Better dark-theme color balancing',
        'Keeps school identity separate from operator catalog',
      ],
    ),
    _BrandService(
      title: 'Team merch design studio',
      audience: 'Coach + team',
      summary:
          'Build singlets, warmups, shirts, and branded team drops from your school identity.',
      bullets: [
        'For school and team branding only',
        'Separated from operator dropshipping revenue',
        'Built for template saving and manufacturer export',
      ],
    ),
  ];

  static const List<_OfferStep> _offerLadder = [
    _OfferStep(
      label: 'Best first offer',
      title: 'Grip trainer',
      summary:
          'Lead with one simple performance product athletes, parents, and coaches understand instantly.',
      accent: Color(0xFF38BDF8),
    ),
    _OfferStep(
      label: 'Growth offer',
      title: 'Grip + bands bundle',
      summary:
          'Move the first purchase into a better-value performance bundle with clear match utility.',
      accent: Color(0xFF14B8A6),
    ),
    _OfferStep(
      label: 'Premium offer',
      title: 'Digital program + team packs',
      summary:
          'Upsell the 30-day program, coach packs, and recurring challenge offers behind the flagship product.',
      accent: Color(0xFFF59E0B),
    ),
  ];

  static const List<_BundleSpotlight> _bundleSpotlights = [
    _BundleSpotlight(
      title: 'Grip + Mini Band Bundle',
      price: '\$58',
      audience: 'Athlete + parent',
      summary:
          'Best first performance bundle for grip, activation, and home mat prep.',
      bullets: [
        'High-converting first upgrade',
        'Easy to explain on video',
        'Fits the flagship offer ladder'
      ],
    ),
    _BundleSpotlight(
      title: '30-Day Wrestler Domination',
      price: '\$24',
      audience: 'Parent + athlete',
      summary:
          'Digital upsell for serious wrestlers who want structure, challenge, and daily performance guidance.',
      bullets: [
        'Pure-margin back-end offer',
        'Perfect post-purchase upsell',
        'Extends the physical products into a system'
      ],
    ),
    _BundleSpotlight(
      title: 'Coach Grip Team Pack',
      price: '\$399',
      audience: 'Coach + program',
      summary:
          'Bulk performance tool pack built for coach outreach, off-season systems, and team development sales.',
      bullets: [
        'Best B2B growth offer',
        'Strong coach outreach product',
        'Turns the store into a team solution'
      ],
    ),
  ];

  static const List<_OperationsLane> _operationsLanes = [
    _OperationsLane(
      title: 'Storefront',
      summary:
          'Customer-facing shopping, bundles, plans, and team branding offers.',
      bullets: ['Collections', 'Bundles', 'Subscriptions', 'Checkout'],
    ),
    _OperationsLane(
      title: 'Fulfillment',
      summary:
          'Supplier routing, direct-ship packets, and vendor handoff by lane.',
      bullets: [
        'Dropship vendors',
        'PO / quote lane',
        'Shipping packets',
        'Vendor notes'
      ],
    ),
    _OperationsLane(
      title: 'Growth engine',
      summary:
          'Content, AI prompts, and seasonal campaigns that keep the catalog moving.',
      bullets: [
        'Offer ladder',
        'Launch promos',
        'Email/SMS hooks',
        'AI copy drafting'
      ],
    ),
  ];

  static const List<_MetricCardData> _metricCards = [
    _MetricCardData(
      label: 'Hook product',
      value: 'Grip',
      note:
          'The flagship offer should be easy to explain and easy to demo in under 3 seconds.',
    ),
    _MetricCardData(
      label: 'AOV lane',
      value: 'Bundles',
      note:
          'Grip + bands and recovery add-ons should raise average order value fast.',
    ),
    _MetricCardData(
      label: 'Margin lane',
      value: 'Digital',
      note:
          'The 30-day program and monthly challenge should be the highest-margin offers.',
    ),
    _MetricCardData(
      label: 'B2B lane',
      value: 'Team packs',
      note:
          'Coach packs should become the strongest school and off-season sales offer.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final allProducts = appState.operatorProducts;
    final products = _visibleProducts(allProducts);
    final plans = appState.operatorSubscriptionPlans;
    final showManagement = appState.canManageRevenue;

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        const SubpageHeader(
          title: 'Store',
          subtitle:
              'A wrestling-focused storefront for schools, teams, families, and operator revenue products.',
        ),
        const SizedBox(height: AppSpacing.lg),
        _StoreHero(
          cartCount: appState.storeCartItemCount,
          onBrowseSupplies: () => setState(() {
            _tab = 'storefront';
            _filter = 'everyday';
          }),
          onBrowsePlans: () => setState(() => _tab = 'plans'),
        ),
        const SizedBox(height: AppSpacing.xl),
        _StoreTabBar(
          value: _tab,
          showManagement: showManagement,
          onChanged: (value) => setState(() => _tab = value),
        ),
        const SizedBox(height: AppSpacing.xl),
        _StoreCommandDeck(
          showManagement: showManagement,
          cartCount: appState.storeCartItemCount,
          productCount: allProducts.length,
          planCount: plans.length,
          onBrowseSupplies: () => setState(() {
            _tab = 'storefront';
            _filter = 'everyday';
          }),
          onBrowsePlans: () => setState(() => _tab = 'plans'),
          onOpenManagement:
              showManagement ? () => setState(() => _tab = 'management') : null,
        ),
        const SizedBox(height: AppSpacing.xl),
        if (_tab == 'storefront')
          _StorefrontView(
            filter: _filter,
            searchQuery: _searchQuery,
            products: products,
            allProducts: allProducts,
            selectedProductId: _selectedProductId,
            onFilterChanged: (value) => setState(() => _filter = value),
            onSearchChanged: (value) => setState(() => _searchQuery = value),
            onSelectProduct: (product) =>
                setState(() => _selectedProductId = product.id),
            onOpenProduct: _openProductDetail,
            onAddToCart: (product) =>
                context.read<AppState>().addProductToCart(product.id),
            brandServices: _brandServices,
            offerLadder: _offerLadder,
            bundleSpotlights: _bundleSpotlights,
          ),
        if (_tab == 'plans') _PlansView(plans: plans),
        if (_tab == 'management')
          _ManagementView(
            canManageRevenue: showManagement,
            products: allProducts,
            offerLadder: _offerLadder,
            operationsLanes: _operationsLanes,
            metricCards: _metricCards,
            onAddListing: _openCreateProduct,
            onEditListing: _openEditProduct,
            onOpenSubscriptions: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => const SubscriptionCenterScreen()),
              );
            },
            onOpenVendors: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const VendorCenterScreen()),
              );
            },
          ),
      ],
    );
  }

  List<OperatorProduct> _visibleProducts(List<OperatorProduct> products) {
    return products.where((product) {
      final matchesSearch = _searchQuery.trim().isEmpty
          ? true
          : product.name
                  .toLowerCase()
                  .contains(_searchQuery.trim().toLowerCase()) ||
              product.category
                  .toLowerCase()
                  .contains(_searchQuery.trim().toLowerCase()) ||
              product.summary
                  .toLowerCase()
                  .contains(_searchQuery.trim().toLowerCase());
      if (!matchesSearch) return false;
      return switch (_filter) {
        'performance' =>
          product.category == 'Performance' || product.category == 'Recovery',
        'digital' =>
          product.category == 'Digital' || product.category == 'Team Pack',
        'everyday' =>
          product.category == 'Cleaning' || product.category == 'Facility',
        'equipment' => product.category == 'Equipment',
        'tech' => product.category == 'Tech',
        'shoes' => product.category == 'Shoes',
        _ => true,
      };
    }).toList();
  }

  Future<void> _openCreateProduct() async {
    final created = await Navigator.of(context).push<OperatorProduct>(
      MaterialPageRoute(
        builder: (_) => const ProductEditorScreen(title: 'Create listing'),
      ),
    );
    if (!mounted || created == null) return;
    context.read<AppState>().addOperatorProduct(created);
    setState(() => _selectedProductId = created.id);
  }

  Future<void> _openEditProduct(OperatorProduct product) async {
    final updated = await Navigator.of(context).push<OperatorProduct>(
      MaterialPageRoute(
        builder: (_) => ProductEditorScreen(
          title: 'Edit listing',
          initialProduct: product,
        ),
      ),
    );
    if (!mounted || updated == null) return;
    context.read<AppState>().updateOperatorProduct(updated);
    setState(() => _selectedProductId = updated.id);
  }

  void _openProductDetail(OperatorProduct product) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _StoreProductDetailScreen(
          product: product,
          onAddToCart: () =>
              context.read<AppState>().addProductToCart(product.id),
        ),
      ),
    );
  }
}

class _StoreHero extends StatelessWidget {
  const _StoreHero({
    required this.cartCount,
    required this.onBrowseSupplies,
    required this.onBrowsePlans,
  });

  final int cartCount;
  final VoidCallback onBrowseSupplies;
  final VoidCallback onBrowsePlans;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF162845),
            Color(0xFF0D1726),
            Color(0xFF1A2231),
          ],
        ),
        borderRadius: BorderRadius.circular(32),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stacked = constraints.maxWidth < 940;
          final copy = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _StoreBadge(
                  label: 'Wrestling store', color: Color(0xFF38BDF8)),
              const SizedBox(height: AppSpacing.md),
              if (cartCount > 0) ...[
                _StoreBadge(
                  label: '$cartCount items in cart',
                  color: const Color(0xFF14B8A6),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              Text(
                'Performance tools, room essentials, team packs, and plans built for serious wrestlers.',
                style: AppTextStyles.pageTitle.copyWith(fontSize: 36),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Lead with products that improve performance, layer in bundles and digital offers, and keep school branding services separate from the operator business.',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textPrimary.withValues(alpha: 0.84),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  ElevatedButton.icon(
                    onPressed: onBrowseSupplies,
                    icon: const Icon(Icons.shopping_bag_outlined),
                    label: const Text('Shop supplies'),
                  ),
                  OutlinedButton.icon(
                    onPressed: onBrowsePlans,
                    icon: const Icon(Icons.workspace_premium_outlined),
                    label: const Text('View plans'),
                  ),
                ],
              ),
            ],
          );

          final highlights = _HeroHighlights(
            items: const [
              _HeroHighlight(
                label: 'Flagship lane',
                value: 'Grip + hand fight',
                note: 'Simple tools that tie directly to match performance',
              ),
              _HeroHighlight(
                label: 'Bundle lane',
                value: 'Bands + recovery',
                note: 'Fast add-ons that lift order value',
              ),
              _HeroHighlight(
                label: 'Back-end lane',
                value: 'Digital + team packs',
                note: 'Programs, challenge offers, and coach bundles',
              ),
            ],
          );

          if (stacked) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                copy,
                const SizedBox(height: AppSpacing.lg),
                highlights,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 6, child: copy),
              const SizedBox(width: AppSpacing.xl),
              Expanded(
                flex: 5,
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: AppColors.surface.withValues(alpha: 0.72),
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.asset(
                          'assets/images/wrestletech_logo.jpg',
                          height: 150,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    highlights,
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

class _StoreTabBar extends StatelessWidget {
  const _StoreTabBar({
    required this.value,
    required this.showManagement,
    required this.onChanged,
  });

  final String value;
  final bool showManagement;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final tabs = [
      ('storefront', 'Storefront'),
      ('plans', 'Plans'),
      if (showManagement) ('management', 'Management'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final tab in tabs)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: ChoiceChip(
                label: Text(tab.$2),
                selected: value == tab.$1,
                onSelected: (_) => onChanged(tab.$1),
              ),
            ),
        ],
      ),
    );
  }
}

class _StoreCommandDeck extends StatelessWidget {
  const _StoreCommandDeck({
    required this.showManagement,
    required this.cartCount,
    required this.productCount,
    required this.planCount,
    required this.onBrowseSupplies,
    required this.onBrowsePlans,
    required this.onOpenManagement,
  });

  final bool showManagement;
  final int cartCount;
  final int productCount;
  final int planCount;
  final VoidCallback onBrowseSupplies;
  final VoidCallback onBrowsePlans;
  final VoidCallback? onOpenManagement;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stacked = constraints.maxWidth < 980;
          final actions = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Store command', style: AppTextStyles.bodyStrong),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Keep the store easy to shop, easy to explain, and clearly separated between team-facing services and operator revenue lanes.',
                style: AppTextStyles.body,
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  ElevatedButton.icon(
                    onPressed: onBrowseSupplies,
                    icon: const Icon(Icons.shopping_bag_outlined),
                    label: const Text('Shop supplies'),
                  ),
                  OutlinedButton.icon(
                    onPressed: onBrowsePlans,
                    icon: const Icon(Icons.workspace_premium_outlined),
                    label: const Text('Open plans'),
                  ),
                  if (showManagement)
                    OutlinedButton.icon(
                      onPressed: onOpenManagement,
                      icon: const Icon(Icons.storefront_outlined),
                      label: const Text('Management'),
                    ),
                ],
              ),
            ],
          );

          final metrics = Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [
              _StoreMetricCard(
                label: 'Cart',
                value: '$cartCount',
                note: 'active items',
              ),
              _StoreMetricCard(
                label: 'Listings',
                value: '$productCount',
                note: 'catalog products',
              ),
              _StoreMetricCard(
                label: 'Plans',
                value: '$planCount',
                note: 'program offers',
              ),
            ],
          );

          if (stacked) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                actions,
                const SizedBox(height: AppSpacing.lg),
                metrics,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 4, child: actions),
              const SizedBox(width: AppSpacing.xl),
              Expanded(flex: 6, child: metrics),
            ],
          );
        },
      ),
    );
  }
}

class _StoreMetricCard extends StatelessWidget {
  const _StoreMetricCard({
    required this.label,
    required this.value,
    required this.note,
  });

  final String label;
  final String value;
  final String note;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.caption),
          const SizedBox(height: AppSpacing.xs),
          Text(value, style: AppTextStyles.cardTitle.copyWith(fontSize: 24)),
          const SizedBox(height: AppSpacing.xxs),
          Text(note, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

class _StorefrontView extends StatelessWidget {
  const _StorefrontView({
    required this.filter,
    required this.searchQuery,
    required this.products,
    required this.allProducts,
    required this.selectedProductId,
    required this.onFilterChanged,
    required this.onSearchChanged,
    required this.onSelectProduct,
    required this.onOpenProduct,
    required this.onAddToCart,
    required this.brandServices,
    required this.offerLadder,
    required this.bundleSpotlights,
  });

  final String filter;
  final String searchQuery;
  final List<OperatorProduct> products;
  final List<OperatorProduct> allProducts;
  final String? selectedProductId;
  final ValueChanged<String> onFilterChanged;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<OperatorProduct> onSelectProduct;
  final ValueChanged<OperatorProduct> onOpenProduct;
  final ValueChanged<OperatorProduct> onAddToCart;
  final List<_BrandService> brandServices;
  final List<_OfferStep> offerLadder;
  final List<_BundleSpotlight> bundleSpotlights;

  @override
  Widget build(BuildContext context) {
    final featured = products.take(3).toList();
    final selected = products
        .where((product) => product.id == selectedProductId)
        .firstOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Featured collections'),
        const SizedBox(height: AppSpacing.md),
        _CollectionShelf(products: products),
        const SizedBox(height: AppSpacing.xl),
        const SectionHeader(title: 'Offer ladder'),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'The store should lead customers from an easy first buy into bundles, subscriptions, and premium upgrades.',
          style: AppTextStyles.body,
        ),
        const SizedBox(height: AppSpacing.md),
        _OfferLadderStrip(steps: offerLadder),
        const SizedBox(height: AppSpacing.xl),
        const SectionHeader(title: 'Elite bundles'),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Bundles should do the heavy lifting because they feel more useful, sell faster, and usually make more than one-off items.',
          style: AppTextStyles.body,
        ),
        const SizedBox(height: AppSpacing.md),
        _BundleGrid(items: bundleSpotlights),
        const SizedBox(height: AppSpacing.xl),
        const SectionHeader(title: 'Shop the catalog'),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Everything here should feel like something a coach or parent could actually buy.',
          style: AppTextStyles.body,
        ),
        const SizedBox(height: AppSpacing.md),
        _StoreSearchBar(
          initialValue: searchQuery,
          onChanged: onSearchChanged,
        ),
        const SizedBox(height: AppSpacing.md),
        _StoreFilterRail(value: filter, onChanged: onFilterChanged),
        const SizedBox(height: AppSpacing.md),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 1160;
            if (wide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 7,
                    child: _ProductGrid(
                      products: products,
                      selectedProductId: selectedProductId,
                      onSelect: onSelectProduct,
                      onAddToCart: onAddToCart,
                      onOpen: onOpenProduct,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    flex: 4,
                    child: Column(
                      children: [
                        _StoreSpotlightPanel(
                          product: selected ??
                              (featured.isNotEmpty ? featured.first : null),
                          onOpen: onOpenProduct,
                          onAddToCart: onAddToCart,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _CartSummaryPanel(products: allProducts),
                      ],
                    ),
                  ),
                ],
              );
            }

            return Column(
              children: [
                _ProductGrid(
                  products: products,
                  selectedProductId: selectedProductId,
                  onSelect: onSelectProduct,
                  onAddToCart: onAddToCart,
                  onOpen: onOpenProduct,
                ),
                const SizedBox(height: AppSpacing.lg),
                _StoreSpotlightPanel(
                  product:
                      selected ?? (featured.isNotEmpty ? featured.first : null),
                  onOpen: onOpenProduct,
                  onAddToCart: onAddToCart,
                ),
                const SizedBox(height: AppSpacing.lg),
                _CartSummaryPanel(products: allProducts),
              ],
            );
          },
        ),
        const SizedBox(height: AppSpacing.xl),
        const SectionHeader(title: 'School branding services'),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Branding and logo work belongs here for schools and teams. This stays separate from your dropshipping catalog.',
          style: AppTextStyles.body,
        ),
        const SizedBox(height: AppSpacing.md),
        _BrandServiceGrid(services: brandServices),
        const SizedBox(height: AppSpacing.xl),
        _CheckoutWorkflowPanel(products: allProducts),
      ],
    );
  }
}

class _PlansView extends StatelessWidget {
  const _PlansView({required this.plans});

  final List<OperatorSubscriptionPlan> plans;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.78),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _StoreBadge(
                  label: 'Program plans', color: Color(0xFFF59E0B)),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Start free for 7 days, then choose monthly or annual.',
                style: AppTextStyles.sectionTitle.copyWith(fontSize: 30),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Annual is the best-value plan at \$29/month billed yearly. Monthly stays flexible at \$39/month.',
                style: AppTextStyles.body,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        _PlanGrid(plans: plans),
      ],
    );
  }
}

class _ManagementView extends StatelessWidget {
  const _ManagementView({
    required this.canManageRevenue,
    required this.products,
    required this.offerLadder,
    required this.operationsLanes,
    required this.metricCards,
    required this.onAddListing,
    required this.onEditListing,
    required this.onOpenSubscriptions,
    required this.onOpenVendors,
  });

  final bool canManageRevenue;
  final List<OperatorProduct> products;
  final List<_OfferStep> offerLadder;
  final List<_OperationsLane> operationsLanes;
  final List<_MetricCardData> metricCards;
  final VoidCallback onAddListing;
  final ValueChanged<OperatorProduct> onEditListing;
  final VoidCallback onOpenSubscriptions;
  final VoidCallback onOpenVendors;

  @override
  Widget build(BuildContext context) {
    if (!canManageRevenue) {
      return const _LockedManagementCard();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.78),
            borderRadius: BorderRadius.circular(28),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final stacked = constraints.maxWidth < 820;
              final controls = Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  ElevatedButton.icon(
                    onPressed: onAddListing,
                    icon: const Icon(Icons.add_business_outlined),
                    label: const Text('Add listing'),
                  ),
                  OutlinedButton.icon(
                    onPressed: onOpenSubscriptions,
                    icon: const Icon(Icons.receipt_long_rounded),
                    label: const Text('Open subscriptions'),
                  ),
                  OutlinedButton.icon(
                    onPressed: onOpenVendors,
                    icon: const Icon(Icons.local_shipping_outlined),
                    label: const Text('Open vendors'),
                  ),
                ],
              );

              final intro = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _StoreBadge(
                      label: 'Operator only', color: Color(0xFF14B8A6)),
                  const SizedBox(height: AppSpacing.md),
                  Text('Store management',
                      style: AppTextStyles.sectionTitle.copyWith(fontSize: 30)),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'This is where listings, vendors, margins, and recurring plans live. Keep it away from the customer-facing storefront.',
                    style: AppTextStyles.body,
                  ),
                ],
              );

              if (stacked) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    intro,
                    const SizedBox(height: AppSpacing.lg),
                    controls,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 6, child: intro),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                      flex: 5,
                      child: Align(
                          alignment: Alignment.topRight, child: controls)),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        const SectionHeader(title: 'Elite store model'),
        const SizedBox(height: AppSpacing.md),
        _OfferLadderStrip(steps: offerLadder),
        const SizedBox(height: AppSpacing.xl),
        const SectionHeader(title: 'Operations'),
        const SizedBox(height: AppSpacing.md),
        _OperationsGrid(lanes: operationsLanes),
        const SizedBox(height: AppSpacing.xl),
        const SectionHeader(title: 'Metrics that matter'),
        const SizedBox(height: AppSpacing.md),
        _MetricsGrid(items: metricCards),
        const SizedBox(height: AppSpacing.xl),
        const SectionHeader(title: 'Listing queue'),
        const SizedBox(height: AppSpacing.md),
        ...products.map(
          (product) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: _ManagementProductRow(
              product: product,
              onEdit: () => onEditListing(product),
            ),
          ),
        ),
      ],
    );
  }
}

class _OfferLadderStrip extends StatelessWidget {
  const _OfferLadderStrip({required this.steps});

  final List<_OfferStep> steps;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 980 ? 3 : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: AppSpacing.md,
            crossAxisSpacing: AppSpacing.md,
            childAspectRatio: columns == 1 ? 2.3 : 1.2,
          ),
          itemCount: steps.length,
          itemBuilder: (context, index) =>
              _OfferStepCard(step: steps[index], number: index + 1),
        );
      },
    );
  }
}

class _BundleGrid extends StatelessWidget {
  const _BundleGrid({required this.items});

  final List<_BundleSpotlight> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1080
            ? 3
            : constraints.maxWidth >= 720
                ? 2
                : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: AppSpacing.md,
            crossAxisSpacing: AppSpacing.md,
            childAspectRatio: columns == 1 ? 1.38 : 0.96,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) => _BundleCard(item: items[index]),
        );
      },
    );
  }
}

class _OperationsGrid extends StatelessWidget {
  const _OperationsGrid({required this.lanes});

  final List<_OperationsLane> lanes;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 980 ? 3 : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: AppSpacing.md,
            crossAxisSpacing: AppSpacing.md,
            childAspectRatio: columns == 1 ? 2.1 : 1.05,
          ),
          itemCount: lanes.length,
          itemBuilder: (context, index) =>
              _OperationsLaneCard(lane: lanes[index]),
        );
      },
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid({required this.items});

  final List<_MetricCardData> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1160
            ? 4
            : constraints.maxWidth >= 760
                ? 2
                : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: AppSpacing.md,
            crossAxisSpacing: AppSpacing.md,
            childAspectRatio: columns == 1 ? 2.3 : 1.25,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) => _MetricCard(item: items[index]),
        );
      },
    );
  }
}

class _OfferStepCard extends StatelessWidget {
  const _OfferStepCard({required this.step, required this.number});

  final _OfferStep step;
  final int number;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: step.accent.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(999),
                ),
                alignment: Alignment.center,
                child: Text(
                  '$number',
                  style: AppTextStyles.bodyStrong.copyWith(color: step.accent),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _StoreBadge(label: step.label, color: step.accent),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(step.title, style: AppTextStyles.cardTitle),
          const SizedBox(height: AppSpacing.sm),
          Text(step.summary, style: AppTextStyles.body),
        ],
      ),
    );
  }
}

class _BundleCard extends StatelessWidget {
  const _BundleCard({required this.item});

  final _BundleSpotlight item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _StoreBadge(label: item.audience, color: const Color(0xFF38BDF8)),
              const Spacer(),
              Text(item.price, style: AppTextStyles.bodyStrong),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(item.title,
              style: AppTextStyles.cardTitle.copyWith(fontSize: 22)),
          const SizedBox(height: AppSpacing.sm),
          Text(item.summary, style: AppTextStyles.body),
          const SizedBox(height: AppSpacing.md),
          ...item.bullets.map(
            (bullet) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Text('• $bullet',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textSecondary)),
            ),
          ),
        ],
      ),
    );
  }
}

class _OperationsLaneCard extends StatelessWidget {
  const _OperationsLaneCard({required this.lane});

  final _OperationsLane lane;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(lane.title, style: AppTextStyles.cardTitle),
          const SizedBox(height: AppSpacing.sm),
          Text(lane.summary, style: AppTextStyles.body),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: lane.bullets
                .map((bullet) =>
                    _StoreBadge(label: bullet, color: const Color(0xFF64748B)))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.item});

  final _MetricCardData item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.label, style: AppTextStyles.caption),
          const SizedBox(height: AppSpacing.sm),
          Text(item.value,
              style: AppTextStyles.cardTitle.copyWith(fontSize: 24)),
          const SizedBox(height: AppSpacing.sm),
          Text(item.note, style: AppTextStyles.body),
        ],
      ),
    );
  }
}

class _CollectionShelf extends StatelessWidget {
  const _CollectionShelf({required this.products});

  final List<OperatorProduct> products;

  @override
  Widget build(BuildContext context) {
    final items = [
      _CollectionCardData(
        title: 'Performance tools',
        count:
            '${products.where((item) => item.category == 'Performance' || item.category == 'Recovery').length} items',
        accent: const Color(0xFF38BDF8),
        summary:
            'Grip, bands, and recovery tools tied directly to mat performance.',
      ),
      _CollectionCardData(
        title: 'Digital + coach offers',
        count:
            '${products.where((item) => item.category == 'Digital' || item.category == 'Team Pack').length} items',
        accent: const Color(0xFFF59E0B),
        summary:
            'Programs, team packs, and offers that sell a system instead of a random product.',
      ),
      _CollectionCardData(
        title: 'Everyday supplies',
        count:
            '${products.where((item) => item.category == 'Cleaning' || item.category == 'Facility').length} items',
        accent: const Color(0xFF14B8A6),
        summary: 'Tape, cleaners, and room essentials teams actually reorder.',
      ),
      _CollectionCardData(
        title: 'Equipment + scoring',
        count:
            '${products.where((item) => item.category == 'Equipment' || item.category == 'Tech').length} items',
        accent: const Color(0xFF14B8A6),
        summary: 'Score clocks, TVs, and event hardware for serious programs.',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1120
            ? 3
            : constraints.maxWidth >= 760
                ? 2
                : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: AppSpacing.md,
            crossAxisSpacing: AppSpacing.md,
            childAspectRatio: constraints.maxWidth >= 760 ? 1.4 : 1.05,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) => _CollectionCard(data: items[index]),
        );
      },
    );
  }
}

class _ProductGrid extends StatelessWidget {
  const _ProductGrid({
    required this.products,
    required this.selectedProductId,
    required this.onSelect,
    required this.onAddToCart,
    required this.onOpen,
  });

  final List<OperatorProduct> products;
  final String? selectedProductId;
  final ValueChanged<OperatorProduct> onSelect;
  final ValueChanged<OperatorProduct> onAddToCart;
  final ValueChanged<OperatorProduct> onOpen;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return const _StoreEmptyCard();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 980
            ? 3
            : constraints.maxWidth >= 640
                ? 2
                : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: AppSpacing.md,
            crossAxisSpacing: AppSpacing.md,
            childAspectRatio: constraints.maxWidth >= 640 ? 0.9 : 0.86,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) => _StoreProductCard(
            product: products[index],
            selected: products[index].id == selectedProductId,
            onSelect: () => onSelect(products[index]),
            onAddToCart: () => onAddToCart(products[index]),
            onOpen: () => onOpen(products[index]),
          ),
        );
      },
    );
  }
}

class _StoreSpotlightPanel extends StatelessWidget {
  const _StoreSpotlightPanel({
    required this.product,
    required this.onOpen,
    required this.onAddToCart,
  });

  final OperatorProduct? product;
  final ValueChanged<OperatorProduct> onOpen;
  final ValueChanged<OperatorProduct> onAddToCart;

  @override
  Widget build(BuildContext context) {
    if (product == null) {
      return const _StoreEmptyCard();
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _StoreBadge(label: 'Spotlight', color: Color(0xFF38BDF8)),
          const SizedBox(height: AppSpacing.md),
          Text(product!.name,
              style: AppTextStyles.sectionTitle.copyWith(fontSize: 28)),
          const SizedBox(height: AppSpacing.xs),
          Text(product!.summary, style: AppTextStyles.body),
          const SizedBox(height: AppSpacing.lg),
          _SpotlightRow(label: 'Price', value: product!.price),
          _SpotlightRow(label: 'Category', value: product!.category),
          _SpotlightRow(label: 'Vendor', value: product!.vendor),
          _SpotlightRow(label: 'Restock', value: product!.cadence),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              ElevatedButton.icon(
                onPressed: () => onOpen(product!),
                icon: const Icon(Icons.open_in_new_rounded),
                label: const Text('View product'),
              ),
              OutlinedButton.icon(
                onPressed: () => onAddToCart(product!),
                icon: const Icon(Icons.add_shopping_cart_rounded),
                label: const Text('Add to cart'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BrandServiceGrid extends StatelessWidget {
  const _BrandServiceGrid({required this.services});

  final List<_BrandService> services;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1120
            ? 3
            : constraints.maxWidth >= 760
                ? 2
                : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: AppSpacing.md,
            crossAxisSpacing: AppSpacing.md,
            childAspectRatio: constraints.maxWidth >= 760 ? 1.06 : 0.98,
          ),
          itemCount: services.length,
          itemBuilder: (context, index) =>
              _BrandServiceCard(service: services[index]),
        );
      },
    );
  }
}

class _PlanGrid extends StatelessWidget {
  const _PlanGrid({required this.plans});

  final List<OperatorSubscriptionPlan> plans;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1120
            ? 3
            : constraints.maxWidth >= 760
                ? 2
                : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: AppSpacing.md,
            crossAxisSpacing: AppSpacing.md,
            childAspectRatio: constraints.maxWidth >= 760 ? 0.92 : 0.9,
          ),
          itemCount: plans.length,
          itemBuilder: (context, index) => _PlanCard(plan: plans[index]),
        );
      },
    );
  }
}

class _StoreProductDetailScreen extends StatelessWidget {
  const _StoreProductDetailScreen({
    required this.product,
    required this.onAddToCart,
  });

  final OperatorProduct product;
  final VoidCallback onAddToCart;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        SubpageHeader(
          title: product.name,
          subtitle: '${product.category} • ${product.vendor}',
        ),
        const SizedBox(height: AppSpacing.lg),
        Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.78),
            borderRadius: BorderRadius.circular(30),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final stacked = constraints.maxWidth < 900;
              final media = Container(
                constraints: const BoxConstraints(minHeight: 300),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF21324B),
                      Color(0xFF151F2E),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: Image.asset(
                          'assets/images/wrestletech_icon.jpg',
                          fit: BoxFit.cover,
                          color: Colors.black.withValues(alpha: 0.28),
                          colorBlendMode: BlendMode.darken,
                        ),
                      ),
                    ),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.asset(
                              'assets/images/wrestletech_logo.jpg',
                              height: 120,
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(product.category,
                              style: AppTextStyles.cardTitle),
                          const SizedBox(height: AppSpacing.xxs),
                          Text('Pin IQ product preview',
                              style: AppTextStyles.caption),
                        ],
                      ),
                    ),
                  ],
                ),
              );
              final details = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: [
                      _StoreBadge(
                          label: product.category,
                          color: const Color(0xFF38BDF8)),
                      _StoreBadge(
                          label: product.status,
                          color: product.status == 'Draft'
                              ? AppColors.textMuted
                              : AppColors.success),
                      _StoreBadge(
                          label: 'Margin ${product.margin}',
                          color: const Color(0xFFF59E0B)),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(product.name,
                      style: AppTextStyles.pageTitle.copyWith(fontSize: 38)),
                  const SizedBox(height: AppSpacing.xs),
                  Text(product.summary,
                      style: AppTextStyles.body.copyWith(fontSize: 16)),
                  const SizedBox(height: AppSpacing.lg),
                  Text(product.price,
                      style: AppTextStyles.sectionTitle.copyWith(fontSize: 30)),
                  const SizedBox(height: AppSpacing.sm),
                  _SpotlightRow(label: 'Vendor', value: product.vendor),
                  _SpotlightRow(label: 'Source', value: product.source),
                  _SpotlightRow(label: 'Reorder', value: product.cadence),
                  const SizedBox(height: AppSpacing.md),
                  Text('Why coaches buy it', style: AppTextStyles.bodyStrong),
                  const SizedBox(height: AppSpacing.sm),
                  ...product.bullets.map(
                    (bullet) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: Icon(Icons.check_circle_outline_rounded,
                                size: 18, color: Color(0xFF14B8A6)),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                              child: Text(bullet, style: AppTextStyles.body)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      ElevatedButton.icon(
                        onPressed: onAddToCart,
                        icon: const Icon(Icons.add_shopping_cart_rounded),
                        label: const Text('Add to cart'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.bookmark_border_rounded),
                        label: const Text('Save for later'),
                      ),
                    ],
                  ),
                ],
              );

              if (stacked) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    media,
                    const SizedBox(height: AppSpacing.lg),
                    details,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 5, child: media),
                  const SizedBox(width: AppSpacing.xl),
                  Expanded(flex: 6, child: details),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _StoreProductCard extends StatelessWidget {
  const _StoreProductCard({
    required this.product,
    required this.selected,
    required this.onSelect,
    required this.onAddToCart,
    required this.onOpen,
  });

  final OperatorProduct product;
  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback onAddToCart;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final accent = product.status == 'Draft'
        ? AppColors.textMuted
        : const Color(0xFF14B8A6);
    return InkWell(
      onTap: onSelect,
      borderRadius: BorderRadius.circular(26),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.surfaceElevated
              : AppColors.surface.withValues(alpha: 0.78),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color:
                selected ? accent.withValues(alpha: 0.42) : Colors.transparent,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 170,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF21324B),
                    Color(0xFF151F2E),
                  ],
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: Image.asset(
                        'assets/images/wrestletech_icon.jpg',
                        fit: BoxFit.cover,
                        color: Colors.black.withValues(alpha: 0.36),
                        colorBlendMode: BlendMode.darken,
                      ),
                    ),
                  ),
                  Center(
                    child: Image.asset(
                      'assets/images/wrestletech_logo.jpg',
                      width: 150,
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                _StoreBadge(
                    label: product.category, color: const Color(0xFF38BDF8)),
                _StoreBadge(label: product.status, color: accent),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(product.name, style: AppTextStyles.cardTitle),
            const SizedBox(height: AppSpacing.xs),
            Text(
              product.summary,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.body,
            ),
            const Spacer(),
            Row(
              children: [
                Text(product.price,
                    style: AppTextStyles.bodyStrong.copyWith(fontSize: 20)),
                const Spacer(),
                Text('Margin ${product.margin}', style: AppTextStyles.caption),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onSelect,
                    child: const Text('Quick view'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onAddToCart,
                    child: const Text('Add to cart'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.plan});

  final OperatorSubscriptionPlan plan;

  @override
  Widget build(BuildContext context) {
    final accent = switch (plan.cadence) {
      'Annual' => const Color(0xFFF59E0B),
      'Custom' => const Color(0xFF38BDF8),
      _ => const Color(0xFF14B8A6),
    };
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StoreBadge(label: plan.cadence, color: accent),
          const SizedBox(height: AppSpacing.md),
          Text(plan.title, style: AppTextStyles.cardTitle),
          const SizedBox(height: AppSpacing.sm),
          Text(plan.price,
              style: AppTextStyles.sectionTitle.copyWith(fontSize: 30)),
          const SizedBox(height: AppSpacing.xs),
          Text(plan.note, style: AppTextStyles.body),
          const SizedBox(height: AppSpacing.md),
          Text(plan.access, style: AppTextStyles.bodyStrong),
          const SizedBox(height: AppSpacing.md),
          ...plan.bullets.map(
            (bullet) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Icon(Icons.check_circle_outline_rounded,
                        size: 18, color: Color(0xFFF59E0B)),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text(bullet, style: AppTextStyles.body)),
                ],
              ),
            ),
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: null,
            icon: const Icon(Icons.workspace_premium_outlined),
            label: const Text('7-day trial soon'),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Beta mode: Stripe checkout is off while teams test the workflow.',
            style:
                AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _BrandServiceCard extends StatelessWidget {
  const _BrandServiceCard({required this.service});

  final _BrandService service;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.asset(
                  'assets/images/wrestletech_icon.jpg',
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _StoreBadge(
                      label: service.audience, color: const Color(0xFFF472B6)),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(service.title, style: AppTextStyles.cardTitle),
          const SizedBox(height: AppSpacing.xs),
          Text(service.summary, style: AppTextStyles.body),
          const SizedBox(height: AppSpacing.md),
          ...service.bullets.map(
            (bullet) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Icon(Icons.palette_outlined,
                        size: 18, color: Color(0xFFF472B6)),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text(bullet, style: AppTextStyles.body)),
                ],
              ),
            ),
          ),
          const Spacer(),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.brush_outlined),
            label: const Text('Open branding'),
          ),
        ],
      ),
    );
  }
}

class _ManagementProductRow extends StatelessWidget {
  const _ManagementProductRow({
    required this.product,
    required this.onEdit,
  });

  final OperatorProduct product;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(_iconForCategory(product.category),
                color: AppColors.textSecondary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name, style: AppTextStyles.bodyStrong),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  '${product.category} • ${product.price} • ${product.vendor}',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          OutlinedButton.icon(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Edit'),
          ),
        ],
      ),
    );
  }
}

class _LockedManagementCard extends StatelessWidget {
  const _LockedManagementCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Management locked', style: AppTextStyles.cardTitle),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Only the operator account can manage listings, subscriptions, vendors, and margins.',
            style: AppTextStyles.body,
          ),
        ],
      ),
    );
  }
}

class _HeroHighlights extends StatelessWidget {
  const _HeroHighlights({required this.items});

  final List<_HeroHighlight> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.74),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            _HeroHighlightCard(item: items[i]),
            if (i != items.length - 1) const SizedBox(height: AppSpacing.md),
          ],
        ],
      ),
    );
  }
}

class _HeroHighlightCard extends StatelessWidget {
  const _HeroHighlightCard({required this.item});

  final _HeroHighlight item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.label, style: AppTextStyles.caption),
          const SizedBox(height: AppSpacing.xs),
          Text(item.value, style: AppTextStyles.cardTitle),
          const SizedBox(height: AppSpacing.xxs),
          Text(item.note, style: AppTextStyles.body),
        ],
      ),
    );
  }
}

class _CollectionCard extends StatelessWidget {
  const _CollectionCard({required this.data});

  final _CollectionCardData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StoreBadge(label: data.count, color: data.accent),
          const Spacer(),
          Text(data.title, style: AppTextStyles.cardTitle),
          const SizedBox(height: AppSpacing.xs),
          Text(data.summary, style: AppTextStyles.body),
        ],
      ),
    );
  }
}

class _StoreFilterRail extends StatelessWidget {
  const _StoreFilterRail({
    required this.value,
    required this.onChanged,
  });

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    const filters = [
      ('all', 'All items'),
      ('everyday', 'Everyday'),
      ('equipment', 'Equipment'),
      ('tech', 'Tech + scoring'),
      ('shoes', 'Shoes'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final filter in filters)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.xs),
              child: ChoiceChip(
                label: Text(filter.$2),
                selected: value == filter.$1,
                onSelected: (_) => onChanged(filter.$1),
              ),
            ),
        ],
      ),
    );
  }
}

class _StoreSearchBar extends StatefulWidget {
  const _StoreSearchBar({
    required this.initialValue,
    required this.onChanged,
  });

  final String initialValue;
  final ValueChanged<String> onChanged;

  @override
  State<_StoreSearchBar> createState() => _StoreSearchBarState();
}

class _StoreSearchBarState extends State<_StoreSearchBar> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(covariant _StoreSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue &&
        _controller.text != widget.initialValue) {
      _controller.text = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onChanged: widget.onChanged,
      decoration: const InputDecoration(
        prefixIcon: Icon(Icons.search_rounded),
        hintText: 'Search tape, clocks, shoes, cleaning, or equipment',
      ),
    );
  }
}

class _CartSummaryPanel extends StatelessWidget {
  const _CartSummaryPanel({required this.products});

  final List<OperatorProduct> products;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final cartEntries = appState.storeCart.entries
        .map((entry) {
          final product =
              products.where((item) => item.id == entry.key).firstOrNull;
          if (product == null) return null;
          return (product: product, quantity: entry.value);
        })
        .whereType<({OperatorProduct product, int quantity})>()
        .toList();
    final subtotal = cartEntries.fold<double>(
      0,
      (sum, entry) => sum + (_priceValue(entry.product.price) * entry.quantity),
    );

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _StoreBadge(label: 'Cart', color: Color(0xFF14B8A6)),
          const SizedBox(height: AppSpacing.md),
          Text('Cart summary', style: AppTextStyles.cardTitle),
          const SizedBox(height: AppSpacing.xs),
          Text(
            cartEntries.isEmpty
                ? 'Add everyday products here so the store feels like shopping instead of just browsing.'
                : '${appState.storeCartItemCount} items ready for checkout handoff.',
            style: AppTextStyles.body,
          ),
          const SizedBox(height: AppSpacing.lg),
          if (cartEntries.isEmpty)
            const Text('No items in cart yet.', style: AppTextStyles.caption)
          else
            ...cartEntries.take(4).map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(entry.product.name,
                              style: AppTextStyles.bodyStrong),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text('x${entry.quantity}',
                            style: AppTextStyles.caption),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          '\$${(_priceValue(entry.product.price) * entry.quantity).toStringAsFixed(0)}',
                          style: AppTextStyles.bodyStrong,
                        ),
                      ],
                    ),
                  ),
                ),
          const SizedBox(height: AppSpacing.lg),
          _SpotlightRow(
              label: 'Subtotal', value: '\$${subtotal.toStringAsFixed(0)}'),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              ElevatedButton.icon(
                onPressed: null,
                icon: const Icon(Icons.lock_clock_rounded),
                label: const Text('Checkout soon'),
              ),
              OutlinedButton.icon(
                onPressed: cartEntries.isEmpty ? null : appState.clearCart,
                icon: const Icon(Icons.remove_shopping_cart_outlined),
                label: const Text('Clear cart'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Beta note: checkout is intentionally disabled until Stripe is connected.',
            style:
                AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _CheckoutWorkflowPanel extends StatelessWidget {
  const _CheckoutWorkflowPanel({required this.products});

  final List<OperatorProduct> products;

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<AppState>().storeCart;
    final routed = cart.entries
        .map((entry) {
          final product =
              products.where((item) => item.id == entry.key).firstOrNull;
          if (product == null) return null;
          return (product: product, quantity: entry.value);
        })
        .whereType<({OperatorProduct product, int quantity})>()
        .toList();

    final groups = <String, List<({OperatorProduct product, int quantity})>>{};
    for (final entry in routed) {
      groups.putIfAbsent(entry.product.vendor, () => []).add(entry);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Checkout routing'),
        const SizedBox(height: AppSpacing.md),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 1020;
            final summary = _CheckoutStatusCard(
              title: 'Customer checkout',
              subtitle: routed.isEmpty
                  ? 'Build the cart to see how orders will split across suppliers.'
                  : '${routed.length} listing(s) are ready to route after payment.',
              bullets: const [
                'Beta users can build carts and review supplier routing',
                'Stripe checkout turns on after launch feedback',
                'Orders split by supplier or dropship lane',
              ],
              color: const Color(0xFF14B8A6),
            );
            final handoff = _CheckoutStatusCard(
              title: 'Supplier handoff',
              subtitle: groups.isEmpty
                  ? 'No supplier packets yet.'
                  : '${groups.length} supplier packet(s) will be created from this cart.',
              bullets: groups.entries
                  .map((entry) =>
                      '${entry.key}: ${entry.value.fold<int>(0, (sum, item) => sum + item.quantity)} item(s)')
                  .toList(),
              color: const Color(0xFF38BDF8),
            );

            if (!wide) {
              return Column(
                children: [
                  summary,
                  const SizedBox(height: AppSpacing.md),
                  handoff,
                ],
              );
            }

            return Row(
              children: [
                Expanded(child: summary),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: handoff),
              ],
            );
          },
        ),
        if (groups.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          ...groups.entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _SupplierRouteRow(
                vendor: entry.key,
                entries: entry.value,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _CheckoutStatusCard extends StatelessWidget {
  const _CheckoutStatusCard({
    required this.title,
    required this.subtitle,
    required this.bullets,
    required this.color,
  });

  final String title;
  final String subtitle;
  final List<String> bullets;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StoreBadge(label: title, color: color),
          const SizedBox(height: AppSpacing.md),
          Text(subtitle, style: AppTextStyles.body),
          const SizedBox(height: AppSpacing.md),
          ...bullets.map(
            (bullet) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle_outline_rounded,
                      size: 18, color: color),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text(bullet, style: AppTextStyles.body)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SupplierRouteRow extends StatelessWidget {
  const _SupplierRouteRow({
    required this.vendor,
    required this.entries,
  });

  final String vendor;
  final List<({OperatorProduct product, int quantity})> entries;

  @override
  Widget build(BuildContext context) {
    final lane = entries.any((item) =>
            item.product.category == 'Equipment' ||
            item.product.category == 'Tech')
        ? 'School PO / quote lane'
        : 'Direct dropship lane';
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.74),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(vendor, style: AppTextStyles.bodyStrong)),
              _StoreBadge(
                  label: lane,
                  color: lane.contains('PO')
                      ? const Color(0xFFF59E0B)
                      : const Color(0xFF14B8A6)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ...entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Text(
                '${entry.product.name} x${entry.quantity} • ${entry.product.source}',
                style: AppTextStyles.body,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StoreEmptyCard extends StatelessWidget {
  const _StoreEmptyCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('No products yet', style: AppTextStyles.cardTitle),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Add the first product to start building the storefront.',
            style: AppTextStyles.body,
          ),
        ],
      ),
    );
  }
}

class _StoreBadge extends StatelessWidget {
  const _StoreBadge({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
      ),
      child: Text(label,
          style: AppTextStyles.caption.copyWith(color: AppColors.textPrimary)),
    );
  }
}

class _SpotlightRow extends StatelessWidget {
  const _SpotlightRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          SizedBox(
            width: 88,
            child: Text(label, style: AppTextStyles.caption),
          ),
          Expanded(child: Text(value, style: AppTextStyles.bodyStrong)),
        ],
      ),
    );
  }
}

class _BrandService {
  const _BrandService({
    required this.title,
    required this.audience,
    required this.summary,
    required this.bullets,
  });

  final String title;
  final String audience;
  final String summary;
  final List<String> bullets;
}

class _OfferStep {
  const _OfferStep({
    required this.label,
    required this.title,
    required this.summary,
    required this.accent,
  });

  final String label;
  final String title;
  final String summary;
  final Color accent;
}

class _BundleSpotlight {
  const _BundleSpotlight({
    required this.title,
    required this.price,
    required this.audience,
    required this.summary,
    required this.bullets,
  });

  final String title;
  final String price;
  final String audience;
  final String summary;
  final List<String> bullets;
}

class _OperationsLane {
  const _OperationsLane({
    required this.title,
    required this.summary,
    required this.bullets,
  });

  final String title;
  final String summary;
  final List<String> bullets;
}

class _MetricCardData {
  const _MetricCardData({
    required this.label,
    required this.value,
    required this.note,
  });

  final String label;
  final String value;
  final String note;
}

class _CollectionCardData {
  const _CollectionCardData({
    required this.title,
    required this.count,
    required this.accent,
    required this.summary,
  });

  final String title;
  final String count;
  final Color accent;
  final String summary;
}

class _HeroHighlight {
  const _HeroHighlight({
    required this.label,
    required this.value,
    required this.note,
  });

  final String label;
  final String value;
  final String note;
}

double _priceValue(String price) {
  final clean = price.replaceAll(RegExp(r'[^0-9.]'), '');
  return double.tryParse(clean) ?? 0;
}

IconData _iconForCategory(String category) {
  return switch (category) {
    'Cleaning' => Icons.cleaning_services_outlined,
    'Facility' => Icons.inventory_2_outlined,
    'Equipment' => Icons.fitness_center_outlined,
    'Tech' => Icons.tv_outlined,
    'Shoes' => Icons.sports_martial_arts_outlined,
    _ => Icons.shopping_bag_outlined,
  };
}
