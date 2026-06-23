import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

class EmptyStateCard extends StatelessWidget {
  const EmptyStateCard({
    super.key,
    required this.title,
    required this.message,
    required this.icon,
  });

  final String title;
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 980;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isDesktop ? AppSpacing.md : AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: isDesktop ? 0.34 : 0.84),
        borderRadius: BorderRadius.circular(isDesktop ? 16 : 20),
        border: Border.all(
          color: AppColors.border.withValues(alpha: isDesktop ? 0.46 : 1),
        ),
      ),
      child: isDesktop
          ? Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated.withValues(alpha: 0.42),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, size: 20, color: AppColors.textSecondary),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppTextStyles.bodyStrong),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(message, style: AppTextStyles.caption),
                    ],
                  ),
                ),
              ],
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated.withValues(alpha: 0.52),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(icon, size: 28, color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(title,
                    style: AppTextStyles.cardTitle,
                    textAlign: TextAlign.center),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  message,
                  style: AppTextStyles.body,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
    );
  }
}
