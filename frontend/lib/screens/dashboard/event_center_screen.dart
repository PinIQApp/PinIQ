import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/section_header.dart';
import '../../widgets/subpage_header.dart';

class EventCenterScreen extends StatefulWidget {
  const EventCenterScreen({super.key});

  @override
  State<EventCenterScreen> createState() => _EventCenterScreenState();
}

class _EventCenterScreenState extends State<EventCenterScreen> {
  String _filter = 'all';
  int _selectedIndex = 0;

  static const List<_EventRecord> _events = [
    _EventRecord(
      title: 'Open practice',
      dateLabel: 'Today • 4:00 PM',
      audience: 'Team',
      status: 'Attendance open',
      location: 'Main room',
      summary: 'Standard weekday practice with attendance check-in enabled.',
      notes: [
        'Reminder scheduled for 2:00 PM',
        'Attendance trend has improved this week',
        'Good candidate for one-tap coach update',
      ],
    ),
    _EventRecord(
      title: 'Bluegrass Spring Open travel',
      dateLabel: 'Saturday • 6:30 AM',
      audience: 'Athletes + Parents',
      status: 'Tournament linked',
      location: 'Lexington departure lot',
      summary: 'Travel block attached to a saved tournament with RSVP still pending.',
      notes: [
        '6 athletes still need RSVP response',
        'Can feed parent reminder flow automatically',
        'Flyer and event share assets should stay linked',
      ],
    ),
    _EventRecord(
      title: 'Booster fundraiser meeting',
      dateLabel: 'Monday • 6:00 PM',
      audience: 'Parents + Staff',
      status: 'Reminder queued',
      location: 'Media center',
      summary: 'Fundraiser planning session tied to upcoming merch campaign.',
      notes: [
        'Parents will receive reminder tonight',
        'Could generate flyer and social post together',
        'Attendance should be tracked for planning follow-up',
      ],
    ),
    _EventRecord(
      title: 'Girls weekend camp',
      dateLabel: 'Jun 8 • 9:00 AM',
      audience: 'Girls roster',
      status: 'Draft',
      location: 'Aux gym',
      summary: 'Special event draft not yet shared publicly.',
      notes: [
        'Needs final coach staffing confirmation',
        'Good use case for a registration flyer',
        'Can become a recruiting visibility event',
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final visible = _events.where((event) {
      return switch (_filter) {
        'practice' => event.title.toLowerCase().contains('practice'),
        'travel' => event.status == 'Tournament linked',
        'parents' => event.audience.contains('Parents'),
        'drafts' => event.status == 'Draft',
        _ => true,
      };
    }).toList();

    if (_selectedIndex >= visible.length) {
      _selectedIndex = visible.isEmpty ? 0 : visible.length - 1;
    }

    final selected = visible.isEmpty ? null : visible[_selectedIndex];

    return LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 1120;

          return ListView(
            padding: EdgeInsets.zero,
            children: [
              const SubpageHeader(
                title: 'Event Center',
                subtitle:
                    'Plan practices, travel, reminders, and attendance from one schedule layer.',
              ),
              const SizedBox(height: AppSpacing.lg),
              const _EventSummaryRow(),
              const SizedBox(height: AppSpacing.xl),
              if (isWide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 5,
                      child: _EventListPanel(
                        filter: _filter,
                        onFilterChanged: (value) => setState(() {
                          _filter = value;
                          _selectedIndex = 0;
                        }),
                        events: visible,
                        selectedIndex: _selectedIndex,
                        onSelect: (index) => setState(() => _selectedIndex = index),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      flex: 4,
                      child: selected == null
                          ? const _EventEmptyPanel()
                          : _EventDetailPanel(event: selected),
                    ),
                  ],
                )
              else ...[
                _EventListPanel(
                  filter: _filter,
                  onFilterChanged: (value) => setState(() {
                    _filter = value;
                    _selectedIndex = 0;
                  }),
                  events: visible,
                  selectedIndex: _selectedIndex,
                  onSelect: (index) => setState(() => _selectedIndex = index),
                ),
                const SizedBox(height: AppSpacing.lg),
                if (selected == null)
                  const _EventEmptyPanel()
                else
                  _EventDetailPanel(event: selected),
              ],
              const SizedBox(height: AppSpacing.xl),
              const SectionHeader(title: 'Attendance watch'),
              const SizedBox(height: AppSpacing.md),
              const _AttendancePanel(),
              const SizedBox(height: AppSpacing.xl),
            ],
          );
        },
    );
  }
}

class _EventSummaryRow extends StatelessWidget {
  const _EventSummaryRow();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      children: const [
        SizedBox(
          width: 240,
          child: _EventMetric(label: 'Upcoming', value: '8', note: 'next 14 days', color: Color(0xFF22C55E)),
        ),
        SizedBox(
          width: 240,
          child: _EventMetric(label: 'RSVPs', value: '31', note: 'awaiting response', color: Color(0xFFF59E0B)),
        ),
        SizedBox(
          width: 240,
          child: _EventMetric(label: 'Attendance', value: '92%', note: 'last 30 days', color: Color(0xFF38BDF8)),
        ),
        SizedBox(
          width: 240,
          child: _EventMetric(label: 'Linked', value: '4', note: 'tournament events', color: Color(0xFF8B5CF6)),
        ),
      ],
    );
  }
}

