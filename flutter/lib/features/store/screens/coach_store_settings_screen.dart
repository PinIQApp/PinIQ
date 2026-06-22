import 'package:flutter/material.dart';

import '../models/store_models.dart';
import '../services/store_api_service.dart';
import '../widgets/store_ui.dart';

class CoachStoreSettingsScreen extends StatefulWidget {
  const CoachStoreSettingsScreen({
    super.key,
    required this.api,
    required this.teamId,
    required this.bundle,
    required this.schoolPrimaryColor,
    required this.schoolAccentColor,
  });

  final StoreApiService api;
  final int teamId;
  final TeamStoreBundle bundle;
  final Color schoolPrimaryColor;
  final Color schoolAccentColor;

  @override
  State<CoachStoreSettingsScreen> createState() => _CoachStoreSettingsScreenState();
}

class _CoachStoreSettingsScreenState extends State<CoachStoreSettingsScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _taglineController;
  late final TextEditingController _announcementController;
  late bool _storeEnabled;
  late bool _athleteCheckoutEnabled;
  late bool _schoolGearEnabled;
  late Set<int> _enabledCategoryIds;
  late Set<int> _featuredProductIds;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final config = widget.bundle.store;
    _nameController = TextEditingController(text: config.storeName);
    _taglineController = TextEditingController(text: config.storeTagline ?? '');
    _announcementController = TextEditingController(text: config.announcementText ?? '');
    _storeEnabled = config.isStoreEnabled;
    _athleteCheckoutEnabled = config.allowAthleteCheckout;
    _schoolGearEnabled = config.schoolGearEnabled;
    _enabledCategoryIds = config.enabledCategoryIds.toSet();
    _featuredProductIds = config.featuredProductIds.toSet();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _taglineController.dispose();
    _announcementController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StoreShell(
      title: 'Store Settings',
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          StorePanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Store Basics',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                _textField(controller: _nameController, label: 'Store name'),
                const SizedBox(height: 12),
                _textField(controller: _taglineController, label: 'Store tagline'),
                const SizedBox(height: 12),
                _textField(
                  controller: _announcementController,
                  label: 'Announcement',
                  maxLines: 4,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          StorePanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Rules',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                _toggleTile(
                  title: 'Store enabled',
                  subtitle: 'Allows athletes, parents, and coaches to view the team store.',
                  value: _storeEnabled,
                  onChanged: (value) => setState(() => _storeEnabled = value),
                ),
                _toggleTile(
                  title: 'Athlete checkout enabled',
                  subtitle: 'Allows athletes to place their own orders when team rules permit it.',
                  value: _athleteCheckoutEnabled,
                  onChanged: (value) => setState(() => _athleteCheckoutEnabled = value),
                ),
                _toggleTile(
                  title: 'School gear placeholder enabled',
                  subtitle: 'Shows the future merch-designer placeholder section in the store.',
                  value: _schoolGearEnabled,
                  onChanged: (value) => setState(() => _schoolGearEnabled = value),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          StorePanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Enabled Categories',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Coaches can hide categories from the school-branded team store without deleting products.',
                  style: TextStyle(color: Color(0xFF97A1B4), height: 1.45),
                ),
                const SizedBox(height: 14),
                ...widget.bundle.categories.map(
                  (category) => CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _enabledCategoryIds.contains(category.id),
                    activeColor: widget.schoolAccentColor,
                    checkColor: Colors.black,
                    title: Text(
                      category.name,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      category.description ?? '',
                      style: const TextStyle(color: Color(0xFF97A1B4)),
                    ),
                    onChanged: (value) {
                      setState(() {
                        if (value ?? false) {
                          _enabledCategoryIds.add(category.id);
                        } else {
                          _enabledCategoryIds.remove(category.id);
                          _featuredProductIds.removeWhere(
                            (productId) => widget.bundle.products.any(
                              (product) => product.id == productId && product.categoryId == category.id,
                            ),
                          );
                        }
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          StorePanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Featured Products',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Use featured products to highlight common reorders, parent favorites, or seasonal essentials.',
                  style: TextStyle(color: Color(0xFF97A1B4), height: 1.45),
                ),
                const SizedBox(height: 14),
                ...widget.bundle.products
                    .where((product) => _enabledCategoryIds.contains(product.categoryId))
                    .map(
                      (product) => SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _featuredProductIds.contains(product.id),
                        activeColor: widget.schoolAccentColor,
                        title: Text(
                          product.name,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          '${product.sku} • \$${product.sellPrice.toStringAsFixed(2)}',
                          style: const TextStyle(color: Color(0xFF97A1B4)),
                        ),
                        onChanged: (value) {
                          setState(() {
                            if (value) {
                              _featuredProductIds.add(product.id);
                            } else {
                              _featuredProductIds.remove(product.id);
                            }
                          });
                        },
                      ),
                    ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: widget.schoolAccentColor,
              foregroundColor: Colors.black,
              minimumSize: const Size.fromHeight(54),
            ),
            onPressed: _saving ? null : _save,
            child: Text(_saving ? 'Saving...' : 'Save Store Settings'),
          ),
        ],
      ),
    );
  }

  Widget _toggleTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      value: value,
      activeColor: widget.schoolAccentColor,
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: Color(0xFF97A1B4)),
      ),
      onChanged: onChanged,
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF97A1B4)),
        filled: true,
        fillColor: const Color(0xFF1A2230),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Store name is required.')),
      );
      return;
    }
    if (_enabledCategoryIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enable at least one category for the team store.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await widget.api.updateTeamStoreConfig(
        teamId: widget.teamId,
        storeName: _nameController.text.trim(),
        storeTagline: _taglineController.text.trim().isEmpty ? null : _taglineController.text.trim(),
        isStoreEnabled: _storeEnabled,
        allowAthleteCheckout: _athleteCheckoutEnabled,
        schoolGearEnabled: _schoolGearEnabled,
        featuredProductIds: _featuredProductIds.toList()..sort(),
        enabledCategoryIds: _enabledCategoryIds.toList()..sort(),
        announcementText: _announcementController.text.trim().isEmpty
            ? null
            : _announcementController.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }
}
