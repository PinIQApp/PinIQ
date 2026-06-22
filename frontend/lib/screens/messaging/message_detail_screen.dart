import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../models/messaging_models.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';

class MessageDetailScreen extends StatefulWidget {
  const MessageDetailScreen({super.key, required this.threadId});

  final int threadId;

  @override
  State<MessageDetailScreen> createState() => _MessageDetailScreenState();
}

class _MessageDetailScreenState extends State<MessageDetailScreen> {
  final _composer = TextEditingController();
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AppState>().loadThread(widget.threadId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final thread = appState.activeThread?.id == widget.threadId ? appState.activeThread : null;
    final currentUserId = appState.user?.id;
    final matchingParticipants = thread == null
        ? const <MessageParticipantModel>[]
        : thread.participants.where((item) => item.userId == currentUserId).toList();
    final myParticipant = matchingParticipants.isEmpty ? null : matchingParticipants.first;
    final isReadOnlyVisibilityParent = myParticipant?.isParentVisibility == true;
    final composerRiskFlags = _localRiskFlags(_composer.text);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: Text(thread?.title ?? 'Conversation')),
      body: thread == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _ThreadMeta(thread: thread),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(AppSpacing.screenPadding),
                    children: _buildMessageList(thread, currentUserId),
                  ),
                ),
                if (isReadOnlyVisibilityParent)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'This thread is visible to you for parent oversight. Replies are disabled for visibility-only participants.',
                        style: AppTextStyles.caption.copyWith(color: AppColors.warning),
                      ),
                    ),
                  ),
                if (composerRiskFlags.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screenPadding,
                      AppSpacing.sm,
                      AppSpacing.screenPadding,
                      0,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.warning.withValues(alpha: 0.5)),
                      ),
                      child: Text(
                        'This draft may trigger adult review for: ${composerRiskFlags.join(', ')}.',
                        style: AppTextStyles.caption,
                      ),
                    ),
                  ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(_error!, style: AppTextStyles.caption.copyWith(color: AppColors.danger)),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenPadding,
                    AppSpacing.md,
                    AppSpacing.screenPadding,
                    AppSpacing.screenPadding,
                  ),
                  decoration: const BoxDecoration(
                    color: AppColors.bg,
                    border: Border(top: BorderSide(color: AppColors.border)),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _composer,
                            onChanged: (_) => setState(() {}),
                            maxLines: null,
                            decoration: const InputDecoration(
                              hintText: 'Send a message',
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        ElevatedButton(
                          onPressed: appState.isBusy || isReadOnlyVisibilityParent
                              ? null
                              : () async {
                                  try {
                                    setState(() => _error = null);
                                    await context.read<AppState>().sendThreadMessage(
                                          threadId: widget.threadId,
                                          body: _composer.text.trim(),
                                        );
                                    _composer.clear();
                                  } catch (e) {
                                    setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
                                  }
                                },
                          child: Text(appState.isBusy ? 'Sending...' : 'Send'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  List<Widget> _buildMessageList(MessageThreadDetailModel thread, int? currentUserId) {
    final widgets = <Widget>[];
    DateTime? currentDay;
    for (final message in thread.messages) {
      final day = DateTime(message.createdAt.year, message.createdAt.month, message.createdAt.day);
      if (currentDay == null || currentDay != day) {
        currentDay = day;
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
                ),
                child: Text(_dateLabel(day), style: AppTextStyles.caption),
              ),
            ),
          ),
        );
      }

      widgets.add(
        _MessageBubble(
          message: message,
          isMine: currentUserId == message.senderId,
        ),
      );
    }
    return widgets;
  }

  String _dateLabel(DateTime value) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (value == today) return 'Today';
    if (value == today.subtract(const Duration(days: 1))) return 'Yesterday';
    return '${value.month}/${value.day}/${value.year}';
  }
}

List<String> _localRiskFlags(String body) {
  final normalized = body.toLowerCase();
  final rules = <String, List<String>>{
    'sexual': ['sext', 'nude', 'sex', 'hook up'],
    'drugs': ['weed', 'vape', 'cocaine', 'beer'],
    'crime': ['steal', 'rob', 'gun', 'knife'],
  };
  final flags = <String>[];
  for (final entry in rules.entries) {
    if (entry.value.any((keyword) => normalized.contains(keyword))) {
      flags.add(entry.key);
    }
  }
  return flags;
}

class _ThreadMeta extends StatelessWidget {
  const _ThreadMeta({required this.thread});

  final MessageThreadDetailModel thread;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.screenPadding,
        AppSpacing.screenPadding,
        0,
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(thread.title, style: AppTextStyles.cardTitle.copyWith(fontSize: 20)),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(label: Text(thread.threadType.toUpperCase())),
              if (thread.parentVisibilityRequired) const Chip(label: Text('Parent-visible')),
              if (thread.isComplianceLocked) const Chip(label: Text('Locked')),
              if (thread.isSafetyAlertThread)
                Chip(label: Text('Safety ${thread.safetySeverity?.toUpperCase() ?? 'ALERT'}')),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Participants', style: AppTextStyles.caption),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: thread.participants
                .map(
                  (participant) => Chip(
                    label: Text(
                      participant.isParentVisibility
                          ? '${participant.user.fullName} • parent visibility'
                          : participant.user.fullName,
                    ),
                  ),
                )
                .toList(),
          ),
          if (thread.parentVisibilityRequired) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              'Every athlete-facing message in this thread is visible to linked parent accounts and retained for audit export.',
              style: AppTextStyles.body,
            ),
          ],
          if (thread.isSafetyAlertThread) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              'This is an adult safety-review thread created automatically by the moderation system.',
              style: AppTextStyles.body,
            ),
          ],
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.isMine});

  final MessageModel message;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final color = isMine
        ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.25)
        : AppColors.surface;
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: isMine ? Colors.transparent : AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message.sender.fullName,
                style: AppTextStyles.bodyStrong,
              ),
              if (message.contentRiskFlags.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${(message.severity ?? 'concern').toUpperCase()} • ${message.contentRiskFlags.join(', ')}',
                        style: AppTextStyles.caption,
                      ),
                    ),
                    if (message.autoEscalated)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'Forwarded to parent + coach',
                          style: AppTextStyles.caption,
                        ),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: AppSpacing.xxs),
              Text(message.body, style: AppTextStyles.body.copyWith(color: AppColors.textPrimary)),
              const SizedBox(height: AppSpacing.xs),
              Text(
                _formatMeta(message),
                style: AppTextStyles.caption,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatMeta(MessageModel message) {
    final hours = message.createdAt.hour == 0
        ? 12
        : (message.createdAt.hour > 12 ? message.createdAt.hour - 12 : message.createdAt.hour);
    final suffix = message.createdAt.hour >= 12 ? 'PM' : 'AM';
    final minutes = message.createdAt.minute.toString().padLeft(2, '0');
    final edited = message.editedAt == null ? '' : ' • edited';
    final deleted = message.deletedAt == null ? '' : ' • soft deleted';
    return '${message.createdAt.month}/${message.createdAt.day} $hours:$minutes $suffix$edited$deleted';
  }
}
