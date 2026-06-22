import 'package:flutter/material.dart';

import '../models/weight_models.dart';

class WeightStatusChip extends StatelessWidget {
  const WeightStatusChip({
    super.key,
    required this.status,
    this.label,
  });

  final WeightPlanStatus status;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final colors = _palette(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colors.$1.withOpacity(0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.$1.withOpacity(0.45)),
      ),
      child: Text(
        label ?? _defaultLabel(status),
        style: TextStyle(
          color: colors.$2,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  static (Color, Color) _palette(WeightPlanStatus status) {
    switch (status) {
      case WeightPlanStatus.green:
        return (const Color(0xFF2D9D78), const Color(0xFF8AF0C0));
      case WeightPlanStatus.red:
        return (const Color(0xFFD64550), const Color(0xFFFFB6BC));
      case WeightPlanStatus.yellow:
        return (const Color(0xFFD6A63F), const Color(0xFFFFE29A));
    }
  }

  static String _defaultLabel(WeightPlanStatus status) {
    switch (status) {
      case WeightPlanStatus.green:
        return 'On Track';
      case WeightPlanStatus.red:
        return 'Unsafe';
      case WeightPlanStatus.yellow:
        return 'Caution';
    }
  }
}
