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

class VendorCenterScreen extends StatelessWidget {
  const VendorCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vendors = context.watch<AppState>().operatorVendors;
    final preferred = vendors.where((item) => item.status == 'Preferred').length;
    final marginWatch = vendors.where((item) => item.status == 'Draft').length;

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        const SubpageHeader(
          title: 'Vendor Center',
          subtitle:
              'Manage dropship sources, preferred suppliers, and operator-side margin lanes for the marketplace.',
        ),
        const SizedBox(height: AppSpacing.lg),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            SizedBox(
              width: 240,
              child: _MetricCard(
                label: 'Vendors',
                value: '${vendors.length}',
                note: 'active supply partners',
                color: const Color(0xFF38BDF8),
              ),
            ),
            SizedBox(
              width: 240,
              child: _MetricCard(
                label: 'Preferred',
                value: '$preferred',
                note: 'operator priority sources',
                color: const Color(0xFF14B8A6),
              ),
            ),
            SizedBox(
              width: 240,
              child: _MetricCard(
                label: 'Margin watch',
                value: '$marginWatch',
                note: 'needs review',
                color: const Color(0xFFF59E0B),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        Row(
          children: [
            const Expanded(child: SectionHeader(title: 'Vendor roster')),
            OutlinedButton.icon(
              onPressed: () => _openCreateVendor(context),
              icon: const Icon(Icons.add_business_outlined),
              label: const Text('Add vendor'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        ...vendors.map(
          (vendor) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: _VendorCard(
              vendor: vendor,
              onEdit: () => _openEditVendor(context, vendor),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openCreateVendor(BuildContext context) async {
    final created = await Navigator.of(context).push<OperatorVendor>(
      MaterialPageRoute(
        builder: (_) => const VendorEditorScreen(title: 'Add vendor'),
      ),
    );
    if (!context.mounted || created == null) return;
    context.read<AppState>().addOperatorVendor(created);
  }

  Future<void> _openEditVendor(BuildContext context, OperatorVendor vendor) async {
    final updated = await Navigator.of(context).push<OperatorVendor>(
      MaterialPageRoute(
        builder: (_) => VendorEditorScreen(
          title: 'Edit vendor',
          initialVendor: vendor,
        ),
      ),
    );
    if (!context.mounted || updated == null) return;
    context.read<AppState>().updateOperatorVendor(updated);
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
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

class _VendorCard extends StatelessWidget {
  const _VendorCard({
    required this.vendor,
    required this.onEdit,
  });

  final OperatorVendor vendor;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final accent = switch (vendor.status) {
      'Preferred' => const Color(0xFF14B8A6),
      'High ticket' => const Color(0xFFF59E0B),
      _ => AppColors.textSecondary,
    };

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              _VendorPill(label: vendor.status, color: accent),
              _VendorPill(label: vendor.lane, color: const Color(0xFF38BDF8)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(vendor.name, style: AppTextStyles.cardTitle),
          const SizedBox(height: AppSpacing.xxs),
          Text(vendor.marginNote, style: AppTextStyles.body),
          const SizedBox(height: AppSpacing.sm),
          Text(vendor.summary, style: AppTextStyles.body),
          const SizedBox(height: AppSpacing.md),
          ...vendor.notes.map(
            (note) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Icon(Icons.local_shipping_outlined, size: 18, color: Color(0xFF14B8A6)),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text(note, style: AppTextStyles.body)),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Edit vendor'),
          ),
        ],
      ),
    );
  }
}

class _VendorPill extends StatelessWidget {
  const _VendorPill({
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
      child: Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.textPrimary)),
    );
  }
}
