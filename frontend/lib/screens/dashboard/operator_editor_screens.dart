import 'package:flutter/material.dart';

import '../../models/operator_models.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/subpage_header.dart';

class ProductEditorScreen extends StatefulWidget {
  const ProductEditorScreen({
    super.key,
    this.initialProduct,
    this.title = 'Product editor',
  });

  final OperatorProduct? initialProduct;
  final String title;

  @override
  State<ProductEditorScreen> createState() => _ProductEditorScreenState();
}

class _ProductEditorScreenState extends State<ProductEditorScreen> {
  late final TextEditingController _name =
      TextEditingController(text: widget.initialProduct?.name ?? '');
  late final TextEditingController _category =
      TextEditingController(text: widget.initialProduct?.category ?? '');
  late final TextEditingController _price =
      TextEditingController(text: widget.initialProduct?.price ?? '');
  late final TextEditingController _margin =
      TextEditingController(text: widget.initialProduct?.margin ?? '');
  late final TextEditingController _vendor =
      TextEditingController(text: widget.initialProduct?.vendor ?? '');
  late final TextEditingController _source =
      TextEditingController(text: widget.initialProduct?.source ?? '');
  late final TextEditingController _cadence =
      TextEditingController(text: widget.initialProduct?.cadence ?? '');
  late final TextEditingController _summary =
      TextEditingController(text: widget.initialProduct?.summary ?? '');

