import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/section_header.dart';
import '../../widgets/subpage_header.dart';

class RecruitingCenterScreen extends StatefulWidget {
  const RecruitingCenterScreen({super.key});

  @override
  State<RecruitingCenterScreen> createState() => _RecruitingCenterScreenState();
}

class _RecruitingCenterScreenState extends State<RecruitingCenterScreen> {
  String _filter = 'all';
  int _selectedIndex = 0;

  static const List<_RecruitingAthlete> _athletes = [
    _RecruitingAthlete(
      name: 'Avery Hall',
      grade: 'Senior',
      weightClass: '120',
      status: 'Priority',
      completeness: '92%',
      interest: '4 schools',
      summary: 'Strong profile, needs one updated varsity highlight set.',
      details: [
        'GPA summary and bio ready',
        'Needs one fresh tournament clip',
        'Coach contact notes updated this week',
      ],
    ),
    _RecruitingAthlete(
      name: 'Maya Slone',
      grade: 'Junior',
      weightClass: '132',
      status: 'Watchlist',
      completeness: '74%',
      interest: '2 schools',
      summary: 'Good athlete page, missing polished transcript and intro video.',
      details: [
        'Highlight package is serviceable',
        'Academic block still incomplete',
        'Could become a strong off-season recruiting push',
      ],
    ),
    _RecruitingAthlete(
      name: 'Kylie Johnson',
      grade: 'Senior',
      weightClass: '145',
      status: 'Missing media',
      completeness: '61%',
      interest: '1 school',
      summary: 'Needs updated photos, clips, and one cleaner public share page.',
      details: [
        'Stats summary is in place',
        'No modern match footage linked yet',
        'Should move into urgent profile rebuild',
      ],
    ),
    _RecruitingAthlete(
      name: 'Jocelyn Reed',
      grade: 'Junior',
      weightClass: '155',
      status: 'Ready',
      completeness: '88%',
      interest: '3 schools',
      summary: 'Recruiting page is clean and ready for outreach this month.',
      details: [
        'Highlight coverage looks solid',
        'Coach note timeline is current',
        'Needs one college outreach packet export',
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final visible = _athletes.where((athlete) {
      return switch (_filter) {
        'priority' => athlete.status == 'Priority',
        'seniors' => athlete.grade == 'Senior',
        'missing' => athlete.status == 'Missing media',
        'watchlist' => athlete.status == 'Watchlist',
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
                title: 'Recruiting Center',
                subtitle:
                    'Track athlete readiness, outreach, and exposure from one recruiting board.',
              ),
              const SizedBox(height: AppSpacing.lg),
              const _RecruitingSummaryRow(),
              const SizedBox(height: AppSpacing.xl),
              if (isWide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 5,
                      child: _RecruitingBoard(
                        filter: _filter,
                        onFilterChanged: (value) => setState(() {
                          _filter = value;
                          _selectedIndex = 0;
                        }),
                        athletes: visible,
                        selectedIndex: _selectedIndex,
                        onSelect: (index) => setState(() => _selectedIndex = index),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      flex: 4,
                      child: selected == null
                          ? const _RecruitingEmptyPanel()
                          : _RecruitingDetailPanel(athlete: selected),
                    ),
                  ],
                )
              else ...[
                _RecruitingBoard(
                  filter: _filter,
                  onFilterChanged: (value) => setState(() {
                    _filter = value;
                    _selectedIndex = 0;
                  }),
                  athletes: visible,
                  selectedIndex: _selectedIndex,
                  onSelect: (index) => setState(() => _selectedIndex = index),
                ),
                const SizedBox(height: AppSpacing.lg),
                if (selected == null)
                  const _RecruitingEmptyPanel()
              else
                  _RecruitingDetailPanel(athlete: selected),
              ],
              const SizedBox(height: AppSpacing.xl),
              const SectionHeader(title: 'Outreach pipeline'),
              const SizedBox(height: AppSpacing.md),
              _RecruitingPipelineRow(athletes: _athletes),
              const SizedBox(height: AppSpacing.xl),
            ],
          );
          },
    );
  }
}

class _RecruitingSummaryRow extends StatelessWidget {
  const _RecruitingSummaryRow();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      children: const [
        SizedBox(
          width: 240,
          child: _RecruitingMetricCard(
            label: 'Profiles',
            value: '9',
            note: 'active athlete pages',
            color: Color(0xFF8B5CF6),
          ),
        ),
        SizedBox(
          width: 240,
          child: _RecruitingMetricCard(
            label: 'Priority',
            value: '4',
            note: 'athletes needing push',
            color: Color(0xFFF59E0B),
          ),
        ),
        SizedBox(
          width: 240,
          child: _RecruitingMetricCard(
            label: 'Highlights',
            value: '27',
            note: 'linked clips',
            color: Color(0xFF38BDF8),
          ),
        ),
        SizedBox(
          width: 240,
          child: _RecruitingMetricCard(
            label: 'Schools',
            value: '11',
            note: 'tracked programs',
            color: AppColors.success,
          ),
        ),
      ],
    );
  }
}

class _RecruitingBoard extends StatelessWidget {
  const _RecruitingBoard({
    required this.filter,
    required this.onFilterChanged,
    required this.athletes,
    required this.selectedIndex,
    required this.onSelect,
  });

