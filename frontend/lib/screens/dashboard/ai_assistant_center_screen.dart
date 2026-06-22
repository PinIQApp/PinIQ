import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/section_header.dart';
import '../../widgets/subpage_header.dart';
import 'ai_replay_analysis_screen.dart';

class AiAssistantCenterScreen extends StatefulWidget {
  const AiAssistantCenterScreen({super.key});

  @override
  State<AiAssistantCenterScreen> createState() => _AiAssistantCenterScreenState();
}

class _AiAssistantCenterScreenState extends State<AiAssistantCenterScreen> {
  String _mode = 'drafting';

  @override
  Widget build(BuildContext context) {
    final title = switch (_mode) {
      'safety' => 'Safety review',
      'planning' => 'Planning prompts',
      _ => 'Message drafting',
    };

    final subtitle = switch (_mode) {
      'safety' => 'Elevate the right risk signals without bypassing coach judgment.',
      'planning' => 'Use athlete, event, and schedule context to draft next steps.',
      _ => 'Generate cleaner team communication from coach notes and event context.',
    };

    return LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 1120;

          return ListView(
            padding: EdgeInsets.zero,
            children: [
              const SubpageHeader(
                title: 'AI Assistant Center',
                subtitle:
                    'Use AI for safe drafting, planning, and recommendations tied to real team workflows.',
              ),
              const SizedBox(height: AppSpacing.lg),
              const _AiSummaryRow(),
              const SizedBox(height: AppSpacing.xl),
              const _ReplayLaunchCard(),
              const SizedBox(height: AppSpacing.xl),
              if (isWide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: _AiControlPanel(
                        mode: _mode,
                        onModeChanged: (value) => setState(() => _mode = value),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      flex: 4,
                      child: _AiWorkspacePanel(
                        title: title,
                        subtitle: subtitle,
                        mode: _mode,
                      ),
                    ),
                  ],
                )
              else ...[
                _AiControlPanel(
                  mode: _mode,
                  onModeChanged: (value) => setState(() => _mode = value),
                ),
                const SizedBox(height: AppSpacing.lg),
                _AiWorkspacePanel(
                  title: title,
                  subtitle: subtitle,
                  mode: _mode,
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              const SectionHeader(title: 'Guardrails'),
              const SizedBox(height: AppSpacing.md),
              const _AiGuardrailPanel(),
              const SizedBox(height: AppSpacing.xl),
            ],
          );
        },
    );
  }
}

class _AiSummaryRow extends StatelessWidget {
  const _AiSummaryRow();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      children: const [
        SizedBox(
          width: 240,
          child: _AiMetric(label: 'Drafts', value: '18', note: 'message assists', color: Color(0xFF6366F1)),
        ),
        SizedBox(
          width: 240,
          child: _AiMetric(label: 'Plans', value: '9', note: 'AI-aided suggestions', color: Color(0xFF38BDF8)),
        ),
        SizedBox(
          width: 240,
          child: _AiMetric(label: 'Alerts', value: '4', note: 'high-risk cases', color: Color(0xFFF59E0B)),
        ),
        SizedBox(
          width: 240,
          child: _AiMetric(label: 'Prompts', value: '11', note: 'coach workflows', color: Color(0xFF8B5CF6)),
        ),
      ],
    );
  }
}

class _AiControlPanel extends StatelessWidget {
  const _AiControlPanel({
    required this.mode,
    required this.onModeChanged,
  });

  final String mode;
  final ValueChanged<String> onModeChanged;

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
          Text('Prompt modes', style: AppTextStyles.cardTitle.copyWith(fontSize: 22)),
          const SizedBox(height: AppSpacing.md),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final chip in const [
                  ('drafting', 'Drafting'),
                  ('safety', 'Safety'),
                  ('planning', 'Planning'),
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.xs),
                    child: ChoiceChip(
                      label: Text(chip.$2),
                      selected: mode == chip.$1,
                      onSelected: (_) => onModeChanged(chip.$1),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.ondemand_video_rounded, color: AppColors.textPrimary),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Replay lane', style: AppTextStyles.bodyStrong),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        'Open AI Replay Analysis for match-film breakdown and athlete action points.',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
                OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).push<void>(
                      PageRouteBuilder<void>(
                        pageBuilder: (_, __, ___) => const AiReplayAnalysisScreen(),
                        transitionDuration: Duration.zero,
                        reverseTransitionDuration: Duration.zero,
                      ),
                    );
                  },
                  child: const Text('Open'),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const _PromptBlock(
            title: 'Connected inputs',
            items: [
              'Weight alerts and safety severity',
              'Schedule and event context',
              'Announcements and messaging history',
              'Nutrition and plan summaries',
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const _PromptBlock(
            title: 'Coach workflows',
            items: [
              'Draft team announcements',
              'Prepare event reminders',
              'Suggest safe next steps for flagged athletes',
              'Summarize parent-facing updates',
            ],
          ),
        ],
      ),
    );
  }
}

