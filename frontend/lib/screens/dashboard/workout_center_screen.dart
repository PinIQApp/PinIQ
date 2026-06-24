import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/subpage_header.dart';
import 'stance_motion_workout_screen.dart';

class WorkoutCenterScreen extends StatefulWidget {
  const WorkoutCenterScreen({super.key});

  @override
  State<WorkoutCenterScreen> createState() => _WorkoutCenterScreenState();
}

class _WorkoutCenterScreenState extends State<WorkoutCenterScreen> {
  String _filter = 'all';
  int _selectedIndex = 0;
  String _reflection = 'good';

  @override
  Widget build(BuildContext context) {
    final workouts = _workouts
        .where((workout) => _filter == 'all' || workout.category == _filter)
        .toList();
    if (_selectedIndex >= workouts.length) {
      _selectedIndex = workouts.isEmpty ? 0 : workouts.length - 1;
    }
    final selected = workouts.isEmpty ? null : workouts[_selectedIndex];
    final isWide = MediaQuery.of(context).size.width >= 980;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          children: [
            const SubpageHeader(
              title: 'Today\'s Training',
              subtitle:
                  'Simple wrestling workouts athletes can follow and parents can understand.',
            ),
            const SizedBox(height: AppSpacing.lg),
            const _WorkoutHero(),
            const SizedBox(height: AppSpacing.lg),
            _TodayPlanPanel(onOpenTimer: _openStanceTimer),
            const SizedBox(height: AppSpacing.lg),
            const _WeeklyPlanPanel(),
            const SizedBox(height: AppSpacing.lg),
            _WorkoutFilters(
              selected: _filter,
              onSelected: (value) => setState(() {
                _filter = value;
                _selectedIndex = 0;
              }),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (isWide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 4,
                    child: _WorkoutList(
                      workouts: workouts,
                      selectedIndex: _selectedIndex,
                      onSelected: (index) =>
                          setState(() => _selectedIndex = index),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    flex: 5,
                    child: selected == null
                        ? const _EmptyWorkoutPanel()
                        : _WorkoutDetail(
                            workout: selected,
                            onOpenTimer: _openWorkoutTimer,
                            reflection: _reflection,
                            onReflectionChanged: (value) =>
                                setState(() => _reflection = value),
                          ),
                  ),
                ],
              )
            else ...[
              _WorkoutList(
                workouts: workouts,
                selectedIndex: _selectedIndex,
                onSelected: (index) => setState(() => _selectedIndex = index),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (selected == null)
                const _EmptyWorkoutPanel()
              else
                _WorkoutDetail(
                  workout: selected,
                  onOpenTimer: _openWorkoutTimer,
                  reflection: _reflection,
                  onReflectionChanged: (value) =>
                      setState(() => _reflection = value),
                ),
            ],
          ],
        ),
      ),
    );
  }

  void _openStanceTimer() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const StanceMotionWorkoutScreen(),
      ),
    );
  }

  void _openWorkoutTimer(_WorkoutPlan workout) {
    final timerCues = workout.timerCues;
    if (timerCues == null) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => StanceMotionWorkoutScreen(
          title: workout.timerTitle ?? workout.title,
          subtitle: workout.timerSubtitle ??
              'Pick a round length and react to random callouts.',
          startCue: workout.timerStartCue ?? workout.title,
          cues: timerCues,
          allowCueSelection: workout.allowTimerCueSelection,
          durationOptions: workout.timerDurationOptions,
          initialMinutes: workout.timerInitialMinutes,
          intervalOptions: workout.timerIntervalOptions,
          initialCueIntervalSeconds: workout.timerInitialIntervalSeconds,
          intervalLabel: workout.timerIntervalLabel,
          cueListLabel: workout.timerCueListLabel,
        ),
      ),
    );
  }
}

class _WorkoutHero extends StatelessWidget {
  const _WorkoutHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: AppColors.brandedGradient(
          primary: const Color(0xFF22C55E),
          secondary: const Color(0xFF2563EB),
        ),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.fitness_center_rounded,
              color: AppColors.textPrimary, size: 34),
          const SizedBox(height: AppSpacing.md),
          Text(
            'One clear plan for today',
            style: AppTextStyles.pageTitle.copyWith(fontSize: 28),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Pick a short session, know what to focus on, and finish with a quick check-in.',
            style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              const _HeroPill(label: '5-30 min'),
              const _HeroPill(label: 'Parent friendly'),
              const _HeroPill(label: 'Safe at home'),
            ],
          ),
        ],
      ),
    );
  }
}

class _TodayPlanPanel extends StatelessWidget {
  const _TodayPlanPanel({required this.onOpenTimer});

  final VoidCallback onOpenTimer;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 760;
          final cards = [
            const _TodayTaskCard(
              icon: Icons.directions_run_rounded,
              title: 'Training',
              value: '8 min stance timer',
              detail: 'Move, fake, level change, reset.',
              color: Color(0xFF22C55E),
            ),
            const _TodayTaskCard(
              icon: Icons.restaurant_menu_rounded,
              title: 'Fuel',
              value: 'Water + recovery snack',
              detail: 'Eat within 45 minutes after practice.',
              color: Color(0xFF14B8A6),
            ),
            const _TodayTaskCard(
              icon: Icons.psychology_rounded,
              title: 'Mindset',
              value: 'One focus word',
              detail: 'Choose pace, pressure, or position.',
              color: Color(0xFF8B5CF6),
            ),
            const _TodayTaskCard(
              icon: Icons.check_circle_rounded,
              title: 'Progress',
              value: 'Quick reflection',
              detail: 'Easy, good, or hard after the workout.',
              color: Color(0xFFF59E0B),
            ),
          ];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.today_rounded, color: AppColors.success),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text('Today\'s plan',
                        style: AppTextStyles.sectionTitle),
                  ),
                  TextButton.icon(
                    onPressed: onOpenTimer,
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Start'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'A simple daily view for athletes and parents: train, fuel, focus, check in.',
                style: AppTextStyles.body,
              ),
              const SizedBox(height: AppSpacing.lg),
              if (isWide)
                Row(
                  children: [
                    for (var i = 0; i < cards.length; i++) ...[
                      Expanded(child: cards[i]),
                      if (i != cards.length - 1)
                        const SizedBox(width: AppSpacing.sm),
                    ],
                  ],
                )
              else
                Column(
                  children: [
                    for (var i = 0; i < cards.length; i++) ...[
                      cards[i],
                      if (i != cards.length - 1)
                        const SizedBox(height: AppSpacing.sm),
                    ],
                  ],
                ),
            ],
          );
        },
      ),
    );
  }
}