  final String filter;
  final ValueChanged<String> onFilterChanged;
  final List<_RecruitingAthlete> athletes;
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
                  Text('Athlete board', style: AppTextStyles.cardTitle.copyWith(fontSize: 22)),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.share_outlined),
                    label: const Text('Export share pack'),
                  ),
                ],
              )
            else ...[
              Text('Athlete board', style: AppTextStyles.cardTitle.copyWith(fontSize: 22)),
              const SizedBox(height: AppSpacing.sm),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.share_outlined),
                label: const Text('Export share pack'),
              ),
            ],
          const SizedBox(height: AppSpacing.md),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final chip in const [
                  ('all', 'All'),
                  ('priority', 'Priority'),
                  ('seniors', 'Seniors'),
                  ('watchlist', 'Watchlist'),
                  ('missing', 'Missing media'),
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
          ...List.generate(athletes.length, (index) {
            final athlete = athletes[index];
            return Padding(
              padding: EdgeInsets.only(bottom: index == athletes.length - 1 ? 0 : AppSpacing.sm),
              child: _RecruitingRow(
                athlete: athlete,
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

class _RecruitingRow extends StatelessWidget {
  const _RecruitingRow({
    required this.athlete,
    required this.selected,
    required this.onTap,
  });

  final _RecruitingAthlete athlete;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = switch (athlete.status) {
      'Priority' => const Color(0xFFF59E0B),
      'Missing media' => const Color(0xFFEF4444),
      'Ready' => AppColors.success,
      _ => const Color(0xFF8B5CF6),
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
            CircleAvatar(
              radius: 24,
              backgroundColor: accent.withValues(alpha: 0.18),
              child: Text(
                athlete.name.substring(0, 1),
                style: AppTextStyles.bodyStrong.copyWith(color: accent),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(athlete.name, style: AppTextStyles.bodyStrong),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    '${athlete.grade} • ${athlete.weightClass} lbs • ${athlete.interest}',
                    style: AppTextStyles.caption,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: [
                      _RecruitingTag(label: athlete.status, color: accent),
                      _RecruitingTag(label: athlete.completeness, color: const Color(0xFF38BDF8)),
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

class _RecruitingDetailPanel extends StatelessWidget {
  const _RecruitingDetailPanel({required this.athlete});

  final _RecruitingAthlete athlete;

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
                    Text(athlete.name, style: AppTextStyles.sectionTitle),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      '${athlete.grade} • ${athlete.weightClass} lbs • ${athlete.interest}',
                      style: AppTextStyles.body,
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.link_rounded),
                label: const Text('Share page'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(athlete.summary, style: AppTextStyles.body.copyWith(color: AppColors.textPrimary)),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _RecruitingMetricCard(
                  label: 'Readiness',
                  value: athlete.completeness,
                  note: 'profile completion',
                  color: const Color(0xFF8B5CF6),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _RecruitingMetricCard(
                  label: 'Interest',
                  value: athlete.interest,
                  note: 'tracked colleges',
                  color: const Color(0xFF38BDF8),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader(title: 'Next moves'),
          const SizedBox(height: AppSpacing.md),
          ...athlete.details.map(
            (detail) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Icon(Icons.check_circle_outline_rounded,
                        size: 18, color: Color(0xFF8B5CF6)),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text(detail, style: AppTextStyles.body)),
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
                icon: const Icon(Icons.video_library_outlined),
                label: const Text('Add highlight'),
              ),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.note_add_outlined),
                label: const Text('Add coach note'),
              ),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.outbound_rounded),
                label: const Text('Prepare outreach'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecruitingAthlete {
  const _RecruitingAthlete({
    required this.name,
    required this.grade,
    required this.weightClass,
    required this.status,
    required this.completeness,
    required this.interest,
    required this.summary,
    required this.details,
  });

  final String name;
  final String grade;
  final String weightClass;
  final String status;
  final String completeness;
  final String interest;
  final String summary;
  final List<String> details;
}

class _RecruitingTag extends StatelessWidget {
  const _RecruitingTag({
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

class _RecruitingMetricCard extends StatelessWidget {
  const _RecruitingMetricCard({
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

class _RecruitingEmptyPanel extends StatelessWidget {
  const _RecruitingEmptyPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        'No athletes match the current recruiting filter.',
        style: AppTextStyles.body,
      ),
    );
  }
}

class _RecruitingPipelineRow extends StatelessWidget {
  const _RecruitingPipelineRow({required this.athletes});

  final List<_RecruitingAthlete> athletes;

  @override
  Widget build(BuildContext context) {
    final ready = athletes.where((athlete) => athlete.status == 'Ready' || athlete.status == 'Priority').length;
    final missing = athletes.where((athlete) => athlete.status == 'Missing media').length;
    final seniors = athletes.where((athlete) => athlete.grade == 'Senior').length;

    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      children: [
        SizedBox(
          width: 260,
          child: _RecruitingMetricCard(
            label: 'Ready to share',
            value: '$ready',
            note: 'profiles ready for outreach packets',
            color: AppColors.success,
          ),
        ),
        SizedBox(
          width: 260,
          child: _RecruitingMetricCard(
            label: 'Missing media',
            value: '$missing',
            note: 'athletes blocking cleaner recruiting pages',
            color: const Color(0xFFEF4444),
          ),
        ),
        SizedBox(
          width: 260,
          child: _RecruitingMetricCard(
            label: 'Senior push',
            value: '$seniors',
            note: 'upperclassmen needing active outreach',
            color: const Color(0xFFF59E0B),
          ),
        ),
      ],
    );
  }
}
