import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../models/tournament_models.dart';
import '../../services/browser_link_service.dart';
import '../messaging/announcements_screen.dart';
import '../messaging/message_threads_screen.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/section_header.dart';
import '../../widgets/subpage_header.dart';
import 'flyer_studio_screen.dart';
import 'tournament_duals_manager_screen.dart';

class TournamentCenterScreen extends StatefulWidget {
  const TournamentCenterScreen({super.key});

  @override
  State<TournamentCenterScreen> createState() => _TournamentCenterScreenState();
}

class _TournamentCenterScreenState extends State<TournamentCenterScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _scanStateController = TextEditingController();
  Timer? _searchDebounce;
  String _filter = 'all';
  String? _sourceFilter;
  String _scanDivision = 'all';
  String _scanStyle = 'all';
  bool _showPastEvents = false;
  int _selectedIndex = 0;
  bool _isLoading = true;
  bool _isScanning = false;
  String? _error;
  String? _scanStatus;
  List<TournamentExternalModel> _discovered = const [];
  List<TournamentSourceModel> _sources = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadTournaments());
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _scanStateController.dispose();
    super.dispose();
  }

  Future<void> _loadTournaments() async {
    final appState = context.read<AppState>();
    if (appState.token == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await appState.api.discoverTournaments(
        token: appState.token!,
        teamId: appState.activeTeam?.id,
        search: _searchController.text.trim(),
        source: _sourceFilter,
      );
      if (!mounted) return;
      setState(() {
        _discovered = response.tournaments;
        _sources = response.availableSources;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _discovered = const [];
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _runLiveScan() async {
    final appState = context.read<AppState>();
    if (appState.token == null || _isScanning) return;

    final sourceKeys = _sourceFilter == null
        ? _sources
            .where((source) => source.sourceKey != 'manual' && source.isActive)
            .map((source) => source.sourceKey)
            .toList()
        : _sources
            .where((source) =>
                source.displayName == _sourceFilter ||
                source.sourceKey == _sourceFilter)
            .map((source) => source.sourceKey)
            .toList();

    if (sourceKeys.isEmpty) {
      setState(() {
        _error = 'No live source is selected or configured yet.';
      });
      return;
    }

    setState(() {
      _isScanning = true;
      _error = null;
      _scanStatus = null;
    });

    try {
      var seen = 0;
      var changed = 0;
      for (final sourceKey in sourceKeys) {
        final scan = await appState.api.runLiveTournamentScan(
          token: appState.token!,
          sourceKey: sourceKey,
          search: _searchController.text.trim().isEmpty
              ? null
              : _searchController.text.trim(),
          state: _scanStateController.text.trim().isEmpty
              ? null
              : _scanStateController.text.trim().toUpperCase(),
          division: _scanDivision == 'all' ? null : _scanDivision,
          style: _scanStyle == 'all' ? null : _scanStyle,
        );
        seen += scan['items_seen_count'] as int? ?? 0;
        changed += (scan['items_created_count'] as int? ?? 0) +
            (scan['items_updated_count'] as int? ?? 0);
      }
      await _loadTournaments();
      if (!mounted) return;
      setState(() {
        _scanStatus =
            'Scan complete: $seen source row${seen == 1 ? '' : 's'} checked, $changed event${changed == 1 ? '' : 's'} added or updated.';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    } finally {
      if (mounted) {
        setState(() => _isScanning = false);
      }
    }
  }

  void _queueSearch(String _) {
    _searchDebounce?.cancel();
    _searchDebounce =
        Timer(const Duration(milliseconds: 350), _loadTournaments);
  }

  Future<void> _saveTournament(_TournamentRecord record) async {
    final appState = context.read<AppState>();
    if (appState.token == null || appState.activeTeam == null) return;

    try {
      await appState.api.saveTournament(
        token: appState.token!,
        teamId: appState.activeTeam!.id,
        tournamentId: record.id,
        notes: 'Saved from Tournament Center.',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${record.title} saved to the team watchlist.')),
      );
      await _loadTournaments();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _addTournamentToCalendar(_TournamentRecord record) async {
    final appState = context.read<AppState>();
    if (appState.token == null || appState.activeTeam == null) return;

    try {
      await appState.api.addTournamentToSchedule(
        token: appState.token!,
        teamId: appState.activeTeam!.id,
        tournamentId: record.id,
        startsAt: DateTime(record.startDate.year, record.startDate.month,
            record.startDate.day, 8),
        endsAt: DateTime(
            record.endDate.year, record.endDate.month, record.endDate.day, 18),
        titleOverride: record.title,
        descriptionOverride: record.notes,
        locationOverride: record.location,
        notes: 'Added from Tournament Center.',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${record.title} added to the team calendar.')),
      );
      await _loadTournaments();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _openFlyerStudio() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const FlyerStudioScreen()),
    );
  }

  Future<void> _openCoachAlertFlow() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const AnnouncementsScreen()),
    );
  }

  Future<void> _openParentReminderFlow() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const MessageThreadsScreen()),
    );
  }

  Future<void> _openDualsManager() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
          builder: (_) => const TournamentDualsManagerScreen()),
    );
  }

  Future<void> _openAddTournamentDialog() async {
    final appState = context.read<AppState>();
    if (appState.token == null || appState.activeTeam == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Pick a team before adding a tournament.')),
      );
      return;
    }

    final nameController = TextEditingController();
    final startDateController = TextEditingController();
    final endDateController = TextEditingController();
    final cityController = TextEditingController();
    final stateController = TextEditingController();
    final locationController = TextEditingController();
    final linkController = TextEditingController();
    final costController = TextEditingController();
    final notesController = TextEditingController();

    String? cleanText(TextEditingController controller) {
      final value = controller.text.trim();
      return value.isEmpty ? null : value;
    }

    try {
      final created = await showDialog<TournamentExternalModel>(
        context: context,
        builder: (dialogContext) {
          bool isSaving = false;
          String? formError;

          Future<void> submit(StateSetter setDialogState) async {
            final name = nameController.text.trim();
            final startDate =
                DateTime.tryParse(startDateController.text.trim());
            final endDate = endDateController.text.trim().isEmpty
                ? startDate
                : DateTime.tryParse(endDateController.text.trim());

            if (name.isEmpty || startDate == null || endDate == null) {
              setDialogState(() {
                formError =
                    'Name, start date, and a valid YYYY-MM-DD date are required.';
              });
              return;
            }

            setDialogState(() {
              isSaving = true;
              formError = null;
            });

            try {
              final tournament = await appState.api.createManualTournament(
                token: appState.token!,
                teamId: appState.activeTeam!.id,
                payload: {
                  'name': name,
                  'start_date': startDateController.text.trim(),
                  'end_date': endDateController.text.trim().isEmpty
                      ? startDateController.text.trim()
                      : endDateController.text.trim(),
                  'location_name': cleanText(locationController),
                  'city': cleanText(cityController),
                  'state': cleanText(stateController),
                  'age_divisions': const ['Youth', 'High School'],
                  'weight_classes': const <String>[],
                  'event_type': 'folkstyle',
                  'registration_link': cleanText(linkController),
                  'event_page_link': cleanText(linkController),
                  'description': cleanText(notesController),
                  'cost': cleanText(costController),
                  'notes': 'Added from Tournament Center manual entry.',
                },
              );
              if (dialogContext.mounted) {
                Navigator.of(dialogContext).pop(tournament);
              }
            } catch (error) {
              setDialogState(() {
                isSaving = false;
                formError = error.toString().replaceFirst('Exception: ', '');
              });
            }
          }

          return StatefulBuilder(
            builder: (context, setDialogState) => AlertDialog(
              title: const Text('Add real tournament'),
              content: SizedBox(
                width: 560,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Tournament name',
                          hintText: 'Example: Kentucky State Open',
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: startDateController,
                              decoration: const InputDecoration(
                                labelText: 'Start date',
                                hintText: 'YYYY-MM-DD',
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: TextField(
                              controller: endDateController,
                              decoration: const InputDecoration(
                                labelText: 'End date',
                                hintText: 'blank = same day',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: cityController,
                              decoration:
                                  const InputDecoration(labelText: 'City'),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          SizedBox(
                            width: 120,
                            child: TextField(
                              controller: stateController,
                              decoration:
                                  const InputDecoration(labelText: 'State'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextField(
                        controller: locationController,
                        decoration: const InputDecoration(labelText: 'Venue'),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextField(
                        controller: linkController,
                        decoration: const InputDecoration(
                            labelText: 'Registration or event link'),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextField(
                        controller: costController,
                        decoration: const InputDecoration(labelText: 'Cost'),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextField(
                        controller: notesController,
                        minLines: 2,
                        maxLines: 4,
                        decoration: const InputDecoration(labelText: 'Notes'),
                      ),
                      if (formError != null) ...[
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          formError!,
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.danger),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed:
                      isSaving ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton.icon(
                  onPressed: isSaving ? null : () => submit(setDialogState),
                  icon: isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add_location_alt_rounded),
                  label: Text(isSaving ? 'Adding...' : 'Add tournament'),
                ),
              ],
            ),
          );
        },
      );

      if (created == null || !mounted) return;
      setState(() {
        _filter = 'all';
        _sourceFilter = null;
        _selectedIndex = 0;
      });
      _searchController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${created.name} added to Tournament Center.')),
      );
      await _loadTournaments();
    } finally {
      nameController.dispose();
      startDateController.dispose();
      endDateController.dispose();
      cityController.dispose();
      stateController.dispose();
      locationController.dispose();
      linkController.dispose();
      costController.dispose();
      notesController.dispose();
    }
  }

  void _handleRecordTap(_TournamentRecord record, int index,
      {required bool isWide}) {
    if (isWide) {
      setState(() => _selectedIndex = index);
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _TournamentDetailScreen(
          record: record,
          onSave: () => _saveTournament(record),
          onAddToCalendar: () => _addTournamentToCalendar(record),
          onCreateFlyer: _openFlyerStudio,
          onSendCoachAlert: _openCoachAlertFlow,
          onParentReminder: _openParentReminderFlow,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final records = _discovered.map(_TournamentRecord.fromModel).toList();
    final savedCount =
        records.where((record) => record.status == 'Saved').length;
    final reviewCount = records
        .where(
            (record) => record.status == 'New' || record.status == 'Scan match')
        .length;
    final girlsCount =
        records.where((record) => record.division.contains('Girls')).length;
    final visible = records.where((record) {
      final matchesDate = _showPastEvents || !record.isPastEvent;
      final matchesFilter = switch (_filter) {
        'saved' => record.status == 'Saved',
        'new' => record.status == 'New' || record.status == 'Scan match',
        'girls' => record.division.contains('Girls'),
        'nearby' =>
          record.distanceMiles == null ? false : record.distanceMiles! <= 90,
        _ => true,
      };
      return matchesDate && matchesFilter;
    }).toList();

    if (_selectedIndex >= visible.length) {
      _selectedIndex = visible.isEmpty ? 0 : visible.length - 1;
    }

    final selected = visible.isEmpty ? null : visible[_selectedIndex];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 1120;

        return ListView(
          padding: EdgeInsets.zero,
          children: [
            const SubpageHeader(
              title: 'Tournament Center',
              subtitle:
                  'Discover, save, scan, and stage events without leaving the product.',
            ),
            const SizedBox(height: AppSpacing.lg),
            _TournamentCommandDeck(
              savedCount: savedCount,
              reviewCount: reviewCount,
              sourceCount: _sources.length,
              isScanning: _isScanning,
              scanStateController: _scanStateController,
              scanDivision: _scanDivision,
              scanStyle: _scanStyle,
              onScanDivisionChanged: (value) =>
                  setState(() => _scanDivision = value),
              onScanStyleChanged: (value) => setState(() => _scanStyle = value),
              onRunLiveScan: _runLiveScan,
              onAddTournament: _openAddTournamentDialog,
              onOpenDuals: _openDualsManager,
            ),
            if (_scanStatus != null) ...[
              const SizedBox(height: AppSpacing.md),
              _StatusBanner(
                message: _scanStatus!,
                color: AppColors.success,
                icon: Icons.check_circle_outline,
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            _SummaryBand(
              accent: const Color(0xFFF59E0B),
              items: [
                _SummaryItem(
                    label: 'Saved',
                    value: '$savedCount',
                    note: 'coach watchlist'),
                _SummaryItem(
                    label: 'Results',
                    value: '${records.length}',
                    note: 'discovery records'),
                _SummaryItem(
                    label: 'Review',
                    value: '$reviewCount',
                    note: 'need coach decision'),
                _SummaryItem(
                    label: 'Sources',
                    value: '${_sources.length}',
                    note: 'configured sources'),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            if (_error != null) ...[
              _EmptyPanel(
                message: _error!.replaceFirst('Exception: ', ''),
                actionLabel: 'Try again',
                onAction: _runLiveScan,
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            _TournamentDecisionBoard(
              savedCount: savedCount,
              reviewCount: reviewCount,
              girlsCount: girlsCount,
            ),
            const SizedBox(height: AppSpacing.lg),
            if (_isLoading) ...[
              const _StatusBanner(
                message: 'Loading tournament discovery results...',
                color: AppColors.warning,
                icon: Icons.sync_rounded,
              ),
              const SizedBox(height: AppSpacing.lg),
            ] else if (records.isEmpty) ...[
              _EmptyPanel(
                message:
                    'No tournaments are showing for the current search and filters. Run a live scan, broaden filters, or add a known event manually.',
                actionLabel: _isScanning ? null : 'Run live scan',
                onAction: _isScanning ? null : _runLiveScan,
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            if (isWide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 5,
                    child: _TournamentListPanel(
                      controller: _searchController,
                      filter: _filter,
                      sourceFilter: _sourceFilter,
                      sources: _sources,
                      isLoading: _isLoading,
                      isScanning: _isScanning,
                      onSearchChanged: _queueSearch,
                      onRefresh: _loadTournaments,
                      onRunLiveScan: _runLiveScan,
                      onSourceChanged: (value) {
                        setState(() {
                          _sourceFilter = value;
                          _selectedIndex = 0;
                        });
                        _loadTournaments();
                      },
                      onFilterChanged: (value) => setState(
                        () {
                          _filter = value;
                          _selectedIndex = 0;
                        },
                      ),
                      showPastEvents: _showPastEvents,
                      onPastEventsChanged: (value) =>
                          setState(() => _showPastEvents = value),
                      records: visible,
                      selectedIndex: _selectedIndex,
                      onSelect: (index) =>
                          _handleRecordTap(visible[index], index, isWide: true),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    flex: 4,
                    child: selected == null
                        ? const _EmptyPanel(
                            message:
                                'No tournaments match the current filters.')
                        : _TournamentDetailPanel(
                            record: selected,
                            onSave: () => _saveTournament(selected),
                            onAddToCalendar: () =>
                                _addTournamentToCalendar(selected),
                            onCreateFlyer: _openFlyerStudio,
                            onSendCoachAlert: _openCoachAlertFlow,
                            onParentReminder: _openParentReminderFlow,
                          ),
                  ),
                ],
              )
            else ...[
              _TournamentListPanel(
                controller: _searchController,
                filter: _filter,
                sourceFilter: _sourceFilter,
                sources: _sources,
                isLoading: _isLoading,
                isScanning: _isScanning,
                onSearchChanged: _queueSearch,
                onRefresh: _loadTournaments,
                onRunLiveScan: _runLiveScan,
                onSourceChanged: (value) {
                  setState(() {
                    _sourceFilter = value;
                    _selectedIndex = 0;
                  });
                  _loadTournaments();
                },
                onFilterChanged: (value) => setState(() {
                  _filter = value;
                  _selectedIndex = 0;
                }),
                showPastEvents: _showPastEvents,
                onPastEventsChanged: (value) =>
                    setState(() => _showPastEvents = value),
                records: visible,
                selectedIndex: _selectedIndex,
                onSelect: (index) =>
                    _handleRecordTap(visible[index], index, isWide: false),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (selected == null)
                const _EmptyPanel(
                    message: 'No tournaments match the current filters.')
              else
                _TournamentDetailPanel(
                  record: selected,
                  onSave: () => _saveTournament(selected),
                  onAddToCalendar: () => _addTournamentToCalendar(selected),
                  onCreateFlyer: _openFlyerStudio,
                  onSendCoachAlert: _openCoachAlertFlow,
                  onParentReminder: _openParentReminderFlow,
                ),
            ],
            const SizedBox(height: AppSpacing.xl),
            const SectionHeader(title: 'Scanner status'),
            const SizedBox(height: AppSpacing.md),
            _ScannerStatusRow(sources: _sources),
            const SizedBox(height: AppSpacing.xl),
            const SectionHeader(title: 'Change watch'),
            const SizedBox(height: AppSpacing.md),
            const _TournamentChangeWatch(),
            const SizedBox(height: AppSpacing.xl),
            const SectionHeader(title: 'Coach pipeline'),
            const SizedBox(height: AppSpacing.md),
            _TournamentWorkflowRow(records: records),
            const SizedBox(height: AppSpacing.xl),
          ],
        );
      },
    );
  }
}

String _displaySourceName(String raw) {
  final normalized = raw.trim().toLowerCase();
  if (normalized == 'usa wrestling' || normalized == 'usa bracketing') {
    return 'USA Bracketing';
  }
  if (normalized == 'flowrestling' || normalized == 'flo wrestling') {
    return 'FloWrestling';
  }
  if (normalized == 'trackwrestling' || normalized == 'track wrestling') {
    return 'TrackWrestling';
  }
  return raw;
}

String _titleCase(String value) {
  return value
      .split(RegExp(r'[_\s]+'))
      .where((part) => part.isNotEmpty)
      .map((part) =>
          '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}')
      .join(' ');
}

String _formatShortDate(DateTime value) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[value.month - 1]} ${value.day}';
}

String _formatDateRange(DateTime start, DateTime end) {
  final startLabel = _formatShortDate(start);
  if (start.year == end.year &&
      start.month == end.month &&
      start.day == end.day) {
    return startLabel;
  }
  return '$startLabel - ${_formatShortDate(end)}';
}

class _TournamentCommandDeck extends StatelessWidget {
  const _TournamentCommandDeck({
    required this.savedCount,
    required this.reviewCount,
    required this.sourceCount,
    required this.isScanning,
    required this.scanStateController,
    required this.scanDivision,
    required this.scanStyle,
    required this.onScanDivisionChanged,
    required this.onScanStyleChanged,
    required this.onRunLiveScan,
    required this.onAddTournament,
    required this.onOpenDuals,
  });

  final int savedCount;
  final int reviewCount;
  final int sourceCount;
  final bool isScanning;
  final TextEditingController scanStateController;
  final String scanDivision;
  final String scanStyle;
  final ValueChanged<String> onScanDivisionChanged;
  final ValueChanged<String> onScanStyleChanged;
  final Future<void> Function() onRunLiveScan;
  final Future<void> Function() onAddTournament;
  final Future<void> Function() onOpenDuals;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF152033),
            Color(0xFF111A28),
            Color(0xFF251017),
          ],
          stops: [0, 0.56, 1],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.72)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 28,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stacked = constraints.maxWidth < 980;
          final actions = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.travel_explore_rounded,
                      color: Color(0xFFF59E0B),
                      size: 19,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text('Tournament command', style: AppTextStyles.bodyStrong),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Search live events, save the right ones, and move straight into coach actions without bouncing between pages.',
                style: AppTextStyles.body,
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: 108,
                    child: TextField(
                      controller: scanStateController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: 'State',
                        hintText: 'KY',
                      ),
                    ),
                  ),
                  for (final option in const [
                    ('all', 'All'),
                    ('girls', 'Girls'),
                    ('coed', 'Coed'),
                  ])
                    ChoiceChip(
                      label: Text(option.$2),
                      selected: scanDivision == option.$1,
                      onSelected: (_) => onScanDivisionChanged(option.$1),
                    ),
                  for (final option in const [
                    ('all', 'All styles'),
                    ('folkstyle', 'Folk'),
                    ('freestyle', 'Free'),
                    ('greco', 'Greco'),
                  ])
                    ChoiceChip(
                      label: Text(option.$2),
                      selected: scanStyle == option.$1,
                      onSelected: (_) => onScanStyleChanged(option.$1),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  ElevatedButton.icon(
                    onPressed: isScanning ? null : onRunLiveScan,
                    icon: const Icon(Icons.radar_rounded),
                    label: Text(isScanning ? 'Scanning...' : 'Run live scan'),
                  ),
                  OutlinedButton.icon(
                    onPressed: onAddTournament,
                    icon: const Icon(Icons.add_location_alt_rounded),
                    label: const Text('Add real tournament'),
                  ),
                  OutlinedButton.icon(
                    onPressed: onOpenDuals,
                    icon: const Icon(Icons.groups_rounded),
                    label: const Text('Team duals'),
                  ),
                ],
              ),
            ],
          );

          final metrics = Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              SizedBox(
                  width: 168,
                  child:
                      _MetricBox(label: 'Saved events', value: '$savedCount')),
              SizedBox(
                  width: 168,
                  child:
                      _MetricBox(label: 'Need review', value: '$reviewCount')),
              SizedBox(
                  width: 168,
                  child:
                      _MetricBox(label: 'Live sources', value: '$sourceCount')),
            ],
          );

          if (stacked) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                actions,
                const SizedBox(height: AppSpacing.lg),
                metrics,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 4, child: actions),
              const SizedBox(width: AppSpacing.xl),
              Expanded(flex: 6, child: metrics),
            ],
          );
        },
      ),
    );
  }
}

