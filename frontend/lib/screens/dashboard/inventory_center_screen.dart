import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/section_header.dart';
import '../../widgets/subpage_header.dart';

class InventoryCenterScreen extends StatefulWidget {
  const InventoryCenterScreen({super.key});

  @override
  State<InventoryCenterScreen> createState() => _InventoryCenterScreenState();
}

class _InventoryCenterScreenState extends State<InventoryCenterScreen> {
  String _filter = 'all';
  int _selectedIndex = 0;

  static const List<_InventoryItem> _items = [
    _InventoryItem(
      name: 'Headgear',
      category: 'Equipment',
      stock: '3 left',
      supplier: 'MatPro Supply',
      status: 'Low stock',
      note: 'Needs reorder before next dual weekend.',
      details: [
        'Tied to athlete onboarding kits',
        'Restock threshold hit yesterday',
        'Can be linked to storefront availability',
      ],
    ),
    _InventoryItem(
      name: 'Knee Pads',
      category: 'Equipment',
      stock: '11 left',
      supplier: 'Wrestle Gear Co.',
      status: 'Healthy',
      note: 'Good depth across common sizes.',
      details: [
        'No reorder needed this week',
        'Useful bundle item in store',
        'Check youth sizing before camp season',
      ],
    ),
    _InventoryItem(
      name: 'Mat Tape',
      category: 'Medical',
      stock: '5 rolls',
      supplier: 'Facility Source',
      status: 'Reorder soon',
      note: 'Facility supplies trending down faster than forecast.',
      details: [
        'Support staff order path should be simplified',
        'Could auto-build supplier reorder',
        'Bundle with cleaning supply restock',
      ],
    ),
    _InventoryItem(
      name: 'Cardinals Hoodie',
      category: 'Merch',
      stock: '14 left',
      supplier: 'TeamPrint Works',
      status: 'Store linked',
      note: 'Selling well and tied to fundraiser push.',
      details: [
        'Most popular parent purchase item',
        'Size medium should be reordered next',
        'Revenue and stock should stay synced',
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final visible = _items.where((item) {
      return switch (_filter) {
        'equipment' => item.category == 'Equipment',
        'medical' => item.category == 'Medical',
        'merch' => item.category == 'Merch',
        'low' => item.status == 'Low stock' || item.status == 'Reorder soon',
        _ => true,
      };
    }).toList();

    if (_selectedIndex >= visible.length) {
      _selectedIndex = visible.isEmpty ? 0 : visible.length - 1;
    }

    final selected = visible.isEmpty ? null : visible[_selectedIndex];

    return LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 1120;

          return ListView(
            padding: EdgeInsets.zero,
            children: [
              const SubpageHeader(
                title: 'Inventory Center',
                subtitle:
                    'Track gear, medical supplies, merch stock, and supplier health from one place.',
              ),
              const SizedBox(height: AppSpacing.lg),
              const _InventorySummaryRow(),
              const SizedBox(height: AppSpacing.xl),
              if (isWide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 5,
                      child: _InventoryCatalog(
                        filter: _filter,
                        onFilterChanged: (value) => setState(() {
                          _filter = value;
                          _selectedIndex = 0;
                        }),
                        items: visible,
                        selectedIndex: _selectedIndex,
                        onSelect: (index) => setState(() => _selectedIndex = index),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      flex: 4,
                      child: selected == null
                          ? const _InventoryEmptyPanel()
                          : _InventoryDetail(item: selected),
                    ),
                  ],
                )
              else ...[
                _InventoryCatalog(
                  filter: _filter,
                  onFilterChanged: (value) => setState(() {
                    _filter = value;
                    _selectedIndex = 0;
                  }),
                  items: visible,
                  selectedIndex: _selectedIndex,
                  onSelect: (index) => setState(() => _selectedIndex = index),
                ),
                const SizedBox(height: AppSpacing.lg),
                if (selected == null)
                  const _InventoryEmptyPanel()
                else
                  _InventoryDetail(item: selected),
              ],
              const SizedBox(height: AppSpacing.xl),
              const SectionHeader(title: 'Supplier watch'),
              const SizedBox(height: AppSpacing.md),
              const _SupplierPanel(),
              const SizedBox(height: AppSpacing.xl),
            ],
          );
          },
    );
  }
}

class _InventorySummaryRow extends StatelessWidget {
  const _InventorySummaryRow();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      children: const [
        SizedBox(
          width: 240,
          child: _InventoryMetric(
            label: 'Tracked items',
            value: '42',
            note: 'gear and supplies',
            color: Color(0xFF0EA5E9),
          ),
        ),
        SizedBox(
          width: 240,
          child: _InventoryMetric(
            label: 'Low stock',
            value: '6',
            note: 'needs action',
            color: Color(0xFFEF4444),
          ),
        ),
        SizedBox(
          width: 240,
          child: _InventoryMetric(
            label: 'Suppliers',
            value: '5',
            note: 'active vendors',
            color: Color(0xFFF59E0B),
          ),
        ),
        SizedBox(
          width: 240,
          child: _InventoryMetric(
            label: 'Orders',
            value: '8',
            note: 'open purchase orders',
            color: AppColors.success,
          ),
        ),
      ],
    );
  }
}

