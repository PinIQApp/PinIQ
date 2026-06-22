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
import 'message_detail_screen.dart';
import 'new_message_screen.dart';
import 'safety_alerts_screen.dart';

class MessageThreadsScreen extends StatefulWidget {
  const MessageThreadsScreen({super.key});

  @override
  State<MessageThreadsScreen> createState() => _MessageThreadsScreenState();
}

class _MessageThreadsScreenState extends State<MessageThreadsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<AppState>().refreshThreads();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final threads = appState.threads;
    final unreadCount = threads.where((thread) => DateTime.now().difference(thread.lastMessageAt).inHours < 24).length;
    final parentVisibleCount = threads.where((thread) => thread.parentVisibilityRequired).length;
    final announcementCount = threads.where((thread) => thread.isAnnouncement).length;
    final internalCount = threads.where((thread) => !thread.parentVisibilityRequired && !thread.isAnnouncement).length;
    final safetyAlertCount = appState.openSafetyAlertCount;
    final content = ListView(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, AppSpacing.xl),
      children: [
        SubpageHeader(
          title: 'Conversations',
          subtitle: 'Threads stay clean, compliant, and easy to scan when parents need visibility.',
          trailing: const SizedBox.shrink(),
        ),
        const SizedBox(height: AppSpacing.md),
        _ConversationCommandDeck(
          unreadCount: unreadCount,
          parentVisibleCount: parentVisibleCount,
          safetyAlertCount: safetyAlertCount,
          onNewThread: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NewMessageScreen()),
            );
          },
          onOpenSafetyQueue: appState.canManageMembers
              ? () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SafetyAlertsScreen()),
                  );
                }
              : null,
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            ElevatedButton.icon(
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const NewMessageScreen()),
                );
              },
              icon: const Icon(Icons.add_comment_outlined),
              label: const Text('New thread'),
            ),
            if (appState.canManageMembers)
              OutlinedButton.icon(
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SafetyAlertsScreen()),
                  );
                },
                icon: const Icon(Icons.shield_outlined),
                label: Text('Safety queue${safetyAlertCount > 0 ? ' ($safetyAlertCount)' : ''}'),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            _ThreadMetricCard(label: 'Unread', value: '$unreadCount', note: 'need attention'),
            _ThreadMetricCard(label: 'Parent-visible', value: '$parentVisibleCount', note: 'compliance aware'),
            _ThreadMetricCard(label: 'Announcements', value: '$announcementCount', note: 'broadcast channels'),
            _ThreadMetricCard(label: 'Internal', value: '$internalCount', note: 'staff or athlete only'),
            _ThreadMetricCard(label: 'Safety queue', value: '$safetyAlertCount', note: 'need adult review'),
            _ThreadMetricCard(label: 'Threads', value: '${threads.length}', note: 'active channels'),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        _CommunicationControlPanel(
          announcementCount: announcementCount,
          parentVisibleCount: parentVisibleCount,
          internalCount: internalCount,
        ),
        const SizedBox(height: AppSpacing.xl),
        const SectionHeader(title: 'Recent conversations'),
        const SizedBox(height: AppSpacing.md),
        if (threads.isEmpty)
          const EmptyStateCard(
            title: 'No conversations yet',
            message: 'Start a direct or group thread. Parent visibility is enforced automatically when needed.',
            icon: Icons.forum_outlined,
          )
        else
          ..._groupThreads(threads).entries.map(
            (entry) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Text(entry.key, style: AppTextStyles.caption),
                ),
                ...entry.value.map(
                  (thread) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _ThreadTile(
                      thread: thread,
                      onTap: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => MessageDetailScreen(threadId: thread.id),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
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
}

class _ThreadTile extends StatelessWidget {
  const _ThreadTile({required this.thread, required this.onTap});

  final MessageThreadSummaryModel thread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final participantNames = thread.participants.map((item) => item.user.fullName).take(4).join(', ');
    final accent = Theme.of(context).colorScheme.primary;
    final isUnread = DateTime.now().difference(thread.lastMessageAt).inHours < 24;
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                thread.isAnnouncement
                    ? Icons.campaign_outlined
                    : thread.isGroup
                        ? Icons.groups_2_outlined
                        : Icons.chat_bubble_outline,
                color: accent,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(thread.title, style: AppTextStyles.cardTitle)),
                      if (isUnread)
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: [
                      _ThreadTag(label: thread.threadType.toUpperCase(), color: accent),
                      if (thread.parentVisibilityRequired)
                        const _ThreadTag(label: 'Parent-visible', color: Color(0xFF38BDF8)),
                      if (thread.isComplianceLocked)
                        const _ThreadTag(label: 'Locked', color: AppColors.warning),
                      if (thread.isSafetyAlertThread)
                        _ThreadTag(
                          label: 'Safety ${thread.safetySeverity?.toUpperCase() ?? 'ALERT'}',
                          color: thread.safetySeverity == 'urgent'
                              ? AppColors.danger
                              : const Color(0xFFF59E0B),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    thread.lastMessagePreview ?? 'No messages yet',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    participantNames.isEmpty ? 'No participants yet' : participantNames,
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Text(_format(thread.lastMessageAt), style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }

  String _format(DateTime value) {
    final hours = value.hour == 0 ? 12 : (value.hour > 12 ? value.hour - 12 : value.hour);
    final suffix = value.hour >= 12 ? 'PM' : 'AM';
    final minutes = value.minute.toString().padLeft(2, '0');
    return '$hours:$minutes $suffix';
  }
}

class _ThreadMetricCard extends StatelessWidget {
  const _ThreadMetricCard({
    required this.label,
    required this.value,
    required this.note,
  });

  final String label;
  final String value;
  final String note;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.caption),
          const SizedBox(height: AppSpacing.xs),
          Text(value, style: AppTextStyles.cardTitle),
          const SizedBox(height: AppSpacing.xxs),
          Text(note, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

class _ConversationCommandDeck extends StatelessWidget {
  const _ConversationCommandDeck({
    required this.unreadCount,
    required this.parentVisibleCount,
    required this.safetyAlertCount,
    required this.onNewThread,
    required this.onOpenSafetyQueue,
  });

  final int unreadCount;
  final int parentVisibleCount;
  final int safetyAlertCount;
  final Future<void> Function() onNewThread;
  final Future<void> Function()? onOpenSafetyQueue;

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
          final stacked = constraints.maxWidth < 980;
          final actions = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Coach messaging desk', style: AppTextStyles.bodyStrong),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Keep parent-visible threads clean, answer unread items fast, and separate safety follow-up from normal team traffic.',
                style: AppTextStyles.body,
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  ElevatedButton.icon(
                    onPressed: onNewThread,
                    icon: const Icon(Icons.add_comment_outlined),
                    label: const Text('Start thread'),
                  ),
                  if (onOpenSafetyQueue != null)
                    OutlinedButton.icon(
                      onPressed: onOpenSafetyQueue,
                      icon: const Icon(Icons.shield_outlined),
                      label: const Text('Open safety queue'),
                    ),
                ],
              ),
            ],
          );

          final metrics = Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [
              _ThreadMetricCard(
                label: 'Unread',
                value: '$unreadCount',
                note: 'reply first',
              ),
              _ThreadMetricCard(
                label: 'Parent-visible',
                value: '$parentVisibleCount',
                note: 'compliance aware',
              ),
              _ThreadMetricCard(
                label: 'Safety queue',
                value: '$safetyAlertCount',
                note: 'adult review',
              ),
            ],
          );

          if (stacked) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                actions,
                const SizedBox(height: AppSpacing.lg),
                metrics,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 4, child: actions),
              const SizedBox(width: AppSpacing.xl),
              Expanded(flex: 6, child: metrics),
            ],
          );
        },
      ),
    );
  }
}

