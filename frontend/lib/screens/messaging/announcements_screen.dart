import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../models/messaging_models.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/empty_state_card.dart';
import '../../widgets/section_header.dart';
import '../../widgets/subpage_header.dart';

class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<AppState>().refreshAnnouncements();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final announcements = appState.announcements;
    final readiness = appState.textAlertReadiness;
    final width = MediaQuery.of(context).size.width;
    final content = ListView(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, AppSpacing.xl),
      children: [
        SubpageHeader(
          title: 'Announcements',
          subtitle: 'Post one clear update for the team, then let conversations happen separately in chat.',
          trailing: appState.canCreateAnnouncements
              ? ElevatedButton.icon(
                  onPressed: appState.isBusy ? null : () => _openComposer(context),
                  icon: const Icon(Icons.campaign_rounded),
                  label: const Text('New announcement'),
                )
              : null,
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            _AnnouncementMetricCard(
              label: 'Posts',
              value: '${announcements.length}',
              note: 'team-wide updates',
            ),
            const _AnnouncementMetricCard(
              label: 'Audience',
              value: 'Team',
              note: 'default delivery',
            ),
            _AnnouncementMetricCard(
              label: 'Latest',
              value: announcements.isEmpty ? '--' : _formatShort(announcements.first.createdAt),
              note: 'last publish',
            ),
            if (appState.canSendTeamTextAlerts && readiness != null)
              _AnnouncementMetricCard(
                label: 'Text Ready',
                value:
                    '${readiness.summary.validPhoneRecipientCount}/${readiness.summary.eligibleRecipientCount}',
                note: 'recipients with valid phones',
              ),
            if (appState.canSendTeamTextAlerts && readiness != null)
              _AnnouncementMetricCard(
                label: 'Missing Phones',
                value: '${readiness.summary.missingPhoneRecipientCount}',
                note: 'need profile updates',
                accentColor: readiness.summary.missingPhoneRecipientCount == 0
                    ? AppColors.success
                    : AppColors.warning,
              ),
          ],
        ),
        if (appState.canSendTeamTextAlerts && readiness != null) ...[
          const SizedBox(height: AppSpacing.lg),
          _TextAlertReadinessCard(readiness: readiness),
        ],
        const SizedBox(height: AppSpacing.xl),
        const SectionHeader(title: 'Recent posts'),
        const SizedBox(height: AppSpacing.md),
        if (announcements.isEmpty)
          const EmptyStateCard(
            title: 'No announcements yet',
            message: 'Coaches can post team-wide updates here when the group needs one clear message.',
            icon: Icons.campaign_outlined,
          )
        else
          ...announcements.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: SizedBox(
                width: width >= 980 ? (width / 2) : double.infinity,
                child: _AnnouncementTile(item: item),
              ),
            ),
          ),
      ],
    );

    if (Navigator.of(context).canPop()) {
      return Scaffold(
        body: AppShell(child: content),
      );
    }

    return content;
  }

  Future<void> _openComposer(BuildContext context) async {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();
    final audienceController = TextEditingController(text: 'team');
    bool sendTextAlert = false;
    String? error;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            final appState = dialogContext.watch<AppState>();
            return AlertDialog(
              title: const Text('Send Announcement'),
              content: SizedBox(
                width: 560,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Title'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: audienceController,
                      decoration: const InputDecoration(labelText: 'Audience Label'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: bodyController,
                      maxLines: 6,
                      decoration: const InputDecoration(labelText: 'Message'),
                    ),
                    const SizedBox(height: 12),
                    if (appState.canSendTeamTextAlerts)
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        value: sendTextAlert,
                        onChanged: appState.isBusy
                            ? null
                            : (value) => setState(() => sendTextAlert = value),
                        title: const Text('Send team text alert'),
                        subtitle: const Text(
                          'Delivers to the whole approved team plus linked parents. Individual targeting is disabled.',
                        ),
                      ),
                    if (appState.canSendTeamTextAlerts) const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text(
                        'Compliance: any athlete recipient requires linked parent visibility. Team text alerts are limited to coaches and administrators, and the backend automatically expands them to the full team plus linked parents.',
                      ),
                    ),
                    if (error != null) ...[
                      const SizedBox(height: 12),
                      Text(error!, style: const TextStyle(color: Colors.redAccent)),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: appState.isBusy ? null : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: appState.isBusy
                      ? null
                      : () async {
                          try {
                            await dialogContext.read<AppState>().sendAnnouncement(
                                  title: titleController.text.trim(),
                                  body: bodyController.text.trim(),
                                  audienceLabel: audienceController.text.trim().isEmpty
                                      ? 'team'
                                      : audienceController.text.trim(),
                                  sendTextAlert: sendTextAlert,
                                );
                            if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                          } catch (e) {
                            setState(() => error = e.toString().replaceFirst('Exception: ', ''));
                          }
                        },
                  child: Text(appState.isBusy ? 'Sending...' : 'Send'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _AnnouncementTile extends StatelessWidget {
  const _AnnouncementTile({required this.item});

  final AnnouncementModel item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.62),
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.campaign_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title, style: AppTextStyles.cardTitle),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: [
                        _AnnouncementTag(
                          label: 'Announcement',
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        _AnnouncementTag(
                          label: item.audienceLabel,
                          color: const Color(0xFF38BDF8),
                        ),
                        if (item.visibilityFlags?['team_text_alert'] == true)
                          const _AnnouncementTag(
                            label: 'Text alert',
                            color: AppColors.warning,
                          ),
                        if ((item.visibilityFlags?['auto_included_parent_links'] as List?)?.isNotEmpty ?? false)
                          const _AnnouncementTag(label: 'Parent-visible', color: AppColors.success),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(item.body, style: AppTextStyles.body.copyWith(color: AppColors.textPrimary)),
          if (item.isTeamTextAlert) ...[
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                _AnnouncementTag(
                  label: 'SMS ${item.smsSentCount}',
                  color: AppColors.success,
                ),
                if (item.emailSentCount > 0)
                  _AnnouncementTag(
                    label: 'Email fallback ${item.emailSentCount}',
                    color: const Color(0xFF38BDF8),
                  ),
                if (item.pushSentCount > 0)
                  _AnnouncementTag(
                    label: 'Push fallback ${item.pushSentCount}',
                    color: AppColors.success,
                  ),
                if (item.smsFailedCount > 0)
                  _AnnouncementTag(
                    label: 'SMS misses ${item.smsFailedCount}',
                    color: AppColors.warning,
                  ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Text(
            '${item.sender.fullName} • ${_format(item.createdAt)}',
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }

  String _format(DateTime value) {
    final hours = value.hour == 0 ? 12 : (value.hour > 12 ? value.hour - 12 : value.hour);
    final suffix = value.hour >= 12 ? 'PM' : 'AM';
    final minutes = value.minute.toString().padLeft(2, '0');
    return '${value.month}/${value.day}/${value.year} $hours:$minutes $suffix';
  }
}

class _TextAlertReadinessCard extends StatelessWidget {
  const _TextAlertReadinessCard({required this.readiness});

  final TeamTextAlertReadinessModel readiness;

  @override
  Widget build(BuildContext context) {
    final missingMembers = readiness.members.where((member) => !member.hasValidPhone).toList();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Text alert readiness', style: AppTextStyles.sectionTitle),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Whole-team alerts go to approved team members plus linked parents. Keep phone numbers current here before game-day updates matter.',
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          ),
          if (missingMembers.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: missingMembers
                  .take(8)
                  .map(
                    (member) => _AnnouncementTag(
                      label: member.autoIncludedReason == null
                          ? member.fullName
                          : '${member.fullName} • parent-visible',
                      color: AppColors.warning,
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _AnnouncementMetricCard extends StatelessWidget {
  const _AnnouncementMetricCard({
    required this.label,
    required this.value,
    required this.note,
    this.accentColor,
  });

  final String label;
  final String value;
  final String note;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.56),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.caption),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: AppTextStyles.cardTitle.copyWith(
              color: accentColor ?? AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(note, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

class _AnnouncementTag extends StatelessWidget {
  const _AnnouncementTag({
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

String _formatShort(DateTime value) {
  final hours = value.hour == 0 ? 12 : (value.hour > 12 ? value.hour - 12 : value.hour);
  final suffix = value.hour >= 12 ? 'PM' : 'AM';
  return '${value.month}/${value.day} $hours$suffix';
}