class _TodayTaskCard extends StatelessWidget {
  const _TodayTaskCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.detail,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String value;
  final String detail;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 138),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: AppSpacing.sm),
          Text(title, style: AppTextStyles.caption),
          const SizedBox(height: AppSpacing.xxs),
          Text(value, style: AppTextStyles.bodyStrong),
          const SizedBox(height: AppSpacing.xxs),
          Text(detail, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

class _WeeklyPlanPanel extends StatelessWidget {
  const _WeeklyPlanPanel();

  @override
  Widget build(BuildContext context) {
    const days = [
      ('Mon', 'Stance', '8 min'),
      ('Tue', 'Strength', '24 min'),
      ('Wed', 'Recovery', '12 min'),
      ('Thu', 'Bottom', '14 min'),
      ('Fri', 'Match prep', '18 min'),
    ];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.76),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_month_rounded,
                  color: AppColors.warning),
              const SizedBox(width: AppSpacing.sm),
              Text('This week', style: AppTextStyles.sectionTitle),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Balanced week: three training days, one recovery day, one match-prep day.',
            style: AppTextStyles.body,
          ),
          const SizedBox(height: AppSpacing.md),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var i = 0; i < days.length; i++) ...[
                  _WeekDayChip(
                      day: days[i].$1, focus: days[i].$2, time: days[i].$3),
                  if (i != days.length - 1)
                    const SizedBox(width: AppSpacing.sm),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekDayChip extends StatelessWidget {
  const _WeekDayChip({
    required this.day,
    required this.focus,
    required this.time,
  });

  final String day;
  final String focus;
  final String time;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 138,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(day, style: AppTextStyles.caption),
          const SizedBox(height: AppSpacing.xs),
          Text(focus, style: AppTextStyles.bodyStrong),
          const SizedBox(height: AppSpacing.xxs),
          Text(time, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

class _WorkoutFilters extends StatelessWidget {
  const _WorkoutFilters({
    required this.selected,
    required this.onSelected,
  });

  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final option in const [
            ('all', 'All'),
            ('stance', 'Stance'),
            ('partner', 'Partner'),
            ('conditioning', 'Conditioning'),
            ('strength', 'Strength'),
            ('mobility', 'Mobility'),
            ('match', 'Match prep'),
          ])
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.xs),
              child: ChoiceChip(
                label: Text(option.$2),
                selected: selected == option.$1,
                onSelected: (_) => onSelected(option.$1),
              ),
            ),
        ],
      ),
    );
  }
}

class _WorkoutList extends StatelessWidget {
  const _WorkoutList({
    required this.workouts,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<_WorkoutPlan> workouts;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < workouts.length; index++) ...[
          _WorkoutCard(
            workout: workouts[index],
            selected: index == selectedIndex,
            onTap: () => onSelected(index),
          ),
          if (index != workouts.length - 1)
            const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

class _WorkoutCard extends StatelessWidget {
  const _WorkoutCard({
    required this.workout,
    required this.selected,
    required this.onTap,
  });

  final _WorkoutPlan workout;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.surfaceElevated.withValues(alpha: 0.98)
                : AppColors.surface.withValues(alpha: 0.74),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? workout.color.withValues(alpha: 0.52)
                  : AppColors.border,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: workout.color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(workout.icon, color: workout.color, size: 21),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(workout.title, style: AppTextStyles.bodyStrong),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      '${workout.minutes} min • ${workout.level} • ${workout.equipment}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _WorkoutDetail extends StatelessWidget {
  const _WorkoutDetail({
    required this.workout,
    required this.onOpenTimer,
    required this.reflection,
    required this.onReflectionChanged,
  });

  final _WorkoutPlan workout;
  final ValueChanged<_WorkoutPlan> onOpenTimer;
  final String reflection;
  final ValueChanged<String> onReflectionChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: workout.color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(workout.icon, color: workout.color),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(workout.title, style: AppTextStyles.sectionTitle),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(workout.description, style: AppTextStyles.body),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              _MetaPill(label: '${workout.minutes} min'),
              _MetaPill(label: workout.level),
              _MetaPill(label: workout.equipment),
              _MetaPill(label: workout.ageLabel),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _HowToPanel(workout: workout),
          const SizedBox(height: AppSpacing.lg),
          Text('Workout steps', style: AppTextStyles.cardTitle),
          const SizedBox(height: AppSpacing.md),
          for (final block in workout.blocks) ...[
            _WorkoutBlockRow(block: block, color: workout.color),
            const SizedBox(height: AppSpacing.sm),
          ],
          const SizedBox(height: AppSpacing.lg),
          Text('What to focus on', style: AppTextStyles.cardTitle),
          const SizedBox(height: AppSpacing.sm),
          for (final cue in workout.cues)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle_rounded,
                      size: 18, color: workout.color),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(child: Text(cue, style: AppTextStyles.body)),
                ],
              ),
            ),
          if (workout.timerCues != null) ...[
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton.icon(
              onPressed: () => onOpenTimer(workout),
              icon: const Icon(Icons.timer_rounded),
              label: Text(workout.timerButtonLabel ?? 'Run callout timer'),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          _SafetyPanel(workout: workout),
          const SizedBox(height: AppSpacing.lg),
          _ReflectionPanel(
            selected: reflection,
            onChanged: onReflectionChanged,
          ),
        ],
      ),
    );
  }
}

class _HowToPanel extends StatelessWidget {
  const _HowToPanel({required this.workout});

