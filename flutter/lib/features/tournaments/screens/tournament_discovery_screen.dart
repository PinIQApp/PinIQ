import 'package:flutter/material.dart';

import '../models/tournament_models.dart';
import '../services/tournament_api_service.dart';
import '../widgets/tournament_ui.dart';
import 'saved_tournaments_screen.dart';
import 'tournament_detail_screen.dart';

class TournamentDiscoveryScreen extends StatefulWidget {
  const TournamentDiscoveryScreen({
    super.key,
    required this.api,
    required this.teamId,
    this.originLatitude,
    this.originLongitude,
  });

  final TournamentApiService api;
  final int teamId;
  final double? originLatitude;
  final double? originLongitude;

  @override
  State<TournamentDiscoveryScreen> createState() => _TournamentDiscoveryScreenState();
}

class _TournamentDiscoveryScreenState extends State<TournamentDiscoveryScreen> {
  late TournamentFilterModel _filters;
  late Future<TournamentDiscoveryBundle> _future;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filters = TournamentFilterModel(
      teamId: widget.teamId,
      originLatitude: widget.originLatitude,
      originLongitude: widget.originLongitude,
    );
    _future = _load();
  }

  Future<TournamentDiscoveryBundle> _load() {
    return widget.api.fetchDiscovery(filters: _filters);
  }

  Future<void> _saveTournament(TournamentSummaryModel tournament) async {
    await widget.api.saveTournament(
      teamId: widget.teamId,
      tournamentId: tournament.id,
    );
    setState(() {
      _future = _load();
    });
  }

  Future<void> _openFilters() async {
    final sourceController = TextEditingController(text: _filters.source ?? '');
    final cityController = TextEditingController(text: _filters.city ?? '');
    final stateController = TextEditingController(text: _filters.state ?? '');
    final ageController = TextEditingController(text: _filters.ageGroup ?? '');
    final weightController = TextEditingController(text: _filters.weightClass ?? '');
    final eventTypeController = TextEditingController(text: _filters.eventType ?? '');
    final radiusController = TextEditingController(
      text: _filters.radiusMiles?.toString() ?? '',
    );

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFEEE4D6),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: ListView(
            shrinkWrap: true,
            children: [
              const TournamentSectionTitle(
                title: 'Filter Tournaments',
                subtitle: 'Date range and radius can be layered with age, weight, and event type.',
              ),
              const SizedBox(height: 14),
              TournamentFilterField(controller: sourceController, label: 'Source'),
              const SizedBox(height: 10),
              TournamentFilterField(controller: cityController, label: 'City'),
              const SizedBox(height: 10),
              TournamentFilterField(controller: stateController, label: 'State'),
              const SizedBox(height: 10),
              TournamentFilterField(controller: ageController, label: 'Age Group'),
              const SizedBox(height: 10),
              TournamentFilterField(controller: weightController, label: 'Weight Class'),
              const SizedBox(height: 10),
              TournamentFilterField(controller: eventTypeController, label: 'Event Type'),
              const SizedBox(height: 10),
              TournamentFilterField(controller: radiusController, label: 'Radius Miles'),
              const SizedBox(height: 14),
              FilledButton(
                onPressed: () {
                  setState(() {
                    _filters = _filters.copyWith(
                      source: sourceController.text.isEmpty ? null : sourceController.text,
                      city: cityController.text.isEmpty ? null : cityController.text,
                      state: stateController.text.isEmpty ? null : stateController.text,
                      ageGroup: ageController.text.isEmpty ? null : ageController.text,
                      weightClass: weightController.text.isEmpty ? null : weightController.text,
                      eventType:
                          eventTypeController.text.isEmpty ? null : eventTypeController.text,
                      radiusMiles: radiusController.text.isEmpty
                          ? null
                          : int.tryParse(radiusController.text),
                    );
                    _future = _load();
                  });
                  Navigator.of(context).pop();
                },
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF8B1E3F),
                ),
                child: const Text('Apply Filters'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEE4D6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFEEE4D6),
        foregroundColor: const Color(0xFF1F1A15),
        elevation: 0,
        title: const Text('Tournament Discovery'),
        actions: [
          IconButton(
            onPressed: _openFilters,
            icon: const Icon(Icons.tune_rounded),
          ),
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => SavedTournamentsScreen(
                    api: widget.api,
                    teamId: widget.teamId,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.bookmarks_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _future = _load();
          });
          await _future;
        },
        child: FutureBuilder<TournamentDiscoveryBundle>(
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
            final bundle = snapshot.data!;
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                TournamentSurface(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const TournamentSectionTitle(
                        title: 'Find the Right Events',
                        subtitle: 'Search, filter, bookmark, and move tournaments straight into the team calendar.',
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search by tournament name or city',
                          filled: true,
                          fillColor: Colors.white,
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                _filters = _filters.copyWith(search: _searchController.text);
                                _future = _load();
                              });
                            },
                            icon: const Icon(Icons.search_rounded),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: const BorderSide(color: Color(0xFFD8C8B5)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          TournamentTag(label: '${bundle.tournaments.length} results'),
                          if (_filters.radiusMiles != null)
                            TournamentTag(label: '${_filters.radiusMiles} mi radius'),
                          if ((_filters.ageGroup ?? '').isNotEmpty)
                            TournamentTag(label: _filters.ageGroup!),
                          if ((_filters.weightClass ?? '').isNotEmpty)
                            TournamentTag(label: _filters.weightClass!),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                _collectionSection(
                  title: 'Recommended for This Team',
                  subtitle: 'Structure-only recommendations based on team level, timing, and distance.',
                  tournaments: bundle.recommended,
                ),
                const SizedBox(height: 18),
                _collectionSection(
                  title: 'Nearby Tournaments',
                  subtitle: 'Best local options based on the current origin and radius filters.',
                  tournaments: bundle.nearby,
                ),
                const SizedBox(height: 18),
                _collectionSection(
                  title: 'Upcoming Weekend',
                  subtitle: 'Quick weekend planning for coaches, athletes, and parents.',
                  tournaments: bundle.upcomingWeekend,
                ),
                const SizedBox(height: 18),
                const TournamentSectionTitle(
                  title: 'All Discovery Results',
                  subtitle: 'Normalized results across manual entries and future external ingestion.',
                ),
                const SizedBox(height: 12),
                ...bundle.tournaments.map(
                  (tournament) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: TournamentCard(
                      tournament: tournament,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => TournamentDetailScreen(
                              api: widget.api,
                              tournamentId: tournament.id,
                              teamId: widget.teamId,
                              originLatitude: widget.originLatitude,
                              originLongitude: widget.originLongitude,
                            ),
                          ),
                        );
                      },
                      onSave: () => _saveTournament(tournament),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _collectionSection({
    required String title,
    required String subtitle,
    required List<TournamentSummaryModel> tournaments,
  }) {
    return TournamentSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TournamentSectionTitle(title: title, subtitle: subtitle),
          const SizedBox(height: 12),
          if (tournaments.isEmpty)
            const Text(
              'No tournaments matched this smart collection yet.',
              style: TextStyle(color: Color(0xFF675D53)),
            ),
          ...tournaments.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: TournamentCard(
                tournament: item,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => TournamentDetailScreen(
                        api: widget.api,
                        tournamentId: item.id,
                        teamId: widget.teamId,
                        originLatitude: widget.originLatitude,
                        originLongitude: widget.originLongitude,
                      ),
                    ),
                  );
                },
                onSave: () => _saveTournament(item),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
