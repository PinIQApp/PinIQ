import 'package:flutter/material.dart';

import '../models/schedule_models.dart';
import '../services/schedule_api_service.dart';

class PracticeTemplatesScreen extends StatefulWidget {
  const PracticeTemplatesScreen({
    super.key,
    required this.api,
    required this.teamId,
    required this.schoolPrimaryColor,
    required this.schoolAccentColor,
    this.onApplyTemplate,
  });

  final ScheduleApiService api;
  final int teamId;
  final Color schoolPrimaryColor;
  final Color schoolAccentColor;
  final ValueChanged<PracticeTemplateItem>? onApplyTemplate;

  @override
  State<PracticeTemplatesScreen> createState() =>
      _PracticeTemplatesScreenState();
}

class _PracticeTemplatesScreenState extends State<PracticeTemplatesScreen> {
  late Future<List<PracticeTemplateItem>> _templatesFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _templatesFuture = widget.api.fetchTeamTemplates(teamId: widget.teamId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E13),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text('Practice Templates'),
      ),
      body: FutureBuilder<List<PracticeTemplateItem>>(
        future: _templatesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                snapshot.error.toString(),
                style: const TextStyle(color: Colors.redAccent),
              ),
            );
          }
          final templates = snapshot.data ?? const <PracticeTemplateItem>[];
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _header(),
              const SizedBox(height: 16),
              ...templates.map(_templateCard),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: widget.schoolAccentColor,
        foregroundColor: Colors.black,
        onPressed: _openCreateTemplateDialog,
        label: const Text('Save Template'),
        icon: const Icon(Icons.post_add),
      ),
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            widget.schoolPrimaryColor.withOpacity(0.42),
            const Color(0xFF131A23),
          ],
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white10),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reusable Room Plans',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Use system templates for quick starts, then save your own coach-built variations for the season.',
            style: TextStyle(color: Color(0xFFD7E0EF), height: 1.45),
          ),
        ],
      ),
    );
  }

  Widget _templateCard(PracticeTemplateItem template) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF121821),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  template.templateName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (template.isSystemTemplate)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: widget.schoolAccentColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'System',
                    style: TextStyle(
                      color: widget.schoolAccentColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            template.description ?? 'No description provided.',
            style: const TextStyle(color: Color(0xFFD7E0EF), height: 1.4),
          ),
          const SizedBox(height: 10),
          Text(
            '${template.totalDurationMinutes} min • ${template.blocks.length} blocks • ${template.focus ?? 'General focus'}',
            style: const TextStyle(color: Color(0xFF97A1B4)),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: template.blocks
                .map(
                  (block) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0E141C),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      '${practiceBlockTypeLabel(block.blockType)} ${block.durationMinutes}m',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 14),
          FilledButton.tonal(
            onPressed: () {
              widget.onApplyTemplate?.call(template);
              Navigator.of(context).pop(template);
            },
            child: const Text('Apply Template'),
          ),
        ],
      ),
    );
  }

  Future<void> _openCreateTemplateDialog() async {
    final nameController = TextEditingController();
    final focusController = TextEditingController();
    final descriptionController = TextEditingController();
    final blocks = <PracticeBlockItem>[
      const PracticeBlockItem(
        id: 0,
        blockOrder: 1,
        blockType: PracticeBlockType.warmUp,
        title: 'Warm-up',
        durationMinutes: 10,
      ),
      const PracticeBlockItem(
        id: 0,
        blockOrder: 2,
        blockType: PracticeBlockType.drilling,
        title: 'Primary drill',
        durationMinutes: 15,
      ),
    ];

    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF121821),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('Template name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: focusController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('Focus'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('Description'),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () async {
                  try {
                    await widget.api.createTemplate(
                      teamId: widget.teamId,
                      templateName: nameController.text.trim(),
                      focus: focusController.text.trim(),
                      description: descriptionController.text.trim(),
                      blocks: blocks,
                    );
                    if (!context.mounted) return;
                    Navigator.of(context).pop(true);
                  } catch (_) {
                    if (!context.mounted) return;
                    Navigator.of(context).pop(false);
                  }
                },
                child: const Text('Create Template'),
              ),
            ],
          ),
        );
      },
    );

    if (created == true) {
      setState(_reload);
    }
  }

  InputDecoration _inputDecoration(String label) => InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: Color(0xFF97A1B4)),
    filled: true,
    fillColor: const Color(0xFF0E141C),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Colors.white10),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Colors.white10),
    ),
  );
}