  final _WorkoutPlan workout;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.76),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HowToVisuals(workout: workout),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.image_search_rounded,
                        color: workout.color, size: 20),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(workout.howToTitle,
                          style: AppTextStyles.cardTitle),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                for (var i = 0; i < workout.howToTips.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: workout.color.withValues(alpha: 0.16),
                            shape: BoxShape.circle,
                          ),
                          child: Text('${i + 1}',
                              style: AppTextStyles.caption
                                  .copyWith(color: workout.color)),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(workout.howToTips[i],
                              style: AppTextStyles.body),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HowToVisuals extends StatelessWidget {
  const _HowToVisuals({required this.workout});

  final _WorkoutPlan workout;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 560;
        final imageHeight = isWide ? 230.0 : 210.0;
        final sequenceHeight = isWide ? 220.0 : 220.0;

        final firstFormCard = _HowToVisualCard(
          label: 'Proper form 1',
          color: workout.color,
          height: imageHeight,
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(20)),
          child: _WorkoutFormImage(
            workout: workout,
            fit: BoxFit.contain,
            alignment: Alignment.center,
          ),
        );

        final secondFormCard = _HowToVisualCard(
          label: 'Proper form 2',
          color: workout.color,
          height: imageHeight,
          borderRadius: isWide
              ? const BorderRadius.only(topRight: Radius.circular(20))
              : BorderRadius.zero,
          child: _WorkoutFormImage(
            workout: workout,
            fit: BoxFit.contain,
            alignment: _checkpointAlignment(workout.category),
          ),
        );

        final sequenceCard = _HowToVisualCard(
          label: 'Movement path',
          color: workout.color,
          height: sequenceHeight,
          borderRadius: BorderRadius.zero,
          child: _FolkstyleSequenceDiagram(
            kind: workout.category,
            color: workout.color,
          ),
        );

        if (isWide) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: firstFormCard),
                  SizedBox(
                    width: 1,
                    height: imageHeight,
                    child: ColoredBox(color: AppColors.border),
                  ),
                  Expanded(child: secondFormCard),
                ],
              ),
              SizedBox(
                height: 1,
                width: double.infinity,
                child: ColoredBox(color: AppColors.border),
              ),
              sequenceCard,
            ],
          );
        }

        return Column(
          children: [
            _HowToVisualCard(
              label: 'Proper form 1',
              color: workout.color,
              height: imageHeight,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              child: _WorkoutFormImage(
                workout: workout,
                fit: BoxFit.contain,
                alignment: Alignment.center,
              ),
            ),
            SizedBox(
              height: 1,
              width: double.infinity,
              child: ColoredBox(color: AppColors.border),
            ),
            _HowToVisualCard(
              label: 'Proper form 2',
              color: workout.color,
              height: imageHeight,
              borderRadius: BorderRadius.zero,
              child: _WorkoutFormImage(
                workout: workout,
                fit: BoxFit.contain,
                alignment: _checkpointAlignment(workout.category),
              ),
            ),
            SizedBox(
              height: 1,
              width: double.infinity,
              child: ColoredBox(color: AppColors.border),
            ),
            sequenceCard,
          ],
        );
      },
    );
  }
}

class _WorkoutFormImage extends StatelessWidget {
  const _WorkoutFormImage({
    required this.workout,
    required this.fit,
    required this.alignment,
  });

  final _WorkoutPlan workout;
  final BoxFit fit;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      workout.imageAsset,
      fit: fit,
      alignment: alignment,
      errorBuilder: (context, error, stackTrace) {
        return _FolkstyleSequenceDiagram(
          kind: workout.category,
          color: workout.color,
        );
      },
    );
  }
}

Alignment _checkpointAlignment(String category) {
  return switch (category) {
    'stance' => Alignment.centerRight,
    'conditioning' => Alignment.centerRight,
    'strength' => Alignment.center,
    'match' => Alignment.centerLeft,
    'mobility' => Alignment.center,
    _ => Alignment.center,
  };
}

class _HowToVisualCard extends StatelessWidget {
  const _HowToVisualCard({
    required this.label,
    required this.color,
    required this.height,
    required this.borderRadius,
    required this.child,
  });

  final String label;
  final Color color;
  final double height;
  final BorderRadius borderRadius;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: SizedBox(
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(
              color: AppColors.bg.withValues(alpha: 0.62),
              child: child,
            ),
            Positioned(
              left: AppSpacing.sm,
              top: AppSpacing.sm,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.bg.withValues(alpha: 0.78),
                  borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
                  border: Border.all(color: color.withValues(alpha: 0.48)),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xxs,
                  ),
                  child: Text(label, style: AppTextStyles.caption),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FolkstyleSequenceDiagram extends StatelessWidget {
  const _FolkstyleSequenceDiagram({
    required this.kind,
    required this.color,
  });

  final String kind;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _FolkstyleSequencePainter(kind: kind, color: color),
      child: const SizedBox.expand(),
    );
  }
}

class _FolkstyleSequencePainter extends CustomPainter {
  const _FolkstyleSequencePainter({
    required this.kind,
    required this.color,
  });

  final String kind;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = AppColors.surfaceElevated;
    canvas.drawRect(Offset.zero & size, bg);

    final panelGap = size.width * 0.018;
    final panelWidth = (size.width - panelGap * 4) / 3;
    final panelHeight = size.height * 0.84;
    final panelTop = size.height * 0.08;
    final panels = [
      for (var i = 0; i < 3; i++)
        Rect.fromLTWH(
          panelGap + i * (panelWidth + panelGap),
          panelTop,
          panelWidth,
          panelHeight,
        ),
    ];