class _CommunicationControlPanel extends StatelessWidget {
  const _CommunicationControlPanel({
    required this.announcementCount,
    required this.parentVisibleCount,
    required this.internalCount,
  });

  final int announcementCount;
  final int parentVisibleCount;
  final int internalCount;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _CommLane(
        title: 'Broadcast lane',
        value: announcementCount == 0 ? 'Quiet' : '$announcementCount live',
        note: 'Announcements should stay one-way and fast to scan.',
        color: const Color(0xFF38BDF8),
      ),
      _CommLane(
        title: 'Parent lane',
        value: parentVisibleCount == 0 ? 'Clear' : '$parentVisibleCount visible',
        note: 'Parent-visible threads need the clearest tone and fastest response.',
        color: const Color(0xFFF59E0B),
      ),
      _CommLane(
        title: 'Internal lane',
        value: internalCount == 0 ? 'Light' : '$internalCount active',
        note: 'Keep coach and athlete-only threads separate from family communication.',
        color: Theme.of(context).colorScheme.primary,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 980 ? 3 : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
            childAspectRatio: columns == 1 ? 2.5 : 1.35,
          ),
          itemCount: cards.length,
          itemBuilder: (context, index) => _CommLaneCard(item: cards[index]),
        );
      },
    );
  }
}

class _CommLane {
  const _CommLane({
    required this.title,
    required this.value,
    required this.note,
    required this.color,
  });

  final String title;
  final String value;
  final String note;
  final Color color;
}

class _CommLaneCard extends StatelessWidget {
  const _CommLaneCard({required this.item});

  final _CommLane item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.title, style: AppTextStyles.caption),
          const SizedBox(height: AppSpacing.sm),
          Text(item.value, style: AppTextStyles.cardTitle.copyWith(color: item.color)),
          const SizedBox(height: AppSpacing.sm),
          Text(item.note, style: AppTextStyles.body),
        ],
      ),
    );
  }
}

class _ThreadTag extends StatelessWidget {
  const _ThreadTag({
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

Map<String, List<MessageThreadSummaryModel>> _groupThreads(List<MessageThreadSummaryModel> threads) {
  final today = <MessageThreadSummaryModel>[];
  final earlier = <MessageThreadSummaryModel>[];
  for (final thread in threads) {
    if (DateTime.now().difference(thread.lastMessageAt).inDays < 1) {
      today.add(thread);
    } else {
      earlier.add(thread);
    }
  }

  final grouped = <String, List<MessageThreadSummaryModel>>{};
  if (today.isNotEmpty) grouped['Today'] = today;
  if (earlier.isNotEmpty) grouped['Earlier'] = earlier;
  return grouped;
}
