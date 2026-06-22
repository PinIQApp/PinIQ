import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/section_header.dart';
import '../../widgets/subpage_header.dart';

class ModuleWorkspaceScreen extends StatelessWidget {
  const ModuleWorkspaceScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.status,
    required this.stats,
    required this.actions,
    required this.focusItems,
    required this.nextSteps,
    this.capabilityGroups = const [],
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String status;
  final List<ModuleMetric> stats;
  final List<ModuleAction> actions;
  final List<ModuleFocusItem> focusItems;
  final List<String> nextSteps;
  final List<ModuleCapabilityGroup> capabilityGroups;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= 1040;

    return ListView(
          padding: const EdgeInsets.only(bottom: AppSpacing.xl),
          children: [
          SubpageHeader(
            title: title,
            subtitle: subtitle,
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _WorkspaceStatusChip(
                        status: status,
                        color: color,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        '$title is now part of the product surface.',
                        style: AppTextStyles.cardTitle.copyWith(fontSize: 24),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(subtitle, style: AppTextStyles.body),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: width >= 1200 ? 4 : 2,
              crossAxisSpacing: AppSpacing.md,
              mainAxisSpacing: AppSpacing.md,
              childAspectRatio: width >= 1200 ? 1.45 : 1.2,
            ),
            itemCount: stats.length,
            itemBuilder: (context, index) => _WorkspaceMetricCard(metric: stats[index]),
          ),
          const SizedBox(height: AppSpacing.xl),
          SectionHeader(title: 'Quick actions'),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: actions
                .map(
                  (action) => _WorkspaceActionCard(
                    action: action,
                    color: color,
                    width: isWide ? ((width - 96) / 3).clamp(220, 360).toDouble() : double.infinity,
                  ),
                )
                .toList(),
          ),
          if (capabilityGroups.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xl),
            SectionHeader(title: 'Built into this module'),
            const SizedBox(height: AppSpacing.md),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: width >= 1280 ? 3 : width >= 760 ? 2 : 1,
                crossAxisSpacing: AppSpacing.md,
                mainAxisSpacing: AppSpacing.md,
                childAspectRatio: width >= 1280 ? 1.4 : width >= 760 ? 1.22 : 1.5,
              ),
              itemCount: capabilityGroups.length,
              itemBuilder: (context, index) => _CapabilityGroupCard(
                group: capabilityGroups[index],
                color: color,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          if (isWide)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: _WorkspaceFocusSection(
                    title: 'Current focus',
                    items: focusItems,
                    accent: color,
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  flex: 2,
                  child: _WorkspaceNextSteps(
                    steps: nextSteps,
                    color: color,
                  ),
                ),
              ],
            )
            else ...[
              _WorkspaceFocusSection(
                title: 'Current focus',
                items: focusItems,
              accent: color,
            ),
            const SizedBox(height: AppSpacing.xl),
              _WorkspaceNextSteps(
                steps: nextSteps,
                color: color,
              ),
            ],
          ],
    );
  }
}

class ModuleMetric {
  const ModuleMetric({
    required this.label,
    required this.value,
    required this.note,
  });

  final String label;
  final String value;
  final String note;
}

class ModuleAction {
  const ModuleAction({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;
}

class ModuleFocusItem {
  const ModuleFocusItem({
    required this.title,
    required this.subtitle,
    this.badge,
  });

  final String title;
  final String subtitle;
  final String? badge;
}

class ModuleCapabilityGroup {
  const ModuleCapabilityGroup({
    required this.title,
    required this.items,
  });

  final String title;
  final List<String> items;
}

class _WorkspaceStatusChip extends StatelessWidget {
  const _WorkspaceStatusChip({
    required this.status,
    required this.color,
  });

  final String status;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Text(
        status,
        style: AppTextStyles.caption.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _WorkspaceMetricCard extends StatelessWidget {
  const _WorkspaceMetricCard({required this.metric});

  final ModuleMetric metric;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.76),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(metric.label, style: AppTextStyles.caption),
          const Spacer(),
          Text(metric.value, style: AppTextStyles.pageTitle.copyWith(fontSize: 32)),
          const SizedBox(height: AppSpacing.xxs),
          Text(metric.note, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

class _WorkspaceActionCard extends StatelessWidget {
  const _WorkspaceActionCard({
    required this.action,
    required this.color,
    required this.width,
  });

  final ModuleAction action;
  final Color color;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.76),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(action.icon, color: color, size: 22),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(action.title, style: AppTextStyles.bodyStrong),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(action.subtitle, style: AppTextStyles.caption),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CapabilityGroupCard extends StatelessWidget {
  const _CapabilityGroupCard({
    required this.group,
    required this.color,
  });

  final ModuleCapabilityGroup group;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.76),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
            ),
            child: Text(
              group.title,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: group.items
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              item,
                              style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkspaceFocusSection extends StatelessWidget {
  const _WorkspaceFocusSection({
    required this.title,
    required this.items,
    required this.accent,
  });

  final String title;
  final List<ModuleFocusItem> items;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: title),
        const SizedBox(height: AppSpacing.md),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.76),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              for (final item in items) ...[
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        margin: const EdgeInsets.only(top: 5),
                        decoration: BoxDecoration(
                          color: accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(item.title, style: AppTextStyles.bodyStrong),
                                ),
                                if (item.badge != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.sm,
                                      vertical: AppSpacing.xxs,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceElevated,
                                      borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
                                    ),
                                    child: Text(item.badge!, style: AppTextStyles.caption),
                                  ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.xxs),
                            Text(item.subtitle, style: AppTextStyles.body),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (item != items.last) const Divider(height: 1, color: AppColors.border),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _WorkspaceNextSteps extends StatelessWidget {
  const _WorkspaceNextSteps({
    required this.steps,
    required this.color,
  });

  final List<String> steps;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: 'Next build moves'),
        const SizedBox(height: AppSpacing.md),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.76),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < steps.length; i++) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${i + 1}',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        steps[i],
                        style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
                      ),
                    ),
                  ],
                ),
                if (i != steps.length - 1) const SizedBox(height: AppSpacing.md),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
