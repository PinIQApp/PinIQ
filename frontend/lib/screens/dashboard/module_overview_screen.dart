import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/section_header.dart';
import '../../widgets/subpage_header.dart';

class ModuleOverviewScreen extends StatelessWidget {
  const ModuleOverviewScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.highlights,
    required this.foundation,
    required this.nextMoves,
    required this.icon,
    required this.color,
  });

  final String title;
  final String subtitle;
  final String status;
  final List<String> highlights;
  final List<String> foundation;
  final List<String> nextMoves;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final twoColumn = width >= 980;

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
                  width: 54,
                  height: 54,
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
                      _ModuleStatusChip(status: status, color: color),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'This module is part of the coach operating system, not an afterthought.',
                        style: AppTextStyles.cardTitle.copyWith(fontSize: 24),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        subtitle,
                        style: AppTextStyles.body,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          if (twoColumn)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _OverviewSection(
                    title: 'What belongs here',
                    items: highlights,
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: _OverviewSection(
                    title: 'Foundation already mapped',
                    items: foundation,
                  ),
                ),
              ],
            )
          else ...[
            _OverviewSection(
              title: 'What belongs here',
              items: highlights,
            ),
            const SizedBox(height: AppSpacing.xl),
            _OverviewSection(
              title: 'Foundation already mapped',
              items: foundation,
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          _OverviewSection(
            title: 'Next build moves',
            items: nextMoves,
          ),
          ],
    );
  }
}

class _OverviewSection extends StatelessWidget {
  const _OverviewSection({
    required this.title,
    required this.items,
  });

  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: title),
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
              for (final item in items) ...[
                _BulletRow(label: item),
                if (item != items.last) const SizedBox(height: AppSpacing.sm),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _BulletRow extends StatelessWidget {
  const _BulletRow({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.only(top: 6),
          decoration: const BoxDecoration(
            color: AppColors.textSecondary,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
          ),
        ),
      ],
    );
  }
}

class _ModuleStatusChip extends StatelessWidget {
  const _ModuleStatusChip({
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
