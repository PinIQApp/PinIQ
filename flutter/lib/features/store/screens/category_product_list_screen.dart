import 'package:flutter/material.dart';

import '../models/store_models.dart';
import '../services/store_api_service.dart';
import '../widgets/store_ui.dart';
import 'product_detail_screen.dart';

class CategoryProductListScreen extends StatefulWidget {
  const CategoryProductListScreen({
    super.key,
    required this.api,
    required this.teamId,
    required this.currentUserId,
    required this.schoolPrimaryColor,
    required this.schoolAccentColor,
    this.initialCategory,
  });

  final StoreApiService api;
  final int teamId;
  final int currentUserId;
  final Color schoolPrimaryColor;
  final Color schoolAccentColor;
  final StoreCategory? initialCategory;

  @override
  State<CategoryProductListScreen> createState() => _CategoryProductListScreenState();
}

class _CategoryProductListScreenState extends State<CategoryProductListScreen> {
  final _searchController = TextEditingController();
  StoreCategory? _selectedCategory;
  late Future<TeamStoreBundle> _storeFuture;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
    _reload();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _reload() {
    _storeFuture = widget.api.fetchTeamStore(teamId: widget.teamId);
  }

  @override
  Widget build(BuildContext context) {
    return StoreShell(
      title: _selectedCategory?.name ?? 'Browse Products',
      child: FutureBuilder<TeamStoreBundle>(
        future: _storeFuture,
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

          final bundle = snapshot.data!;
          final allProducts = bundle.products.where((product) {
            final categoryMatch = _selectedCategory == null || product.categoryId == _selectedCategory!.id;
            final search = _searchController.text.trim().toLowerCase();
            final searchMatch = search.isEmpty ||
                product.name.toLowerCase().contains(search) ||
                (product.description ?? '').toLowerCase().contains(search) ||
                product.sku.toLowerCase().contains(search);
            return categoryMatch && searchMatch;
          }).toList();

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search athletic tape, headgear, scorebooks...',
                  hintStyle: const TextStyle(color: Color(0xFF97A1B4)),
                  prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF97A1B4)),
                  filled: true,
                  fillColor: const Color(0xFF121821),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 42,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: bundle.categories.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final category = index == 0 ? null : bundle.categories[index - 1];
                    final selected = category?.id == _selectedCategory?.id || (index == 0 && _selectedCategory == null);
                    return ChoiceChip(
                      selected: selected,
                      label: Text(category?.name ?? 'All'),
                      backgroundColor: const Color(0xFF121821),
                      selectedColor: widget.schoolAccentColor,
                      side: const BorderSide(color: Colors.white10),
                      labelStyle: TextStyle(
                        color: selected ? Colors.black : Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                      onSelected: (_) => setState(() => _selectedCategory = category),
                    );
                  },
                ),
              ),
              const SizedBox(height: 18),
              Text(
                '${allProducts.length} products',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              ...allProducts.map(
                (product) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ProductCard(
                    product: product,
                    accentColor: widget.schoolAccentColor,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ProductDetailScreen(
                            api: widget.api,
                            productId: product.id,
                            currentUserId: widget.currentUserId,
                            teamId: widget.teamId,
                            schoolPrimaryColor: widget.schoolPrimaryColor,
                            schoolAccentColor: widget.schoolAccentColor,
                          ),
                        ),
                      );
                    },
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