    final labels = _labelsFor(kind);
    for (var i = 0; i < panels.length; i++) {
      _drawPanel(canvas, panels[i], labels[i], i + 1);
      _drawStep(canvas, panels[i], i);
    }
  }

  List<String> _labelsFor(String kind) {
    return switch (kind) {
      'stance' => ['Stance', 'Motion', 'Sprawl'],
      'conditioning' => ['Setup', 'Shot', 'Finish'],
      'strength' => ['Hinge', 'Pull', 'Carry'],
      'match' => ['Base', 'Stand', 'Face'],
      'mobility' => ['Hip', 'Switch', 'Reach'],
      _ => ['Step 1', 'Step 2', 'Step 3'],
    };
  }

  void _drawPanel(Canvas canvas, Rect rect, String label, int step) {
    final border = Paint()
      ..color = AppColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final fill = Paint()..color = AppColors.bg.withValues(alpha: 0.42);

    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(18));
    canvas.drawRRect(rrect, fill);
    canvas.drawRRect(rrect, border);

    final mat = Paint()
      ..color = color.withValues(alpha: 0.42)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(rect.center.dx, rect.bottom - rect.height * 0.18),
        width: rect.width * 0.82,
        height: rect.height * 0.18,
      ),
      mat,
    );

    _drawText(
      canvas,
      '$step',
      Offset(rect.left + 16, rect.top + 12),
      fontSize: 14,
      fontWeight: FontWeight.w800,
      color: AppColors.textPrimary,
    );
    _drawText(
      canvas,
      label,
      Offset(rect.left + 40, rect.top + 12),
      fontSize: 13,
      fontWeight: FontWeight.w700,
      color: AppColors.textSecondary,
    );
  }

  void _drawStep(Canvas canvas, Rect rect, int step) {
    switch (kind) {
      case 'stance':
        if (step == 0) {
          _drawWrestler(canvas, rect, const _Pose.stance(), color);
        } else if (step == 1) {
          _drawWrestler(canvas, rect, const _Pose.stance(shift: 0.04), color);
          _drawArrow(canvas, rect.center + Offset(-20, 34),
              rect.center + Offset(30, 18));
        } else {
          _drawWrestler(canvas, rect, const _Pose.sprawl(), color);
          _drawArrow(canvas, rect.center + Offset(20, 38),
              rect.center + Offset(-28, 38));
        }
        break;
      case 'conditioning':
        if (step == 0) {
          _drawWrestler(canvas, rect, const _Pose.stance(shift: -0.05), color);
          _drawWrestler(
              canvas, rect, const _Pose.stance(shift: 0.16), AppColors.danger);
        } else if (step == 1) {
          _drawWrestler(canvas, rect, const _Pose.shot(), color);
          _drawWrestler(canvas, rect, const _Pose.defender(), AppColors.danger);
        } else {
          _drawWrestler(canvas, rect, const _Pose.finish(), color);
          _drawWrestler(canvas, rect, const _Pose.defender(kneeling: true),
              AppColors.danger);
        }
        break;
      case 'strength':
        if (step == 0) {
          _drawWrestler(canvas, rect, const _Pose.hinge(), color);
          _drawDumbbells(canvas, rect);
        } else if (step == 1) {
          _drawWrestler(canvas, rect, const _Pose.row(), color);
          _drawBand(canvas, rect);
        } else {
          _drawWrestler(canvas, rect, const _Pose.carry(), color);
          _drawDumbbells(canvas, rect, carry: true);
        }
        break;
      case 'match':
        if (step == 0) {
          _drawWrestler(canvas, rect, const _Pose.baseBottom(), color);
          _drawWrestler(
              canvas, rect, const _Pose.topControl(), AppColors.danger);
        } else if (step == 1) {
          _drawWrestler(canvas, rect, const _Pose.standUp(), color);
          _drawWrestler(
              canvas, rect, const _Pose.topBehind(), AppColors.danger);
          _drawArrow(canvas, rect.center + Offset(-22, 38),
              rect.center + Offset(-22, -30));
        } else {
          _drawWrestler(canvas, rect, const _Pose.stance(shift: -0.08), color);
          _drawWrestler(
              canvas, rect, const _Pose.stance(shift: 0.14), AppColors.danger);
          _drawArrow(canvas, rect.center + Offset(-5, 35),
              rect.center + Offset(38, 8));
        }
        break;
      case 'mobility':
        if (step == 0) {
          _drawWrestler(canvas, rect, const _Pose.hipStretch(), color);
        } else if (step == 1) {
          _drawWrestler(canvas, rect, const _Pose.shinBox(), color);
          _drawArrow(canvas, rect.center + Offset(-20, 28),
              rect.center + Offset(22, 28));
        } else {
          _drawWrestler(canvas, rect, const _Pose.threadNeedle(), color);
        }
        break;
      default:
        _drawWrestler(canvas, rect, const _Pose.stance(), color);
    }
  }

  void _drawWrestler(Canvas canvas, Rect rect, _Pose pose, Color singlet) {
    Offset p(double x, double y) => Offset(
          rect.left + rect.width * (x + pose.shift),
          rect.top + rect.height * y,
        );

    final body = Paint()
      ..color = singlet
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    final skin = Paint()
      ..color = const Color(0xFFF6C28B)
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    final outline = Paint()
      ..color = AppColors.textPrimary.withValues(alpha: 0.88)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final head = Paint()..color = const Color(0xFFF6C28B);

    canvas.drawLine(
        p(pose.hip.dx, pose.hip.dy), p(pose.chest.dx, pose.chest.dy), body);
    canvas.drawCircle(p(pose.head.dx, pose.head.dy), rect.width * 0.055, head);
    canvas.drawCircle(
        p(pose.head.dx, pose.head.dy), rect.width * 0.055, outline);

    for (final limb in pose.limbs) {
      final paint = limb.singlet ? body : skin;
      canvas.drawLine(p(limb.a.dx, limb.a.dy), p(limb.b.dx, limb.b.dy), paint);
      canvas.drawLine(p(limb.b.dx, limb.b.dy), p(limb.c.dx, limb.c.dy), paint);
    }
  }

  void _drawArrow(Canvas canvas, Offset start, Offset end) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(start, end, paint);
    final direction = (end - start);
    final angle = direction.direction;
    final left = end - Offset.fromDirection(angle - 0.7, 12);
    final right = end - Offset.fromDirection(angle + 0.7, 12);
    canvas.drawLine(end, left, paint);
    canvas.drawLine(end, right, paint);
  }

  void _drawDumbbells(Canvas canvas, Rect rect, {bool carry = false}) {
    final paint = Paint()..color = AppColors.textMuted;
    final y = rect.top + rect.height * (carry ? 0.68 : 0.71);
    for (final x in [
      rect.left + rect.width * 0.36,
      rect.left + rect.width * 0.58
    ]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(x, y), width: 26, height: 12),
          const Radius.circular(4),
        ),
        paint,
      );
    }
  }

  void _drawBand(Canvas canvas, Rect rect) {
    final paint = Paint()
      ..color = AppColors.success
      ..strokeWidth = 3;
    final anchor = Offset(rect.right - rect.width * 0.12, rect.center.dy);
    canvas.drawCircle(anchor, 5, paint);
    canvas.drawLine(anchor, Offset(rect.center.dx, rect.center.dy + 6), paint);
    canvas.drawLine(
        anchor, Offset(rect.center.dx - 12, rect.center.dy + 18), paint);
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset offset, {
    required double fontSize,
    required FontWeight fontWeight,
    required Color color,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _FolkstyleSequencePainter oldDelegate) {
    return oldDelegate.kind != kind || oldDelegate.color != color;
  }
}

