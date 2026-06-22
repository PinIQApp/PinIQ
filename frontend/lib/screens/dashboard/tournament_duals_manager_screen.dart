import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../models/team_model.dart';
import '../../models/tournament_models.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/section_header.dart';
import '../../widgets/subpage_header.dart';

class TournamentDualsManagerScreen extends StatefulWidget {
  const TournamentDualsManagerScreen({super.key});

  @override
  State<TournamentDualsManagerScreen> createState() => _TournamentDualsManagerScreenState();
}

class _TournamentDualsManagerScreenState extends State<TournamentDualsManagerScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _opponentSearchController = TextEditingController();
  final TextEditingController _matLabelController = TextEditingController();
  Timer? _searchDebounce;

  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 1));
  String _formatType = 'dual_pool';
  bool _isLoading = true;
  bool _isSaving = false;
  bool _searchAttempted = false;
  String? _error;

  List<ManagedTournamentModel> _managedTournaments = const [];
  ManagedTournamentModel? _selectedTournament;
  List<TournamentMatModel> _mats = const [];
  List<TournamentDualMeetModel> _dualMeets = const [];
  List<TeamLookupModel> _searchResults = const [];
  final List<TeamLookupModel> _selectedOpponents = [];
  final Map<int, TeamLookupModel> _teamDirectory = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _nameController.dispose();
    _locationController.dispose();
    _opponentSearchController.dispose();
    _matLabelController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final appState = context.read<AppState>();
    final team = appState.activeTeam;
    if (team != null) {
      _teamDirectory[team.id] = TeamLookupModel(
        id: team.id,
        name: team.name,
        schoolName: team.schoolName,
        mascotName: team.mascotName,
        division: null,
      );
    }
    await _loadManagedTournaments();
  }

  Future<void> _loadManagedTournaments() async {
    final appState = context.read<AppState>();
    if (appState.token == null || appState.activeTeam == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final tournaments = await appState.api.listTeamTournaments(
        token: appState.token!,
        teamId: appState.activeTeam!.id,
      );
      final duals = tournaments.where((item) => item.eventType == 'dual_event').toList();
      ManagedTournamentModel? selected = _selectedTournament;
      if (duals.isNotEmpty) {
        selected = duals.firstWhere(
          (item) => item.id == _selectedTournament?.id,
          orElse: () => duals.first,
        );
      } else {
        selected = null;
      }
      if (!mounted) return;
      setState(() {
        _managedTournaments = duals;
        _selectedTournament = selected;
      });
      if (selected != null) {
        await _loadTournamentOps(selected.id);
      } else if (mounted) {
        setState(() {
          _mats = const [];
          _dualMeets = const [];
        });
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadTournamentOps(int tournamentId) async {
    final appState = context.read<AppState>();
    if (appState.token == null) return;

    final mats = await appState.api.listTournamentMats(
      token: appState.token!,
      tournamentId: tournamentId,
    );
    final dualMeets = await appState.api.listTournamentDualMeets(
      token: appState.token!,
      tournamentId: tournamentId,
    );

    if (!mounted) return;
    setState(() {
      _mats = mats;
      _dualMeets = dualMeets;
    });
  }

  void _queueTeamSearch(String _) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), _searchTeams);
  }

  Future<void> _searchTeams() async {
    final appState = context.read<AppState>();
    final query = _opponentSearchController.text.trim();
    if (mounted) {
      setState(() => _searchAttempted = query.length >= 2);
    }
    if (appState.token == null || query.length < 2) {
      if (mounted) {
        setState(() => _searchResults = const []);
      }
      return;
    }

    try {
      final results = await appState.api.searchTeams(token: appState.token!, query: query);
      final filtered = results.where((item) => item.id != appState.activeTeam?.id).toList();
      for (final item in filtered) {
        _teamDirectory[item.id] = item;
      }
      if (!mounted) return;
      setState(() => _searchResults = filtered);
    } catch (_) {
      if (!mounted) return;
      setState(() => _searchResults = const []);
    }
  }

  Future<void> _createDualTournament() async {
    final appState = context.read<AppState>();
    if (appState.token == null || appState.activeTeam == null) return;
    if (_nameController.text.trim().isEmpty) {
      setState(() => _error = 'Tournament name is required.');
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final teamIds = <int>{
        appState.activeTeam!.id,
        ..._selectedOpponents.map((item) => item.id),
      }.toList();

      final created = await appState.api.createManagedTournament(
        token: appState.token!,
        payload: {
          'name': _nameController.text.trim(),
          'host_team_id': appState.activeTeam!.id,
          'event_type': 'dual_event',
          'format_type': _formatType,
          'start_date': _startDate.toIso8601String().split('T').first,
          'end_date': _endDate.toIso8601String().split('T').first,
          'location': _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
          'notes': 'Created from Team Duals Manager.',
          'is_public': false,
          'divisions': const [],
          'teams': teamIds.map((teamId) => {'team_id': teamId}).toList(),
        },
      );

      if (!mounted) return;
      setState(() {
        _nameController.clear();
        _locationController.clear();
        _opponentSearchController.clear();
        _selectedOpponents.clear();
        _searchResults = const [];
        _selectedTournament = created;
      });
      await _loadManagedTournaments();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${created.name} is ready for mats and dual pairings.')),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _addTeamToSelectedTournament(TeamLookupModel team) async {
    final appState = context.read<AppState>();
    final tournament = _selectedTournament;
    if (appState.token == null || tournament == null) return;

    try {
      final updated = await appState.api.addTeamToManagedTournament(
        token: appState.token!,
        tournamentId: tournament.id,
        teamId: team.id,
      );
      if (!mounted) return;
      setState(() {
        _selectedTournament = updated;
        _managedTournaments = _managedTournaments
            .map((item) => item.id == updated.id ? updated : item)
            .toList();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${team.displayLabel} added to ${updated.name}.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _addMat() async {
    final appState = context.read<AppState>();
    final tournament = _selectedTournament;
    if (appState.token == null || tournament == null) return;
    if (_matLabelController.text.trim().isEmpty) return;

    try {
      await appState.api.createTournamentMat(
        token: appState.token!,
        tournamentId: tournament.id,
        payload: {
          'label': _matLabelController.text.trim(),
          'display_order': _mats.length + 1,
        },
      );
      _matLabelController.clear();
      await _loadTournamentOps(tournament.id);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _createDualMeet() async {
    final appState = context.read<AppState>();
    final tournament = _selectedTournament;
    if (appState.token == null || tournament == null) return;

    final teamIds = tournament.teams.map((item) => item.teamId).toList();
    if (teamIds.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least two teams to run dual pairings.')),
      );
      return;
    }

    int? teamAId = teamIds.first;
    int? teamBId = teamIds.length > 1 ? teamIds[1] : null;
    String roundLabel = 'Pool A';
    int? matId = _mats.isNotEmpty ? _mats.first.id : null;

    final shouldCreate = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              title: const Text('Create dual meet'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    initialValue: teamAId,
                    items: teamIds
                        .map(
                          (teamId) => DropdownMenuItem(
                            value: teamId,
                            child: Text(_teamName(teamId)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setLocalState(() => teamAId = value),
                    decoration: const InputDecoration(labelText: 'Team A'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<int>(
                    initialValue: teamBId,
                    items: teamIds
                        .map(
                          (teamId) => DropdownMenuItem(
                            value: teamId,
                            child: Text(_teamName(teamId)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setLocalState(() => teamBId = value),
                    decoration: const InputDecoration(labelText: 'Team B'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    initialValue: roundLabel,
                    onChanged: (value) => roundLabel = value,
                    decoration: const InputDecoration(labelText: 'Round / pool label'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<int?>(
                    initialValue: matId,
                    items: [
                      const DropdownMenuItem<int?>(value: null, child: Text('Unassigned')),
                      ..._mats.map(
                        (mat) => DropdownMenuItem<int?>(
                          value: mat.id,
                          child: Text(mat.label),
                        ),
                      ),
                    ],
                    onChanged: (value) => setLocalState(() => matId = value),
                    decoration: const InputDecoration(labelText: 'Mat'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );

    if (shouldCreate != true || teamAId == null || teamBId == null || teamAId == teamBId) {
      return;
    }

    try {
      await appState.api.createTournamentDualMeet(
        token: appState.token!,
        tournamentId: tournament.id,
        payload: {
          'team_a_id': teamAId,
          'team_b_id': teamBId,
          'round_label': roundLabel,
          'pool_name': roundLabel,
          'mat_id': matId,
          'scheduled_sequence': _dualMeets.length + 1,
          'queue_position': _dualMeets.length + 1,
        },
      );
      await _loadTournamentOps(tournament.id);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _editBout({required TournamentDualMeetModel dualMeet, TournamentDualBoutModel? bout}) async {
    final appState = context.read<AppState>();
    if (appState.token == null) return;

    final weightController = TextEditingController(text: bout?.weightClass ?? '');
    final wrestlerAController = TextEditingController(text: bout?.wrestlerAName ?? '');
    final wrestlerBController = TextEditingController(text: bout?.wrestlerBName ?? '');
    int? winnerTeamId = bout?.winnerTeamId;
    String? resultType = bout?.resultType;
    bool isComplete = bout?.isComplete ?? true;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              title: Text(bout == null ? 'Add bout result' : 'Update bout'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: weightController,
                      decoration: const InputDecoration(labelText: 'Weight class'),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: wrestlerAController,
                      decoration: InputDecoration(labelText: _teamName(dualMeet.teamAId)),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: wrestlerBController,
                      decoration: InputDecoration(labelText: _teamName(dualMeet.teamBId)),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    DropdownButtonFormField<int>(
                      initialValue: winnerTeamId,
                      items: [
                        DropdownMenuItem(value: dualMeet.teamAId, child: Text('${_teamName(dualMeet.teamAId)} wins')),
                        DropdownMenuItem(value: dualMeet.teamBId, child: Text('${_teamName(dualMeet.teamBId)} wins')),
                      ],
                      onChanged: (value) => setLocalState(() => winnerTeamId = value),
                      decoration: const InputDecoration(labelText: 'Winner'),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    DropdownButtonFormField<String>(
                      initialValue: resultType,
                      items: const [
                        DropdownMenuItem(value: 'decision', child: Text('Decision')),
                        DropdownMenuItem(value: 'major_decision', child: Text('Major decision')),
                        DropdownMenuItem(value: 'technical_fall', child: Text('Technical fall')),
                        DropdownMenuItem(value: 'fall', child: Text('Fall / pin')),
                        DropdownMenuItem(value: 'forfeit', child: Text('Forfeit')),
                        DropdownMenuItem(value: 'default', child: Text('Default')),
                        DropdownMenuItem(value: 'disqualification', child: Text('Disqualification')),
                      ],
                      onChanged: (value) => setLocalState(() => resultType = value),
                      decoration: const InputDecoration(labelText: 'Result type'),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: isComplete,
                      onChanged: (value) => setLocalState(() => isComplete = value),
                      title: const Text('Count this bout in the dual score'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(bout == null ? 'Add bout' : 'Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed != true || weightController.text.trim().isEmpty || winnerTeamId == null || resultType == null) {
      weightController.dispose();
      wrestlerAController.dispose();
      wrestlerBController.dispose();
      return;
    }

    final payload = {
      'weight_class': weightController.text.trim(),
      'wrestler_a_name': wrestlerAController.text.trim().isEmpty ? null : wrestlerAController.text.trim(),
      'wrestler_b_name': wrestlerBController.text.trim().isEmpty ? null : wrestlerBController.text.trim(),
      'winner_team_id': winnerTeamId,
      'result_type': resultType,
      'result_summary': resultType!.replaceAll('_', ' '),
      'is_complete': isComplete,
      'wrestler_a_team_id': dualMeet.teamAId,
      'wrestler_b_team_id': dualMeet.teamBId,
    };

    try {
      if (bout == null) {
        await appState.api.createTournamentDualBout(
          token: appState.token!,
          dualMeetId: dualMeet.id,
          payload: payload,
        );
      } else {
        await appState.api.updateTournamentDualBout(
          token: appState.token!,
          dualBoutId: bout.id,
          payload: payload,
        );
      }
      await _loadTournamentOps(dualMeet.tournamentId);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      weightController.dispose();
      wrestlerAController.dispose();
      wrestlerBController.dispose();
    }
  }

  String _teamName(int teamId) {
    final team = _teamDirectory[teamId];
    if (team != null) return team.schoolName;
    if (context.read<AppState>().activeTeam?.id == teamId) {
      return context.read<AppState>().activeTeam!.schoolName;
    }
    return 'Team #$teamId';
  }

  List<_DualStandingRow> _buildStandings() {
    final standings = <int, _DualStandingAccumulator>{};

    for (final dualMeet in _dualMeets) {
      standings.putIfAbsent(dualMeet.teamAId, _DualStandingAccumulator.new);
      standings.putIfAbsent(dualMeet.teamBId, _DualStandingAccumulator.new);

      final teamA = standings[dualMeet.teamAId]!;
      final teamB = standings[dualMeet.teamBId]!;

      teamA.teamId = dualMeet.teamAId;
      teamB.teamId = dualMeet.teamBId;
      teamA.teamPointsFor += dualMeet.teamAScore;
      teamA.teamPointsAgainst += dualMeet.teamBScore;
      teamB.teamPointsFor += dualMeet.teamBScore;
      teamB.teamPointsAgainst += dualMeet.teamAScore;

      if (dualMeet.status == 'completed') {
        if (dualMeet.teamAScore > dualMeet.teamBScore) {
          teamA.wins += 1;
          teamB.losses += 1;
        } else if (dualMeet.teamBScore > dualMeet.teamAScore) {
          teamB.wins += 1;
          teamA.losses += 1;
        } else {
          teamA.ties += 1;
          teamB.ties += 1;
        }
      }
    }

    final rows = standings.values
        .map(
          (item) => _DualStandingRow(
            teamId: item.teamId,
            teamName: _teamName(item.teamId),
            wins: item.wins,
            losses: item.losses,
            ties: item.ties,
            teamPointsFor: item.teamPointsFor,
            teamPointsAgainst: item.teamPointsAgainst,
          ),
        )
        .toList();

    rows.sort((a, b) {
      final winCompare = b.wins.compareTo(a.wins);
      if (winCompare != 0) return winCompare;
      final diffCompare = b.pointDifferential.compareTo(a.pointDifferential);
      if (diffCompare != 0) return diffCompare;
      return b.teamPointsFor.compareTo(a.teamPointsFor);
    });
    return rows;
  }

  Map<String, List<_DualStandingRow>> _buildPoolStandings() {
    final poolStandings = <String, Map<int, _DualStandingAccumulator>>{};

    for (final dualMeet in _dualMeets) {
      final poolKey = (dualMeet.poolName?.trim().isNotEmpty ?? false)
          ? dualMeet.poolName!.trim()
          : 'Championship';
      final standings = poolStandings.putIfAbsent(poolKey, () => <int, _DualStandingAccumulator>{});
      standings.putIfAbsent(dualMeet.teamAId, _DualStandingAccumulator.new);
      standings.putIfAbsent(dualMeet.teamBId, _DualStandingAccumulator.new);

      final teamA = standings[dualMeet.teamAId]!;
      final teamB = standings[dualMeet.teamBId]!;
      teamA.teamId = dualMeet.teamAId;
      teamB.teamId = dualMeet.teamBId;
      teamA.teamPointsFor += dualMeet.teamAScore;
      teamA.teamPointsAgainst += dualMeet.teamBScore;
      teamB.teamPointsFor += dualMeet.teamBScore;
      teamB.teamPointsAgainst += dualMeet.teamAScore;

      if (dualMeet.status == 'completed') {
        if (dualMeet.teamAScore > dualMeet.teamBScore) {
          teamA.wins += 1;
          teamB.losses += 1;
        } else if (dualMeet.teamBScore > dualMeet.teamAScore) {
          teamB.wins += 1;
          teamA.losses += 1;
        } else {
          teamA.ties += 1;
          teamB.ties += 1;
        }
      }
    }

    final normalized = <String, List<_DualStandingRow>>{};
    for (final entry in poolStandings.entries) {
      final rows = entry.value.values
          .map(
            (item) => _DualStandingRow(
              teamId: item.teamId,
              teamName: _teamName(item.teamId),
              wins: item.wins,
              losses: item.losses,
              ties: item.ties,
              teamPointsFor: item.teamPointsFor,
              teamPointsAgainst: item.teamPointsAgainst,
            ),
          )
          .toList();
      rows.sort((a, b) {
        final winCompare = b.wins.compareTo(a.wins);
        if (winCompare != 0) return winCompare;
        final diffCompare = b.pointDifferential.compareTo(a.pointDifferential);
        if (diffCompare != 0) return diffCompare;
        return b.teamPointsFor.compareTo(a.teamPointsFor);
      });
      normalized[entry.key] = rows;
    }
    return normalized;
  }

  List<_AdvancementMatchup> _buildAdvancementPreview() {
    final formatType = _selectedTournament?.formatType ?? 'dual_pool';
    final overallStandings = _buildStandings();
    final poolStandings = _buildPoolStandings();

    if (formatType == 'dual_round_robin') {
      return overallStandings.take(4).toList().asMap().entries.map((entry) {
        final row = entry.value;
        return _AdvancementMatchup(
          label: entry.key == 0 ? 'Projected champion' : 'Placement ${entry.key + 1}',
          sideA: row.teamName,
          sideB: '${row.wins}-${row.losses}${row.ties > 0 ? '-${row.ties}' : ''}',
          detail: 'Round robin finish',
        );
      }).toList();
    }

    if (formatType == 'dual_bracket') {
      final top = overallStandings.take(4).toList();
      if (top.length < 4) {
        return [];
      }
      return [
        _AdvancementMatchup(
          label: 'Semifinal 1',
          sideA: '#1 ${top[0].teamName}',
          sideB: '#4 ${top[3].teamName}',
          detail: 'Bracket seed crossover',
        ),
        _AdvancementMatchup(
          label: 'Semifinal 2',
          sideA: '#2 ${top[1].teamName}',
          sideB: '#3 ${top[2].teamName}',
          detail: 'Bracket seed crossover',
        ),
        _AdvancementMatchup(
          label: 'Championship',
          sideA: 'Winner SF1',
          sideB: 'Winner SF2',
          detail: 'Dual bracket final',
        ),
      ];
    }

    final poolNames = poolStandings.keys.toList()..sort();
    if (poolNames.length >= 2) {
      final poolA = poolStandings[poolNames[0]] ?? const <_DualStandingRow>[];
      final poolB = poolStandings[poolNames[1]] ?? const <_DualStandingRow>[];
      if (poolA.length >= 2 && poolB.length >= 2) {
        return [
          _AdvancementMatchup(
            label: 'Semifinal 1',
            sideA: '${poolNames[0]} #1 • ${poolA[0].teamName}',
            sideB: '${poolNames[1]} #2 • ${poolB[1].teamName}',
            detail: 'Pool crossover',
          ),
          _AdvancementMatchup(
            label: 'Semifinal 2',
            sideA: '${poolNames[1]} #1 • ${poolB[0].teamName}',
            sideB: '${poolNames[0]} #2 • ${poolA[1].teamName}',
            detail: 'Pool crossover',
          ),
          _AdvancementMatchup(
            label: 'Championship',
            sideA: 'Winner SF1',
            sideB: 'Winner SF2',
            detail: 'Pool champions final',
          ),
        ];
      }
    }

    if (overallStandings.length >= 2) {
      return [
        _AdvancementMatchup(
          label: 'Featured dual',
          sideA: overallStandings[0].teamName,
          sideB: overallStandings[1].teamName,
          detail: 'Top current teams',
        ),
      ];
    }
    return [];
  }

  Map<String, List<TournamentDualMeetModel>> _buildMatQueue() {
    final queues = <String, List<TournamentDualMeetModel>>{};
    for (final dualMeet in _dualMeets) {
      final matLabel = dualMeet.matId == null
          ? 'Unassigned'
          : (_mats.cast<TournamentMatModel?>().firstWhere(
                (mat) => mat?.id == dualMeet.matId,
                orElse: () => null,
              )?.label ??
              'Mat ${dualMeet.matId}');
      queues.putIfAbsent(matLabel, () => []);
      queues[matLabel]!.add(dualMeet);
    }
    for (final item in queues.values) {
      item.sort((a, b) {
        final queueCompare = (a.queuePosition ?? 9999).compareTo(b.queuePosition ?? 9999);
        if (queueCompare != 0) return queueCompare;
        return a.id.compareTo(b.id);
      });
    }
    final orderedEntries = queues.entries.toList()
      ..sort((a, b) {
        if (a.key == 'Unassigned') return 1;
        if (b.key == 'Unassigned') return -1;
        return a.key.compareTo(b.key);
      });
    return {for (final entry in orderedEntries) entry.key: entry.value};
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final activeTeam = appState.activeTeam;

    if (activeTeam == null) {
      return const Center(child: Text('Pick a team to manage team duals.'));
    }

    final assignedTeamIds = _selectedTournament?.teams.map((item) => item.teamId).toList() ?? const [];
    final standings = _buildStandings();
    final poolStandings = _buildPoolStandings();
    final advancement = _buildAdvancementPreview();
    final matQueue = _buildMatQueue();

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        const SubpageHeader(
          title: 'Team Duals',
          subtitle: 'Build dual events, assign mats, queue pairings, and score team results.',
        ),
        const SizedBox(height: AppSpacing.lg),
        if (_error != null) ...[
          _DualsPanel(
            child: Text(_error!, style: AppTextStyles.body.copyWith(color: AppColors.danger)),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        _DualsPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(title: 'Create team dual event'),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Event name'),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _locationController,
                decoration: const InputDecoration(labelText: 'Location'),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _formatType,
                      items: const [
                        DropdownMenuItem(value: 'dual_pool', child: Text('Dual pool')),
                        DropdownMenuItem(value: 'dual_bracket', child: Text('Dual bracket')),
                        DropdownMenuItem(value: 'dual_round_robin', child: Text('Dual round robin')),
                      ],
                      onChanged: (value) => setState(() => _formatType = value ?? 'dual_pool'),
                      decoration: const InputDecoration(labelText: 'Format'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          firstDate: DateTime.now().subtract(const Duration(days: 30)),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                          initialDate: _startDate,
                        );
                        if (picked != null) {
                          setState(() {
                            _startDate = picked;
                            if (_endDate.isBefore(_startDate)) _endDate = _startDate;
                          });
                        }
                      },
                      icon: const Icon(Icons.event_rounded),
                      label: Text('Start ${_startDate.month}/${_startDate.day}'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          firstDate: _startDate,
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                          initialDate: _endDate,
                        );
                        if (picked != null) {
                          setState(() => _endDate = picked);
                        }
                      },
                      icon: const Icon(Icons.event_available_rounded),
                      label: Text('End ${_endDate.month}/${_endDate.day}'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _opponentSearchController,
                      onChanged: _queueTeamSearch,
                      onSubmitted: (_) => _searchTeams(),
                      decoration: const InputDecoration(
                        labelText: 'Add opponents',
                        hintText: 'Search schools, mascots, or team names',
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  OutlinedButton.icon(
                    onPressed: _searchTeams,
                    icon: const Icon(Icons.search_rounded),
                    label: const Text('Search'),
                  ),
                ],
              ),
              if (_searchResults.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Column(
                  children: _searchResults.map((team) {
                    final selected = _selectedOpponents.any((item) => item.id == team.id);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated.withValues(alpha: 0.56),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Expanded(child: Text(team.displayLabel, style: AppTextStyles.bodyStrong)),
                            const SizedBox(width: AppSpacing.md),
                            ElevatedButton.icon(
                              onPressed: () {
                                setState(() {
                                  if (!selected) {
                                    _selectedOpponents.add(team);
                                    _teamDirectory[team.id] = team;
                                  }
                                });
                              },
                              icon: Icon(selected ? Icons.check_rounded : Icons.add_rounded),
                              label: Text(selected ? 'Added' : 'Add'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ] else if (_searchAttempted && _opponentSearchController.text.trim().length >= 2) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'No teams matched that search yet. Try the full school name, mascot, or a shorter phrase.',
                  style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                ),
              ],
              if (_selectedOpponents.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: _selectedOpponents
                      .map(
                        (team) => Chip(
                          label: Text(team.displayLabel),
                          onDeleted: () => setState(() => _selectedOpponents.remove(team)),
                        ),
                      )
                      .toList(),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _createDualTournament,
                icon: const Icon(Icons.add_circle_outline_rounded),
                label: Text(_isSaving ? 'Creating...' : 'Create dual event'),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        _DualsPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(title: 'Managed dual events'),
              const SizedBox(height: AppSpacing.md),
              if (_isLoading)
                const Text('Loading dual events...')
              else if (_managedTournaments.isEmpty)
                const Text('No team dual events yet. Create the first one above.')
              else
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: _managedTournaments.map((tournament) {
                    final selected = _selectedTournament?.id == tournament.id;
                    return ChoiceChip(
                      selected: selected,
                      label: Text(tournament.name),
                      onSelected: (_) async {
                        setState(() => _selectedTournament = tournament);
                        await _loadTournamentOps(tournament.id);
                      },
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
        if (_selectedTournament != null) ...[
          const SizedBox(height: AppSpacing.xl),
          _DualsPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(title: 'Teams in this dual event'),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: _selectedTournament!.teams
                      .map((team) => Chip(label: Text(_teamName(team.teamId))))
                      .toList(),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _opponentSearchController,
                        onChanged: _queueTeamSearch,
                        onSubmitted: (_) => _searchTeams(),
                        decoration: const InputDecoration(
                          labelText: 'Add more teams',
                          hintText: 'Search schools, mascots, or team names',
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    OutlinedButton.icon(
                      onPressed: _searchTeams,
                      icon: const Icon(Icons.search_rounded),
                      label: const Text('Search'),
                    ),
                  ],
                ),
                if (_searchResults.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Column(
                    children: _searchResults
                        .where((team) => !_selectedTournament!.teams.any((item) => item.teamId == team.id))
                        .map(
                          (team) => Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(AppSpacing.md),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceElevated.withValues(alpha: 0.56),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(team.displayLabel, style: AppTextStyles.bodyStrong),
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  ElevatedButton.icon(
                                    onPressed: () => _addTeamToSelectedTournament(team),
                                    icon: const Icon(Icons.add_rounded),
                                    label: const Text('Add team'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ] else if (_searchAttempted && _opponentSearchController.text.trim().length >= 2) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'No additional teams matched that search. Try the school name instead of a nickname.',
                    style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          _DualsPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(title: 'Standings'),
                const SizedBox(height: AppSpacing.md),
                if (standings.isEmpty)
                  const Text('Standings will populate as dual results come in.')
                else
                  if (poolStandings.length <= 1)
                    ...standings.asMap().entries.map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: _StandingRowCard(rank: entry.key + 1, row: entry.value),
                      ),
                    )
                  else
                    ...poolStandings.entries.map(
                      (poolEntry) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(poolEntry.key, style: AppTextStyles.cardTitle),
                            const SizedBox(height: AppSpacing.sm),
                            ...poolEntry.value.asMap().entries.map(
                              (entry) => Padding(
                                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                                child: _StandingRowCard(rank: entry.key + 1, row: entry.value),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          _DualsPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(title: 'Advancement board'),
                const SizedBox(height: AppSpacing.md),
                if (advancement.isEmpty)
                  Text(
                    _selectedTournament!.formatType == 'dual_bracket'
                        ? 'Complete more duals to seed the bracket board.'
                        : 'Build at least two populated pools to project advancement.',
                  )
                else
                  ...advancement.map(
                    (matchup) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _AdvancementCard(matchup: matchup),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          _DualsPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(title: '${_selectedTournament!.name} mats'),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _matLabelController,
                        decoration: const InputDecoration(labelText: 'Mat label'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    ElevatedButton(
                      onPressed: _addMat,
                      child: const Text('Add mat'),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: _mats
                      .map((mat) => Chip(label: Text('${mat.label} • ${mat.status}')))
                      .toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          _DualsPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(title: 'Mat queue'),
                const SizedBox(height: AppSpacing.md),
                if (matQueue.isEmpty)
                  const Text('Create dual meets to populate the on-deck board.')
                else
                  ...matQueue.entries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: _MatQueueCard(
                        matLabel: entry.key,
                        queue: entry.value,
                        teamName: _teamName,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          _DualsPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(title: 'Dual queue'),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        assignedTeamIds.isEmpty
                            ? 'No assigned teams yet.'
                            : 'Assigned teams: ${assignedTeamIds.map(_teamName).join(' • ')}',
                        style: AppTextStyles.body,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _createDualMeet,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Add dual'),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                if (_dualMeets.isEmpty)
                  const Text('No dual meets yet. Create one to start scoring.')
                else
                  ..._dualMeets.map(
                    (dualMeet) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: _DualMeetCard(
                        dualMeet: dualMeet,
                        teamName: _teamName,
                        onAddBout: () => _editBout(dualMeet: dualMeet),
                        onEditBout: (bout) => _editBout(dualMeet: dualMeet, bout: bout),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}

class _DualsPanel extends StatelessWidget {
  const _DualsPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

class _DualMeetCard extends StatelessWidget {
  const _DualMeetCard({
    required this.dualMeet,
    required this.teamName,
    required this.onAddBout,
    required this.onEditBout,
  });

  final TournamentDualMeetModel dualMeet;
  final String Function(int teamId) teamName;
  final VoidCallback onAddBout;
  final ValueChanged<TournamentDualBoutModel> onEditBout;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${teamName(dualMeet.teamAId)} ${dualMeet.teamAScore} • ${dualMeet.teamBScore} ${teamName(dualMeet.teamBId)}',
                  style: AppTextStyles.cardTitle,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                dualMeet.roundLabel ?? dualMeet.poolName ?? dualMeet.status,
                style: AppTextStyles.caption,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Queue ${dualMeet.queuePosition ?? '-'} • ${dualMeet.status.replaceAll('_', ' ')}',
            style: AppTextStyles.body,
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              OutlinedButton.icon(
                onPressed: onAddBout,
                icon: const Icon(Icons.sports_mma_rounded),
                label: const Text('Add bout'),
              ),
            ],
          ),
          if (dualMeet.bouts.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            ...dualMeet.bouts.map(
              (bout) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('${bout.weightClass} • ${bout.resultType ?? 'pending'}'),
                subtitle: Text(
                  '${bout.wrestlerAName ?? 'Team A'} vs ${bout.wrestlerBName ?? 'Team B'}',
                ),
                trailing: IconButton(
                  onPressed: () => onEditBout(bout),
                  icon: const Icon(Icons.edit_outlined),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DualStandingAccumulator {
  _DualStandingAccumulator();

  int teamId = 0;
  int wins = 0;
  int losses = 0;
  int ties = 0;
  int teamPointsFor = 0;
  int teamPointsAgainst = 0;
}

class _DualStandingRow {
  const _DualStandingRow({
    required this.teamId,
    required this.teamName,
    required this.wins,
    required this.losses,
    required this.ties,
    required this.teamPointsFor,
    required this.teamPointsAgainst,
  });

  final int teamId;
  final String teamName;
  final int wins;
  final int losses;
  final int ties;
  final int teamPointsFor;
  final int teamPointsAgainst;

  int get dualPoints => (wins * 2) + ties;
  int get pointDifferential => teamPointsFor - teamPointsAgainst;
}

class _StandingRowCard extends StatelessWidget {
  const _StandingRowCard({
    required this.rank,
    required this.row,
  });

  final int rank;
  final _DualStandingRow row;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: Text('#$rank', style: AppTextStyles.caption),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(row.teamName, style: AppTextStyles.cardTitle),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  '${row.wins}-${row.losses}${row.ties > 0 ? '-${row.ties}' : ''} • '
                  '${row.teamPointsFor} PF / ${row.teamPointsAgainst} PA',
                  style: AppTextStyles.body,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Text('${row.dualPoints} pts', style: AppTextStyles.sectionTitle),
        ],
      ),
    );
  }
}

class _MatQueueCard extends StatelessWidget {
  const _MatQueueCard({
    required this.matLabel,
    required this.queue,
    required this.teamName,
  });

  final String matLabel;
  final List<TournamentDualMeetModel> queue;
  final String Function(int teamId) teamName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(matLabel, style: AppTextStyles.cardTitle),
          const SizedBox(height: AppSpacing.md),
          ...queue.asMap().entries.map((entry) {
            final dualMeet = entry.value;
            final lane = entry.key == 0
                ? 'Now wrestling'
                : entry.key == 1
                    ? 'On deck'
                    : 'Queue ${entry.key + 1}';
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 90,
                    child: Text(lane, style: AppTextStyles.caption),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      '${teamName(dualMeet.teamAId)} vs ${teamName(dualMeet.teamBId)}'
                      '${dualMeet.roundLabel == null ? '' : ' • ${dualMeet.roundLabel}'}',
                      style: AppTextStyles.body,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    '${dualMeet.teamAScore}-${dualMeet.teamBScore}',
                    style: AppTextStyles.cardTitle,
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _AdvancementMatchup {
  const _AdvancementMatchup({
    required this.label,
    required this.sideA,
    required this.sideB,
    required this.detail,
  });

  final String label;
  final String sideA;
  final String sideB;
  final String detail;
}

class _AdvancementCard extends StatelessWidget {
  const _AdvancementCard({required this.matchup});

  final _AdvancementMatchup matchup;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(matchup.label, style: AppTextStyles.caption),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(matchup.sideA, style: AppTextStyles.cardTitle),
                const SizedBox(height: AppSpacing.xxs),
                Text('vs', style: AppTextStyles.caption),
                const SizedBox(height: AppSpacing.xxs),
                Text(matchup.sideB, style: AppTextStyles.cardTitle),
                const SizedBox(height: AppSpacing.xxs),
                Text(matchup.detail, style: AppTextStyles.body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
