import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';

class RoleSelectScreen extends StatelessWidget {
  const RoleSelectScreen({
    super.key,
    required this.selectedRole,
    required this.onSelected,
  });

  final String selectedRole;
  final ValueChanged<String> onSelected;

  static const roles = [
    ('coach', 'Coach'),
    ('assistant_coach', 'Assistant Coach'),
    ('athlete', 'Athlete'),
    ('parent', 'Parent'),
    ('admin', 'Admin'),
  ];

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: roles.map((entry) {
        final isSelected = entry.$1 == selectedRole;
        return ChoiceChip(
          label: Text(
            entry.$2,
            style: AppTextStyles.caption.copyWith(
              color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
          backgroundColor: AppColors.surfaceElevated,
          selectedColor: accent.withValues(alpha: 0.16),
          side: BorderSide(
            color: isSelected ? accent.withValues(alpha: 0.28) : AppColors.border,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
          ),
          selected: isSelected,
          onSelected: (_) => onSelected(entry.$1),
        );
      }).toList(),
    );
  }
}
