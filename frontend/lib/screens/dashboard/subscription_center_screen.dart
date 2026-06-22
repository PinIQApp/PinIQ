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

class SubscriptionCenterScreen extends StatelessWidget {
  const SubscriptionCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final plans = context.watch<AppState>().operatorSubscriptionPlans;
    final subscribers = plans.length * 6;
    final mrr = plans.length * 700;

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        const SubpageHeader(
          title: 'Subscription Center',
          subtitle:
              'Manage monthly, bi-monthly, and yearly billing plans for the operator side of the business.',
        ),
        const SizedBox(height: AppSpacing.lg),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            SizedBox(
              width: 240,
              child: _MetricCard(
                label: 'Active plans',
                value: '${plans.length}',
                note: 'billing products live',
                color: const Color(0xFFF59E0B),
              ),
            ),
            SizedBox(
              width: 240,
              child: _MetricCard(
                label: 'Subscribers',
                value: '$subscribers',
                note: 'active program accounts',
                color: const Color(0xFF38BDF8),
              ),
            ),
            SizedBox(
              width: 240,
              child: _MetricCard(
                label: 'MRR',
                value: '\$$mrr',
                note: 'estimated recurring',
                color: const Color(0xFF14B8A6),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        Row(
          children: [
            const Expanded(child: SectionHeader(title: 'Plan catalog')),
            OutlinedButton.icon(
              onPressed: () => _openCreatePlan(context),
              icon: const Icon(Icons.add_circle_outline_rounded),
              label: const Text('Add plan'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        ...plans.map(
          (plan) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: _SubscriptionPlanCard(
              plan: plan,
              onEdit: () => _openEditPlan(context, plan),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openCreatePlan(BuildContext context) async {
    final created = await Navigator.of(context).push<OperatorSubscriptionPlan>(
      MaterialPageRoute(
        builder: (_) => const SubscriptionPlanEditorScreen(title: 'Create subscription plan'),
      ),
    );
    if (!context.mounted || created == null) return;
    context.read<AppState>().addOperatorSubscriptionPlan(created);
  }

  Future<void> _openEditPlan(BuildContext context, OperatorSubscriptionPlan plan) async {
    final updated = await Navigator.of(context).push<OperatorSubscriptionPlan>(
      MaterialPageRoute(
        builder: (_) => SubscriptionPlanEditorScreen(
          title: 'Edit subscription plan',
          initialPlan: plan,
        ),
      ),
    );
    if (!context.mounted || updated == null) return;
    context.read<AppState>().updateOperatorSubscriptionPlan(updated);
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

class _SubscriptionPlanCard extends StatelessWidget {
  const _SubscriptionPlanCard({
    required this.plan,
    required this.onEdit,
  });

  final OperatorSubscriptionPlan plan;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final accent = plan.cadence == 'Yearly' ? const Color(0xFFF59E0B) : const Color(0xFF14B8A6);

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
              _PlanPill(label: plan.cadence, color: accent),
              _PlanPill(label: plan.billingCode, color: const Color(0xFF38BDF8)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(plan.title, style: AppTextStyles.cardTitle),
          const SizedBox(height: AppSpacing.xxs),
          Text(plan.price, style: AppTextStyles.sectionTitle.copyWith(fontSize: 28)),
          const SizedBox(height: AppSpacing.xs),
          Text(plan.access, style: AppTextStyles.body),
          const SizedBox(height: AppSpacing.sm),
          Text(plan.note, style: AppTextStyles.body),
          const SizedBox(height: AppSpacing.md),
          ...plan.bullets.map(
            (bullet) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Icon(Icons.check_circle_outline_rounded, size: 18, color: Color(0xFFF59E0B)),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text(bullet, style: AppTextStyles.body)),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Edit plan'),
          ),
        ],
      ),
    );
  }
}

class _PlanPill extends StatelessWidget {
  const _PlanPill({
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