class _Pose {
  const _Pose.stance({this.shift = 0})
      : head = const Offset(0.52, 0.34),
        chest = const Offset(0.48, 0.46),
        hip = const Offset(0.42, 0.60),
        limbs = const [
          _Limb(Offset(0.47, 0.47), Offset(0.36, 0.55), Offset(0.30, 0.63)),
          _Limb(Offset(0.50, 0.48), Offset(0.63, 0.54), Offset(0.68, 0.62)),
          _Limb(Offset(0.42, 0.60), Offset(0.32, 0.74), Offset(0.22, 0.76),
              singlet: true),
          _Limb(Offset(0.43, 0.61), Offset(0.58, 0.74), Offset(0.70, 0.76),
              singlet: true),
        ];

  const _Pose.sprawl()
      : shift = 0,
        head = const Offset(0.66, 0.45),
        chest = const Offset(0.55, 0.54),
        hip = const Offset(0.36, 0.56),
        limbs = const [
          _Limb(Offset(0.55, 0.55), Offset(0.68, 0.64), Offset(0.78, 0.70)),
          _Limb(Offset(0.52, 0.56), Offset(0.60, 0.70), Offset(0.66, 0.79)),
          _Limb(Offset(0.36, 0.57), Offset(0.22, 0.68), Offset(0.13, 0.75),
              singlet: true),
          _Limb(Offset(0.37, 0.57), Offset(0.28, 0.76), Offset(0.20, 0.82),
              singlet: true),
        ];

  const _Pose.shot()
      : shift = 0,
        head = const Offset(0.52, 0.46),
        chest = const Offset(0.45, 0.55),
        hip = const Offset(0.34, 0.66),
        limbs = const [
          _Limb(Offset(0.45, 0.55), Offset(0.57, 0.62), Offset(0.66, 0.66)),
          _Limb(Offset(0.43, 0.56), Offset(0.55, 0.70), Offset(0.63, 0.76)),
          _Limb(Offset(0.34, 0.66), Offset(0.45, 0.78), Offset(0.55, 0.80),
              singlet: true),
          _Limb(Offset(0.34, 0.66), Offset(0.22, 0.78), Offset(0.13, 0.82),
              singlet: true),
        ];

  const _Pose.defender({bool kneeling = false})
      : shift = 0.16,
        head = kneeling ? const Offset(0.50, 0.42) : const Offset(0.50, 0.34),
        chest = kneeling ? const Offset(0.44, 0.54) : const Offset(0.47, 0.47),
        hip = kneeling ? const Offset(0.36, 0.66) : const Offset(0.42, 0.60),
        limbs = kneeling
            ? const [
                _Limb(
                    Offset(0.44, 0.55), Offset(0.52, 0.68), Offset(0.62, 0.74)),
                _Limb(
                    Offset(0.42, 0.56), Offset(0.34, 0.66), Offset(0.25, 0.71)),
                _Limb(
                    Offset(0.36, 0.66), Offset(0.44, 0.78), Offset(0.54, 0.80),
                    singlet: true),
                _Limb(
                    Offset(0.36, 0.66), Offset(0.25, 0.78), Offset(0.16, 0.82),
                    singlet: true),
              ]
            : const [
                _Limb(
                    Offset(0.47, 0.47), Offset(0.36, 0.55), Offset(0.30, 0.63)),
                _Limb(
                    Offset(0.50, 0.48), Offset(0.63, 0.54), Offset(0.68, 0.62)),
                _Limb(
                    Offset(0.42, 0.60), Offset(0.32, 0.74), Offset(0.22, 0.76),
                    singlet: true),
                _Limb(
                    Offset(0.43, 0.61), Offset(0.58, 0.74), Offset(0.70, 0.76),
                    singlet: true),
              ];

  const _Pose.finish()
      : shift = -0.04,
        head = const Offset(0.52, 0.45),
        chest = const Offset(0.44, 0.55),
        hip = const Offset(0.31, 0.63),
        limbs = const [
          _Limb(Offset(0.44, 0.55), Offset(0.58, 0.62), Offset(0.67, 0.68)),
          _Limb(Offset(0.43, 0.56), Offset(0.55, 0.70), Offset(0.64, 0.75)),
          _Limb(Offset(0.31, 0.63), Offset(0.20, 0.75), Offset(0.10, 0.80),
              singlet: true),
          _Limb(Offset(0.32, 0.64), Offset(0.44, 0.76), Offset(0.56, 0.79),
              singlet: true),
        ];

  const _Pose.hinge()
      : shift = 0,
        head = const Offset(0.52, 0.40),
        chest = const Offset(0.46, 0.50),
        hip = const Offset(0.38, 0.62),
        limbs = const [
          _Limb(Offset(0.45, 0.51), Offset(0.45, 0.64), Offset(0.45, 0.76)),
          _Limb(Offset(0.48, 0.51), Offset(0.58, 0.64), Offset(0.59, 0.76)),
          _Limb(Offset(0.38, 0.62), Offset(0.34, 0.76), Offset(0.28, 0.82),
              singlet: true),
          _Limb(Offset(0.39, 0.62), Offset(0.52, 0.76), Offset(0.64, 0.82),
              singlet: true),
        ];

  const _Pose.row()
      : shift = 0,
        head = const Offset(0.46, 0.40),
        chest = const Offset(0.43, 0.50),
        hip = const Offset(0.36, 0.62),
        limbs = const [
          _Limb(Offset(0.43, 0.51), Offset(0.52, 0.56), Offset(0.62, 0.57)),
          _Limb(Offset(0.42, 0.51), Offset(0.50, 0.64), Offset(0.60, 0.68)),
          _Limb(Offset(0.36, 0.62), Offset(0.30, 0.76), Offset(0.21, 0.80),
              singlet: true),
          _Limb(Offset(0.37, 0.62), Offset(0.50, 0.74), Offset(0.62, 0.79),
              singlet: true),
        ];