  @override
  void dispose() {
    _name.dispose();
    _category.dispose();
    _price.dispose();
    _margin.dispose();
    _vendor.dispose();
    _source.dispose();
    _cadence.dispose();
    _summary.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        SubpageHeader(
          title: widget.title,
          subtitle: 'Create or refine an operator-only dropship listing with vendor and margin details.',
        ),
        const SizedBox(height: AppSpacing.lg),
        _EditorCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _field(_name, 'Listing name'),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(child: _field(_category, 'Category')),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: _field(_cadence, 'Cadence')),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(child: _field(_price, 'Price')),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: _field(_margin, 'Margin')),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(child: _field(_vendor, 'Vendor')),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: _field(_source, 'Source lane')),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _field(_summary, 'Summary', maxLines: 4),
              const SizedBox(height: AppSpacing.lg),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  ElevatedButton.icon(
                    onPressed: _saveProduct,
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Save draft'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.visibility_outlined),
                    label: const Text('Preview'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _saveProduct() {
    final summary = _summary.text.trim();
    final existing = widget.initialProduct;
    final product = OperatorProduct(
      id: existing?.id ?? _buildId(_name.text, prefix: 'product'),
      name: _name.text.trim(),
      category: _category.text.trim(),
      price: _price.text.trim(),
      margin: _margin.text.trim(),
      status: existing?.status ?? 'Draft',
      cadence: _cadence.text.trim(),
      vendor: _vendor.text.trim(),
      source: _source.text.trim(),
      summary: summary,
      bullets: existing?.bullets ??
          [
            if (summary.isNotEmpty) summary,
            if (_vendor.text.trim().isNotEmpty)
              'Sourced through ${_vendor.text.trim()} for the operator marketplace.',
            if (_cadence.text.trim().isNotEmpty)
              'Best positioned for ${_cadence.text.trim()} ordering.',
          ],
    );
    Navigator.of(context).pop(product);
  }
}

class SubscriptionPlanEditorScreen extends StatefulWidget {
  const SubscriptionPlanEditorScreen({
    super.key,
    this.initialPlan,
    this.title = 'Subscription plan editor',
  });

  final OperatorSubscriptionPlan? initialPlan;
  final String title;

  @override
  State<SubscriptionPlanEditorScreen> createState() => _SubscriptionPlanEditorScreenState();
}

class _SubscriptionPlanEditorScreenState extends State<SubscriptionPlanEditorScreen> {
  late final TextEditingController _title =
      TextEditingController(text: widget.initialPlan?.title ?? '');
  late final TextEditingController _cadence =
      TextEditingController(text: widget.initialPlan?.cadence ?? '');
  late final TextEditingController _price =
      TextEditingController(text: widget.initialPlan?.price ?? '');
  late final TextEditingController _code =
      TextEditingController(text: widget.initialPlan?.billingCode ?? '');
  late final TextEditingController _access =
      TextEditingController(text: widget.initialPlan?.access ?? '');
  late final TextEditingController _note =
      TextEditingController(text: widget.initialPlan?.note ?? '');

  @override
  void dispose() {
    _title.dispose();
    _cadence.dispose();
    _price.dispose();
    _code.dispose();
    _access.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        SubpageHeader(
          title: widget.title,
          subtitle: 'Create or refine a monthly, bi-monthly, or yearly plan for the operator billing side.',
        ),
        const SizedBox(height: AppSpacing.lg),
        _EditorCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _field(_title, 'Plan title'),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(child: _field(_cadence, 'Cadence')),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: _field(_price, 'Price')),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(child: _field(_code, 'Billing code')),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: _field(_access, 'Access scope')),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _field(_note, 'Plan note', maxLines: 4),
              const SizedBox(height: AppSpacing.lg),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  ElevatedButton.icon(
                    onPressed: _savePlan,
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Save plan'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.receipt_long_rounded),
                    label: const Text('Review billing'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _savePlan() {
    final note = _note.text.trim();
    final existing = widget.initialPlan;
    final plan = OperatorSubscriptionPlan(
      id: existing?.id ?? _buildId(_title.text, prefix: 'plan'),
      title: _title.text.trim(),
      cadence: _cadence.text.trim(),
      price: _price.text.trim(),
      billingCode: _code.text.trim(),
      access: _access.text.trim(),
      note: note,
      bullets: existing?.bullets ??
          [
            if (note.isNotEmpty) note,
            if (_access.text.trim().isNotEmpty) 'Access scope: ${_access.text.trim()}',
            if (_cadence.text.trim().isNotEmpty) 'Billed on a ${_cadence.text.trim().toLowerCase()} cadence',
          ],
    );
    Navigator.of(context).pop(plan);
  }
}

class VendorEditorScreen extends StatefulWidget {
  const VendorEditorScreen({
    super.key,
    this.initialVendor,
    this.title = 'Vendor editor',
  });

  final OperatorVendor? initialVendor;
  final String title;

  @override
  State<VendorEditorScreen> createState() => _VendorEditorScreenState();
}

class _VendorEditorScreenState extends State<VendorEditorScreen> {
  late final TextEditingController _name =
      TextEditingController(text: widget.initialVendor?.name ?? '');
  late final TextEditingController _lane =
      TextEditingController(text: widget.initialVendor?.lane ?? '');
  late final TextEditingController _status =
      TextEditingController(text: widget.initialVendor?.status ?? '');
  late final TextEditingController _marginNote =
      TextEditingController(text: widget.initialVendor?.marginNote ?? '');
  late final TextEditingController _summary =
      TextEditingController(text: widget.initialVendor?.summary ?? '');

  @override
  void dispose() {
    _name.dispose();
    _lane.dispose();
    _status.dispose();
    _marginNote.dispose();
    _summary.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        SubpageHeader(
          title: widget.title,
          subtitle: 'Add or update a dropship source, lane ownership, and margin notes for the operator marketplace.',
        ),
        const SizedBox(height: AppSpacing.lg),
        _EditorCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _field(_name, 'Vendor name'),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(child: _field(_lane, 'Supply lane')),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: _field(_status, 'Status')),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _field(_marginNote, 'Margin note'),
              const SizedBox(height: AppSpacing.md),
              _field(_summary, 'Vendor summary', maxLines: 4),
              const SizedBox(height: AppSpacing.lg),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  ElevatedButton.icon(
                    onPressed: _saveVendor,
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Save vendor'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.local_shipping_outlined),
                    label: const Text('Review sourcing'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _saveVendor() {
    final summary = _summary.text.trim();
    final existing = widget.initialVendor;
    final vendor = OperatorVendor(
      id: existing?.id ?? _buildId(_name.text, prefix: 'vendor'),
      name: _name.text.trim(),
      lane: _lane.text.trim(),
      status: _status.text.trim(),
      marginNote: _marginNote.text.trim(),
      summary: summary,
      notes: existing?.notes ??
          [
            if (summary.isNotEmpty) summary,
            if (_marginNote.text.trim().isNotEmpty) 'Margin watch: ${_marginNote.text.trim()}',
            if (_lane.text.trim().isNotEmpty) 'Primary supply lane: ${_lane.text.trim()}',
          ],
    );
    Navigator.of(context).pop(vendor);
  }
}

class _EditorCard extends StatelessWidget {
  const _EditorCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: child,
    );
  }
}

Widget _field(
  TextEditingController controller,
  String label, {
  int maxLines = 1,
}) {
  return TextField(
    controller: controller,
    maxLines: maxLines,
    style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
    decoration: InputDecoration(labelText: label),
  );
}

String _buildId(String raw, {required String prefix}) {
  final normalized = raw.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
  final safe = normalized.replaceAll(RegExp(r'^-+|-+$'), '');
  if (safe.isNotEmpty) {
    return '$prefix-$safe';
  }
  return '$prefix-${DateTime.now().microsecondsSinceEpoch}';
}
