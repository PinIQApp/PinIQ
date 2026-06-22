import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/section_header.dart';
import '../../widgets/subpage_header.dart';

class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  State<NotificationCenterScreen> createState() => _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  String _filter = 'all';

  static const List<_NotificationRecord> _records = [
    _NotificationRecord(
      title: '2 weight alerts need review',
      subtitle: 'Unsafe change pattern surfaced in the last 24 hours.',
      type: 'Weights',
      audience: 'Coaches',
      status: 'High priority',
    ),
    _NotificationRecord(
      title: '3 unread parent-visible threads',
      subtitle: 'Messages are waiting for a coach or assistant response.',
      type: 'Messages',
      audience: 'Coaches',
      status: 'Unread',
    ),
    _NotificationRecord(
      title: 'Bluegrass Spring Open added to watchlist',
      subtitle: 'Tournament scanner surfaced a new event match.',
      type: 'Tournaments',
      audience: 'Coaches',
      status: 'New',
    ),
    _NotificationRecord(
      title: 'Thursday practice reminder scheduled',
      subtitle: 'Parents and athletes will receive a reminder at 2:00 PM.',
      type: 'Events',
      audience: 'Athletes + Parents',
      status: 'Queued',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final visible = _records.where((record) {
      return switch (_filter) {
        'weights' => record.type == 'Weights',
        'messages' => record.type == 'Messages',
        'events' => record.type == 'Events',
        'queued' => record.status == 'Queued',
        _ => true,
      };
    }).toList();

    return ListView(
        padding: EdgeInsets.zero,
        children: [
          const SubpageHeader(
            title: 'Notification Center',
            subtitle:
                'Control who gets alerted, what gets sent, and which signals matter most.',
          ),
          const SizedBox(height: AppSpacing.lg),
          const _NotificationSummaryRow(),
          const SizedBox(height: AppSpacing.xl),
          Container(
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth >= 560) {
                      return Row(
                        children: [
                          Text('Alert stream', style: AppTextStyles.cardTitle.copyWith(fontSize: 22)),
                          const Spacer(),
                          OutlinedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.tune_rounded),
                            label: const Text('Edit rules'),
                          ),
                        ],
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Alert stream', style: AppTextStyles.cardTitle.copyWith(fontSize: 22)),
                        const SizedBox(height: AppSpacing.sm),
                        OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.tune_rounded),
                          label: const Text('Edit rules'),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final chip in const [
                        ('all', 'All'),
                        ('weights', 'Weights'),
                        ('messages', 'Messages'),
                        ('events', 'Events'),
                        ('queued', 'Queued'),
                      ])
                        Padding(
                          padding: const EdgeInsets.only(right: AppSpacing.xs),
                          child: ChoiceChip(
                            label: Text(chip.$2),
                            selected: _filter == chip.$1,
                            onSelected: (_) => setState(() => _filter = chip.$1),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                ...visible.map(
                  (record) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _NotificationRow(record: record),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 1040;
              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Expanded(flex: 3, child: _DeliveryRulesPanel()),
                    SizedBox(width: AppSpacing.lg),
                    Expanded(flex: 2, child: _QuietHoursPanel()),
                  ],
                );
              }

              return const Column(
                children: [
                  _DeliveryRulesPanel(),
                  SizedBox(height: AppSpacing.lg),
                  _QuietHoursPanel(),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
    );
  }
}

class _NotificationSummaryRow extends StatelessWidget {
  const _NotificationSummaryRow();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      children: const [
        SizedBox(
          width: 240,
          child: _NotificationMetric(
            label: 'Active rules',
            value: '12',
            note: 'trigger sets',
            color: Color(0xFFF97316),
          ),
        ),
        SizedBox(
          width: 240,
          child: _NotificationMetric(
            label: 'Unread',
            value: '9',
            note: 'coach-facing alerts',
            color: Color(0xFF38BDF8),
          ),
        ),
        SizedBox(
          width: 240,
          child: _NotificationMetric(
            label: 'Queued',
            value: '37',
            note: 'pending sends',
            color: Color(0xFFF59E0B),
          ),
        ),
        SizedBox(
          width: 240,
          child: _NotificationMetric(
            label: 'Quiet hours',
            value: '3',
            note: 'audience presets',
            color: AppColors.success,
          ),
        ),
      ],
    );
  }
}