class _ReplayLaunchCard extends StatelessWidget {
  const _ReplayLaunchCard();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 860;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            gradient: AppColors.brandedGradient(
              primary: const Color(0xFF2563EB),
              secondary: AppColors.surfaceElevated,
            ),
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            border: Border.all(color: AppColors.border),
          ),
          child: stacked
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _AiTag(label: 'NEW'),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'AI Replay Analysis',
                      style: AppTextStyles.cardTitle.copyWith(fontSize: 28),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Upload match film, flag key sequences, and turn replay into coach notes, athlete corrections, and clean recaps.',
                      style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push<void>(
                          PageRouteBuilder<void>(
                            pageBuilder: (_, __, ___) => const AiReplayAnalysisScreen(),
                            transitionDuration: Duration.zero,
                            reverseTransitionDuration: Duration.zero,
                          ),
                        );
                      },
                      icon: const Icon(Icons.ondemand_video_rounded),
                      label: const Text('Open replay tool'),
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _AiTag(label: 'NEW'),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'AI Replay Analysis',
                            style: AppTextStyles.cardTitle.copyWith(fontSize: 28),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'Upload match film, flag key sequences, and turn replay into coach notes, athlete corrections, and clean recaps.',
                            style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push<void>(
                          PageRouteBuilder<void>(
                            pageBuilder: (_, __, ___) => const AiReplayAnalysisScreen(),
                            transitionDuration: Duration.zero,
                            reverseTransitionDuration: Duration.zero,
                          ),
                        );
                      },
                      icon: const Icon(Icons.ondemand_video_rounded),
                      label: const Text('Open replay tool'),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class _PromptBlock extends StatelessWidget {
  const _PromptBlock({
    required this.title,
    required this.items,
  });

  final String title;
  final List<String> items;

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
          const SizedBox(height: AppSpacing.sm),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Icon(Icons.circle, size: 8, color: Color(0xFF6366F1)),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text(item, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AiWorkspacePanel extends StatelessWidget {
  const _AiWorkspacePanel({
    required this.title,
    required this.subtitle,
    required this.mode,
  });

  final String title;
  final String subtitle;
  final String mode;

  @override
  Widget build(BuildContext context) {
    final accent = switch (mode) {
      'safety' => const Color(0xFFF59E0B),
      'planning' => const Color(0xFF38BDF8),
      _ => const Color(0xFF6366F1),
    };

    final promptText = switch (mode) {
      'safety' =>
          'Review Avery Hall weight alerts and suggest only coach-safe next steps with hydration, recovery, and approval cautions.',
      'planning' =>
          'Build a next-week action plan using practice schedule, event reminders, and nutrition reviews for the girls roster.',
      _ =>
          'Draft a cleaner announcement about Saturday travel, check-in time, and parent-visible reminders for the Bluegrass Spring Open.',
    };

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
              Text(title, style: AppTextStyles.cardTitle.copyWith(fontSize: 22)),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.auto_fix_high_rounded),
                label: const Text('Generate'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(subtitle, style: AppTextStyles.body),
          const SizedBox(height: AppSpacing.lg),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              gradient: AppColors.brandedGradient(primary: accent, secondary: AppColors.surfaceElevated),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _AiTag(label: mode.toUpperCase()),
                const SizedBox(height: AppSpacing.lg),
                Text('Prompt', style: AppTextStyles.bodyStrong),
                const SizedBox(height: AppSpacing.sm),
                Text(promptText, style: AppTextStyles.body.copyWith(color: AppColors.textPrimary)),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader(title: 'Suggested output'),
          const SizedBox(height: AppSpacing.md),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              'AI output should stay coach-safe, concise, and tied to real athlete, event, and alert context. Keep red-flag decisions with staff, not automation.',
              style: AppTextStyles.body,
            ),
          ),
        ],
      ),
    );
  }
}

class _AiGuardrailPanel extends StatelessWidget {
  const _AiGuardrailPanel();

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
          _GuardrailRow(
            title: 'Coach approval required',
            subtitle: 'AI can assist, but final safety decisions stay with staff.',
            value: 'Required',
          ),
          SizedBox(height: AppSpacing.sm),
          _GuardrailRow(
            title: 'No unsafe cut automation',
            subtitle: 'The assistant can flag risk, not authorize aggressive changes.',
            value: 'Protected',
          ),
          SizedBox(height: AppSpacing.sm),
          _GuardrailRow(
            title: 'Parent-facing summaries',
            subtitle: 'AI outputs must stay clean and role-appropriate before sharing.',
            value: 'Reviewed',
          ),
        ],
      ),
    );
  }
}

class _GuardrailRow extends StatelessWidget {
  const _GuardrailRow({
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
          _AiTag(label: value),
        ],
      ),
    );
  }
}

class _AiMetric extends StatelessWidget {
  const _AiMetric({
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

class _AiTag extends StatelessWidget {
  const _AiTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF6366F1).withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
      ),
      child: Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.textPrimary)),
    );
  }
}
