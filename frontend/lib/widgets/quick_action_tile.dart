import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

class QuickActionTile extends StatelessWidget {
  const QuickActionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.color,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color? color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final accent = color ?? Theme.of(context).colorScheme.primary;
    final width = MediaQuery.of(context).size.width;
    final isCompact = width < 430;
    final useRowLayout = width >= 720;
    final isDesktop = width >= 980;
    return InkWell(
      borderRadius: BorderRadius.circular(isDesktop ? 0 : 16),
      onTap: onTap,
      child: Ink(
        padding: EdgeInsets.symmetric(
          horizontal: isCompact
              ? AppSpacing.sm
              : isDesktop
                  ? AppSpacing.lg
                  : AppSpacing.md,
          vertical: isCompact
              ? AppSpacing.sm
              : isDesktop
                  ? AppSpacing.sm
                  : AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: isDesktop
              ? Colors.transparent
              : AppColors.surface.withValues(alpha: 0.66),
          borderRadius: BorderRadius.circular(isDesktop ? 0 : 16),
          border: isDesktop
              ? null
              : Border.all(color: AppColors.border.withValues(alpha: 0.68)),
          boxShadow: isDesktop
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: Flex(
          direction: useRowLayout ? Axis.horizontal : Axis.vertical,
          crossAxisAlignment: useRowLayout
              ? CrossAxisAlignment.center
              : CrossAxisAlignment.start,
          children: [
            Container(
              width: isCompact ? 30 : 34,
              height: isCompact ? 30 : 34,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, color: accent, size: 17),
            ),
            SizedBox(
              width: useRowLayout ? AppSpacing.md : 0,
              height: useRowLayout
                  ? 0
                  : isCompact
                      ? AppSpacing.xs
                      : AppSpacing.sm,
            ),
            Expanded(
              flex: useRowLayout ? 1 : 0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyStrong.copyWith(
                      fontSize: isCompact ? 13 : 15,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    subtitle,
                    maxLines: useRowLayout ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
            if (useRowLayout) ...[
              const SizedBox(width: AppSpacing.sm),
              Icon(Icons.chevron_right_rounded,
                  color: AppColors.textMuted, size: 20),
            ],
          ],
        ),
      ),
    );
  }
}