  const _Pose.carry()
      : shift = 0,
        head = const Offset(0.48, 0.30),
        chest = const Offset(0.48, 0.43),
        hip = const Offset(0.48, 0.58),
        limbs = const [
          _Limb(Offset(0.47, 0.44), Offset(0.38, 0.58), Offset(0.37, 0.72)),
          _Limb(Offset(0.49, 0.44), Offset(0.59, 0.58), Offset(0.60, 0.72)),
          _Limb(Offset(0.48, 0.58), Offset(0.38, 0.74), Offset(0.30, 0.80),
              singlet: true),
          _Limb(Offset(0.48, 0.58), Offset(0.60, 0.74), Offset(0.70, 0.80),
              singlet: true),
        ];

  const _Pose.baseBottom()
      : shift = -0.04,
        head = const Offset(0.54, 0.47),
        chest = const Offset(0.45, 0.56),
        hip = const Offset(0.34, 0.66),
        limbs = const [
          _Limb(Offset(0.45, 0.56), Offset(0.56, 0.67), Offset(0.66, 0.74)),
          _Limb(Offset(0.43, 0.57), Offset(0.40, 0.70), Offset(0.37, 0.80)),
          _Limb(Offset(0.34, 0.66), Offset(0.24, 0.76), Offset(0.16, 0.82),
              singlet: true),
          _Limb(Offset(0.34, 0.66), Offset(0.45, 0.78), Offset(0.55, 0.82),
              singlet: true),
        ];

  const _Pose.topControl()
      : shift = 0.10,
        head = const Offset(0.40, 0.38),
        chest = const Offset(0.38, 0.50),
        hip = const Offset(0.35, 0.62),
        limbs = const [
          _Limb(Offset(0.38, 0.50), Offset(0.48, 0.58), Offset(0.58, 0.64)),
          _Limb(Offset(0.37, 0.51), Offset(0.45, 0.62), Offset(0.55, 0.69)),
          _Limb(Offset(0.35, 0.62), Offset(0.25, 0.74), Offset(0.16, 0.79),
              singlet: true),
          _Limb(Offset(0.35, 0.62), Offset(0.45, 0.76), Offset(0.55, 0.80),
              singlet: true),
        ];

  const _Pose.standUp()
      : shift = -0.02,
        head = const Offset(0.49, 0.32),
        chest = const Offset(0.46, 0.44),
        hip = const Offset(0.43, 0.59),
        limbs = const [
          _Limb(Offset(0.45, 0.45), Offset(0.34, 0.56), Offset(0.28, 0.64)),
          _Limb(Offset(0.47, 0.45), Offset(0.58, 0.54), Offset(0.66, 0.62)),
          _Limb(Offset(0.43, 0.59), Offset(0.34, 0.73), Offset(0.24, 0.79),
              singlet: true),
          _Limb(Offset(0.43, 0.59), Offset(0.56, 0.72), Offset(0.68, 0.78),
              singlet: true),
        ];

  const _Pose.topBehind()
      : shift = 0.10,
        head = const Offset(0.43, 0.36),
        chest = const Offset(0.42, 0.49),
        hip = const Offset(0.42, 0.63),
        limbs = const [
          _Limb(Offset(0.42, 0.49), Offset(0.35, 0.58), Offset(0.30, 0.68)),
          _Limb(Offset(0.43, 0.49), Offset(0.54, 0.57), Offset(0.63, 0.64)),
          _Limb(Offset(0.42, 0.63), Offset(0.34, 0.76), Offset(0.25, 0.82),
              singlet: true),
          _Limb(Offset(0.42, 0.63), Offset(0.55, 0.76), Offset(0.66, 0.82),
              singlet: true),
        ];

  const _Pose.hipStretch()
      : shift = 0,
        head = const Offset(0.48, 0.36),
        chest = const Offset(0.48, 0.49),
        hip = const Offset(0.48, 0.66),
        limbs = const [
          _Limb(Offset(0.47, 0.50), Offset(0.36, 0.62), Offset(0.28, 0.70)),
          _Limb(Offset(0.49, 0.50), Offset(0.60, 0.62), Offset(0.68, 0.70)),
          _Limb(Offset(0.48, 0.66), Offset(0.34, 0.74), Offset(0.20, 0.72),
              singlet: true),
          _Limb(Offset(0.48, 0.66), Offset(0.62, 0.74), Offset(0.76, 0.72),
              singlet: true),
        ];

  const _Pose.shinBox()
      : shift = 0,
        head = const Offset(0.48, 0.36),
        chest = const Offset(0.48, 0.50),
        hip = const Offset(0.48, 0.66),
        limbs = const [
          _Limb(Offset(0.47, 0.50), Offset(0.36, 0.64), Offset(0.30, 0.76)),
          _Limb(Offset(0.49, 0.50), Offset(0.60, 0.64), Offset(0.66, 0.76)),
          _Limb(Offset(0.48, 0.66), Offset(0.36, 0.78), Offset(0.25, 0.72),
              singlet: true),
          _Limb(Offset(0.48, 0.66), Offset(0.60, 0.78), Offset(0.72, 0.72),
              singlet: true),
        ];

  const _Pose.threadNeedle()
      : shift = 0,
        head = const Offset(0.54, 0.55),
        chest = const Offset(0.46, 0.58),
        hip = const Offset(0.36, 0.66),
        limbs = const [
          _Limb(Offset(0.46, 0.58), Offset(0.62, 0.66), Offset(0.74, 0.72)),
          _Limb(Offset(0.44, 0.58), Offset(0.35, 0.72), Offset(0.30, 0.82)),
          _Limb(Offset(0.36, 0.66), Offset(0.28, 0.78), Offset(0.20, 0.82),
              singlet: true),
          _Limb(Offset(0.36, 0.66), Offset(0.48, 0.78), Offset(0.58, 0.82),
              singlet: true),
        ];

