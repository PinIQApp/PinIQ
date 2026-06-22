import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/stats_models.dart';
import '../services/stats_api_service.dart';

class MatchEntryScreen extends StatefulWidget {
  const MatchEntryScreen({
    super.key,
    required this.api,
    required this.teamId,
    required this.athleteId,
    required this.schoolPrimaryColor,
    required this.schoolAccentColor,
  });

  final StatsApiService api;
  final int teamId;
  final int athleteId;
  final Color schoolPrimaryColor;
  final Color schoolAccentColor;

  @override
  State<MatchEntryScreen> createState() => _MatchEntryScreenState();
}

class _MatchEntryScreenState extends State<MatchEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _opponentController = TextEditingController();
  final _schoolController = TextEditingController();
  final _eventController = TextEditingController();
  final _weightClassController = TextEditingController();
  final _scoreForController = TextEditingController(text: '0');
  final _scoreAgainstController = TextEditingController(text: '0');
  final _pinTimeController = TextEditingController();
  final _notesController = TextEditingController();
  final _takedownsController = TextEditingController(text: '0');
  final _escapesController = TextEditingController(text: '0');
  final _reversalsController = TextEditingController(text: '0');
  final _nearfallController = TextEditingController(text: '0');
  final _stallsController = TextEditingController(text: '0');
  final _rideTimeController = TextEditingController();
  final _shotAttemptsController = TextEditingController();
  final _shotConversionsController = TextEditingController();

  DateTime _matchDate = DateTime.now();
  MatchOutcome _outcome = MatchOutcome.win;
  MatchResultType _resultType = MatchResultType.decision;
  bool _saving = false;

  @override
  void dispose() {
    _opponentController.dispose();
    _schoolController.dispose();
    _eventController.dispose();
    _weightClassController.dispose();
    _scoreForController.dispose();
    _scoreAgainstController.dispose();
    _pinTimeController.dispose();
    _notesController.dispose();
    _takedownsController.dispose();
    _escapesController.dispose();
    _reversalsController.dispose();
    _nearfallController.dispose();
    _stallsController.dispose();
    _rideTimeController.dispose();
    _shotAttemptsController.dispose();
    _shotConversionsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.api.createFullMatchEntry(
        athleteId: widget.athleteId,
        teamId: widget.teamId,
        opponentName: _opponentController.text.trim(),
        opponentSchool: _emptyToNull(_schoolController.text),
        eventName: _emptyToNull(_eventController.text),
        matchDate: _matchDate,
        weightClass: _weightClassController.text.trim(),
        result: _outcome,
        resultType: _resultType,
        scoreFor: int.parse(_scoreForController.text),
        scoreAgainst: int.parse(_scoreAgainstController.text),
        pinTime: _emptyToNull(_pinTimeController.text),
        notes: _emptyToNull(_notesController.text),
        takedowns: _parseInt(_takedownsController.text),
        escapes: _parseInt(_escapesController.text),
        reversals: _parseInt(_reversalsController.text),
        nearfallPoints: _parseInt(_nearfallController.text),
        stallCalls: _parseInt(_stallsController.text),
        rideTimeSeconds: _parseOptionalInt(_rideTimeController.text),
        shotAttempts: _parseOptionalInt(_shotAttemptsController.text),
        shotConversions: _parseOptionalInt(_shotConversionsController.text),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Match logged successfully.')),
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090D12),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text('Match Entry'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _heroCard(),
            const SizedBox(height: 18),
            _section(
              title: 'Match Result',
              children: [
                _textField(_opponentController, 'Opponent name'),
                _textField(_schoolController, 'Opponent school'),
                _textField(_eventController, 'Event name'),
                _dateField(context),
                _textField(_weightClassController, 'Weight class'),
                _resultPickers(),
                Row(
                  children: [
                    Expanded(child: _numberField(_scoreForController, 'Score for')),
                    const SizedBox(width: 12),
                    Expanded(child: _numberField(_scoreAgainstController, 'Score against')),
                  ],
                ),
                _textField(_pinTimeController, 'Pin time (mm:ss)', requiredField: false),
                _textField(_notesController, 'Coach notes', maxLines: 4, requiredField: false),
              ],
            ),
            const SizedBox(height: 16),
            _section(
              title: 'Detailed Stats',
              children: [
                Row(
                  children: [
                    Expanded(child: _numberField(_takedownsController, 'Takedowns')),
                    const SizedBox(width: 12),
                    Expanded(child: _numberField(_escapesController, 'Escapes')),
                  ],
                ),
                Row(
                  children: [
                    Expanded(child: _numberField(_reversalsController, 'Reversals')),
                    const SizedBox(width: 12),
                    Expanded(child: _numberField(_nearfallController, 'Nearfall points')),
                  ],
                ),
                Row(
                  children: [
                    Expanded(child: _numberField(_stallsController, 'Stalling calls')),
                    const SizedBox(width: 12),
                    Expanded(child: _numberField(_rideTimeController, 'Ride time sec', requiredField: false)),
                  ],
                ),
                Row(
                  children: [
                    Expanded(child: _numberField(_shotAttemptsController, 'Shot attempts', requiredField: false)),
                    const SizedBox(width: 12),
                    Expanded(child: _numberField(_shotConversionsController, 'Shot conversions', requiredField: false)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _saving ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: widget.schoolAccentColor,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(_saving ? 'Saving...' : 'Log Match'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _heroCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            widget.schoolPrimaryColor.withOpacity(0.45),
            widget.schoolAccentColor.withOpacity(0.28),
            const Color(0xFF101722),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white10),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Fast Coach Workflow',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Log the outcome first, then add the stat line in the same flow so post-match corrections stay quick and organized.',
            style: TextStyle(color: Color(0xFFD8E1EE), height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _section({required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF121821),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          ...children.expand((item) => [item, const SizedBox(height: 12)]).toList()..removeLast(),
        ],
      ),
    );
  }

  Widget _dateField(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _matchDate,
          firstDate: DateTime(2020),
          lastDate: DateTime(2100),
        );
        if (picked != null) {
          setState(() => _matchDate = picked);
        }
      },
      child: InputDecorator(
        decoration: _decorator('Match date'),
        child: Text(
          DateFormat('MMM d, y').format(_matchDate),
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _resultPickers() {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<MatchOutcome>(
            value: _outcome,
            decoration: _decorator('Win / Loss'),
            dropdownColor: const Color(0xFF1A2230),
            style: const TextStyle(color: Colors.white),
            items: const [
              DropdownMenuItem(value: MatchOutcome.win, child: Text('Win')),
              DropdownMenuItem(value: MatchOutcome.loss, child: Text('Loss')),
            ],
            onChanged: (value) => setState(() => _outcome = value ?? MatchOutcome.win),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: DropdownButtonFormField<MatchResultType>(
            value: _resultType,
            decoration: _decorator('Result type'),
            dropdownColor: const Color(0xFF1A2230),
            style: const TextStyle(color: Colors.white),
            items: MatchResultType.values
                .map(
                  (type) => DropdownMenuItem(
                    value: type,
                    child: Text(matchResultTypeLabel(type)),
                  ),
                )
                .toList(growable: false),
            onChanged: (value) => setState(() => _resultType = value ?? MatchResultType.decision),
          ),
        ),
      ],
    );
  }

  Widget _textField(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
    bool requiredField = true,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: _decorator(label),
      validator: requiredField
          ? (value) => (value == null || value.trim().isEmpty) ? 'Required' : null
          : null,
    );
  }

  Widget _numberField(
    TextEditingController controller,
    String label, {
    bool requiredField = true,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: const TextStyle(color: Colors.white),
      decoration: _decorator(label),
      validator: (value) {
        if (!requiredField && (value == null || value.trim().isEmpty)) {
          return null;
        }
        final parsed = int.tryParse(value ?? '');
        return parsed == null ? 'Enter a whole number' : null;
      },
    );
  }

  InputDecoration _decorator(String label) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF98A5BA)),
        filled: true,
        fillColor: const Color(0xFF1A2230),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      );

  int _parseInt(String value) => int.tryParse(value.trim()) ?? 0;

  int? _parseOptionalInt(String value) =>
      value.trim().isEmpty ? null : int.tryParse(value.trim());

  String? _emptyToNull(String value) => value.trim().isEmpty ? null : value.trim();
}
