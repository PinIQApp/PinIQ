import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../models/watch_models.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/section_header.dart';
import '../../widgets/subpage_header.dart';

class AppleWatchCenterScreen extends StatefulWidget {
  const AppleWatchCenterScreen({super.key});

  @override
  State<AppleWatchCenterScreen> createState() => _AppleWatchCenterScreenState();
}

class _AppleWatchCenterScreenState extends State<AppleWatchCenterScreen> {
  String _previewRole = 'coach';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final appState = context.read<AppState>();
    if (appState.isAthlete) {
      _previewRole = 'athlete';
    } else if (appState.isParent) {
      _previewRole = 'parent';
    } else {
      _previewRole = 'coach';
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final profiles = appState.watchProfiles;
    final profile = profiles[_previewRole] ?? appState.activeWatchProfile;
    final isWide = MediaQuery.of(context).size.width >= 1120;

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        const SubpageHeader(
          title: 'Apple Watch Companion',
          subtitle:
              'Plan a wrist-first Pin IQ companion for messages, tournament timing, health, and reminders.',
        ),
        const SizedBox(height: AppSpacing.lg),
        _WatchHeroCard(
          profile: profile,
          selectedRole: _previewRole,
          onRoleChanged: (value) => setState(() => _previewRole = value),
        ),
        const SizedBox(height: AppSpacing.xl),
        const SectionHeader(title: 'Watch MVP'),
        const SizedBox(height: AppSpacing.md),
        GridView.count(
          crossAxisCount: isWide ? 4 : 2,
          crossAxisSpacing: AppSpacing.md,
          mainAxisSpacing: AppSpacing.md,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: isWide ? 1.18 : 1.06,
          children: profile.metrics
              .map((metric) => _WatchMetricCard(metric: metric))
              .toList(),
        ),
        const SizedBox(height: AppSpacing.xl),
        if (isWide)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 5,
                child: _WatchStackPanel(profile: profile),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                flex: 4,
                child: _WatchReminderPanel(profile: profile),
              ),
            ],
          )
        else ...[
          _WatchStackPanel(profile: profile),
          const SizedBox(height: AppSpacing.lg),
          _WatchReminderPanel(profile: profile),
        ],
        const SizedBox(height: AppSpacing.xl),
        const SectionHeader(title: 'Hydration lane'),
        const SizedBox(height: AppSpacing.md),
        const _HydrationWatchPanel(),
        const SizedBox(height: AppSpacing.xl),
        const SectionHeader(title: 'Build path'),
        const SizedBox(height: AppSpacing.md),
        const _BuildPathPanel(),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}

class _WatchHeroCard extends StatelessWidget {
  const _WatchHeroCard({
    required this.profile,
    required this.selectedRole,
    required this.onRoleChanged,
  });

