import 'package:flutter/material.dart';

import '../models/recruiting_models.dart';
import '../services/recruiting_api_service.dart';
import '../widgets/recruiting_ui.dart';
import 'athlete_recruiting_profile_screen.dart';

class CoachWatchlistScreen extends StatefulWidget {
  const CoachWatchlistScreen({
    super.key,
    required this.api,
    required this.coachId,
    required this.schoolPrimaryColor,
    required this.schoolAccentColor,
  });

  final RecruitingApiService api;
  final int coachId;
  final Color schoolPrimaryColor;
  final Color schoolAccentColor;

  @override
  State<CoachWatchlistScreen> createState() => _CoachWatchlistScreenState();
}

class _CoachWatchlistScreenState extends State<CoachWatchlistScreen> {
  late Future<List<RecruitingWatchlistEntry>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.api.fetchWatchlist(widget.coachId);
  }

  Future<void> _saveQuickNote(RecruitingWatchlistEntry entry) async {
    await widget.api.saveNote(
      coachId: widget.coachId,
      athleteId: entry.athleteId,
      note: entry.note?.isNotEmpty == true ? entry.note! : 'Continue evaluation after next event.',
      tagLabels: entry.tags,
    );
    setState(() {
      _future = widget.api.fetchWatchlist(widget.coachId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E13),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text('Coach Watchlist'),
      ),
      body: FutureBuilder<List<RecruitingWatchlistEntry>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(snapshot.error.toString(), style: const TextStyle(color: Colors.redAccent)),
              ),
            );
          }
          final entries = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: entries.map(_entryCard).toList(growable: false),
          );
        },
      ),
    );
  }

  Widget _entryCard(RecruitingWatchlistEntry entry) {
    return RecruitingPanel(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RecruitingAthleteCardView(
            athlete: entry.athlete,
            primaryColor: widget.schoolPrimaryColor,
            accentColor: widget.schoolAccentColor,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AthleteRecruitingProfileScreen(
                    api: widget.api,
                    athleteId: entry.athleteId,
                    schoolPrimaryColor: widget.schoolPrimaryColor,
                    schoolAccentColor: widget.schoolAccentColor,
                  ),
                ),
              );
            },
          ),
          if (entry.tags.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: entry.tags
                  .map((tag) => RecruitingStatusPill(label: tag, color: widget.schoolAccentColor))
                  .toList(growable: false),
            ),
          const SizedBox(height: 12),
          Text(
            entry.note ?? 'No private coach note yet.',
            style: const TextStyle(color: Color(0xFFD8E2EF), height: 1.5),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton(
              onPressed: () => _saveQuickNote(entry),
              style: OutlinedButton.styleFrom(foregroundColor: Colors.white),
              child: const Text('Refresh Note'),
            ),
          ),
        ],
      ),
    );
  }
}
