import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.sublabel,
    this.highlightColor,
  });

  final String label;
  final String value;
  final String sublabel;
  final Color? highlightColor;

  @override
  Widget build(BuildContext context) {
    final accent = highlightColor ?? Theme.of(context).colorScheme.primary;
    final isCompact = MediaQuery.of(context).size.width < 430;

    return Container(
      padding: EdgeInsets.all(isCompact ? AppSpacing.sm : AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surface.withValues(alpha: 0.88),
            AppColors.surfaceElevated.withValues(alpha: 0.82),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.74)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 4,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: AppSpacing.xxs),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: AppTextStyles.statNumber.copyWith(
                fontSize: isCompact ? 24 : 28,
                color: highlightColor ?? AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Expanded(
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Text(
                sublabel,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
