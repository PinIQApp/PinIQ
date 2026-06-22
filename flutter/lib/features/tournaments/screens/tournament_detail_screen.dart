import 'package:flutter/material.dart';

import '../models/tournament_models.dart';
import '../services/tournament_api_service.dart';
import '../widgets/tournament_ui.dart';

class TournamentDetailScreen extends StatefulWidget {
  const TournamentDetailScreen({
    super.key,
    required this.api,
    required this.tournamentId,
    this.teamId,
    this.originLatitude,
    this.originLongitude,
    this.onRegistrationRequested,
  });

  final TournamentApiService api;
  final int tournamentId;
  final int? teamId;
  final double? originLatitude;
  final double? originLongitude;
  final ValueChanged<String>? onRegistrationRequested;

  @override
  State<TournamentDetailScreen> createState() => _TournamentDetailScreenState();
}

class _TournamentDetailScreenState extends State<TournamentDetailScreen> {
  late Future<TournamentDetailModel> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<TournamentDetailModel> _load() {
    return widget.api.fetchTournamentDetail(
      tournamentId: widget.tournamentId,
      teamId: widget.teamId,
      originLatitude: widget.originLatitude,
      originLongitude: widget.originLongitude,
    );
  }

  Future<void> _saveTournament(TournamentDetailModel detail) async {
    if (widget.teamId == null) return;
    await widget.api.saveTournament(
      teamId: widget.teamId!,
      tournamentId: detail.tournament.id,
      notes: detail.savedEntry?.notes,
    );
    setState(() {
      _future = _load();
    });
  }

  Future<void> _addToSchedule(TournamentDetailModel detail) async {
    if (widget.teamId == null) return;
    await widget.api.addTournamentToSchedule(
      teamId: widget.teamId!,
      tournamentId: detail.tournament.id,
      notes: 'Added from tournament discovery in Wrestling OS.',
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tournament added to the team schedule.')),
    );
    setState(() {
      _future = _load();
    });
  }

  void _openRegistration(TournamentDetailModel detail) {
    final link = detail.availableRegistrationLink;
    if (link == null || link.isEmpty) return;
    widget.onRegistrationRequested?.call(link);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Registration link: $link')),
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
        title: const Text('Tournament Details'),
      ),
      body: FutureBuilder<TournamentDetailModel>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }
          final detail = snapshot.data!;
          final tournament = detail.tournament;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              TournamentSurface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TournamentSectionTitle(
                      title: tournament.name,
                      subtitle: '${tournament.dateLabel} • ${tournament.locationLabel}',
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        TournamentTag(label: tournament.sourceLabel),
                        TournamentTag(label: tournament.eventType.toUpperCase()),
                        if (tournament.cost != null) TournamentTag(label: tournament.cost!),
                        if (tournament.deadline != null)
                          TournamentTag(
                            label:
                                'Deadline ${tournament.deadline!.month}/${tournament.deadline!.day}',
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      tournament.description ?? 'No description has been added yet.',
                      style: const TextStyle(
                        color: Color(0xFF5C5248),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TournamentSurface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const TournamentSectionTitle(
                      title: 'Eligibility',
                      subtitle: 'Normalized divisions and classes across manual and external sources.',
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: tournament.ageDivisions
                          .map((item) => TournamentTag(label: item))
                          .toList(growable: false),
                    ),
                    if ((tournament.weightClasses ?? const []).isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: (tournament.weightClasses ?? const [])
                            .map((item) => TournamentTag(label: item))
                            .toList(growable: false),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TournamentSurface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const TournamentSectionTitle(
                      title: 'Coach Actions',
                      subtitle: 'Save, add to team schedule, and hand off registration.',
                    ),
                    const SizedBox(height: 12),
                    if (widget.teamId != null)
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          FilledButton.icon(
                            onPressed: () => _saveTournament(detail),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF8B1E3F),
                            ),
                            icon: Icon(
                              tournament.isSaved
                                  ? Icons.bookmark_added_rounded
                                  : Icons.bookmark_add_rounded,
                            ),
                            label: Text(
                              tournament.isSaved ? 'Saved for Team' : 'Save Tournament',
                            ),
                          ),
                          FilledButton.icon(
                            onPressed: () => _addToSchedule(detail),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF264653),
                            ),
                            icon: const Icon(Icons.event_available_rounded),
                            label: Text(
                              detail.scheduleEventId != null
                                  ? 'Already on Schedule'
                                  : 'Add to Schedule',
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: detail.availableRegistrationLink == null
                          ? null
                          : () => _openRegistration(detail),
                      icon: const Icon(Icons.open_in_new_rounded),
                      label: const Text('Open Registration Link'),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      detail.shareContext['team_message_preview']?.toString() ??
                          'Share preview unavailable.',
                      style: const TextStyle(
                        color: Color(0xFF655A4F),
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TournamentSurface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const TournamentSectionTitle(title: 'Contact'),
                    const SizedBox(height: 12),
                    _detailLine('Contact', tournament.contactName),
                    _detailLine('Email', tournament.contactEmail),
                    _detailLine('Phone', tournament.contactPhone),
                    _detailLine('Saved by teams', detail.relatedTeamIds.join(', ')),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _detailLine(String label, String? value) {
    if (value == null || value.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          color: Color(0xFF564C43),
          height: 1.4,
        ),
      ),
    );
  }
}
