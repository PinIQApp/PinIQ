import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../models/messaging_models.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import 'message_detail_screen.dart';

class SafetyAlertsScreen extends StatefulWidget {
  const SafetyAlertsScreen({super.key});

  @override
  State<SafetyAlertsScreen> createState() => _SafetyAlertsScreenState();
}

class _SafetyAlertsScreenState extends State<SafetyAlertsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AppState>().refreshSafetyAlerts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final alerts = appState.safetyAlerts;

    return Scaffold(
      appBar: AppBar(title: const Text('Safety Queue')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          Text(
            'Review flagged conversations, acknowledge adult follow-up, and move fast on urgent items.',
            style: AppTextStyles.body,
          ),
          const SizedBox(height: AppSpacing.lg),
          if (alerts.isEmpty)
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: const Text('No safety alerts right now.'),
            )
          else
            ...alerts.map(
              (alert) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: _SafetyAlertCard(alert: alert),
              ),
            ),
        ],
      ),
    );
  }
}

class _SafetyAlertCard extends StatelessWidget {
  const _SafetyAlertCard({required this.alert});

  final SafetyAlertModel alert;

  @override
  Widget build(BuildContext context) {
    final accent = switch (alert.severity) {
      'urgent' => AppColors.danger,
      'concern' => const Color(0xFFF59E0B),
      _ => const Color(0xFF38BDF8),
    };

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(alert.summary, style: AppTextStyles.cardTitle),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${alert.severity.toUpperCase()} • ${alert.status.toUpperCase()}',
                  style: AppTextStyles.caption,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Sender: ${alert.sourceSender.fullName} • Score ${alert.score} • Repeat count ${alert.repeatedTriggerCount}',
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: alert.categories
                .map(
                  (item) => Chip(label: Text(item.replaceAll('_', ' '))),
                )
                .toList(),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(alert.sourceExcerpt, style: AppTextStyles.body),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => MessageDetailScreen(threadId: alert.alertThreadId),
                    ),
                  );
                },
                icon: const Icon(Icons.visibility_outlined),
                label: const Text('Open alert'),
              ),
              const SizedBox(width: AppSpacing.sm),
              if (alert.isOpen)
                ElevatedButton.icon(
                  onPressed: () => context.read<AppState>().acknowledgeSafetyAlert(alert.id),
                  icon: const Icon(Icons.task_alt_outlined),
                  label: const Text('Acknowledge'),
                )
              else
                Text(
                  'Acknowledged by ${alert.acknowledgedBy?.fullName ?? 'staff'}',
                  style: AppTextStyles.caption,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
