import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/weight_models.dart';
import '../services/weight_api_service.dart';
import '../widgets/weight_cards.dart';

class AthleteWeightLogScreen extends StatefulWidget {
  const AthleteWeightLogScreen({
    super.key,
    required this.api,
    required this.athleteId,
    required this.teamId,
    required this.schoolAccentColor,
  });

  final WeightApiService api;
  final int athleteId;
  final int teamId;
  final Color schoolAccentColor;

  @override
  State<AthleteWeightLogScreen> createState() => _AthleteWeightLogScreenState();
}

class _AthleteWeightLogScreenState extends State<AthleteWeightLogScreen> {
  final _formKey = GlobalKey<FormState>();
  final _weightController = TextEditingController();
  final _bodyFatController = TextEditingController();
  final _hydrationController = TextEditingController();
  final _commentsController = TextEditingController();

  DateTime _loggedAt = DateTime.now();
  bool _submitting = false;
  late Future<List<WeightLogEntry>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = _loadHistory();
  }

  @override
  void dispose() {
    _weightController.dispose();
    _bodyFatController.dispose();
    _hydrationController.dispose();
    _commentsController.dispose();
    super.dispose();
  }

  Future<List<WeightLogEntry>> _loadHistory() {
    return widget.api.fetchWeightHistory(
      athleteId: widget.athleteId,
      teamId: widget.teamId,
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _submitting = true);
    try {
      await widget.api.createWeightLog(
        athleteId: widget.athleteId,
        teamId: widget.teamId,
        loggedAt: _loggedAt,
        weight: double.parse(_weightController.text.trim()),
        bodyFatPercentage: _bodyFatController.text.trim().isEmpty
            ? null
            : double.parse(_bodyFatController.text.trim()),
        hydrationNote: _hydrationController.text.trim().isEmpty
            ? null
            : _hydrationController.text.trim(),
        comments: _commentsController.text.trim().isEmpty
            ? null
            : _commentsController.text.trim(),
      );
      _weightController.clear();
      _bodyFatController.clear();
      _hydrationController.clear();
      _commentsController.clear();
      setState(() {
        _loggedAt = DateTime.now();
        _historyFuture = _loadHistory();
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Weight log saved.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F14),
      appBar: AppBar(
        title: const Text('Weight Log'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() => _historyFuture = _loadHistory());
          await _historyFuture;
        },
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildEntryForm(),
            const SizedBox(height: 24),
            const Text(
              'Recent Entries',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<WeightLogEntry>>(
              future: _historyFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Text(
                    snapshot.error.toString(),
                    style: const TextStyle(color: Colors.redAccent),
                  );
                }
                final logs = snapshot.data ?? const [];
                if (logs.isEmpty) {
                  return const Text(
                    'No weight entries yet. Daily logging helps coaches and families track a safe planning pace.',
                    style: TextStyle(color: Color(0xFF9AA3B2), height: 1.45),
                  );
                }
                return Column(
                  children: logs.map((log) => WeightLogTile(log: log)).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEntryForm() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF121720),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Daily Check-In',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Planning and visibility tool for school staff and families. Not medical advice.',
              style: TextStyle(color: Color(0xFF9FAABD), height: 1.4),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _numberField(_weightController, 'Current weight (lbs)')),
                const SizedBox(width: 12),
                Expanded(child: _numberField(_bodyFatController, 'Body fat %', required: false)),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _hydrationController,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration('Hydration note'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _commentsController,
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
              decoration: _inputDecoration('Comments'),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _pickLogDate,
              child: InputDecorator(
                decoration: _inputDecoration('Logged at'),
                child: Text(
                  DateFormat('EEE, MMM d • h:mm a').format(_loggedAt),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: widget.schoolAccentColor,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: _submitting ? null : _submit,
                child: Text(_submitting ? 'Saving...' : 'Save Weight Log'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  TextFormField _numberField(
    TextEditingController controller,
    String label, {
    bool required = true,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: const TextStyle(color: Colors.white),
      decoration: _inputDecoration(label),
      validator: (value) {
        final text = value?.trim() ?? '';
        if (text.isEmpty) {
          return required ? 'Required' : null;
        }
        if (double.tryParse(text) == null) {
          return 'Enter a number';
        }
        return null;
      },
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFF9AA3B2)),
      filled: true,
      fillColor: const Color(0xFF1B2230),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.white10),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: widget.schoolAccentColor),
      ),
    );
  }

  Future<void> _pickLogDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _loggedAt,
      firstDate: DateTime.now().subtract(const Duration(days: 120)),
      lastDate: DateTime.now().add(const Duration(days: 2)),
    );
    if (date == null || !mounted) {
      return;
    }
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_loggedAt),
    );
    if (time == null) {
      return;
    }
    setState(() {
      _loggedAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }
}
