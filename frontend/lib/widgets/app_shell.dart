import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final horizontalPadding = width >= 1200
        ? AppSpacing.xxl
        : width >= 720
            ? AppSpacing.screenPadding
            : AppSpacing.sm;
    final verticalPadding = width >= 960
        ? AppSpacing.md
        : width >= 420
            ? AppSpacing.sm
            : AppSpacing.xs;

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.bg,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF07101B),
            AppColors.bg,
          ],
        ),
      ),
      child: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: Center(
              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(maxWidth: AppSpacing.maxContentWidth),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: verticalPadding,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: child,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
