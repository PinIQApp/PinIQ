import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/section_header.dart';
import '../../widgets/subpage_header.dart';

class OperationsCenterScreen extends StatelessWidget {
  const OperationsCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, AppSpacing.xl),
          children: const [
          SubpageHeader(
            title: 'Operations Center',
            subtitle: 'The full product map: what is live now, what is in foundation, and what is planned next.',
          ),
          SizedBox(height: AppSpacing.lg),
          _FeatureGroup(
            title: 'Core system',
            status: 'Foundation',
            items: [
              'User auth for coach, athlete, and parent roles',
              'Team creation and join code system',
              'Role-based permissions and admin controls',
              'Multi-team support',
              'Dark theme by default',
              'School branding with colors, logo, and mascot',
            ],
          ),
          SizedBox(height: AppSpacing.xl),
          _FeatureGroup(
            title: 'Team management',
            status: 'Live',
            items: [
              'Roster management for athletes, staff, and parents',
              'Approval flow from pending to approved',
              'Parent linking to athlete',
              'Staff roles for assistants and admins',
              'Search and filters for athletes, staff, and pending',
              'Athlete profile expansion',
            ],
          ),
          SizedBox(height: AppSpacing.xl),
          _FeatureGroup(
            title: 'Communication',
            status: 'Live',
            items: [
              'Announcements as one-way broadcast',
              'Messaging threads and group chats',
              'Unread indicators',
              'Parent-visible versus internal threads',
              'Push notifications pipeline',
            ],
          ),
          SizedBox(height: AppSpacing.xl),
          _FeatureGroup(
            title: 'Weight management',
            status: 'Live',
            items: [
              'Athlete weight entry system',
              'Weekly change tracking',
              'Unsafe weight drop alerts',
              'Missing weigh-in alerts',
              'Weight class planning dashboard',
              'Coach approval and override flow',
            ],
          ),
          SizedBox(height: AppSpacing.xl),
          _FeatureGroup(
            title: 'Events, tournaments, and recruiting',
            status: 'Live',
            items: [
              'Tournament discovery and saved events',
              'TrackWrestling, FloWrestling, and USA Bracketing scan jobs',
              'Daily tournament scan and coach alerts',
              'Bracket tournament builder and dual-meet manager',
              'Event creation, RSVP, reminders, and attendance',
              'Recruiting profiles and college interest tracking',
            ],
          ),
          SizedBox(height: AppSpacing.xl),
          _FeatureGroup(
            title: 'Nutrition and training',
            status: 'Live',
            items: [
              'AI meal planning for wrestlers',
              'Weight-safe diet guidance',
              'Nutrition center with review queue and body-fat workflow',
              'Training suggestions by phase and alert level',
            ],
          ),
          SizedBox(height: AppSpacing.xl),
          _FeatureGroup(
            title: 'Store, merch, and inventory',
            status: 'Planned',
            items: [
              'Built-in team store',
              'Coach-controlled products and parent purchasing access',
              'Print-on-demand integration',
              'Revenue dashboard and order tracking',
              'Merch, equipment, and medical supply inventory',
              'Auto-restock alerts and supplier integration',
            ],
          ),
          SizedBox(height: AppSpacing.xl),
          _FeatureGroup(
            title: 'Creative tools',
            status: 'Planned',
            items: [
              'Custom singlet, warmup, and shirt designer',
              'Tournament and fundraiser flyer builder',
              'Template system with drag-and-drop editing',
              'Export to PDF, story, square, and social share formats',
            ],
          ),
          SizedBox(height: AppSpacing.xl),
          _FeatureGroup(
            title: 'Notifications and admin tools',
            status: 'Planned',
            items: [
              'Push notifications for weights, messages, approvals, events, and tournaments',
              'Manual refresh and scanner controls',
              'Debug logs and admin-only diagnostics',
              'Premium unlocks, subscriptions, and promotion fees',
            ],
          ),
          ],
    );
  }
}

class _FeatureGroup extends StatelessWidget {
  const _FeatureGroup({
    required this.title,
    required this.status,
    required this.items,
  });

  final String title;
  final String status;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: title),
        const SizedBox(height: AppSpacing.md),
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.78),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StatusChip(status: status),
              const SizedBox(height: AppSpacing.md),
              for (final item in items) ...[
                _FeatureRow(label: item),
                if (item != items.last) const SizedBox(height: AppSpacing.sm),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.only(top: 6),
          decoration: const BoxDecoration(
            color: AppColors.textSecondary,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(label, style: AppTextStyles.body.copyWith(color: AppColors.textPrimary)),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'Live' => AppColors.success,
      'Foundation' => Theme.of(context).colorScheme.primary,
      _ => AppColors.warning,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        status,
        style: AppTextStyles.caption.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