  final WatchCompanionProfile profile;
  final String selectedRole;
  final ValueChanged<String> onRoleChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: AppColors.brandedGradient(
          primary: const Color(0xFF2563EB),
          secondary: AppColors.surfaceElevated,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _WatchPill(label: 'Companion app'),
          const SizedBox(height: AppSpacing.md),
          Text(
            profile.heroTitle,
            style: AppTextStyles.cardTitle.copyWith(fontSize: 30),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            profile.heroSubtitle,
            style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final role in const [
                ('coach', 'Coach'),
                ('athlete', 'Athlete'),
                ('parent', 'Parent'),
              ])
                ChoiceChip(
                  label: Text(role.$2),
                  selected: selectedRole == role.$1,
                  onSelected: (_) => onRoleChanged(role.$1),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WatchMetricCard extends StatelessWidget {
  const _WatchMetricCard({required this.metric});

  final WatchFeatureCardModel metric;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _WatchPill(label: metric.lane),
          const SizedBox(height: AppSpacing.md),
          Text(metric.title, style: AppTextStyles.bodyStrong),
          const SizedBox(height: AppSpacing.xxs),
          Text(metric.subtitle, style: AppTextStyles.caption),
          const Spacer(),
          Text(metric.value,
              style: AppTextStyles.cardTitle.copyWith(fontSize: 24)),
          const SizedBox(height: AppSpacing.xxs),
          Text(metric.note,
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _WatchStackPanel extends StatelessWidget {
  const _WatchStackPanel({required this.profile});

  final WatchCompanionProfile profile;

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
          Text('Companion surfaces', style: AppTextStyles.cardTitle),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Keep the watch fast and glanceable. These are the surfaces worth building first.',
            style: AppTextStyles.body,
          ),
          const SizedBox(height: AppSpacing.lg),
          ...profile.quickActions.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.watch_rounded,
                          color: AppColors.textPrimary),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                        child: Text(item, style: AppTextStyles.bodyStrong)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const SectionHeader(title: 'Sync lanes'),
          const SizedBox(height: AppSpacing.md),
          ...profile.syncItems.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child:
                        Icon(Icons.circle, size: 8, color: Color(0xFF2563EB)),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                      child: Text(item,
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.textSecondary))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WatchReminderPanel extends StatelessWidget {
  const _WatchReminderPanel({required this.profile});

  final WatchCompanionProfile profile;

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
          Text('Reminder design', style: AppTextStyles.cardTitle),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'The best watch version of Pin IQ should feel like smart nudges, not tiny admin screens.',
            style: AppTextStyles.body,
          ),
          const SizedBox(height: AppSpacing.lg),
          ...profile.reminders.map(
            (reminder) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                            child: Text(reminder.title,
                                style: AppTextStyles.bodyStrong)),
                        _WatchPill(label: reminder.kind),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(reminder.timeLabel,
                        style: AppTextStyles.cardTitle.copyWith(fontSize: 20)),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(reminder.note,
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              'Watch rule: no heavy roster management, no long threads, no clutter. Only glance, act, and move.',
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _HydrationWatchPanel extends StatelessWidget {
  const _HydrationWatchPanel();

  @override
  Widget build(BuildContext context) {
    final items = const [
      (
        'Drink water reminders',
        'Push simple hydration nudges before practice, tournament blocks, and after hard sessions.'
      ),
      (
        'Coach-safe timing',
        'Hydration prompts should support health and readiness, never aggressive cutting behavior.'
      ),
      (
        'One-tap completion',
        'Let athletes, coaches, and parents clear the reminder from the wrist without opening the phone app.'
      ),
    ];

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
          Text('Hydration should be a first-class watch feature.',
              style: AppTextStyles.cardTitle),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Pin IQ can use the watch for the simplest high-value behavior in the whole app: drink water on time.',
            style: AppTextStyles.body,
          ),
          const SizedBox(height: AppSpacing.lg),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Icon(Icons.water_drop_rounded,
                        color: Color(0xFF38BDF8), size: 18),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.$1, style: AppTextStyles.bodyStrong),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(item.$2,
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BuildPathPanel extends StatelessWidget {
  const _BuildPathPanel();

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
          _BuildStep(
            title: 'Phase 1: Companion MVP',
            note:
                'Messages, tournament timing, heart rate, steps, hydration nudges, and check-in reminders.',
          ),
          SizedBox(height: AppSpacing.sm),
          _BuildStep(
            title: 'Phase 2: Health sync',
            note:
                'Apple Health read access for heart rate, steps, active minutes, and workout summaries.',
          ),
          SizedBox(height: AppSpacing.sm),
          _BuildStep(
            title: 'Phase 3: Native watchOS target',
            note:
                'Build the actual Apple Watch app in Xcode once the data contracts and wrist screens are locked.',
          ),
          SizedBox(height: AppSpacing.sm),
          _BuildStep(
            title: 'Phase 4: Coach polish',
            note:
                'Quick replies, bracket alerts, arrival confirmations, and travel status on the wrist.',
          ),
        ],
      ),
    );
  }
}

class _BuildStep extends StatelessWidget {
  const _BuildStep({
    required this.title,
    required this.note,
  });

  final String title;
  final String note;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.bodyStrong),
          const SizedBox(height: AppSpacing.xxs),
          Text(note,
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _WatchPill extends StatelessWidget {
  const _WatchPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2563EB).withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
      ),
      child: Text(label,
          style: AppTextStyles.caption.copyWith(color: AppColors.textPrimary)),
    );
  }
}
