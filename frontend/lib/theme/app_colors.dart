import 'package:flutter/material.dart';

class AppColors {
  static const Color bg = Color(0xFF050B14);
  static const Color surface = Color(0xFF0D1624);
  static const Color surfaceElevated = Color(0xFF121D2E);
  static const Color surfaceMuted = Color(0xFF162235);
  static const Color border = Color(0xFF142033);
  static const Color hairline = Color(0xFF101A2A);

  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);

  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);

  static const Color white = Colors.white;
  static const Color black = Colors.black;

  static Color? get schoolPrimary => null;

  static LinearGradient authPanelGradient(Color primary) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        surfaceElevated.withValues(alpha: 0.98),
        primary.withValues(alpha: 0.22),
        bg.withValues(alpha: 0.98),
      ],
    );
  }

  static LinearGradient brandedGradient({
    required Color primary,
    required Color secondary,
  }) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        primary.withValues(alpha: 0.92),
        secondary.withValues(alpha: 0.70),
      ],
    );
  }
}