class _EventListPanel extends StatelessWidget {
  const _EventListPanel({
    required this.filter,
    required this.onFilterChanged,
    required this.events,
    required this.selectedIndex,
    required this.onSelect,
  });

  final String filter;
  final ValueChanged<String> onFilterChanged;
  final List<_EventRecord> events;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (constraints.maxWidth >= 560)
              Row(
                children: [
                  Text('Schedule board', style: AppTextStyles.cardTitle.copyWith(fontSize: 22)),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.add_circle_outline_rounded),
                    label: const Text('Create event'),
                  ),
                ],
              )
            else ...[
              Text('Schedule board', style: AppTextStyles.cardTitle.copyWith(fontSize: 22)),
              const SizedBox(height: AppSpacing.sm),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add_circle_outline_rounded),
                label: const Text('Create event'),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final chip in const [
                    ('all', 'All'),
                    ('practice', 'Practice'),
                    ('travel', 'Travel'),
                    ('parents', 'Parents'),
                    ('drafts', 'Drafts'),
                  ])
                    Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.xs),
                      child: ChoiceChip(
                        label: Text(chip.$2),
                        selected: filter == chip.$1,
                        onSelected: (_) => onFilterChanged(chip.$1),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ...List.generate(events.length, (index) {
              final event = events[index];
              return Padding(
                padding: EdgeInsets.only(bottom: index == events.length - 1 ? 0 : AppSpacing.sm),
                child: _EventRow(
                  event: event,
                  selected: index == selectedIndex,
                  onTap: () => onSelect(index),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _EventRow extends StatelessWidget {
  const _EventRow({
    required this.event,
    required this.selected,
    required this.onTap,
  });

  final _EventRecord event;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = switch (event.status) {
      'Draft' => AppColors.textSecondary,
      'Tournament linked' => const Color(0xFF8B5CF6),
      'Reminder queued' => const Color(0xFFF59E0B),
      _ => const Color(0xFF22C55E),
    };

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: selected ? AppColors.surfaceElevated : AppColors.surface.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: selected ? accent.withValues(alpha: 0.4) : AppColors.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event.title, style: AppTextStyles.bodyStrong),
                  const SizedBox(height: AppSpacing.xxs),
                  Text('${event.dateLabel} • ${event.location}', style: AppTextStyles.caption),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: [
                      _EventTag(label: event.status, color: accent),
                      _EventTag(label: event.audience, color: const Color(0xFF38BDF8)),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

class _EventDetailPanel extends StatelessWidget {
  const _EventDetailPanel({required this.event});

  final _EventRecord event;

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
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(event.title, style: AppTextStyles.sectionTitle),
                    const SizedBox(height: AppSpacing.xxs),
                    Text('${event.dateLabel} • ${event.location}', style: AppTextStyles.body),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.notifications_outlined),
                label: const Text('Send reminder'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(event.summary, style: AppTextStyles.body.copyWith(color: AppColors.textPrimary)),
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader(title: 'What needs attention'),
          const SizedBox(height: AppSpacing.md),
          ...event.notes.map(
            (note) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Icon(Icons.event_note_rounded, size: 18, color: Color(0xFF22C55E)),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text(note, style: AppTextStyles.body)),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.fact_check_outlined),
                label: const Text('Track attendance'),
              ),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.campaign_outlined),
                label: const Text('Post update'),
              ),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.design_services_outlined),
                label: const Text('Create flyer'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AttendancePanel extends StatelessWidget {
  const _AttendancePanel();

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
          _AttendanceRow(title: 'Open practice', subtitle: '3 athletes have not checked in yet', value: 'Today'),
          SizedBox(height: AppSpacing.sm),
          _AttendanceRow(title: 'Bluegrass Spring Open travel', subtitle: '6 RSVPs still missing', value: 'Needs response'),
          SizedBox(height: AppSpacing.sm),
          _AttendanceRow(title: 'Booster fundraiser meeting', subtitle: 'Parent reminder is queued', value: 'Queued'),
        ],
      ),
    );
  }
}

class _AttendanceRow extends StatelessWidget {
  const _AttendanceRow({
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
          _EventTag(label: value, color: const Color(0xFFF59E0B)),
        ],
      ),
    );
  }
}

class _EventMetric extends StatelessWidget {
  const _EventMetric({
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

class _EventTag extends StatelessWidget {
  const _EventTag({
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
      child: Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.textPrimary)),
    );
  }
}

class _EventRecord {
  const _EventRecord({
    required this.title,
    required this.dateLabel,
    required this.audience,
    required this.status,
    required this.location,
    required this.summary,
    required this.notes,
  });

  final String title;
  final String dateLabel;
  final String audience;
  final String status;
  final String location;
  final String summary;
  final List<String> notes;
}

class _EventEmptyPanel extends StatelessWidget {
  const _EventEmptyPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Text('No events match the current filter.', style: AppTextStyles.body),
    );
  }
}