class _TournamentListPanel extends StatelessWidget {
  const _TournamentListPanel({
    required this.controller,
    required this.filter,
    required this.sourceFilter,
    required this.sources,
    required this.isLoading,
    required this.isScanning,
    required this.onSearchChanged,
    required this.onRefresh,
    required this.onRunLiveScan,
    required this.onSourceChanged,
    required this.onFilterChanged,
    required this.showPastEvents,
    required this.onPastEventsChanged,
    required this.records,
    required this.selectedIndex,
    required this.onSelect,
  });

  final TextEditingController controller;
  final String filter;
  final String? sourceFilter;
  final List<TournamentSourceModel> sources;
  final bool isLoading;
  final bool isScanning;
  final ValueChanged<String> onSearchChanged;
  final Future<void> Function() onRefresh;
  final Future<void> Function() onRunLiveScan;
  final ValueChanged<String?> onSourceChanged;
  final ValueChanged<String> onFilterChanged;
  final bool showPastEvents;
  final ValueChanged<bool> onPastEventsChanged;
  final List<_TournamentRecord> records;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.72)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (constraints.maxWidth >= 560)
              Row(
                children: [
                  Text('Discovery queue',
                      style: AppTextStyles.cardTitle.copyWith(fontSize: 22)),
                  const Spacer(),
                  OutlinedButton.icon(
                    onPressed: isScanning ? null : onRunLiveScan,
                    icon: const Icon(Icons.travel_explore_rounded),
                    label: Text(isScanning ? 'Scanning...' : 'Run live scan'),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  OutlinedButton.icon(
                    onPressed: isLoading ? null : onRefresh,
                    icon: const Icon(Icons.sync_rounded),
                    label: const Text('Refresh results'),
                  ),
                ],
              )
            else ...[
              Text('Discovery queue',
                  style: AppTextStyles.cardTitle.copyWith(fontSize: 22)),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton.icon(
                onPressed: isScanning ? null : onRunLiveScan,
                icon: const Icon(Icons.travel_explore_rounded),
                label: Text(isScanning ? 'Scanning...' : 'Run live scan'),
              ),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton.icon(
                onPressed: isLoading ? null : onRefresh,
                icon: const Icon(Icons.sync_rounded),
                label: const Text('Refresh results'),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: controller,
              onChanged: onSearchChanged,
              decoration: const InputDecoration(
                hintText: 'Search tournaments, locations, and sources',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (sources.isNotEmpty)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.xs),
                      child: ChoiceChip(
                        label: const Text('All sources'),
                        selected: sourceFilter == null,
                        onSelected: (_) => onSourceChanged(null),
                      ),
                    ),
                    for (final source in sources)
                      Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.xs),
                        child: ChoiceChip(
                          label: Text(_displaySourceName(source.displayName)),
                          selected: sourceFilter == source.displayName,
                          onSelected: (_) =>
                              onSourceChanged(source.displayName),
                        ),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: AppSpacing.md),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final chip in const [
                    ('all', 'All'),
                    ('saved', 'Saved'),
                    ('new', 'New'),
                    ('girls', 'Girls'),
                    ('nearby', 'Nearby'),
                  ])
                    Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.xs),
                      child: ChoiceChip(
                        label: Text(chip.$2),
                        selected: filter == chip.$1,
                        onSelected: (_) => onFilterChanged(chip.$1),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            FilterChip(
              label: const Text('Past events'),
              selected: showPastEvents,
              onSelected: onPastEventsChanged,
            ),
            const SizedBox(height: AppSpacing.lg),
            if (!isLoading && records.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _EmptyPanel(
                  message:
                      'No tournaments match these filters. Try all sources, clear the search, include past events, or run a fresh scan.',
                  actionLabel: isScanning ? null : 'Run scan',
                  onAction: isScanning ? null : onRunLiveScan,
                ),
              ),
            ...List.generate(records.length, (index) {
              final record = records[index];
              final isSelected = index == selectedIndex;
              return Padding(
                padding: EdgeInsets.only(
                    bottom: index == records.length - 1 ? 0 : AppSpacing.sm),
                child: _TournamentRow(
                  record: record,
                  selected: isSelected,
                  onTap: () => onSelect(index),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _TournamentRow extends StatelessWidget {
  const _TournamentRow({
    required this.record,
    required this.selected,
    required this.onTap,
  });

  final _TournamentRecord record;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFF172033)
                : AppColors.surface.withValues(alpha: 0.36),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: selected
                  ? const Color(0xFFF59E0B).withValues(alpha: 0.48)
                  : AppColors.border.withValues(alpha: 0.46),
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(record.title, style: AppTextStyles.bodyStrong),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      '${record.dateLabel} • ${record.location}',
                      style: AppTextStyles.caption,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: [
                        _Pill(
                            label: record.status,
                            color: const Color(0xFFF59E0B)),
                        _Pill(
                            label: record.division,
                            color: const Color(0xFF38BDF8)),
                        _Pill(
                            label: record.distance,
                            color: AppColors.textSecondary),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              OutlinedButton.icon(
                onPressed: onTap,
                icon: const Icon(Icons.open_in_new_rounded, size: 18),
                label: const Text('Open'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TournamentDetailPanel extends StatelessWidget {
  const _TournamentDetailPanel({
    required this.record,
    required this.onSave,
    required this.onAddToCalendar,
    required this.onCreateFlyer,
    required this.onSendCoachAlert,
    required this.onParentReminder,
  });

  final _TournamentRecord record;
  final VoidCallback onSave;
  final VoidCallback onAddToCalendar;
  final VoidCallback onCreateFlyer;
  final VoidCallback onSendCoachAlert;
  final VoidCallback onParentReminder;

  String _primaryEventLinkLabel() {
    final link = record.eventPageLink?.toLowerCase();
    if (link == null || link.isEmpty) {
      return 'Open event page';
    }
    if (link.contains('/registration/')) {
      return 'Open registration';
    }
    if (link.endsWith('.pdf') ||
        link.endsWith('.doc') ||
        link.endsWith('.docx')) {
      return 'Open flyer';
    }
    return 'Open website';
  }

  bool _shouldShowSeparateRegistrationButton() {
    final registrationLink = record.registrationLink;
    if (registrationLink == null || registrationLink.isEmpty) {
      return false;
    }
    return registrationLink != record.eventPageLink;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.72)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(record.title, style: AppTextStyles.sectionTitle),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      '${record.dateLabel} • ${record.location} • ${record.source}',
                      style: AppTextStyles.body,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              ElevatedButton.icon(
                onPressed: onSave,
                icon: const Icon(Icons.bookmark_add_outlined),
                label: const Text('Save'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(record.notes,
              style: AppTextStyles.body.copyWith(color: AppColors.textPrimary)),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _Pill(
                label: switch (record.status) {
                  'Saved' => 'Calendar-ready',
                  'New' => 'Needs coach decision',
                  _ => 'Source merge check',
                },
                color: switch (record.status) {
                  'Saved' => AppColors.success,
                  'New' => AppColors.warning,
                  _ => const Color(0xFF38BDF8),
                },
              ),
              _Pill(
                label: record.division.contains('Girls')
                    ? 'Girls roster fit'
                    : 'General roster fit',
                color: record.division.contains('Girls')
                    ? const Color(0xFFEC4899)
                    : const Color(0xFF38BDF8),
              ),
              _Pill(
                label: record.distance.contains('182')
                    ? 'Travel planning needed'
                    : 'Day-trip range',
                color: record.distance.contains('182')
                    ? const Color(0xFFF97316)
                    : AppColors.success,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                  child: _MetricBox(label: 'Division', value: record.division)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                  child: _MetricBox(label: 'Weights', value: record.weights)),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader(title: 'Why it fits'),
          const SizedBox(height: AppSpacing.md),
          ...record.focus.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _ChecklistRow(text: item, color: const Color(0xFFF59E0B)),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader(title: 'Coach actions'),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              ElevatedButton.icon(
                onPressed: onSave,
                icon: const Icon(Icons.bookmark_add_outlined),
                label: const Text('Save event'),
              ),
              _TournamentExternalActionButton(
                url: record.eventPageLink,
                icon: Icons.open_in_browser_rounded,
                label: _primaryEventLinkLabel(),
              ),
              if (_shouldShowSeparateRegistrationButton())
                _TournamentExternalActionButton(
                  url: record.registrationLink,
                  icon: Icons.app_registration_rounded,
                  label: 'Registration',
                ),
              OutlinedButton.icon(
                onPressed: onAddToCalendar,
                icon: const Icon(Icons.calendar_month_rounded),
                label: const Text('Add to calendar'),
              ),
              OutlinedButton.icon(
                onPressed: onCreateFlyer,
                icon: const Icon(Icons.campaign_outlined),
                label: const Text('Create flyer'),
              ),
              OutlinedButton.icon(
                onPressed: onSendCoachAlert,
                icon: const Icon(Icons.notifications_outlined),
                label: const Text('Send coach alert'),
              ),
              OutlinedButton.icon(
                onPressed: onParentReminder,
                icon: const Icon(Icons.family_restroom_rounded),
                label: const Text('Parent reminder'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TournamentDetailScreen extends StatelessWidget {
  const _TournamentDetailScreen({
    required this.record,
    required this.onSave,
    required this.onAddToCalendar,
    required this.onCreateFlyer,
    required this.onSendCoachAlert,
    required this.onParentReminder,
  });

  final _TournamentRecord record;
  final VoidCallback onSave;
  final VoidCallback onAddToCalendar;
  final VoidCallback onCreateFlyer;
  final VoidCallback onSendCoachAlert;
  final VoidCallback onParentReminder;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            AppSpacing.lg,
            AppSpacing.screenPadding,
            AppSpacing.xl,
          ),
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back_rounded,
                      color: AppColors.textPrimary),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tournament details',
                          style: AppTextStyles.cardTitle),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(record.source, style: AppTextStyles.caption),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            _TournamentDetailPanel(
              record: record,
              onSave: onSave,
              onAddToCalendar: onAddToCalendar,
              onCreateFlyer: onCreateFlyer,
              onSendCoachAlert: onSendCoachAlert,
              onParentReminder: onParentReminder,
            ),
          ],
        ),
      ),
    );
  }
}

class _TournamentExternalActionButton extends StatelessWidget {
  const _TournamentExternalActionButton({
    required this.url,
    required this.icon,
    required this.label,
  });

  final String? url;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final resolvedUrl = url?.trim();
    if (resolvedUrl == null || resolvedUrl.isEmpty) {
      return OutlinedButton.icon(
        onPressed: null,
        icon: Icon(icon),
        label: Text(label),
      );
    }

    return OutlinedButton.icon(
      onPressed: () async {
        final opened = await openBrowserLink(resolvedUrl);
        if (!opened && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Unable to open $label right now.')),
          );
        }
      },
      icon: Icon(icon),
      label: Text(label),
    );
  }
}

class _TournamentDecisionBoard extends StatelessWidget {
  const _TournamentDecisionBoard({
    required this.savedCount,
    required this.reviewCount,
    required this.girlsCount,
  });

  final int savedCount;
  final int reviewCount;
  final int girlsCount;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _TournamentDecisionCard(
        title: 'Needs coach decision',
        value: '$reviewCount events',
        note:
            'New scans should be saved, dismissed, or turned into reminders before they pile up.',
        color: AppColors.warning,
        icon: Icons.rule_folder_outlined,
      ),
      _TournamentDecisionCard(
        title: 'Watchlist strength',
        value: '$savedCount saved',
        note:
            'Saved events are the real working queue for calendar, travel, and flyer follow-up.',
        color: const Color(0xFF38BDF8),
        icon: Icons.bookmarks_rounded,
      ),
      _TournamentDecisionCard(
        title: 'Girls opportunities',
        value: '$girlsCount events',
        note:
            'Keep strong girls-fit tournaments easy to surface and promote quickly.',
        color: const Color(0xFFEC4899),
        icon: Icons.workspace_premium_rounded,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 980;
        if (stacked) {
          return Column(
            children: [
              for (var i = 0; i < cards.length; i++) ...[
                cards[i],
                if (i != cards.length - 1)
                  const SizedBox(height: AppSpacing.md),
              ],
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < cards.length; i++) ...[
              Expanded(child: cards[i]),
              if (i != cards.length - 1) const SizedBox(width: AppSpacing.md),
            ],
          ],
        );
      },
    );
  }
}

class _TournamentDecisionCard extends StatelessWidget {
  const _TournamentDecisionCard({
    required this.title,
    required this.value,
    required this.note,
    required this.color,
    required this.icon,
  });

  final String title;
  final String value;
  final String note;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              Text(value, style: AppTextStyles.caption.copyWith(color: color)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(title, style: AppTextStyles.bodyStrong),
          const SizedBox(height: AppSpacing.xs),
          Text(note,
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _TournamentRecord {
  const _TournamentRecord({
    required this.id,
    required this.title,
    required this.startDate,
    required this.endDate,
    required this.location,
    required this.dateLabel,
    required this.source,
    required this.status,
    required this.division,
    required this.weights,
    required this.distance,
    required this.notes,
    required this.focus,
    required this.distanceMiles,
    required this.isSaved,
    required this.eventPageLink,
    required this.registrationLink,
    required this.isPastEvent,
  });

  final int id;
  final String title;
  final DateTime startDate;
  final DateTime endDate;
  final String location;
  final String dateLabel;
  final String source;
  final String status;
  final String division;
  final String weights;
  final String distance;
  final String notes;
  final List<String> focus;
  final double? distanceMiles;
  final bool isSaved;
  final String? eventPageLink;
  final String? registrationLink;
  final bool isPastEvent;

  factory _TournamentRecord.fromModel(TournamentExternalModel model) {
    final locationParts = [
      if ((model.locationName ?? '').trim().isNotEmpty)
        model.locationName!.trim(),
      if ((model.city ?? '').trim().isNotEmpty) model.city!.trim(),
      if ((model.state ?? '').trim().isNotEmpty) model.state!.trim(),
    ];
    final location =
        locationParts.isEmpty ? 'Location pending' : locationParts.join(', ');
    final division = model.ageDivisions.isEmpty
        ? _titleCase(model.eventType)
        : model.ageDivisions.join(' + ');
    final weights =
        (model.weightClasses == null || model.weightClasses!.isEmpty)
            ? 'Weight classes pending'
            : model.weightClasses!.join(', ');
    final status = model.isSaved
        ? 'Saved'
        : model.ingestionStatus == 'normalized'
            ? 'New'
            : 'Scan match';
    final notes = model.description?.trim().isNotEmpty == true
        ? model.description!.trim()
        : model.ingestionNotes?.trim().isNotEmpty == true
            ? model.ingestionNotes!.trim()
            : 'This event is available in the discovery database and ready for a coach decision.';

    return _TournamentRecord(
      id: model.id,
      title: model.name,
      startDate: model.startDate,
      endDate: model.endDate,
      location: location,
      dateLabel: _formatDateRange(model.startDate, model.endDate),
      source: _displaySourceName(model.sourceLabel),
      status: status,
      division: division,
      weights: weights,
      distance: model.distanceMiles == null
          ? 'Distance pending'
          : '${model.distanceMiles!.round()} mi',
      notes: notes,
      focus: [
        if (model.recommendationScore != null)
          'Recommendation score ${model.recommendationScore!.toStringAsFixed(1)} based on roster fit and timing.',
        if (model.registrationLink != null &&
            model.registrationLink!.isNotEmpty)
          'Registration link is already attached for coach follow-through.',
        if (model.deadline != null)
          'Deadline lands on ${_formatShortDate(model.deadline!)}.',
        if (model.isOnTeamSchedule)
          'This event is already linked into the team schedule.',
      ].isEmpty
          ? [
              'Coach review is needed before this event becomes part of the working calendar.'
            ]
          : [
              if (model.recommendationScore != null)
                'Recommendation score ${model.recommendationScore!.toStringAsFixed(1)} based on roster fit and timing.',
              if (model.registrationLink != null &&
                  model.registrationLink!.isNotEmpty)
                'Registration link is already attached for coach follow-through.',
              if (model.deadline != null)
                'Deadline lands on ${_formatShortDate(model.deadline!)}.',
              if (model.isOnTeamSchedule)
                'This event is already linked into the team schedule.',
            ],
      distanceMiles: model.distanceMiles,
      isSaved: model.isSaved,
      eventPageLink: model.eventPageLink,
      registrationLink: model.registrationLink,
      isPastEvent: model.endDate.isBefore(DateTime.now()),
    );
  }
}

class _ScannerStatusRow extends StatelessWidget {
  const _ScannerStatusRow({required this.sources});

  final List<TournamentSourceModel> sources;

  @override
  Widget build(BuildContext context) {
    final cards = sources.isEmpty
        ? const [
            _StatusCard(
              title: 'Tournament sources',
              value: 'Waiting',
              subtitle:
                  'No source records came back from the backend. Refresh or check API health.',
              color: AppColors.textMuted,
            ),
          ]
        : sources
            .map(
              (source) => _StatusCard(
                title: _displaySourceName(source.displayName),
                value: source.isActive ? 'Configured' : 'Offline',
                subtitle: source.supportsScraping
                    ? 'Discovery source is configured in the backend'
                    : 'Source is configured but not crawler-backed yet',
                color: source.isActive ? AppColors.success : AppColors.warning,
              ),
            )
            .toList();

    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      children: cards.map((card) => SizedBox(width: 260, child: card)).toList(),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({
    required this.message,
    required this.color,
    required this.icon,
  });

  final String message;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

class _TournamentWorkflowRow extends StatelessWidget {
  const _TournamentWorkflowRow({required this.records});

  final List<_TournamentRecord> records;

  @override
  Widget build(BuildContext context) {
    final saved = records.where((record) => record.status == 'Saved').length;
    final needsReview = records
        .where(
            (record) => record.status == 'New' || record.status == 'Scan match')
        .length;
    final flyerReady = records
        .where((record) =>
            record.focus.any((item) => item.toLowerCase().contains('flyer')))
        .length;

    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      children: [
        SizedBox(
          width: 260,
          child: _StatusCard(
            title: 'Needs save',
            value: '$needsReview',
            subtitle: 'new scans still need coach decisions',
            color: const Color(0xFFF59E0B),
          ),
        ),
        SizedBox(
          width: 260,
          child: _StatusCard(
            title: 'Saved events',
            value: '$saved',
            subtitle: 'watchlist and calendar-ready events',
            color: const Color(0xFF38BDF8),
          ),
        ),
        SizedBox(
          width: 260,
          child: _StatusCard(
            title: 'Flyer-ready',
            value: '$flyerReady',
            subtitle: 'good candidates for promotion or graphics',
            color: AppColors.success,
          ),
        ),
        const SizedBox(
          width: 260,
          child: _StatusCard(
            title: 'Alert-ready',
            value: '3',
            subtitle: 'events worth saving with reminders',
            color: Color(0xFF8B5CF6),
          ),
        ),
      ],
    );
  }
}

class _TournamentChangeWatch extends StatelessWidget {
  const _TournamentChangeWatch();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 980;
        final items = const [
          _TournamentChangeItem(
            title: 'Bluegrass Spring Open updated deadline',
            subtitle:
                'Registration now closes 48 hours earlier than the last scan.',
            status: 'Deadline',
            color: AppColors.warning,
          ),
          _TournamentChangeItem(
            title: 'Cardinal Dual Showcase merged source data',
            subtitle:
                'Track and Flo entries now resolve to one cleaned event record.',
            status: 'Merged',
            color: Color(0xFF38BDF8),
          ),
          _TournamentChangeItem(
            title: 'Mountain Regional Girls Day marked alert-ready',
            subtitle:
                'Good fit for girls roster and parent-visible reminder flow.',
            status: 'Alert',
            color: Color(0xFF8B5CF6),
          ),
        ];

        if (!wide) {
          return Column(
            children: items
                .map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _TournamentChangeCard(item: item),
                    ))
                .toList(),
          );
        }

        return Row(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              Expanded(child: _TournamentChangeCard(item: items[i])),
              if (i != items.length - 1) const SizedBox(width: AppSpacing.md),
            ],
          ],
        );
      },
    );
  }
}

