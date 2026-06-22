import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_brand_mark.dart';
import '../../widgets/app_shell.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final role = appState.user?.role ?? 'coach';
    final steps = _stepsForRole(role);

    return Scaffold(
      body: AppShell(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 980),
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
              children: [
                Row(
                  children: [
                    const AppBrandMark(iconSize: 48, showWordmark: false),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pin IQ is ready',
                            style: AppTextStyles.pageTitle.copyWith(
                              fontSize: 32,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            _introForRole(role),
                            style: AppTextStyles.body,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxl),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth > 760 ? 3 : 1;
                    return GridView.count(
                      crossAxisCount: columns,
                      crossAxisSpacing: AppSpacing.md,
                      mainAxisSpacing: AppSpacing.md,
                      childAspectRatio: columns == 1 ? 2.9 : 1.16,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        for (final step in steps)
                          _OnboardingStepCard(step: step),
                      ],
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.xxl),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated.withValues(alpha: 0.96),
                    borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Wrap(
                    spacing: AppSpacing.md,
                    runSpacing: AppSpacing.md,
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      SizedBox(
                        width: 560,
                        child: Text(
                          'You can get back to these tools anytime from Home, Team, Chat, and Hub.',
                          style: AppTextStyles.body,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: appState.isBusy
                            ? null
                            : () =>
                                context.read<AppState>().completeOnboarding(),
                        icon: const Icon(Icons.arrow_forward_rounded),
                        label: const Text('Go to dashboard'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardingStepCard extends StatelessWidget {
  const _OnboardingStepCard({required this.step});

  final _OnboardingStep step;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: step.color.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(step.icon, color: step.color, size: 30),
          const SizedBox(height: AppSpacing.md),
          Text(step.title, style: AppTextStyles.cardTitle),
          const SizedBox(height: AppSpacing.sm),
          Text(step.body, style: AppTextStyles.body),
        ],
      ),
    );
  }
}

class _OnboardingStep {
  const _OnboardingStep({
    required this.icon,
    required this.title,
    required this.body,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String body;
  final Color color;
}

String _introForRole(String role) {
  return switch (role) {
    'athlete' =>
      'Start with your weight plan, messages, and workout tools so practice day stays simple.',
    'parent' =>
      'See the team updates, parent-visible messages, and athlete safety items that matter first.',
    'assistant_coach' =>
      'Jump into roster support, messaging, and practice tools without needing the head coach account.',
    'admin' =>
      'Use the dashboard to check program setup, messaging safety, store status, and operations.',
    _ =>
      'Start with the few actions that keep the wrestling room organized every day.',
  };
}

List<_OnboardingStep> _stepsForRole(String role) {
  return switch (role) {
    'athlete' => const [
        _OnboardingStep(
          icon: Icons.monitor_weight_outlined,
          title: 'Check weight plan',
          body: 'Open Hub for weight, nutrition, and stance-motion work.',
          color: AppColors.warning,
        ),
        _OnboardingStep(
          icon: Icons.forum_rounded,
          title: 'Read messages',
          body: 'Team updates and coach conversations stay in Chat.',
          color: Color(0xFF38BDF8),
        ),
        _OnboardingStep(
          icon: Icons.directions_run_rounded,
          title: 'Start workout',
          body: 'Run 1, 2, or 3 minute callout rounds from Hub.',
          color: AppColors.success,
        ),
      ],
    'parent' => const [
        _OnboardingStep(
          icon: Icons.campaign_rounded,
          title: 'Read updates',
          body: 'Announcements show schedule, travel, and program notes.',
          color: Color(0xFF60A5FA),
        ),
        _OnboardingStep(
          icon: Icons.visibility_rounded,
          title: 'Review safety',
          body: 'Parent-visible messages and weight items stay easy to find.',
          color: AppColors.warning,
        ),
        _OnboardingStep(
          icon: Icons.restaurant_menu_rounded,
          title: 'Support nutrition',
          body: 'Use meal plans and grocery notes to keep recovery realistic.',
          color: Color(0xFF14B8A6),
        ),
      ],
    _ => const [
        _OnboardingStep(
          icon: Icons.groups_2_rounded,
          title: 'Build roster',
          body: 'Approve athletes, parents, and staff from Team.',
          color: Color(0xFF60A5FA),
        ),
        _OnboardingStep(
          icon: Icons.campaign_rounded,
          title: 'Send update',
          body:
              'Use Chat for conversations and announcements for team-wide notes.',
          color: Color(0xFF38BDF8),
        ),
        _OnboardingStep(
          icon: Icons.grid_view_rounded,
          title: 'Open Hub',
          body:
              'Find AI Assistant, Recruiting, Nutrition, Store, and workouts there.',
          color: Color(0xFF8B5CF6),
        ),
      ],
  };
}
