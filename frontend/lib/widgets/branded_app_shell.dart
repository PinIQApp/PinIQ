import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'app_bottom_nav.dart';
import 'app_shell.dart';

class BrandedAppShell extends StatelessWidget {
  const BrandedAppShell({
    super.key,
    required this.title,
    required this.currentIndex,
    required this.onTap,
    required this.body,
    required this.destinations,
    this.actions = const [],
  });

  final String title;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final Widget body;
  final List<NavigationDestination> destinations;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 980;
    final accent = Theme.of(context).colorScheme.primary;
    return Scaffold(
      body: AppShell(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.lg),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: AppTextStyles.sectionTitle),
                      ],
                    ),
                  ),
                  ...actions,
                ],
              ),
            ),
            Expanded(
              child: isWide
                  ? Row(
                      children: [
                        Container(
                          width: 108,
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: NavigationRail(
                            backgroundColor: Colors.transparent,
                            indicatorColor: accent.withValues(alpha: 0.16),
                            selectedIndex: currentIndex,
                            onDestinationSelected: onTap,
                            labelType: NavigationRailLabelType.all,
                            destinations: destinations
                                .map(
                                  (item) => NavigationRailDestination(
                                    icon: item.icon,
                                    selectedIcon: item.selectedIcon ?? item.icon,
                                    label: Text(item.label),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.lg),
                        Expanded(child: body),
                      ],
                    )
                  : body,
            ),
            if (!isWide)
              AppBottomNav(
                selectedIndex: currentIndex,
                onSelected: onTap,
                items: destinations
                    .map(
                      (item) => AppBottomNavItem(
                        icon: _iconData(item.icon),
                        activeIcon: _iconData(item.selectedIcon ?? item.icon),
                        label: item.label,
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }

  IconData _iconData(Widget widget) {
    if (widget is Icon && widget.icon != null) return widget.icon!;
    return Icons.circle;
  }
}
