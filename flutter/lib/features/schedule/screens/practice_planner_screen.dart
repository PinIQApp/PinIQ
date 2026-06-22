import 'package:flutter/material.dart';

import '../models/schedule_models.dart';
import '../services/schedule_api_service.dart';

class PracticePlannerScreen extends StatefulWidget {
  const PracticePlannerScreen({
    super.key,
    required this.api,
    required this.teamId,
    required this.schoolPrimaryColor,
    required this.schoolAccentColor,
    this.initialPractice,
  });

  final ScheduleApiService api;
  final int teamId;
  final Color schoolPrimaryColor;
  final Color schoolAccentColor;
  final PracticePlanItem? initialPractice;

  @override
  State<PracticePlannerScreen> createState() => _PracticePlannerScreenState();
}

class _PracticePlannerScreenState extends State<PracticePlannerScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _focusController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _notesController;
  late List<PracticeBlockItem> _blocks;
  bool _saving = false;

  bool get _editing => widget.initialPractice != null;

  int get _totalDuration =>
      _blocks.fold<int>(0, (sum, block) => sum + block.durationMinutes);

  @override
  void initState() {
    super.initState();
    final practice = widget.initialPractice;
    _titleController = TextEditingController(text: practice?.title ?? '');
    _focusController = TextEditingController(text: practice?.focus ?? '');
    _descriptionController = TextEditingController(
      text: practice?.description ?? '',
    );
    _notesController = TextEditingController(text: practice?.notes ?? '');
    _blocks =
        practice?.blocks.toList() ??
        [
          const PracticeBlockItem(
            id: 0,
            blockOrder: 1,
            blockType: PracticeBlockType.warmUp,
            title: 'Dynamic warm-up',
            durationMinutes: 10,
          ),
          const PracticeBlockItem(
            id: 0,
            blockOrder: 2,
            blockType: PracticeBlockType.drilling,
            title: 'Primary drilling series',
            durationMinutes: 20,
          ),
          const PracticeBlockItem(
            id: 0,
            blockOrder: 3,
            blockType: PracticeBlockType.liveGoes,
            title: 'Live goes',
            durationMinutes: 18,
          ),
          const PracticeBlockItem(
            id: 0,
            blockOrder: 4,
            blockType: PracticeBlockType.coolDown,
            title: 'Cool down',
            durationMinutes: 8,
          ),
        ];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _focusController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E13),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: Text(_editing ? 'Edit Practice Plan' : 'Practice Planner'),
        actions: [
          if (_editing)
            TextButton(
              onPressed: _saving ? null : _duplicatePractice,
              child: const Text('Duplicate'),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _summaryCard(),
          const SizedBox(height: 16),
          _formCard(),
          const SizedBox(height: 16),
          _blocksCard(),
          const SizedBox(height: 18),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: widget.schoolAccentColor,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            onPressed: _saving ? null : _savePractice,
            child: Text(
              _saving
                  ? 'Saving...'
                  : (_editing ? 'Update Practice' : 'Save Practice'),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: widget.schoolPrimaryColor,
        foregroundColor: Colors.white,
        onPressed: _addBlock,
        icon: const Icon(Icons.add),
        label: const Text('Add Block'),
      ),
    );
  }

  Widget _summaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            widget.schoolPrimaryColor.withOpacity(0.46),
            const Color(0xFF121821),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Expanded(child: _metric('Total Time', '$_totalDuration min')),
          Expanded(child: _metric('Blocks', '${_blocks.length}')),
          Expanded(child: _metric('Mode', _editing ? 'Edit' : 'Create')),
        ],
      ),
    );
  }

  Widget _metric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFFD7E0EF))),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _formCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _panelDecoration(),
      child: Column(
        children: [
          _textField(_titleController, 'Practice title'),
          const SizedBox(height: 12),
          _textField(_focusController, 'Focus area'),
          const SizedBox(height: 12),
          _textField(_descriptionController, 'Description', maxLines: 3),
          const SizedBox(height: 12),
          _textField(_notesController, 'Coach notes', maxLines: 4),
        ],
      ),
    );
  }

  Widget _blocksCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ordered Practice Blocks',
            style: TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Keep the plan clean and fast. Coaches should be able to build the room in under a minute.',
            style: TextStyle(color: Color(0xFF97A1B4), height: 1.4),
          ),
          const SizedBox(height: 14),
          ..._blocks.asMap().entries.map((entry) {
            final index = entry.key;
            final block = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _blockTile(block, index),
            );
          }),
        ],
      ),
    );
  }

  Widget _blockTile(PracticeBlockItem block, int index) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0E141C),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: widget.schoolAccentColor.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<PracticeBlockType>(
                  initialValue: block.blockType,
                  dropdownColor: const Color(0xFF1A2230),
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('Block type'),
                  items: PracticeBlockType.values
                      .map(
                        (type) => DropdownMenuItem(
                          value: type,
                          child: Text(practiceBlockTypeLabel(type)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _blocks[index] = _blocks[index].copyWith(
                        blockType: value,
                      );
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: block.title ?? '',
            style: const TextStyle(color: Colors.white),
            decoration: _inputDecoration('Block title'),
            onChanged: (value) {
              _blocks[index] = _blocks[index].copyWith(title: value);
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: '${block.durationMinutes}',
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('Minutes'),
                  onChanged: (value) {
                    final parsed = int.tryParse(value) ?? block.durationMinutes;
                    _blocks[index] = _blocks[index].copyWith(
                      durationMinutes: parsed,
                    );
                    setState(() {});
                  },
                ),
              ),
              const SizedBox(width: 12),
              IconButton.filledTonal(
                onPressed: _blocks.length == 1
                    ? null
                    : () => setState(() {
                        _blocks.removeAt(index);
                        _reorderBlocks();
                      }),
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _textField(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: _inputDecoration(label),
    );
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

  BoxDecoration _panelDecoration() => BoxDecoration(
    color: const Color(0xFF121821),
    borderRadius: BorderRadius.circular(24),
    border: Border.all(color: Colors.white10),
  );

  void _addBlock() {
    setState(() {
      _blocks.add(
        PracticeBlockItem(
          id: 0,
          blockOrder: _blocks.length + 1,
          blockType: PracticeBlockType.drilling,
          title: 'New block',
          durationMinutes: 10,
        ),
      );
      _reorderBlocks();
    });
  }

  void _reorderBlocks() {
    _blocks = _blocks
        .asMap()
        .entries
        .map((entry) => entry.value.copyWith(blockOrder: entry.key + 1))
        .toList();
  }

  Future<void> _savePractice() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Practice title is required.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final ordered = _blocks
          .asMap()
          .entries
          .map((entry) => entry.value.copyWith(blockOrder: entry.key + 1))
          .toList();
      final saved = _editing
          ? await widget.api.updatePractice(
              practiceId: widget.initialPractice!.id,
              title: _titleController.text.trim(),
              description: _descriptionController.text.trim(),
              focus: _focusController.text.trim(),
              notes: _notesController.text.trim(),
              blocks: ordered,
            )
          : await widget.api.createPractice(
              teamId: widget.teamId,
              title: _titleController.text.trim(),
              description: _descriptionController.text.trim(),
              focus: _focusController.text.trim(),
              notes: _notesController.text.trim(),
              blocks: ordered,
            );
      if (!mounted) return;
      Navigator.of(context).pop(saved);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _duplicatePractice() async {
    try {
      final duplicated = await widget.api.duplicatePractice(
        practiceId: widget.initialPractice!.id,
        title: '${widget.initialPractice!.title} Copy',
      );
      if (!mounted) return;
      Navigator.of(context).pop(duplicated);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }
}
