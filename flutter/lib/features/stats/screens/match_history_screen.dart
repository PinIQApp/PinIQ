import 'package:flutter/material.dart';

import '../models/stats_models.dart';
import '../services/stats_api_service.dart';
import '../widgets/stats_cards.dart';

class MatchHistoryScreen extends StatefulWidget {
  const MatchHistoryScreen({
    super.key,
    required this.api,
    required this.teamId,
    required this.schoolPrimaryColor,
    required this.schoolAccentColor,
  });

  final StatsApiService api;
  final int teamId;
  final Color schoolPrimaryColor;
  final Color schoolAccentColor;

  @override
  State<MatchHistoryScreen> createState() => _MatchHistoryScreenState();
}

class _MatchHistoryScreenState extends State<MatchHistoryScreen> {
  final _athleteController = TextEditingController();
  final _eventController = TextEditingController();
  final _weightClassController = TextEditingController();

  late Future<List<MatchEntry>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.api.fetchTeamMatches(teamId: widget.teamId);
  }

  @override
  void dispose() {
    _athleteController.dispose();
    _eventController.dispose();
    _weightClassController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    setState(() {
      _future = widget.api.fetchTeamMatches(
        teamId: widget.teamId,
        athleteId: int.tryParse(_athleteController.text.trim()),
        eventName: _eventController.text.trim().isEmpty ? null : _eventController.text.trim(),
        weightClass: _weightClassController.text.trim().isEmpty
            ? null
            : _weightClassController.text.trim(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E13),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text('Match History'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _filterPanel(),
          const SizedBox(height: 18),
          FutureBuilder<List<MatchEntry>>(
            future: _future,
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
              final matches = snapshot.data ?? const <MatchEntry>[];
              if (matches.isEmpty) {
                return const Text(
                  'No matches found for the current filter set.',
                  style: TextStyle(color: Color(0xFF98A4B8)),
                );
              }
              return Column(
                children: matches.map((match) => MatchHistoryTile(match: match)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _filterPanel() {
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
          const Text(
            'Search + Filters',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _athleteController,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white),
            decoration: _decoration('Athlete ID'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _eventController,
            style: const TextStyle(color: Colors.white),
            decoration: _decoration('Event name'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _weightClassController,
            style: const TextStyle(color: Colors.white),
            decoration: _decoration('Weight class'),
          ),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: _applyFilters,
            style: FilledButton.styleFrom(
              backgroundColor: widget.schoolAccentColor,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Apply Filters'),
          ),
        ],
      ),
    );
  }

  InputDecoration _decoration(String label) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF95A2B7)),
        filled: true,
        fillColor: const Color(0xFF1A2230),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      );
}
