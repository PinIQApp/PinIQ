import 'package:flutter/material.dart';

class WeightStatusChip extends StatelessWidget {
  const WeightStatusChip({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mapping = switch (status) {
      'green' => (label: 'On Track', color: const Color(0xFF3DDC97)),
      'yellow' => (label: 'Caution', color: const Color(0xFFF4C95D)),
      'red' => (label: 'Unsafe', color: const Color(0xFFFF6B6B)),
      _ => (label: 'Review', color: theme.colorScheme.primary),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: mapping.color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: mapping.color.withValues(alpha: 0.5)),
      ),
      child: Text(
        mapping.label,
        style: TextStyle(
          color: mapping.color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}
