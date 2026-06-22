import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../models/team_model.dart';
import '../../models/team_member_model.dart';
import '../../models/tournament_models.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/section_header.dart';
import '../../widgets/subpage_header.dart';

class TournamentEventStudioScreen extends StatefulWidget {
  const TournamentEventStudioScreen({super.key});

  @override
  State<TournamentEventStudioScreen> createState() =>
      _TournamentEventStudioScreenState();
}

class _TournamentEventStudioScreenState
    extends State<TournamentEventStudioScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _teamSearchController = TextEditingController();
  final TextEditingController _divisionController =
      TextEditingController(text: 'Varsity');
  final TextEditingController _weightClassController = TextEditingController();
  final TextEditingController _newWeightClassController =
      TextEditingController();
  final TextEditingController _matLabelController = TextEditingController();

  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 1));
  String _eliminationStyle = 'single_elimination';
  int _bracketSize = 16;
  bool _isSaving = false;
  bool _isLoading = true;
  String? _error;
  List<ManagedTournamentModel> _managedTournaments = const [];
  ManagedTournamentModel? _selectedTournament;
  List<TeamLookupModel> _teamSearchResults = const [];
  List<TournamentEntryModel> _entries = const [];
  List<TournamentMatModel> _mats = const [];
  final Map<String, List<SeedScoreModel>> _seedCache = {};
  final Map<String, TournamentBracketModel> _bracketCache = {};
  final Map<int, TeamLookupModel> _teamDirectory = {};
  final Set<String> _manualWeightClasses = {};
  int? _selectedAthleteId;
  bool _teamSearchAttempted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _loadManagedTournaments());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _teamSearchController.dispose();
    _divisionController.dispose();
    _weightClassController.dispose();
    _newWeightClassController.dispose();
    _matLabelController.dispose();
    super.dispose();
  }

  List<TeamMemberModel> _approvedAthletes(AppState appState) {
    return (appState.activeTeam?.members ?? const [])
        .where((member) =>
            member.status == 'approved' && member.user.role == 'athlete')
        .toList();
  }

  Future<void> _loadManagedTournaments() async {
    final appState = context.read<AppState>();
    final team = appState.activeTeam;
    if (appState.token == null || team == null) return;
    _teamDirectory[team.id] = TeamLookupModel(
      id: team.id,
      name: team.name,
      schoolName: team.schoolName,
      mascotName: team.mascotName,
      division: null,
    );

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final tournaments = await appState.api.listTeamTournaments(
        token: appState.token!,
        teamId: team.id,
      );
      final managed = tournaments
          .where((item) => item.eventType != 'dual_event')
          .toList()
        ..sort((a, b) => b.startDate.compareTo(a.startDate));

      ManagedTournamentModel? selected = _selectedTournament;
      if (managed.isNotEmpty) {
        selected = managed.firstWhere(
          (item) => item.id == _selectedTournament?.id,
          orElse: () => managed.first,
        );
      } else {
        selected = null;
      }

      if (!mounted) return;
      setState(() {
        _managedTournaments = managed;
        _selectedTournament = selected;
      });
      await _loadEntries();
      await _loadMats();
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadEntries() async {
    final appState = context.read<AppState>();
    final tournament = _selectedTournament;
    if (appState.token == null || tournament == null) {
      if (mounted) {
        setState(() => _entries = const []);
      }
      return;
    }

    try {
      final entries = await appState.api.listTournamentEntries(
        token: appState.token!,
        tournamentId: tournament.id,
      );
      if (!mounted) return;
      setState(() {
        _entries = entries;
        _seedCache.clear();
        _bracketCache.clear();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _entries = const []);
    }
  }

  Future<void> _loadMats() async {
    final appState = context.read<AppState>();
    final tournament = _selectedTournament;
    if (appState.token == null || tournament == null) {
      if (mounted) {
        setState(() => _mats = const []);
      }
      return;
    }

    try {
      final mats = await appState.api.listTournamentMats(
        token: appState.token!,
        tournamentId: tournament.id,
      );
      if (!mounted) return;
      setState(() => _mats = mats);
    } catch (_) {
      if (!mounted) return;
      setState(() => _mats = const []);
    }
  }

  Future<void> _searchTeams(String value) async {
    final appState = context.read<AppState>();
    setState(() => _teamSearchAttempted = value.trim().length >= 2);
    if (appState.token == null || value.trim().length < 2) {
      setState(() => _teamSearchResults = const []);
      return;
    }

    try {
      final results = await appState.api.searchTeams(
        token: appState.token!,
        query: value.trim(),
      );
      for (final result in results) {
        _teamDirectory[result.id] = result;
      }
      if (!mounted) return;
      setState(() => _teamSearchResults = results);
    } catch (_) {
      if (!mounted) return;
      setState(() => _teamSearchResults = const []);
    }
  }

  Map<String, List<TournamentEntryModel>> _groupedEntries() {
    final grouped = <String, List<TournamentEntryModel>>{};
    for (final entry in _entries) {
      grouped.putIfAbsent(entry.weightClass, () => []);
      grouped[entry.weightClass]!.add(entry);
    }
    final ordered = grouped.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return {for (final entry in ordered) entry.key: entry.value};
  }

  List<String> _weightClasses() {
    final classes = {
      ..._manualWeightClasses,
      ..._entries
          .map((entry) => entry.weightClass.trim())
          .where((value) => value.isNotEmpty),
    }.toList()
      ..sort((a, b) => a.compareTo(b));
    return classes;
  }

  void _addWeightClassDraft() {
    final value = _newWeightClassController.text.trim();
    if (value.isEmpty) {
      setState(() => _error = 'Enter a weight class before adding it.');
      return;
    }
    setState(() {
      _manualWeightClasses.add(value);
      _weightClassController.text = value;
      _newWeightClassController.clear();
      _error = null;
    });
  }

  Future<void> _addMat() async {
    final appState = context.read<AppState>();
    final tournament = _selectedTournament;
    if (appState.token == null || tournament == null) return;
    final label = _matLabelController.text.trim();
    if (label.isEmpty) {
      setState(() => _error = 'Enter a mat label before adding it.');
      return;
    }

    try {
      await appState.api.createTournamentMat(
        token: appState.token!,
        tournamentId: tournament.id,
        payload: {
          'label': label,
          'display_order': _mats.length + 1,
        },
      );
      _matLabelController.clear();
      await _loadMats();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mat added to the tournament.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _createTournament() async {
    final appState = context.read<AppState>();
    final team = appState.activeTeam;
    if (appState.token == null || team == null) return;
    if (_nameController.text.trim().isEmpty) {
      setState(() => _error = 'Tournament name is required.');
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final created = await appState.api.createManagedTournament(
        token: appState.token!,
        payload: {
          'name': _nameController.text.trim(),
          'host_team_id': team.id,
          'event_type': 'bracket_style_event',
          'format_type': 'single_elimination',
          'elimination_style': _eliminationStyle,
          'bracket_size': _bracketSize,
          'start_date': _startDate.toIso8601String().split('T').first,
          'end_date': _endDate.toIso8601String().split('T').first,
          'location': _locationController.text.trim().isEmpty
              ? null
              : _locationController.text.trim(),
          'notes': 'Created from Tournament Event Studio.',
          'is_public': false,
          'divisions': const [],
          'teams': [
            {'team_id': team.id},
          ],
        },
      );
      if (!mounted) return;
      setState(() {
        _nameController.clear();
        _locationController.clear();
        _eliminationStyle = 'single_elimination';
        _bracketSize = 16;
        _managedTournaments = [created, ..._managedTournaments];
        _selectedTournament = created;
      });
      await _loadEntries();
      await _loadMats();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('${created.name} is ready for teams and entries.')),
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

  Future<void> _addTeamToTournament(TeamLookupModel team) async {
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
        SnackBar(
            content: Text('${team.displayLabel} linked to ${updated.name}.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _addEntry() async {
    final appState = context.read<AppState>();
    final tournament = _selectedTournament;
    final team = appState.activeTeam;
    if (appState.token == null || tournament == null || team == null) return;
    if (_selectedAthleteId == null ||
        _weightClassController.text.trim().isEmpty) {
      setState(() =>
          _error = 'Pick an athlete and weight class to create an entry.');
      return;
    }

    try {
      final entry = await appState.api.createTournamentEntry(
        token: appState.token!,
        tournamentId: tournament.id,
        payload: {
          'team_id': team.id,
          'athlete_id': _selectedAthleteId,
          'division_name': _divisionController.text.trim().isEmpty
              ? 'Varsity'
              : _divisionController.text.trim(),
          'weight_class': _weightClassController.text.trim(),
          'entry_status': 'entered',
        },
      );
      if (!mounted) return;
      setState(() {
        _entries = [entry, ..._entries];
        _manualWeightClasses.add(entry.weightClass);
        _seedCache.remove(entry.weightClass);
        _bracketCache.remove(entry.weightClass);
        _weightClassController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Athlete entry added to the tournament.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _scratchEntry(TournamentEntryModel entry) async {
    final appState = context.read<AppState>();
    if (appState.token == null) return;
    try {
      await appState.api.updateTournamentEntry(
        token: appState.token!,
        entryId: entry.id,
        payload: {'entry_status': 'scratched'},
      );
      await _loadEntries();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                '${_athleteName(appState, entry.athleteId)} was scratched.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _moveEntryToWeightClass(TournamentEntryModel entry) async {
    final appState = context.read<AppState>();
    if (appState.token == null) return;
    final options =
        _weightClasses().where((value) => value != entry.weightClass).toList();
    String selectedWeightClass = options.isNotEmpty ? options.first : '';
    final customController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Move wrestler'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Move ${_athleteName(appState, entry.athleteId)} from ${entry.weightClass} to another class.',
                style:
                    AppTextStyles.body.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.md),
              if (options.isNotEmpty)
                StatefulBuilder(
                  builder: (context, setDialogState) {
                    return DropdownButtonFormField<String>(
                      initialValue: selectedWeightClass.isEmpty
                          ? null
                          : selectedWeightClass,
                      decoration:
                          const InputDecoration(labelText: 'Existing class'),
                      items: options
                          .map(
                            (weightClass) => DropdownMenuItem<String>(
                              value: weightClass,
                              child: Text(weightClass),
                            ),
                          )
                          .toList(),
                      onChanged: (value) => setDialogState(
                          () => selectedWeightClass = value ?? ''),
                    );
                  },
                ),
              if (options.isNotEmpty) const SizedBox(height: AppSpacing.md),
              TextField(
                controller: customController,
                decoration: const InputDecoration(
                  labelText: 'Or enter a new class',
                  hintText: '120, 126, 132...',
                ),
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
              child: const Text('Move wrestler'),
            ),
          ],
        );
      },
    );
    final nextClass = customController.text.trim().isEmpty
        ? selectedWeightClass.trim()
        : customController.text.trim();
    customController.dispose();
    if (confirmed != true || nextClass.isEmpty) return;

    try {
      await appState.api.updateTournamentEntry(
        token: appState.token!,
        entryId: entry.id,
        payload: {'weight_class': nextClass},
      );
      if (!mounted) return;
      setState(() => _manualWeightClasses.add(nextClass));
      await _loadEntries();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                '${_athleteName(appState, entry.athleteId)} moved to $nextClass.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _calculateSeedsForWeightClass(String weightClass) async {
    final appState = context.read<AppState>();
    final tournament = _selectedTournament;
    if (appState.token == null || tournament == null) return;

    try {
      final results = await appState.api.calculateTournamentSeeds(
        token: appState.token!,
        tournamentId: tournament.id,
      );
      if (!mounted) return;
      setState(() {
        _seedCache[weightClass] =
            results.where((item) => item.weightClass == weightClass).toList();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Seeds recalculated for $weightClass.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  String _bracketTypeForTournament() {
    final size = _selectedTournament?.bracketSize ?? 16;
    if (size <= 4) return '4_man';
    if (size <= 8) return '8_man';
    if (size <= 16) return '16_man';
    return '32_man';
  }

  Future<void> _buildBracketForWeightClass(
      String weightClass, List<TournamentEntryModel> entries) async {
    final appState = context.read<AppState>();
    final tournament = _selectedTournament;
    if (appState.token == null || tournament == null || entries.isEmpty) return;

    try {
      if (!_seedCache.containsKey(weightClass) ||
          _seedCache[weightClass]!.isEmpty) {
        final results = await appState.api.calculateTournamentSeeds(
          token: appState.token!,
          tournamentId: tournament.id,
        );
        _seedCache[weightClass] =
            results.where((item) => item.weightClass == weightClass).toList();
      }
      final bracket = await appState.api.generateTournamentBracket(
        token: appState.token!,
        tournamentId: tournament.id,
        weightClass: weightClass,
        payload: {
          'division_name': entries.first.divisionName,
          'bracket_type': _bracketTypeForTournament(),
          'finalize_now': true,
          'publish_now': false,
        },
      );
      if (!mounted) return;
      setState(() => _bracketCache[weightClass] = bracket);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bracket built for $weightClass.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<TournamentBracketModel?> _recordBracketWinner({
    required String weightClass,
    required TournamentBracketMatchModel match,
    required int winnerEntryId,
    required String winType,
  }) async {
    final appState = context.read<AppState>();
    final tournament = _selectedTournament;
    if (appState.token == null || tournament == null) return null;

    final winnerName = _athleteName(appState, winnerEntryId);
    try {
      await appState.api.updateTournamentBracketMatch(
        token: appState.token!,
        matchId: match.id,
        payload: {
          'winner_entry_id': winnerEntryId,
          'match_status': 'completed',
          'result_summary': '$winnerName by $winType',
        },
      );
      final refreshed = await appState.api.getTournamentBracket(
        token: appState.token!,
        tournamentId: tournament.id,
        weightClass: weightClass,
      );
      if (!mounted) return null;
      setState(() => _bracketCache[weightClass] = refreshed);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$winnerName advanced in $weightClass.')),
      );
      return refreshed;
    } catch (error) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
      return null;
    }
  }

  String _formatLabel(ManagedTournamentModel tournament) {
    final style = switch (tournament.eliminationStyle) {
      'double_elimination' => 'Double elimination',
      'single_elimination' => 'Single elimination',
      _ => 'Bracket event',
    };
    final size = tournament.bracketSize == null
        ? ''
        : ' • ${tournament.bracketSize}-man';
    return '$style$size';
  }

  String _athleteName(AppState appState, int athleteId) {
    final athlete =
        _approvedAthletes(appState).cast<TeamMemberModel?>().firstWhere(
              (member) => member?.user.id == athleteId,
              orElse: () => null,
            );
    return athlete?.user.fullName ?? 'Athlete #$athleteId';
  }

  String _teamLabel(TeamLookupModel? team) =>
      team == null ? 'Team' : team.displayLabel;

  Map<int, List<TournamentBracketMatchModel>> _groupBracketMatches(
      TournamentBracketModel bracket) {
    final rounds = <int, List<TournamentBracketMatchModel>>{};
    for (final match in bracket.matches) {
      rounds.putIfAbsent(match.roundNumber, () => []);
      rounds[match.roundNumber]!.add(match);
    }
    for (final matches in rounds.values) {
      matches.sort((a, b) => a.matchupOrder.compareTo(b.matchupOrder));
    }
    final orderedKeys = rounds.keys.toList()..sort();
    return {for (final key in orderedKeys) key: rounds[key]!};
  }

  Future<void> _openBracketBoard({
    required String weightClass,
    required TournamentBracketModel bracket,
  }) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return _BracketBoardDialog(
          weightClass: weightClass,
          initialBracket: bracket,
          mats: _mats,
          athleteName: (athleteId) =>
              _athleteName(this.context.read<AppState>(), athleteId),
          onRecordWinner: ({
            required TournamentBracketMatchModel match,
            required int winnerEntryId,
            required String winType,
          }) {
            return _recordBracketWinner(
              weightClass: weightClass,
              match: match,
              winnerEntryId: winnerEntryId,
              winType: winType,
            );
          },
          onAssignMat: ({
            required TournamentBracketMatchModel match,
            required String matLabel,
          }) async {
            final appState = this.context.read<AppState>();
            final tournament = _selectedTournament;
            if (appState.token == null || tournament == null) return null;
            try {
              await appState.api.updateTournamentBracketMatch(
                token: appState.token!,
                matchId: match.id,
                payload: {
                  'mat_label': matLabel,
                  'match_status': match.matchStatus,
                },
              );
              final refreshed = await appState.api.getTournamentBracket(
                token: appState.token!,
                tournamentId: tournament.id,
                weightClass: weightClass,
              );
              if (mounted) {
                setState(() => _bracketCache[weightClass] = refreshed);
              }
              return refreshed;
            } catch (_) {
              return null;
            }
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final athletes = _approvedAthletes(appState);
    final groupedEntries = _groupedEntries();
    final weightClasses = _weightClasses();

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        const SubpageHeader(
          title: 'Create Tournament',
          subtitle:
              'Set up bracket events, link teams, and add real athlete entries instead of stopping at setup.',
        ),
        const SizedBox(height: AppSpacing.lg),
        if (_error != null) ...[
          _StudioPanel(
            child: Text(_error!,
                style: AppTextStyles.body.copyWith(color: AppColors.danger)),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        _StudioPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(title: 'Create bracket tournament'),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Tournament name'),
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
                      initialValue: _eliminationStyle,
                      decoration:
                          const InputDecoration(labelText: 'Elimination style'),
                      items: const [
                        DropdownMenuItem(
                            value: 'single_elimination',
                            child: Text('Single elimination')),
                        DropdownMenuItem(
                            value: 'double_elimination',
                            child: Text('Double elimination')),
                      ],
                      onChanged: (value) => setState(() =>
                          _eliminationStyle = value ?? 'single_elimination'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: _bracketSize,
                      decoration:
                          const InputDecoration(labelText: 'Bracket size'),
                      items: const [
                        DropdownMenuItem(value: 8, child: Text('8-man')),
                        DropdownMenuItem(value: 16, child: Text('16-man')),
                        DropdownMenuItem(value: 24, child: Text('24-man')),
                        DropdownMenuItem(value: 32, child: Text('32-man')),
                      ],
                      onChanged: (value) =>
                          setState(() => _bracketSize = value ?? 16),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          firstDate:
                              DateTime.now().subtract(const Duration(days: 60)),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
                          initialDate: _startDate,
                        );
                        if (picked != null) {
                          setState(() {
                            _startDate = picked;
                            if (_endDate.isBefore(_startDate)) {
                              _endDate = _startDate;
                            }
                          });
                        }
                      },
                      icon: const Icon(Icons.event_rounded),
                      label:
                          Text('Start ${_startDate.month}/${_startDate.day}'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          firstDate: _startDate,
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
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
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _createTournament,
                icon: const Icon(Icons.add_circle_outline_rounded),
                label: Text(_isSaving ? 'Creating...' : 'Create tournament'),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        _StudioPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(title: 'Managed tournaments'),
              const SizedBox(height: AppSpacing.md),
              if (_isLoading)
                const Text('Loading tournaments...')
              else if (_managedTournaments.isEmpty)
                const Text(
                    'No bracket tournaments yet. Create the first one above.')
              else
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: _managedTournaments
                      .map(
                        (tournament) => ChoiceChip(
                          selected: _selectedTournament?.id == tournament.id,
                          label: Text(tournament.name),
                          onSelected: (_) async {
                            setState(() => _selectedTournament = tournament);
                            await _loadEntries();
                            await _loadMats();
                          },
                        ),
                      )
                      .toList(),
                ),
            ],
          ),
        ),
        if (_selectedTournament != null) ...[
          const SizedBox(height: AppSpacing.xl),
          _StudioPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_selectedTournament!.name,
                    style: AppTextStyles.sectionTitle),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  _formatLabel(_selectedTournament!),
                  style: AppTextStyles.body
                      .copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.md),
                const SectionHeader(title: 'Teams in this tournament'),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: _selectedTournament!.teams.map((team) {
                    final match = _teamDirectory[team.teamId];
                    return _TournamentMetaChip(
                      label: _teamLabel(match) == 'Team'
                          ? 'Team ${team.teamId}'
                          : _teamLabel(match),
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _teamSearchController,
                        onChanged: _searchTeams,
                        onSubmitted: _searchTeams,
                        decoration: const InputDecoration(
                          labelText: 'Add teams',
                          hintText: 'Search schools, mascots, or team names',
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    OutlinedButton.icon(
                      onPressed: () => _searchTeams(_teamSearchController.text),
                      icon: const Icon(Icons.search_rounded),
                      label: const Text('Search'),
                    ),
                  ],
                ),
                if (_teamSearchResults.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Column(
                    children: _teamSearchResults
                        .where(
                          (team) => !_selectedTournament!.teams
                              .any((item) => item.teamId == team.id),
                        )
                        .map(
                          (team) => Padding(
                            padding:
                                const EdgeInsets.only(bottom: AppSpacing.sm),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(AppSpacing.md),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceElevated
                                    .withValues(alpha: 0.56),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(team.displayLabel,
                                        style: AppTextStyles.bodyStrong),
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  ElevatedButton.icon(
                                    onPressed: () => _addTeamToTournament(team),
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
                ] else if (_teamSearchAttempted &&
                    _teamSearchController.text.trim().length >= 2) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'No teams matched that search yet. Try a school name, mascot, or shorter phrase.',
                    style: AppTextStyles.body
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          _StudioPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(title: 'Tournament mats'),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _matLabelController,
                        decoration: const InputDecoration(
                          labelText: 'Add mat',
                          hintText: 'Mat 1, Mat 2, Finals...',
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    ElevatedButton.icon(
                      onPressed: _addMat,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Add mat'),
                    ),
                  ],
                ),
                if (_mats.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: _mats
                        .map((mat) => _TournamentMetaChip(label: mat.label))
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          _StudioPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(title: 'Weight class board'),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _newWeightClassController,
                        decoration: const InputDecoration(
                          labelText: 'Add weight class',
                          hintText: '106, 113, 120, 126...',
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    ElevatedButton.icon(
                      onPressed: _addWeightClassDraft,
                      icon: const Icon(Icons.playlist_add_rounded),
                      label: const Text('Add class'),
                    ),
                  ],
                ),
                if (weightClasses.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: weightClasses
                        .map(
                          (weightClass) => ActionChip(
                            label: Text(weightClass),
                            onPressed: () => setState(() =>
                                _weightClassController.text = weightClass),
                          ),
                        )
                        .toList(),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                const SectionHeader(title: 'Add athlete entry'),
                const SizedBox(height: AppSpacing.md),
                if (athletes.isEmpty)
                  const Text('No approved athletes are on the active team yet.')
                else ...[
                  DropdownButtonFormField<int>(
                    initialValue: _selectedAthleteId,
                    decoration: const InputDecoration(labelText: 'Athlete'),
                    items: athletes
                        .map(
                          (member) => DropdownMenuItem<int>(
                            value: member.user.id,
                            child: Text(member.user.fullName),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _selectedAthleteId = value),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _divisionController,
                          decoration:
                              const InputDecoration(labelText: 'Division'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: weightClasses.isEmpty
                            ? TextField(
                                controller: _weightClassController,
                                decoration: const InputDecoration(
                                    labelText: 'Weight class'),
                              )
                            : DropdownButtonFormField<String>(
                                initialValue: weightClasses.contains(
                                        _weightClassController.text.trim())
                                    ? _weightClassController.text.trim()
                                    : null,
                                decoration: const InputDecoration(
                                    labelText: 'Weight class'),
                                items: weightClasses
                                    .map(
                                      (weightClass) => DropdownMenuItem<String>(
                                        value: weightClass,
                                        child: Text(weightClass),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) => setState(() =>
                                    _weightClassController.text = value ?? ''),
                              ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ElevatedButton.icon(
                    onPressed: _addEntry,
                    icon: const Icon(Icons.person_add_alt_1_rounded),
                    label: const Text('Add entry'),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                const SectionHeader(title: 'Weight classes + entries'),
                const SizedBox(height: AppSpacing.sm),
                if (weightClasses.isEmpty)
                  const Text(
                      'No weight classes yet. Add one above, then add wrestlers into it.')
                else
                  Column(
                    children: weightClasses.map((weightClass) {
                      final entriesForClass = groupedEntries[weightClass] ??
                          const <TournamentEntryModel>[];
                      final seeds =
                          _seedCache[weightClass] ?? const <SeedScoreModel>[];
                      final bracket = _bracketCache[weightClass];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceElevated
                                .withValues(alpha: 0.58),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(weightClass,
                                        style: AppTextStyles.cardTitle),
                                  ),
                                  _TournamentMetaChip(
                                      label:
                                          '${entriesForClass.length} wrestlers'),
                                  if ((_selectedTournament?.bracketSize ?? 0) ==
                                      24)
                                    const Padding(
                                      padding:
                                          EdgeInsets.only(left: AppSpacing.sm),
                                      child: _TournamentMetaChip(
                                          label: '24-man uses 32-man shell'),
                                    ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              if (entriesForClass.isEmpty)
                                Text(
                                  'No wrestlers added yet. Pick this class above and add entries to build the bracket.',
                                  style: AppTextStyles.body
                                      .copyWith(color: AppColors.textSecondary),
                                )
                              else
                                ...entriesForClass.map(
                                  (entry) => Padding(
                                    padding: const EdgeInsets.only(
                                        bottom: AppSpacing.sm),
                                    child: Container(
                                      padding:
                                          const EdgeInsets.all(AppSpacing.sm),
                                      decoration: BoxDecoration(
                                        color: AppColors.surface
                                            .withValues(alpha: 0.44),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  _athleteName(appState,
                                                      entry.athleteId),
                                                  style:
                                                      AppTextStyles.bodyStrong,
                                                ),
                                                const SizedBox(
                                                    height: AppSpacing.xxs),
                                                Text(
                                                  '${entry.divisionName} • ${entry.entryStatus}',
                                                  style: AppTextStyles.caption
                                                      .copyWith(
                                                    color:
                                                        AppColors.textSecondary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          PopupMenuButton<String>(
                                            color: AppColors.surfaceElevated,
                                            onSelected: (value) {
                                              if (value == 'move') {
                                                _moveEntryToWeightClass(entry);
                                              } else if (value == 'scratch') {
                                                _scratchEntry(entry);
                                              }
                                            },
                                            itemBuilder: (context) => const [
                                              PopupMenuItem(
                                                value: 'move',
                                                child:
                                                    Text('Move weight class'),
                                              ),
                                              PopupMenuItem(
                                                value: 'scratch',
                                                child: Text('Scratch wrestler'),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              const SizedBox(height: AppSpacing.md),
                              Wrap(
                                spacing: AppSpacing.sm,
                                runSpacing: AppSpacing.sm,
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: entriesForClass.isEmpty
                                        ? null
                                        : () => _calculateSeedsForWeightClass(
                                            weightClass),
                                    icon: const Icon(Icons.auto_graph_rounded),
                                    label: const Text('Calculate seeds'),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: entriesForClass.isEmpty
                                        ? null
                                        : () => _buildBracketForWeightClass(
                                            weightClass, entriesForClass),
                                    icon:
                                        const Icon(Icons.account_tree_rounded),
                                    label: const Text('Build bracket'),
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: () => setState(() =>
                                        _weightClassController.text =
                                            weightClass),
                                    icon: const Icon(
                                        Icons.person_add_alt_1_rounded),
                                    label: const Text('Add wrestler'),
                                  ),
                                ],
                              ),
                              if (seeds.isNotEmpty) ...[
                                const SizedBox(height: AppSpacing.md),
                                Text('Seeds', style: AppTextStyles.bodyStrong),
                                const SizedBox(height: AppSpacing.xs),
                                ...seeds.map(
                                  (seed) => Padding(
                                    padding: const EdgeInsets.only(
                                        bottom: AppSpacing.xxs),
                                    child: Text(
                                      '#${seed.seedNumber} • ${_athleteName(appState, seed.athleteId)}',
                                      style: AppTextStyles.body.copyWith(
                                          color: AppColors.textSecondary),
                                    ),
                                  ),
                                ),
                              ],
                              if (bracket != null) ...[
                                const SizedBox(height: AppSpacing.md),
                                Text('Bracket board',
                                    style: AppTextStyles.bodyStrong),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  '${bracket.bracketType} • ${bracket.bracketSize}-man • ${bracket.status} • open this class in its own board to run the bracket cleanly',
                                  style: AppTextStyles.body
                                      .copyWith(color: AppColors.textSecondary),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Wrap(
                                  spacing: AppSpacing.sm,
                                  runSpacing: AppSpacing.sm,
                                  children: [
                                    _TournamentMetaChip(
                                        label:
                                            '${_groupBracketMatches(bracket).length} rounds'),
                                    _TournamentMetaChip(
                                        label:
                                            '${bracket.matches.length} matches'),
                                    ElevatedButton.icon(
                                      onPressed: () => _openBracketBoard(
                                          weightClass: weightClass,
                                          bracket: bracket),
                                      icon: const Icon(
                                          Icons.open_in_full_rounded),
                                      label: const Text('Open bracket board'),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _StudioPanel extends StatelessWidget {
  const _StudioPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.76),
        borderRadius: BorderRadius.circular(22),
      ),
      child: child,
    );
  }
}

class _TournamentMetaChip extends StatelessWidget {
  const _TournamentMetaChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label,
          style: AppTextStyles.caption.copyWith(color: AppColors.textPrimary)),
    );
  }
}

class _BracketBoardDialog extends StatefulWidget {
  const _BracketBoardDialog({
    required this.weightClass,
    required this.initialBracket,
    required this.mats,
    required this.athleteName,
    required this.onRecordWinner,
    required this.onAssignMat,
  });

  final String weightClass;
  final TournamentBracketModel initialBracket;
  final List<TournamentMatModel> mats;
  final String Function(int athleteId) athleteName;
  final Future<TournamentBracketModel?> Function({
    required TournamentBracketMatchModel match,
    required int winnerEntryId,
    required String winType,
  }) onRecordWinner;
  final Future<TournamentBracketModel?> Function({
    required TournamentBracketMatchModel match,
    required String matLabel,
  }) onAssignMat;

  @override
  State<_BracketBoardDialog> createState() => _BracketBoardDialogState();
}

class _BracketBoardDialogState extends State<_BracketBoardDialog> {
  late TournamentBracketModel _bracket;
  String _matFilter = 'All mats';
  bool _publicDisplay = false;

  @override
  void initState() {
    super.initState();
    _bracket = widget.initialBracket;
  }

  Map<int, List<TournamentBracketMatchModel>> _groupMatches() {
    final rounds = <int, List<TournamentBracketMatchModel>>{};
    for (final match in _bracket.matches) {
      rounds.putIfAbsent(match.roundNumber, () => []);
      rounds[match.roundNumber]!.add(match);
    }
    for (final matches in rounds.values) {
      matches.sort((a, b) => a.matchupOrder.compareTo(b.matchupOrder));
    }
    final keys = rounds.keys.toList()..sort();
    return {for (final key in keys) key: rounds[key]!};
  }

  String _roundLabel(int roundNumber) {
    final lastRound = _bracket.matches.fold<int>(
        1,
        (value, match) =>
            match.roundNumber > value ? match.roundNumber : value);
    if (roundNumber == lastRound) return 'Championship';
    if (roundNumber == lastRound - 1) return 'Semifinals';
    if (roundNumber == 1) return 'Opening round';
    return 'Round $roundNumber';
  }

  Future<void> _handleResult({
    required TournamentBracketMatchModel match,
    required int winnerEntryId,
    required String winType,
  }) async {
    final refreshed = await widget.onRecordWinner(
      match: match,
      winnerEntryId: winnerEntryId,
      winType: winType,
    );
    if (refreshed != null && mounted) {
      setState(() => _bracket = refreshed);
    }
  }

  Map<String, List<TournamentBracketMatchModel>> _buildMatQueue() {
    final queue = <String, List<TournamentBracketMatchModel>>{};
    for (final match
        in _bracket.matches.where((item) => item.matchStatus != 'completed')) {
      final matLabel = match.matLabel?.trim().isNotEmpty == true
          ? match.matLabel!.trim()
          : 'Unassigned';
      queue.putIfAbsent(matLabel, () => []);
      queue[matLabel]!.add(match);
    }
    for (final matches in queue.values) {
      matches.sort((a, b) {
        final roundCompare = a.roundNumber.compareTo(b.roundNumber);
        if (roundCompare != 0) return roundCompare;
        return a.matchupOrder.compareTo(b.matchupOrder);
      });
    }
    return queue;
  }

  List<TournamentBracketMatchModel> _filteredMatches(
      List<TournamentBracketMatchModel> matches) {
    if (_matFilter == 'All mats') return matches;
    return matches.where((match) => match.matLabel == _matFilter).toList();
  }

  double _roundSpacing(int roundNumber) {
    final safeRound = roundNumber < 1 ? 1 : roundNumber;
    return 20 + ((safeRound - 1) * 36);
  }

  @override
  Widget build(BuildContext context) {
    final roundEntries = _groupMatches().entries.toList();
    final matQueue = _buildMatQueue();
    final remainingMatches = _bracket.matches
        .where((match) => match.matchStatus != 'completed')
        .length;
    final completedMatches = _bracket.matches.length - remainingMatches;
    final unassignedMatches = _bracket.matches.where((match) {
      return match.matchStatus != 'completed' &&
          (match.matLabel == null || match.matLabel!.trim().isEmpty);
    }).length;
    final availableMatFilters = [
      'All mats',
      ...widget.mats.map((mat) => mat.label)
    ];
    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      backgroundColor: AppColors.surface,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.92,
        height: MediaQuery.of(context).size.height * 0.88,
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${widget.weightClass} bracket',
                          style: AppTextStyles.sectionTitle),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        _publicDisplay
                            ? 'Public board view for this weight class.'
                            : 'Scorekeeper picks the winner and result type. Pin IQ advances the bracket automatically.',
                        style: AppTextStyles.body
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                _TournamentMetaChip(label: '$completedMatches complete'),
                _TournamentMetaChip(label: '$remainingMatches remaining'),
                _TournamentMetaChip(label: '$unassignedMatches unassigned'),
                FilterChip(
                  selected: _publicDisplay,
                  label: const Text('Public board'),
                  onSelected: (value) => setState(() => _publicDisplay = value),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            if (availableMatFilters.length > 1) ...[
              Text(_publicDisplay ? 'View mat' : 'Scorekeeper view',
                  style: AppTextStyles.bodyStrong),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: availableMatFilters
                    .map(
                      (matLabel) => ChoiceChip(
                        selected: _matFilter == matLabel,
                        label: Text(matLabel),
                        onSelected: (_) =>
                            setState(() => _matFilter = matLabel),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            if (widget.mats.isNotEmpty) ...[
              Text('Mat queue', style: AppTextStyles.bodyStrong),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: matQueue.entries.map((entry) {
                  if (_matFilter != 'All mats' && entry.key != _matFilter) {
                    return const SizedBox.shrink();
                  }
                  final nowWrestling =
                      entry.value.isNotEmpty ? entry.value.first : null;
                  final onDeck = entry.value.length > 1 ? entry.value[1] : null;
                  final inTheHole =
                      entry.value.length > 2 ? entry.value[2] : null;
                  return Container(
                    width: 240,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(entry.key, style: AppTextStyles.bodyStrong),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          nowWrestling == null
                              ? 'No active match'
                              : 'Now: R${nowWrestling.roundNumber} M${nowWrestling.matchupOrder}',
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.textSecondary),
                        ),
                        Text(
                          onDeck == null
                              ? 'On deck: none'
                              : 'On deck: R${onDeck.roundNumber} M${onDeck.matchupOrder}',
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.textSecondary),
                        ),
                        Text(
                          inTheHole == null
                              ? 'In the hole: none'
                              : 'In the hole: R${inTheHole.roundNumber} M${inTheHole.matchupOrder}',
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            Expanded(
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: roundEntries.map((roundEntry) {
                  final roundNumber = roundEntry.key;
                  final matches = _filteredMatches(roundEntry.value);
                  if (matches.isEmpty) return const SizedBox.shrink();
                  return Container(
                    width: 340,
                    margin: const EdgeInsets.only(right: AppSpacing.md),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated.withValues(alpha: 0.72),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_roundLabel(roundNumber),
                            style: AppTextStyles.cardTitle),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          '${matches.length} matches',
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              children: List.generate(matches.length, (index) {
                                final match = matches[index];
                                final wrestlerA = match.wrestlerAEntryId == null
                                    ? 'TBD'
                                    : widget
                                        .athleteName(match.wrestlerAEntryId!);
                                final wrestlerB = match.wrestlerBEntryId == null
                                    ? 'TBD'
                                    : widget
                                        .athleteName(match.wrestlerBEntryId!);
                                final topGap = index == 0
                                    ? _roundSpacing(roundNumber) / 2
                                    : _roundSpacing(roundNumber);
                                return Padding(
                                  padding: EdgeInsets.only(
                                      top: topGap, bottom: AppSpacing.sm),
                                  child: _BracketMatchCard(
                                    title: 'Match ${match.matchupOrder}',
                                    wrestlerA: wrestlerA,
                                    wrestlerB: wrestlerB,
                                    matOptions: widget.mats
                                        .map((mat) => mat.label)
                                        .toList(),
                                    selectedMat: match.matLabel,
                                    onAssignMat: (matLabel) async {
                                      if (_publicDisplay) return;
                                      final refreshed =
                                          await widget.onAssignMat(
                                        match: match,
                                        matLabel: matLabel,
                                      );
                                      if (refreshed != null && mounted) {
                                        setState(() => _bracket = refreshed);
                                      }
                                    },
                                    statusLabel: match.resultSummary ??
                                        'Status: ${match.matchStatus}',
                                    onResultSelectedForA: _publicDisplay ||
                                            match.wrestlerAEntryId == null
                                        ? null
                                        : (resultLabel) => _handleResult(
                                              match: match,
                                              winnerEntryId:
                                                  match.wrestlerAEntryId!,
                                              winType: resultLabel,
                                            ),
                                    onResultSelectedForB: _publicDisplay ||
                                            match.wrestlerBEntryId == null
                                        ? null
                                        : (resultLabel) => _handleResult(
                                              match: match,
                                              winnerEntryId:
                                                  match.wrestlerBEntryId!,
                                              winType: resultLabel,
                                            ),
                                    wrestlerASelected:
                                        match.winnerEntryId != null &&
                                            match.winnerEntryId ==
                                                match.wrestlerAEntryId,
                                    wrestlerBSelected:
                                        match.winnerEntryId != null &&
                                            match.winnerEntryId ==
                                                match.wrestlerBEntryId,
                                  ),
                                );
                              }),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BracketMatchCard extends StatefulWidget {
  const _BracketMatchCard({
    required this.title,
    required this.wrestlerA,
    required this.wrestlerB,
    required this.matOptions,
    required this.selectedMat,
    required this.onAssignMat,
    required this.statusLabel,
    required this.onResultSelectedForA,
    required this.onResultSelectedForB,
    required this.wrestlerASelected,
    required this.wrestlerBSelected,
  });

  final String title;
  final String wrestlerA;
  final String wrestlerB;
  final List<String> matOptions;
  final String? selectedMat;
  final ValueChanged<String>? onAssignMat;
  final String statusLabel;
  final ValueChanged<String>? onResultSelectedForA;
  final ValueChanged<String>? onResultSelectedForB;
  final bool wrestlerASelected;
  final bool wrestlerBSelected;

  @override
  State<_BracketMatchCard> createState() => _BracketMatchCardState();
}

class _BracketMatchCardState extends State<_BracketMatchCard> {
  String? _selectedLane;

  @override
  void initState() {
    super.initState();
    if (widget.wrestlerASelected) {
      _selectedLane = 'A';
    } else if (widget.wrestlerBSelected) {
      _selectedLane = 'B';
    }
  }

  @override
  Widget build(BuildContext context) {
    final showResultPicker =
        (_selectedLane == 'A' && widget.onResultSelectedForA != null) ||
            (_selectedLane == 'B' && widget.onResultSelectedForB != null);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm + 2),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated.withValues(alpha: 0.68),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(widget.title, style: AppTextStyles.bodyStrong),
              ),
              if (widget.matOptions.isNotEmpty)
                SizedBox(
                  width: 112,
                  child: DropdownButtonFormField<String>(
                    initialValue: widget.matOptions.contains(widget.selectedMat)
                        ? widget.selectedMat
                        : null,
                    decoration: const InputDecoration(
                      labelText: 'Mat',
                      isDense: true,
                    ),
                    items: widget.matOptions
                        .map(
                          (matLabel) => DropdownMenuItem<String>(
                            value: matLabel,
                            child: Text(matLabel),
                          ),
                        )
                        .toList(),
                    onChanged: widget.onAssignMat == null
                        ? null
                        : (value) {
                            if (value != null) widget.onAssignMat!(value);
                          },
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            widget.selectedMat == null
                ? widget.statusLabel
                : '${widget.statusLabel} • ${widget.selectedMat!}',
            style:
                AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.sm),
          _BracketCompetitorRow(
            label: widget.wrestlerA,
            selected: widget.wrestlerASelected || _selectedLane == 'A',
            selectable: widget.onResultSelectedForA != null,
            onTap: widget.onResultSelectedForA == null
                ? null
                : () => setState(() => _selectedLane = 'A'),
          ),
          const SizedBox(height: AppSpacing.xs),
          _BracketCompetitorRow(
            label: widget.wrestlerB,
            selected: widget.wrestlerBSelected || _selectedLane == 'B',
            selectable: widget.onResultSelectedForB != null,
            onTap: widget.onResultSelectedForB == null
                ? null
                : () => setState(() => _selectedLane = 'B'),
          ),
          if (showResultPicker) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              _selectedLane == 'A'
                  ? 'Confirm ${widget.wrestlerA}'
                  : 'Confirm ${widget.wrestlerB}',
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.xs),
            _BracketResultPicker(
              onSelected: (value) {
                if (_selectedLane == 'A') {
                  widget.onResultSelectedForA?.call(value);
                } else {
                  widget.onResultSelectedForB?.call(value);
                }
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _BracketCompetitorRow extends StatelessWidget {
  const _BracketCompetitorRow({
    required this.label,
    required this.selected,
    required this.selectable,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool selectable;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.danger.withValues(alpha: 0.16)
              : AppColors.surface.withValues(alpha: 0.52),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? AppColors.danger.withValues(alpha: 0.55)
                : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(label, style: AppTextStyles.bodyStrong),
            ),
            if (!selectable)
              Text(
                'Waiting',
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textSecondary),
              )
            else if (selected)
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.danger, size: 18)
            else
              Text(
                'Pick winner',
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textSecondary),
              ),
          ],
        ),
      ),
    );
  }
}

class _BracketResultPicker extends StatelessWidget {
  const _BracketResultPicker({required this.onSelected});

  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final resultOptions = const <(String, String)>[
      ('Decision', 'DEC'),
      ('Major', 'MAJ'),
      ('Tech', 'TF'),
      ('Pin', 'FALL'),
      ('Forfeit', 'FFT'),
      ('Default', 'DEF'),
      ('DQ', 'DQ'),
    ];
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: resultOptions
          .map(
            (option) => OutlinedButton(
              onPressed: () => onSelected(option.$1),
              child: Text(option.$2),
            ),
          )
          .toList(),
    );
  }
}