  final Offset head;
  final Offset chest;
  final Offset hip;
  final List<_Limb> limbs;
  final double shift;
}

class _Limb {
  const _Limb(this.a, this.b, this.c, {this.singlet = false});

  final Offset a;
  final Offset b;
  final Offset c;
  final bool singlet;
}

class _SafetyPanel extends StatelessWidget {
  const _SafetyPanel({required this.workout});

  final _WorkoutPlan workout;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.health_and_safety_rounded,
                  color: AppColors.success),
              const SizedBox(width: AppSpacing.sm),
              Text('Parent safety notes', style: AppTextStyles.cardTitle),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final note in workout.safetyNotes)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('- ', style: AppTextStyles.body),
                  Expanded(child: Text(note, style: AppTextStyles.body)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ReflectionPanel extends StatelessWidget {
  const _ReflectionPanel({
    required this.selected,
    required this.onChanged,
  });

  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('After-workout check-in', style: AppTextStyles.cardTitle),
          const SizedBox(height: AppSpacing.xs),
          Text('How did it feel today?', style: AppTextStyles.body),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final option in const [
                ('easy', 'Easy'),
                ('good', 'Good'),
                ('hard', 'Hard'),
              ])
                ChoiceChip(
                  label: Text(option.$2),
                  selected: selected == option.$1,
                  onSelected: (_) => onChanged(option.$1),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Write down one thing that improved and one thing to repeat next time.',
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }
}

class _WorkoutBlockRow extends StatelessWidget {
  const _WorkoutBlockRow({required this.block, required this.color});

  final _WorkoutBlock block;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(block.time, style: AppTextStyles.caption),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(block.title, style: AppTextStyles.bodyStrong),
                const SizedBox(height: AppSpacing.xxs),
                Text(block.detail, style: AppTextStyles.body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return _MetaPill(label: label);
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(label: Text(label));
  }
}

class _EmptyWorkoutPanel extends StatelessWidget {
  const _EmptyWorkoutPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: const Text('No workouts match this filter.'),
    );
  }
}

class _WorkoutPlan {
  const _WorkoutPlan({
    required this.title,
    required this.category,
    required this.description,
    required this.minutes,
    required this.level,
    required this.equipment,
    required this.ageLabel,
    required this.imageAsset,
    required this.imageAspectRatio,
    required this.howToTitle,
    required this.howToTips,
    required this.icon,
    required this.color,
    required this.blocks,
    required this.cues,
    required this.safetyNotes,
    this.timerTitle,
    this.timerSubtitle,
    this.timerStartCue,
    this.timerButtonLabel,
    this.timerCues,
    this.allowTimerCueSelection = false,
    this.timerDurationOptions = const [1, 2, 3],
    this.timerInitialMinutes = 1,
    this.timerIntervalOptions,
    this.timerInitialIntervalSeconds,
    this.timerIntervalLabel = 'Time between callouts',
    this.timerCueListLabel = 'Callouts',
  });

  final String title;
  final String category;
  final String description;
  final int minutes;
  final String level;
  final String equipment;
  final String ageLabel;
  final String imageAsset;
  final double imageAspectRatio;
  final String howToTitle;
  final List<String> howToTips;
  final IconData icon;
  final Color color;
  final List<_WorkoutBlock> blocks;
  final List<String> cues;
  final List<String> safetyNotes;
  final String? timerTitle;
  final String? timerSubtitle;
  final String? timerStartCue;
  final String? timerButtonLabel;
  final List<String>? timerCues;
  final bool allowTimerCueSelection;
  final List<int> timerDurationOptions;
  final int timerInitialMinutes;
  final List<int>? timerIntervalOptions;
  final int? timerInitialIntervalSeconds;
  final String timerIntervalLabel;
  final String timerCueListLabel;
}

class _WorkoutBlock {
  const _WorkoutBlock({
    required this.time,
    required this.title,
    required this.detail,
  });

  final String time;
  final String title;
  final String detail;
}

