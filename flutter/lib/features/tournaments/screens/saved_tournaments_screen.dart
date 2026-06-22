import 'package:flutter/material.dart';

import '../models/tournament_models.dart';
import '../services/tournament_api_service.dart';
import '../widgets/tournament_ui.dart';
import 'tournament_detail_screen.dart';

class SavedTournamentsScreen extends StatefulWidget {
  const SavedTournamentsScreen({
    super.key,
    required this.api,
    required this.teamId,
  });

  final TournamentApiService api;
  final int teamId;

  @override
  State<SavedTournamentsScreen> createState() => _SavedTournamentsScreenState();
}

class _SavedTournamentsScreenState extends State<SavedTournamentsScreen> {
  late Future<List<SavedTournamentModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.api.fetchSavedTournaments(teamId: widget.teamId);
  }

  Future<void> _reload() async {
    setState(() {
      _future = widget.api.fetchSavedTournaments(teamId: widget.teamId);
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEE4D6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFEEE4D6),
        foregroundColor: const Color(0xFF1F1A15),
        elevation: 0,
        title: const Text('Saved Tournaments'),
      ),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: FutureBuilder<List<SavedTournamentModel>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return ListView(
                padding: const EdgeInsets.all(20),
                children: [Text(snapshot.error.toString())],
              );
            }
            final savedItems = snapshot.data ?? const <SavedTournamentModel>[];
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const TournamentSectionTitle(
                  title: 'Coach-Selected Events',
                  subtitle: 'Bookmarks become the shared shortlist for athletes and parents.',
                ),
                const SizedBox(height: 14),
                ...savedItems.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: TournamentCard(
                      tournament: item.tournament,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => TournamentDetailScreen(
                              api: widget.api,
                              tournamentId: item.tournament.id,
                              teamId: widget.teamId,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                if (savedItems.isEmpty)
                  const TournamentSurface(
                    child: Text(
                      'No tournaments have been saved yet. Coaches can bookmark events from discovery and they will appear here.',
                      style: TextStyle(height: 1.5),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