class _InventoryCatalog extends StatelessWidget {
  const _InventoryCatalog({
    required this.filter,
    required this.onFilterChanged,
    required this.items,
    required this.selectedIndex,
    required this.onSelect,
  });

  final String filter;
  final ValueChanged<String> onFilterChanged;
  final List<_InventoryItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (constraints.maxWidth >= 560)
              Row(
                children: [
                  Text('Inventory catalog', style: AppTextStyles.cardTitle.copyWith(fontSize: 22)),
                  const Spacer(),
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.add_shopping_cart_outlined),
                    label: const Text('Create PO'),
                  ),
                ],
              )
            else ...[
              Text('Inventory catalog', style: AppTextStyles.cardTitle.copyWith(fontSize: 22)),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add_shopping_cart_outlined),
                label: const Text('Create PO'),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final chip in const [
                    ('all', 'All'),
                    ('equipment', 'Equipment'),
                    ('medical', 'Medical'),
                    ('merch', 'Merch'),
                    ('low', 'Low stock'),
                  ])
                    Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.xs),
                      child: ChoiceChip(
                        label: Text(chip.$2),
                        selected: filter == chip.$1,
                        onSelected: (_) => onFilterChanged(chip.$1),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ...List.generate(items.length, (index) {
              final item = items[index];
              return Padding(
                padding: EdgeInsets.only(bottom: index == items.length - 1 ? 0 : AppSpacing.sm),
                child: _InventoryRow(
                  item: item,
                  selected: index == selectedIndex,
                  onTap: () => onSelect(index),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _InventoryRow extends StatelessWidget {
  const _InventoryRow({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _InventoryItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = switch (item.status) {
      'Low stock' => const Color(0xFFEF4444),
      'Reorder soon' => const Color(0xFFF59E0B),
      'Store linked' => const Color(0xFF14B8A6),
      _ => const Color(0xFF0EA5E9),
    };

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: selected ? AppColors.surfaceElevated : AppColors.surface.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: selected ? accent.withValues(alpha: 0.4) : AppColors.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name, style: AppTextStyles.bodyStrong),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    '${item.category} • ${item.stock} • ${item.supplier}',
                    style: AppTextStyles.caption,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  _InventoryTag(label: item.status, color: accent),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

class _InventoryDetail extends StatelessWidget {
  const _InventoryDetail({required this.item});

  final _InventoryItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name, style: AppTextStyles.sectionTitle),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      '${item.category} • ${item.stock} • ${item.supplier}',
                      style: AppTextStyles.body,
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.shopping_bag_outlined),
                label: const Text('Reorder'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(item.note, style: AppTextStyles.body.copyWith(color: AppColors.textPrimary)),
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader(title: 'Operational context'),
          const SizedBox(height: AppSpacing.md),
          ...item.details.map(
            (detail) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Icon(Icons.inventory_rounded, size: 18, color: Color(0xFF0EA5E9)),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text(detail, style: AppTextStyles.body)),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.local_shipping_outlined),
                label: const Text('Open supplier'),
              ),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.storefront_outlined),
                label: const Text('View store impact'),
              ),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.notifications_outlined),
                label: const Text('Set alert'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SupplierPanel extends StatelessWidget {
  const _SupplierPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _SupplierRow(
            name: 'MatPro Supply',
            status: '2 items low',
            note: 'Headgear reorder should be created today.',
          ),
          SizedBox(height: AppSpacing.sm),
          _SupplierRow(
            name: 'TeamPrint Works',
            status: 'Stable',
            note: 'Merch inventory sync looks clean this week.',
          ),
          SizedBox(height: AppSpacing.sm),
          _SupplierRow(
            name: 'Facility Source',
            status: 'Needs follow-up',
            note: 'Mat tape and cleaning supply lead times increased.',
          ),
        ],
      ),
    );
  }
}

class _SupplierRow extends StatelessWidget {
  const _SupplierRow({
    required this.name,
    required this.status,
    required this.note,
  });

  final String name;
  final String status;
  final String note;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppTextStyles.bodyStrong),
                const SizedBox(height: AppSpacing.xxs),
                Text(note, style: AppTextStyles.caption),
              ],
            ),
          ),
          _InventoryTag(label: status, color: const Color(0xFFF59E0B)),
        ],
      ),
    );
  }
}

class _InventoryMetric extends StatelessWidget {
  const _InventoryMetric({
    required this.label,
    required this.value,
    required this.note,
    required this.color,
  });

  final String label;
  final String value;
  final String note;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.caption),
          const SizedBox(height: AppSpacing.sm),
          Text(value, style: AppTextStyles.cardTitle.copyWith(color: color)),
          const SizedBox(height: AppSpacing.xxs),
          Text(note, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

class _InventoryTag extends StatelessWidget {
  const _InventoryTag({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(color: AppColors.textPrimary),
      ),
    );
  }
}

class _InventoryItem {
  const _InventoryItem({
    required this.name,
    required this.category,
    required this.stock,
    required this.supplier,
    required this.status,
    required this.note,
    required this.details,
  });

  final String name;
  final String category;
  final String stock;
  final String supplier;
  final String status;
  final String note;
  final List<String> details;
}

class _InventoryEmptyPanel extends StatelessWidget {
  const _InventoryEmptyPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        'No inventory items match the current filter.',
        style: AppTextStyles.body,
      ),
    );
  }
}