class _NotificationMetric extends StatelessWidget {
  const _NotificationMetric({
    required this.label,
    required this.value,
    required this.note,
    required this.color,
  });

  final String label;
  final String value;
  final String note;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.caption),
          const SizedBox(height: AppSpacing.sm),
          Text(value, style: AppTextStyles.cardTitle.copyWith(color: color)),
          const SizedBox(height: AppSpacing.xxs),
          Text(note, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

class _NotificationRow extends StatelessWidget {
  const _NotificationRow({required this.record});

  final _NotificationRecord record;

  @override
  Widget build(BuildContext context) {
    final accent = switch (record.status) {
      'High priority' => const Color(0xFFEF4444),
      'Unread' => const Color(0xFF38BDF8),
      'Queued' => const Color(0xFFF59E0B),
      _ => const Color(0xFFF97316),
    };

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.notifications_active_outlined, color: accent),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(record.title, style: AppTextStyles.bodyStrong),
                const SizedBox(height: AppSpacing.xxs),
                Text(record.subtitle, style: AppTextStyles.caption),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    _NotificationTag(label: record.type, color: accent),
                    _NotificationTag(label: record.audience, color: AppColors.textSecondary),
                    _NotificationTag(label: record.status, color: accent),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DeliveryRulesPanel extends StatelessWidget {
  const _DeliveryRulesPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          SectionHeader(title: 'Delivery rules'),
          SizedBox(height: AppSpacing.md),
          _RuleRow(
            title: 'Weights',
            subtitle: 'High-risk alerts go to coaches immediately.',
            value: 'Immediate',
          ),
          SizedBox(height: AppSpacing.sm),
          _RuleRow(
            title: 'Messages',
            subtitle: 'Unread parent-visible threads stay on coach alerts.',
            value: 'Coach only',
          ),
          SizedBox(height: AppSpacing.sm),
          _RuleRow(
            title: 'Events',
            subtitle: 'Practice reminders notify athletes and parents at 2 PM.',
            value: 'Scheduled',
          ),
        ],
      ),
    );
  }
}

class _QuietHoursPanel extends StatelessWidget {
  const _QuietHoursPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          SectionHeader(title: 'Quiet hours'),
          SizedBox(height: AppSpacing.md),
          _RuleRow(
            title: 'Parents',
            subtitle: '9:00 PM to 6:00 AM',
            value: 'On',
          ),
          SizedBox(height: AppSpacing.sm),
          _RuleRow(
            title: 'Athletes',
            subtitle: '10:00 PM to 6:00 AM',
            value: 'On',
          ),
          SizedBox(height: AppSpacing.sm),
          _RuleRow(
            title: 'Coaches',
            subtitle: 'Weight and safety alerts bypass quiet hours',
            value: 'Override',
          ),
        ],
      ),
    );
  }
}

class _RuleRow extends StatelessWidget {
  const _RuleRow({
    required this.title,
    required this.subtitle,
    required this.value,
  });

  final String title;
  final String subtitle;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.bodyStrong),
                const SizedBox(height: AppSpacing.xxs),
                Text(subtitle, style: AppTextStyles.caption),
              ],
            ),
          ),
          _NotificationTag(label: value, color: const Color(0xFFF97316)),
        ],
      ),
    );
  }
}

class _NotificationTag extends StatelessWidget {
  const _NotificationTag({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(color: AppColors.textPrimary),
      ),
    );
  }
}

class _NotificationRecord {
  const _NotificationRecord({
    required this.title,
    required this.subtitle,
    required this.type,
    required this.audience,
    required this.status,
  });

  final String title;
  final String subtitle;
  final String type;
  final String audience;
  final String status;
}
