import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../models/team_member_model.dart';
import 'message_detail_screen.dart';

class NewMessageScreen extends StatefulWidget {
  const NewMessageScreen({super.key});

  @override
  State<NewMessageScreen> createState() => _NewMessageScreenState();
}

class _NewMessageScreenState extends State<NewMessageScreen> {
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  final Set<int> _selectedUserIds = {};
  String _threadType = 'group';
  String? _error;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final members = appState.activeTeam?.members.where((item) => item.status == 'approved').toList() ?? [];
    final selectedMembers = members.where((member) => _selectedUserIds.contains(member.user.id)).toList();
    final selectedAthletes = selectedMembers.where((member) => member.user.role == 'athlete').toList();
    final draftRiskFlags = _localRiskFlags(_messageController.text);

    return Scaffold(
      appBar: AppBar(title: const Text('New Message')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Create Thread', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 12),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'group', label: Text('Group')),
                    ButtonSegment(value: 'direct', label: Text('Direct')),
                  ],
                  selected: {_threadType},
                  onSelectionChanged: (selection) {
                    setState(() => _threadType = selection.first);
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Thread Title'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _messageController,
                  onChanged: (_) => setState(() {}),
                  maxLines: 5,
                  decoration: const InputDecoration(labelText: 'Initial Message'),
                ),
                if (draftRiskFlags.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.error.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'This draft may trigger adult review for: ${draftRiskFlags.join(', ')}.',
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                const Text('Recipients', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                if (selectedAthletes.isNotEmpty)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'Parent visibility will be enforced for ${selectedAthletes.map((item) => item.user.fullName).join(', ')}. Linked parent accounts are auto-added by the backend.',
                    ),
                  ),
                ...members.map((member) => _RecipientTile(
                      member: member,
                      selected: _selectedUserIds.contains(member.user.id),
                      onChanged: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedUserIds.add(member.user.id);
                          } else {
                            _selectedUserIds.remove(member.user.id);
                          }
                        });
                      },
                    )),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: Colors.redAccent)),
                ],
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: appState.isBusy
                      ? null
                      : () async {
                          try {
                            setState(() => _error = null);
                            final thread = await context.read<AppState>().createThread(
                                  title: _titleController.text.trim(),
                                  threadType: _threadType,
                                  participantUserIds: _selectedUserIds.toList(),
                                  initialMessage: _messageController.text.trim(),
                                );
                            if (!context.mounted) return;
                            await Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (_) => MessageDetailScreen(threadId: thread.id),
                              ),
                            );
                          } catch (e) {
                            setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
                          }
                        },
                  child: Text(appState.isBusy ? 'Creating...' : 'Create Thread'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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

class _RecipientTile extends StatelessWidget {
  const _RecipientTile({
    required this.member,
    required this.selected,
    required this.onChanged,
  });

  final TeamMemberModel member;
  final bool selected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: CheckboxListTile(
        value: selected,
        onChanged: (value) => onChanged(value ?? false),
        title: Text(member.user.fullName),
        subtitle: Text('${member.roleLabel} • ${member.user.email}'),
        secondary: Wrap(
          spacing: 8,
          children: [
            if (member.user.role == 'athlete') const Chip(label: Text('Athlete')),
            if (member.user.role == 'parent') const Chip(label: Text('Parent')),
            if (member.isStaff) const Chip(label: Text('Staff')),
          ],
        ),
      ),
    );
  }
}
