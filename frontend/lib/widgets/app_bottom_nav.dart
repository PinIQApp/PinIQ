import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

class AppBottomNavItem {
  const AppBottomNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
}

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
    required this.items,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final List<AppBottomNavItem> items;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final width = MediaQuery.of(context).size.width;
    final isCompact = width < 430;

    return Container(
      margin: EdgeInsets.only(
        top: isCompact ? AppSpacing.md : AppSpacing.lg,
        bottom: isCompact ? AppSpacing.sm : AppSpacing.lg,
      ),
      padding: EdgeInsets.all(isCompact ? 4 : 6),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(isCompact ? 22 : 30),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: List.generate(items.length, (index) {
          final item = items[index];
          final isSelected = index == selectedIndex;

          return Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () => onSelected(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                padding: EdgeInsets.symmetric(vertical: isCompact ? 8 : 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? accent.withValues(alpha: 0.16)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(24),
                  border: isSelected
                      ? Border.all(
                          color: accent.withValues(alpha: 0.18),
                        )
                      : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedScale(
                      duration: const Duration(milliseconds: 180),
                      scale: isSelected ? 1.02 : 1.0,
                      child: Icon(
                        isSelected ? item.activeIcon : item.icon,
                        size: isCompact ? 20 : 22,
                        color: isSelected ? accent : AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: isCompact ? 3 : 5),
                    Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.navLabel.copyWith(
                        fontSize: isCompact ? 11 : 12,
                        color: isSelected ? accent : AppColors.textSecondary,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