const _workouts = [
  _WorkoutPlan(
    title: 'Stance + motion',
    category: 'stance',
    description:
        'Short reaction round for footwork, level change, and defense.',
    minutes: 8,
    level: 'All levels',
    equipment: 'No equipment',
    ageLabel: 'Middle school+',
    imageAsset: 'assets/images/workouts/howto_stance.png',
    imageAspectRatio: 1.02,
    howToTitle: 'How it should look',
    howToTips: [
      'Keep knees bent, hips back, and chest over the knees.',
      'Hands stay ready in front of the body.',
      'After every callout, reset back to this stance.',
    ],
    icon: Icons.directions_run_rounded,
    color: Color(0xFF22C55E),
    blocks: [
      _WorkoutBlock(
          time: '2m',
          title: 'Motion warmup',
          detail: 'Circle, fake, level change, and recover stance.'),
      _WorkoutBlock(
          time: '3m',
          title: 'Callout round',
          detail:
              'React to shot, sprawl, down block, and sweep-circle-snap cues.'),
      _WorkoutBlock(
          time: '3m',
          title: 'Finish clean',
          detail: 'Shadow attack, finish through, reset stance.'),
    ],
    cues: [
      'Hands low enough to touch, eyes up.',
      'Move feet before reaching.',
      'Recover stance after every action.',
    ],
    safetyNotes: [
      'Needs open floor space.',
      'Stop if knees, back, or shoulders hurt.',
      'Parent can watch posture and effort.',
    ],
    timerTitle: 'Stance + motion',
    timerSubtitle: 'Pick a round length and react to neutral callouts.',
    timerStartCue: 'Stance and motion',
    timerButtonLabel: 'Run stance timer',
    timerCues: ['Shot', 'Sprawl', 'Down block', 'Sweep, circle, snap'],
  ),
  _WorkoutPlan(
    title: 'Partner takedown phases',
    category: 'partner',
    description:
        'Coach-selected partner drill for setup reps, setup-to-finish reps, and clean takedown timing.',
    minutes: 12,
    level: 'Intermediate',
    equipment: 'Partner',
    ageLabel: 'Middle school+',
    imageAsset: 'assets/images/workouts/howto_shot_entry.png',
    imageAspectRatio: 1.02,
    howToTitle: 'How the partner drill should look',
    howToTips: [
      'Phase 1 is only setup position, motion, and contact.',
      'Phase 2 adds setup, takedown, finish, and controlled release.',
      'Coach selects the takedowns and interval before starting.',
    ],
    icon: Icons.groups_rounded,
    color: Color(0xFF2563EB),
    blocks: [
      _WorkoutBlock(
          time: 'Phase 1',
          title: 'Setup',
          detail:
              'Partner gives a realistic stance and reaction while the attacker wins the setup.'),
      _WorkoutBlock(
          time: 'Phase 2',
          title: 'Setup and takedown',
          detail:
              'Use the same setup, finish the selected takedown, then release and reset.'),
      _WorkoutBlock(
          time: 'Coach',
          title: 'Select attacks',
          detail:
              'Choose the takedowns to work, total drill time, and seconds between takedown calls.'),
    ],
    cues: [
      'Good setup before every finish.',
      'Partner gives realistic but controlled resistance.',
      'Reset fast so the next callout starts clean.',
    ],
    safetyNotes: [
      'Finish takedowns with control and space.',
      'No hard mat returns in this drill.',
      'Slow down if either partner loses position.',
    ],
    timerTitle: 'Partner takedown phases',
    timerSubtitle:
        'Select takedowns, drill length, and time between takedown calls.',
    timerStartCue: 'Phase one setup. Phase two setup and takedown.',
    timerButtonLabel: 'Configure partner drill',
    timerCues: [
      'Double',
      'Sweep',
      'High crotch',
      'Throwby',
      'Duck under',
      'Arm drag',
      'Fireman\'s',
      'Underhook knee block',
      'Ankle pick',
      'Cross ankle pick',
    ],
    allowTimerCueSelection: true,
    timerDurationOptions: [2, 3, 5, 10],
    timerInitialMinutes: 3,
    timerIntervalOptions: [10, 15, 20, 30],
    timerInitialIntervalSeconds: 15,
    timerIntervalLabel: 'Time between takedowns',
    timerCueListLabel: 'Takedowns to work',
  ),
  _WorkoutPlan(
    title: 'Referee down position',
    category: 'match',
    description:
        'Bottom-position reaction drill for first moves, hip movement, and quick recoveries.',
    minutes: 10,
    level: 'All levels',
    equipment: 'No equipment',
    ageLabel: 'Middle school+',
    imageAsset: 'assets/images/workouts/howto_bottom_escape.png',
    imageAspectRatio: 1.06,
    howToTitle: 'How the bottom start should look',
    howToTips: [
      'Start with weight balanced and hands ready.',
      'Move on the callout before the position gets heavy.',
      'Return to referee down position after every rep.',
    ],
    icon: Icons.sports_martial_arts_rounded,
    color: Color(0xFFEC4899),
    blocks: [
      _WorkoutBlock(
          time: '2m',
          title: 'Position setup',
          detail: 'Set hands, knees, head, and hips in referee down position.'),
      _WorkoutBlock(
          time: '6m',
          title: 'Bottom callout round',
          detail:
              'React to Granby, standup, switch, knee slide, sitout, and quad pod knee slide.'),
      _WorkoutBlock(
          time: '2m',
          title: 'Clean reset',
          detail: 'Finish the motion, clear the hips, then reset position.'),
    ],
    cues: [
      'First movement should be immediate.',
      'Keep hips active instead of reaching back.',
      'Reset cleanly after every callout.',
    ],
    safetyNotes: [
      'Use a soft surface when rolling or sliding.',
      'Keep neck pressure light during Granby reps.',
      'Slow the drill down if technique gets loose.',
    ],
    timerTitle: 'Referee down position',
    timerSubtitle: 'Pick a round length and react to bottom-position callouts.',
    timerStartCue: 'Referee down position',
    timerButtonLabel: 'Run bottom timer',
    timerCues: [
      'Granby',
      'Standup',
      'Switch',
      'Knee slide',
      'Sitout',
      'Quad pod knee slide',
    ],
    timerIntervalOptions: [10, 15, 20, 25, 30],
    timerInitialIntervalSeconds: 15,
    timerIntervalLabel: 'Seconds between bottom calls',
  ),
  _WorkoutPlan(
    title: 'Recovery mobility',
    category: 'mobility',
    description: 'Low-load reset for hips, shoulders, ankles, and spine.',
    minutes: 12,
    level: 'Recovery',
    equipment: 'No equipment',
    ageLabel: 'All ages',
    imageAsset: 'assets/images/workouts/howto_mobility.png',
    imageAspectRatio: 1.06,
    howToTitle: 'How recovery should look',
    howToTips: [
      'Move slowly and breathe through the stretch.',
      'Stay in a pain-free range.',
      'Finish feeling looser, not tired.',
    ],
    icon: Icons.self_improvement_rounded,
    color: Color(0xFF14B8A6),
    blocks: [
      _WorkoutBlock(
          time: '3m',
          title: 'Breathing reset',
          detail: 'Nose inhale, slow exhale, ribs down.'),
      _WorkoutBlock(
          time: '5m',
          title: 'Hip and ankle flow',
          detail: '90/90, shin box, calf rocks.'),
      _WorkoutBlock(
          time: '4m',
          title: 'Shoulder spine flow',
          detail: 'Thread needle, wall slides, prone swimmers.'),
    ],
    cues: [
      'Move slow enough to own the position.',
      'No pain chasing.',
      'Finish feeling better than you started.',
    ],
    safetyNotes: [
      'Keep every stretch pain-free.',
      'Move slowly and breathe normally.',
      'Good option for parents to do with athletes.',
    ],
    timerTitle: 'Recovery mobility',
    timerSubtitle:
        'Pick a recovery round length and move slowly through mobility cues.',
    timerStartCue: 'Recovery mobility',
    timerButtonLabel: 'Run recovery timer',
    timerCues: [
      'Breathing reset',
      'Hip and ankle flow',
      'Shoulder spine flow',
      'Easy reset',
    ],
    timerDurationOptions: [5, 10, 12],
    timerInitialMinutes: 10,
    timerIntervalOptions: [30, 45, 60],
    timerInitialIntervalSeconds: 45,
    timerIntervalLabel: 'Seconds between mobility cues',
  ),
];
