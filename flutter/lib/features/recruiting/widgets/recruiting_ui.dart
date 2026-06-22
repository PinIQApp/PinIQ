import 'package:flutter/material.dart';

import '../models/recruiting_models.dart';

class RecruitingPanel extends StatelessWidget {
  const RecruitingPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: const Color(0xFF121923),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
      ),
      child: child,
    );
  }
}

class RecruitingSectionTitle extends StatelessWidget {
  const RecruitingSectionTitle(this.title, {super.key, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class RecruitingMetricChip extends StatelessWidget {
  const RecruitingMetricChip({
    super.key,
    required this.metric,
    this.tint = const Color(0xFFF4A300),
  });

  final RecruitingStatMetric metric;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: tint.withOpacity(0.14),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tint.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            metric.label,
            style: const TextStyle(color: Color(0xFF93A4BC), fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            metric.value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class RecruitingStatusPill extends StatelessWidget {
  const RecruitingStatusPill({
    super.key,
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class RecruitingAthleteCardView extends StatelessWidget {
  const RecruitingAthleteCardView({
    super.key,
    required this.athlete,
    required this.primaryColor,
    required this.accentColor,
    this.onTap,
    this.trailing,
  });

  final RecruitingAthleteCard athlete;
  final Color primaryColor;
  final Color accentColor;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              primaryColor.withOpacity(0.18),
              accentColor.withOpacity(0.08),
              const Color(0xFF121923),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: accentColor.withOpacity(0.25),
                  backgroundImage: athlete.profileImageUrl != null && athlete.profileImageUrl!.isNotEmpty
                      ? NetworkImage(athlete.profileImageUrl!)
                      : null,
                  child: athlete.profileImageUrl == null || athlete.profileImageUrl!.isEmpty
                      ? Text(
                          athlete.athleteName.isNotEmpty ? athlete.athleteName[0] : '?',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                        )
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        athlete.athleteName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${athlete.weightClass} • ${athlete.graduationYear} • ${athlete.locationLabel ?? 'Location hidden'}',
                        style: const TextStyle(color: Color(0xFFD8E2EF), height: 1.35),
                      ),
                    ],
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                RecruitingStatusPill(
                  label: athlete.isActivelyLooking ? 'Actively Looking' : 'Open',
                  color: athlete.isActivelyLooking ? const Color(0xFFF7D354) : accentColor,
                ),
                if (athlete.isFeatured)
                  const RecruitingStatusPill(
                    label: 'Featured',
                    color: Color(0xFFFF6B6B),
                  ),
                if (athlete.trendLabel != null)
                  RecruitingStatusPill(
                    label: athlete.trendLabel!,
                    color: primaryColor,
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _miniMetric('Record', athlete.record),
                const SizedBox(width: 10),
                _miniMetric(
                  'Win %',
                  athlete.winPercentage == null ? '--' : '${((athlete.winPercentage ?? 0) * 100).round()}%',
                ),
                const SizedBox(width: 10),
                _miniMetric('Film', '${athlete.highlightCount} clips'),
              ],
            ),
            if (athlete.statsMetrics.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: athlete.statsMetrics
                    .take(4)
                    .map((metric) => RecruitingMetricChip(metric: metric, tint: accentColor))
                    .toList(growable: false),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _miniMetric(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Color(0xFF7F8FA5), fontSize: 12)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}