class _TournamentChangeItem {
  const _TournamentChangeItem({
    required this.title,
    required this.subtitle,
    required this.status,
    required this.color,
  });

  final String title;
  final String subtitle;
  final String status;
  final Color color;
}

class _TournamentChangeCard extends StatelessWidget {
  const _TournamentChangeCard({required this.item});

  final _TournamentChangeItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(item.status,
                  style: AppTextStyles.caption.copyWith(color: item.color)),
              const Spacer(),
              Icon(Icons.history_toggle_off_rounded,
                  size: 18, color: item.color),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(item.title, style: AppTextStyles.bodyStrong),
          const SizedBox(height: AppSpacing.xs),
          Text(item.subtitle, style: AppTextStyles.body),
        ],
      ),
    );
  }
}

class _SummaryBand extends StatelessWidget {
  const _SummaryBand({
    required this.accent,
    required this.items,
  });

  final Color accent;
  final List<_SummaryItem> items;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: items
          .map(
            (item) => SizedBox(
              width: 230,
              child: _StatusCard(
                title: item.label,
                value: item.value,
                subtitle: item.note,
                color: accent,
              ),
            ),
          )
          .toList(),
    );
  }
}

class _SummaryItem {
  const _SummaryItem({
    required this.label,
    required this.value,
    required this.note,
  });

  final String label;
  final String value;
  final String note;
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
  });

  final String title;
  final String value;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.72)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 36,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(value, style: AppTextStyles.bodyStrong.copyWith(color: color)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.caption),
                Text(subtitle, style: AppTextStyles.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricBox extends StatelessWidget {
  const _MetricBox({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.46),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.72)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.caption),
          const SizedBox(height: AppSpacing.xxs),
          Text(value, style: AppTextStyles.bodyStrong),
        ],
      ),
    );
  }
}

class _ChecklistRow extends StatelessWidget {
  const _ChecklistRow({
    required this.text,
    required this.color,
  });

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Icon(Icons.check_circle_rounded, size: 18, color: color),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(text, style: AppTextStyles.body)),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(color: AppColors.textPrimary),
      ),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message, style: AppTextStyles.body),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.travel_explore_rounded),
              label: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}
