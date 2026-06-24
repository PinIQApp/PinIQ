import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../models/recruiting_models.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/section_header.dart';
import '../../widgets/subpage_header.dart';

class RecruitingCenterScreen extends StatefulWidget {
  const RecruitingCenterScreen({super.key});

  @override
  State<RecruitingCenterScreen> createState() => _RecruitingCenterScreenState();
}

class _RecruitingCenterScreenState extends State<RecruitingCenterScreen> {
  String _filter = 'all';
  int _selectedIndex = 0;
  bool _isLoading = true;
  bool _isSavingLinks = false;
  bool _isScanning = false;
  String? _error;
  String? _sourceStatus;
  List<RecruitingAthleteModel> _athletes = [];
  final Map<int, List<RecruitingSourceLinkModel>> _sourceLinksByAthlete = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadRecruitingData());
  }

  Future<void> _loadRecruitingData() async {
    final appState = context.read<AppState>();
    final token = appState.token;
    if (token == null) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final athletes = await appState.api.fetchRecruitingAthletes(token: token);
      if (!mounted) return;
      setState(() {
        _athletes = athletes;
        _selectedIndex = 0;
        _isLoading = false;
      });
      if (athletes.isNotEmpty) {
        await _loadSourceLinks(athletes.first.athleteId);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _loadSourceLinks(int athleteId) async {
    final appState = context.read<AppState>();
    final token = appState.token;
    if (token == null || _sourceLinksByAthlete.containsKey(athleteId)) return;
    try {
      final links = await appState.api.fetchRecruitingSourceLinks(
        token: token,
        athleteId: athleteId,
      );
      if (!mounted) return;
      setState(() => _sourceLinksByAthlete[athleteId] = links);
    } catch (error) {
      if (!mounted) return;
      setState(() =>
          _sourceStatus = error.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _selectAthlete(
      int index, List<RecruitingAthleteModel> visible) async {
    setState(() {
      _selectedIndex = index;
      _sourceStatus = null;
    });
    await _loadSourceLinks(visible[index].athleteId);
  }

  Future<void> _saveSourceLinks(
    RecruitingAthleteModel athlete,
    List<RecruitingSourceLinkModel> links,
  ) async {
    final appState = context.read<AppState>();
    final token = appState.token;
    if (token == null) return;
    setState(() {
      _isSavingLinks = true;
      _sourceStatus = null;
    });
    try {
      final saved = await appState.api.saveRecruitingSourceLinks(
        token: token,
        athleteId: athlete.athleteId,
        sourceLinks: links,
      );
      if (!mounted) return;
      setState(() {
        _sourceLinksByAthlete[athlete.athleteId] = saved;
        _sourceStatus = 'Source links saved.';
        _isSavingLinks = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _sourceStatus = error.toString().replaceFirst('Exception: ', '');
        _isSavingLinks = false;
      });
    }
  }

  Future<void> _scanSourceLinks(RecruitingAthleteModel athlete) async {
    final appState = context.read<AppState>();
    final token = appState.token;
    final links = _sourceLinksByAthlete[athlete.athleteId] ?? const [];
    if (token == null || links.isEmpty) return;
    setState(() {
      _isScanning = true;
      _sourceStatus = null;
    });
    try {
      final result = await appState.api.scanRecruitingSources(
        token: token,
        athleteId: athlete.athleteId,
        sourceLinks: links,
      );
      final refreshed =
          await appState.api.fetchRecruitingAthletes(token: token);
      if (!mounted) return;
      setState(() {
        _athletes = refreshed;
        _sourceStatus =
            'Scan complete: ${result.sourceRankings.length} wrestler rows, ${result.schoolRankings.length} school rows.';
        _isScanning = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _sourceStatus = error.toString().replaceFirst('Exception: ', '');
        _isScanning = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final visible = _athletes.where((athlete) {
      return switch (_filter) {
        'priority' => athlete.isFeatured || athlete.isActivelyLooking,
        'seniors' => athlete.graduationYear <= DateTime.now().year + 1,
        'missing' => athlete.highlightCount == 0,
        'watchlist' => athlete.sourceRankings.isNotEmpty,
        _ => true,
      };
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
              title: 'Recruiting Center',
              subtitle:
                  'Track athlete readiness, outreach, and exposure from one recruiting board.',
            ),
            const SizedBox(height: AppSpacing.lg),
            if (_isLoading)
              const _RecruitingLoadingPanel()
            else if (_error != null)
              _RecruitingMessagePanel(
                title: 'Recruiting data did not load',
                message: _error!,
                actionLabel: 'Retry',
                onAction: _loadRecruitingData,
              )
            else if (_athletes.isEmpty)
              const _RecruitingMessagePanel(
                title: 'No recruiting profiles yet',
                message:
                    'Create athlete recruiting profiles first, then Pin IQ can track verified rankings and records from public sources.',
              )
            else ...[
              _RecruitingSummaryRow(athletes: _athletes),
              const SizedBox(height: AppSpacing.xl),
              _SchoolRankingBoards(athletes: _athletes),
              const SizedBox(height: AppSpacing.xl),
              if (isWide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 5,
                      child: _RecruitingBoard(
                        filter: _filter,
                        onFilterChanged: (value) => setState(() {
                          _filter = value;
                          _selectedIndex = 0;
                        }),
                        athletes: visible,
                        selectedIndex: _selectedIndex,
                        onSelect: (index) => _selectAthlete(index, visible),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      flex: 4,
                      child: selected == null
                          ? const _RecruitingEmptyPanel()
                          : _RecruitingDetailPanel(
                              athlete: selected,
                              sourceLinks:
                                  _sourceLinksByAthlete[selected.athleteId] ??
                                      const [],
                              isSavingLinks: _isSavingLinks,
                              isScanning: _isScanning,
                              sourceStatus: _sourceStatus,
                              onSaveSourceLinks: (links) =>
                                  _saveSourceLinks(selected, links),
                              onScanSourceLinks: () =>
                                  _scanSourceLinks(selected),
                            ),
                    ),
                  ],
                )
              else ...[
                _RecruitingBoard(
                  filter: _filter,
                  onFilterChanged: (value) => setState(() {
                    _filter = value;
                    _selectedIndex = 0;
                  }),
                  athletes: visible,
                  selectedIndex: _selectedIndex,
                  onSelect: (index) => _selectAthlete(index, visible),
                ),
                const SizedBox(height: AppSpacing.lg),
                if (selected == null)
                  const _RecruitingEmptyPanel()
                else
                  _RecruitingDetailPanel(
                    athlete: selected,
                    sourceLinks:
                        _sourceLinksByAthlete[selected.athleteId] ?? const [],
                    isSavingLinks: _isSavingLinks,
                    isScanning: _isScanning,
                    sourceStatus: _sourceStatus,
                    onSaveSourceLinks: (links) =>
                        _saveSourceLinks(selected, links),
                    onScanSourceLinks: () => _scanSourceLinks(selected),
                  ),
              ],
              const SizedBox(height: AppSpacing.xl),
              const SectionHeader(title: 'Outreach pipeline'),
              const SizedBox(height: AppSpacing.md),
              _RecruitingPipelineRow(athletes: _athletes),
              const SizedBox(height: AppSpacing.xl),
            ],
          ],
        );
      },
    );
  }
}

class _RecruitingSummaryRow extends StatelessWidget {
  const _RecruitingSummaryRow({required this.athletes});

  final List<RecruitingAthleteModel> athletes;

  @override
  Widget build(BuildContext context) {
    final priority = athletes
        .where((athlete) => athlete.isFeatured || athlete.isActivelyLooking)
        .length;
    final verified =
        athletes.where((athlete) => athlete.sourceRankings.isNotEmpty).length;
    final schools = athletes
        .map((athlete) => athlete.schoolTeam)
        .where((school) => school != null && school.trim().isNotEmpty)
        .toSet()
        .length;
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      children: [
        SizedBox(
          width: 240,
          child: _RecruitingMetricCard(
            label: 'Profiles',
            value: '${athletes.length}',
            note: 'active athlete pages',
            color: Color(0xFF8B5CF6),
          ),
        ),
        SizedBox(
          width: 240,
          child: _RecruitingMetricCard(
            label: 'Priority',
            value: '$priority',
            note: 'athletes needing push',
            color: Color(0xFFF59E0B),
          ),
        ),
        SizedBox(
          width: 240,
          child: _RecruitingMetricCard(
            label: 'Verified',
            value: '$verified',
            note: 'source-ranked athletes',
            color: Color(0xFF38BDF8),
          ),
        ),
        SizedBox(
          width: 240,
          child: _RecruitingMetricCard(
            label: 'Schools',
            value: '$schools',
            note: 'tracked programs',
            color: AppColors.success,
          ),
        ),
      ],
    );
  }
}

class _SchoolRankingBoardRow {
  const _SchoolRankingBoardRow({
    required this.schoolName,
    required this.source,
    required this.athleteNames,
    this.state,
    this.stateRank,
    this.nationalRank,
    this.division,
    this.season,
  });

  final String schoolName;
  final String source;
  final String? state;
  final int? stateRank;
  final int? nationalRank;
  final String? division;
  final String? season;
  final List<String> athleteNames;
}

class _SchoolRankingBoards extends StatelessWidget {
  const _SchoolRankingBoards({required this.athletes});

  final List<RecruitingAthleteModel> athletes;

  @override
  Widget build(BuildContext context) {
    final stateRows = _buildSchoolRankingRows(athletes, national: false);
    final nationalRows = _buildSchoolRankingRows(athletes, national: true);
    if (stateRows.isEmpty && nationalRows.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'School rankings'),
        const SizedBox(height: AppSpacing.md),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 900;
            final boards = [
              Expanded(
                child: _SchoolRankingList(
                  title: 'State board',
                  rows: stateRows,
                  national: false,
                ),
              ),
              Expanded(
                child: _SchoolRankingList(
                  title: 'National board',
                  rows: nationalRows,
                  national: true,
                ),
              ),
            ];
            if (isWide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  boards.first,
                  const SizedBox(width: AppSpacing.md),
                  boards.last,
                ],
              );
            }
            return Column(
              children: [
                _SchoolRankingList(
                  title: 'State board',
                  rows: stateRows,
                  national: false,
                ),
                const SizedBox(height: AppSpacing.md),
                _SchoolRankingList(
                  title: 'National board',
                  rows: nationalRows,
                  national: true,
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _SchoolRankingList extends StatelessWidget {
  const _SchoolRankingList({
    required this.title,
    required this.rows,
    required this.national,
  });

  final String title;
  final List<_SchoolRankingBoardRow> rows;
  final bool national;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.bodyStrong),
          const SizedBox(height: AppSpacing.md),
          if (rows.isEmpty)
            Text('No verified school rankings yet.', style: AppTextStyles.body)
          else
            for (final row in rows.take(6))
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _SchoolRankingTile(row: row, national: national),
              ),
        ],
      ),
    );
  }
}

class _SchoolRankingTile extends StatelessWidget {
  const _SchoolRankingTile({required this.row, required this.national});

  final _SchoolRankingBoardRow row;
  final bool national;

  @override
  Widget build(BuildContext context) {
    final rank = national ? row.nationalRank : row.stateRank;
    final subtitle = [
      row.source,
      if (row.state != null) row.state!,
      if (row.division != null) row.division!,
      if (row.season != null) row.season!,
    ].join(' • ');
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text('#${rank ?? '-'}', style: AppTextStyles.bodyStrong),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(row.schoolName, style: AppTextStyles.bodyStrong),
              const SizedBox(height: AppSpacing.xxs),
              Text(subtitle, style: AppTextStyles.caption),
              if (row.athleteNames.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  row.athleteNames.take(3).join(', '),
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textPrimary),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

List<_SchoolRankingBoardRow> _buildSchoolRankingRows(
  List<RecruitingAthleteModel> athletes, {
  required bool national,
}) {
  final rows = <String, _SchoolRankingBoardRow>{};
  for (final athlete in athletes) {
    for (final ranking in athlete.schoolRankings) {
      final rank = national ? ranking.nationalRank : ranking.stateRank;
      if (rank == null) continue;
      final key = [
        ranking.source,
        ranking.schoolName.toLowerCase().trim(),
        ranking.state ?? '',
        ranking.division ?? '',
        ranking.season ?? '',
      ].join('|');
      final existing = rows[key];
      if (existing == null) {
        rows[key] = _SchoolRankingBoardRow(
          schoolName: ranking.schoolName,
          source: ranking.source,
          state: ranking.state,
          stateRank: ranking.stateRank,
          nationalRank: ranking.nationalRank,
          division: ranking.division,
          season: ranking.season,
          athleteNames: [athlete.athleteName],
        );
      } else if (!existing.athleteNames.contains(athlete.athleteName)) {
        existing.athleteNames.add(athlete.athleteName);
      }
    }
  }
  final values = rows.values.toList()
    ..sort((a, b) {
      final left = national ? a.nationalRank ?? 9999 : a.stateRank ?? 9999;
      final right = national ? b.nationalRank ?? 9999 : b.stateRank ?? 9999;
      final rankCompare = left.compareTo(right);
      if (rankCompare != 0) return rankCompare;
      return a.schoolName.compareTo(b.schoolName);
    });
  return values;
}

class _RecruitingBoard extends StatelessWidget {
  const _RecruitingBoard({
    required this.filter,
    required this.onFilterChanged,
    required this.athletes,
    required this.selectedIndex,
    required this.onSelect,
  });

  final String filter;
  final ValueChanged<String> onFilterChanged;
  final List<RecruitingAthleteModel> athletes;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (constraints.maxWidth >= 560)
              Row(
                children: [
                  Text('Athlete board',
                      style: AppTextStyles.cardTitle.copyWith(fontSize: 22)),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.share_outlined),
                    label: const Text('Export share pack'),
                  ),
                ],
              )
            else ...[
              Text('Athlete board',
                  style: AppTextStyles.cardTitle.copyWith(fontSize: 22)),
              const SizedBox(height: AppSpacing.sm),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.share_outlined),
                label: const Text('Export share pack'),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final chip in const [
                    ('all', 'All'),
                    ('priority', 'Priority'),
                    ('seniors', 'Seniors'),
                    ('watchlist', 'Watchlist'),
                    ('missing', 'Missing media'),
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
            const SizedBox(height: AppSpacing.lg),
            ...List.generate(athletes.length, (index) {
              final athlete = athletes[index];
              return Padding(
                padding: EdgeInsets.only(
                    bottom: index == athletes.length - 1 ? 0 : AppSpacing.sm),
                child: _RecruitingRow(
                  athlete: athlete,
                  selected: index == selectedIndex,
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

class _RecruitingRow extends StatelessWidget {
  const _RecruitingRow({
    required this.athlete,
    required this.selected,
    required this.onTap,
  });

  final RecruitingAthleteModel athlete;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final status = _statusLabel(athlete);
    final accent = switch (status) {
      'Priority' => const Color(0xFFF59E0B),
      'Missing media' => const Color(0xFFEF4444),
      'Verified' => AppColors.success,
      _ => const Color(0xFF8B5CF6),
    };

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.surfaceElevated
              : AppColors.surface.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color:
                  selected ? accent.withValues(alpha: 0.4) : AppColors.border),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: accent.withValues(alpha: 0.18),
              child: Text(
                athlete.athleteName.substring(0, 1),
                style: AppTextStyles.bodyStrong.copyWith(color: accent),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(athlete.athleteName, style: AppTextStyles.bodyStrong),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    '${_gradeLabel(athlete.graduationYear)} • ${athlete.weightClass} lbs • ${athlete.record}',
                    style: AppTextStyles.caption,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: [
                      _RecruitingTag(label: status, color: accent),
                      _RecruitingTag(
                          label: _rankingLabel(athlete),
                          color: const Color(0xFF38BDF8)),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

String _gradeLabel(int graduationYear) {
  final currentYear = DateTime.now().year;
  final yearsLeft = graduationYear - currentYear;
  if (yearsLeft <= 0) return 'Senior';
  if (yearsLeft == 1) return 'Junior';
  if (yearsLeft == 2) return 'Sophomore';
  return 'Freshman';
}

String _statusLabel(RecruitingAthleteModel athlete) {
  if (athlete.isFeatured || athlete.isActivelyLooking) return 'Priority';
  if (athlete.sourceRankings.isNotEmpty) return 'Verified';
  if (athlete.highlightCount == 0) return 'Missing media';
  return 'Ready';
}

String _rankingLabel(RecruitingAthleteModel athlete) {
  if (athlete.sourceRankings.isEmpty) return 'No source rank';
  final ranking = athlete.sourceRankings.first;
  return '${ranking.source} ${ranking.ranking ?? ranking.record ?? 'verified'}';
}

String _pinIqRankingNote(RecruitingAthleteModel athlete) {
  final ranking = athlete.pinIqRanking;
  if (ranking == null) return 'needs verified data';
  final rankHints = [
    if (ranking.stateRankHint != null) 'State #${ranking.stateRankHint}',
    if (ranking.nationalRankHint != null)
      'National #${ranking.nationalRankHint}',
  ];
  if (rankHints.isNotEmpty) return rankHints.join(' • ');
  return '${ranking.tier} • ${ranking.confidence} confidence';
}

class _RecruitingDetailPanel extends StatelessWidget {
  const _RecruitingDetailPanel({
    required this.athlete,
    required this.sourceLinks,
    required this.isSavingLinks,
    required this.isScanning,
    required this.onSaveSourceLinks,
    required this.onScanSourceLinks,
    this.sourceStatus,
  });

  final RecruitingAthleteModel athlete;
  final List<RecruitingSourceLinkModel> sourceLinks;
  final bool isSavingLinks;
  final bool isScanning;
  final String? sourceStatus;
  final ValueChanged<List<RecruitingSourceLinkModel>> onSaveSourceLinks;
  final VoidCallback onScanSourceLinks;

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
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(athlete.athleteName,
                        style: AppTextStyles.sectionTitle),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      '${_gradeLabel(athlete.graduationYear)} • ${athlete.weightClass} lbs • ${athlete.record}',
                      style: AppTextStyles.body,
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.link_rounded),
                label: const Text('Share page'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            [
              if (athlete.schoolTeam != null) athlete.schoolTeam!,
              if (athlete.locationLabel != null) athlete.locationLabel!,
              if (athlete.height != null) athlete.height!,
            ].join(' • '),
            style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              SizedBox(
                width: 170,
                child: _RecruitingMetricCard(
                  label: 'Pin IQ',
                  value: athlete.pinIqRanking == null
                      ? '--'
                      : athlete.pinIqRanking!.score.toStringAsFixed(0),
                  note: _pinIqRankingNote(athlete),
                  color: AppColors.success,
                ),
              ),
              SizedBox(
                width: 170,
                child: _RecruitingMetricCard(
                  label: 'Record',
                  value: athlete.record,
                  note: 'profile record',
                  color: const Color(0xFF8B5CF6),
                ),
              ),
              SizedBox(
                width: 190,
                child: _RecruitingMetricCard(
                  label: 'Sources',
                  value: '${athlete.sourceRankings.length}',
                  note: 'verified ranking rows',
                  color: const Color(0xFF38BDF8),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader(title: 'Verified rankings'),
          const SizedBox(height: AppSpacing.md),
          if (athlete.sourceRankings.isEmpty && athlete.schoolRankings.isEmpty)
            Text('No verified source rankings yet.', style: AppTextStyles.body)
          else ...[
            for (final ranking in athlete.sourceRankings)
              _VerifiedRankingRow(
                title: ranking.source,
                value: ranking.ranking ?? ranking.record ?? 'Verified',
                note: [
                  if (ranking.weightClass != null) '${ranking.weightClass} lbs',
                  if (ranking.season != null) ranking.season!,
                  if (ranking.lastChecked != null)
                    'checked ${ranking.lastChecked}',
                ].join(' • '),
              ),
            for (final ranking in athlete.schoolRankings)
              _VerifiedRankingRow(
                title: ranking.source,
                value: [
                  if (ranking.stateRank != null) 'KY #${ranking.stateRank}',
                  if (ranking.nationalRank != null)
                    'US #${ranking.nationalRank}',
                ].join(' • '),
                note: ranking.schoolName,
              ),
          ],
          const SizedBox(height: AppSpacing.lg),
          _SourceScanAuditPanel(entries: athlete.sourceScanAudit),
          const SizedBox(height: AppSpacing.lg),
          _SourceLinksPanel(
            links: sourceLinks,
            isSaving: isSavingLinks,
            isScanning: isScanning,
            status: sourceStatus,
            onSave: onSaveSourceLinks,
            onScan: onScanSourceLinks,
          ),
        ],
      ),
    );
  }
}

class _SourceScanAuditPanel extends StatelessWidget {
  const _SourceScanAuditPanel({required this.entries});

  final List<RecruitingSourceScanAuditModel> entries;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated.withValues(alpha: 0.68),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Source audit', style: AppTextStyles.bodyStrong),
          const SizedBox(height: AppSpacing.md),
          if (entries.isEmpty)
            Text('No source scans logged yet.', style: AppTextStyles.body)
          else
            for (final entry in entries.take(4))
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _SourceScanAuditRow(entry: entry),
              ),
        ],
      ),
    );
  }
}

class _SourceScanAuditRow extends StatelessWidget {
  const _SourceScanAuditRow({required this.entry});

  final RecruitingSourceScanAuditModel entry;

  @override
  Widget build(BuildContext context) {
    final color = entry.success ? AppColors.success : AppColors.danger;
    final changed = entry.changedFields.isEmpty
        ? 'no ranking changes'
        : entry.changedFields.join(', ');
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          entry.success ? Icons.check_circle_outline : Icons.error_outline,
          color: color,
          size: 20,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(entry.source, style: AppTextStyles.bodyStrong),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                '${_shortDateTime(entry.scannedAt)} • $changed',
                style: AppTextStyles.caption,
              ),
              Text(
                entry.url,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textPrimary),
              ),
              if (entry.message != null && entry.message!.trim().isNotEmpty)
                Text(entry.message!, style: AppTextStyles.caption),
            ],
          ),
        ),
      ],
    );
  }
}

String _shortDateTime(DateTime value) {
  final local = value.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$month/$day $hour:$minute';
}

class _VerifiedRankingRow extends StatelessWidget {
  const _VerifiedRankingRow({
    required this.title,
    required this.value,
    required this.note,
  });

  final String title;
  final String value;
  final String note;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          const Icon(Icons.verified_outlined, color: AppColors.success),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.bodyStrong),
                if (note.isNotEmpty) Text(note, style: AppTextStyles.caption),
              ],
            ),
          ),
          Text(value.isEmpty ? 'Verified' : value,
              style: AppTextStyles.bodyStrong),
        ],
      ),
    );
  }
}

class _RecruitingTag extends StatelessWidget {
  const _RecruitingTag({
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

class _SourceLinksPanel extends StatefulWidget {
  const _SourceLinksPanel({
    required this.links,
    required this.isSaving,
    required this.isScanning,
    required this.onSave,
    required this.onScan,
    this.status,
  });

  final List<RecruitingSourceLinkModel> links;
  final bool isSaving;
  final bool isScanning;
  final String? status;
  final ValueChanged<List<RecruitingSourceLinkModel>> onSave;
  final VoidCallback onScan;

  @override
  State<_SourceLinksPanel> createState() => _SourceLinksPanelState();
}

class _SourceLinksPanelState extends State<_SourceLinksPanel> {
  static const _sources = [
    'KentuckyMat',
    'TrackWrestling',
    'FloWrestling',
    'USA Bracketing'
  ];
  late final Map<String, TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = {
      for (final source in _sources)
        source: TextEditingController(text: _urlFor(source)),
    };
  }

  @override
  void didUpdateWidget(covariant _SourceLinksPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.links == widget.links) return;
    for (final source in _sources) {
      _controllers[source]!.text = _urlFor(source);
    }
  }

  String _urlFor(String source) {
    for (final link in widget.links) {
      if (link.source.toLowerCase() == source.toLowerCase()) return link.url;
    }
    return '';
  }

  List<RecruitingSourceLinkModel> _currentLinks() {
    return _sources
        .map((source) => RecruitingSourceLinkModel(
              source: source,
              url: _controllers[source]!.text.trim(),
            ))
        .where((link) => link.url.isNotEmpty)
        .toList();
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasLinks = _currentLinks().isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Source links', style: AppTextStyles.cardTitle),
              const Spacer(),
              if (widget.isSaving || widget.isScanning)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          for (final source in _sources) ...[
            TextField(
              controller: _controllers[source],
              decoration: InputDecoration(
                labelText: source,
                hintText: source == 'KentuckyMat'
                    ? 'https://kentuckymat.com/...'
                    : source == 'TrackWrestling'
                        ? 'https://www.trackwrestling.com/...'
                        : 'Public ranking/profile URL',
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          if (widget.status != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(widget.status!,
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textPrimary)),
          ],
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              ElevatedButton.icon(
                onPressed: widget.isSaving
                    ? null
                    : () => widget.onSave(_currentLinks()),
                icon: const Icon(Icons.save_outlined),
                label: const Text('Save links'),
              ),
              OutlinedButton.icon(
                onPressed:
                    widget.isScanning || !hasLinks ? null : widget.onScan,
                icon: const Icon(Icons.radar_outlined),
                label: const Text('Scan now'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecruitingMetricCard extends StatelessWidget {
  const _RecruitingMetricCard({
    required this.label,
    required this.value,
    required this.note,
    required this.color,
  });

  final String label;
  final String value;
  final String note;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.caption),
          const SizedBox(height: AppSpacing.sm),
          Text(value, style: AppTextStyles.cardTitle.copyWith(color: color)),
          const SizedBox(height: AppSpacing.xxs),
          Text(note, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

class _RecruitingEmptyPanel extends StatelessWidget {
  const _RecruitingEmptyPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        'No athletes match the current recruiting filter.',
        style: AppTextStyles.body,
      ),
    );
  }
}

class _RecruitingLoadingPanel extends StatelessWidget {
  const _RecruitingLoadingPanel();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(AppSpacing.xl),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _RecruitingMessagePanel extends StatelessWidget {
  const _RecruitingMessagePanel({
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final String title;
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
          Text(title, style: AppTextStyles.cardTitle),
          const SizedBox(height: AppSpacing.sm),
          Text(message, style: AppTextStyles.body),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AppSpacing.md),
            OutlinedButton(
              onPressed: onAction,
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

class _RecruitingPipelineRow extends StatelessWidget {
  const _RecruitingPipelineRow({required this.athletes});

  final List<RecruitingAthleteModel> athletes;

  @override
  Widget build(BuildContext context) {
    final ready = athletes
        .where((athlete) =>
            athlete.sourceRankings.isNotEmpty || athlete.isFeatured)
        .length;
    final missing =
        athletes.where((athlete) => athlete.highlightCount == 0).length;
    final seniors = athletes
        .where((athlete) => athlete.graduationYear <= DateTime.now().year + 1)
        .length;

    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      children: [
        SizedBox(
          width: 260,
          child: _RecruitingMetricCard(
            label: 'Ready to share',
            value: '$ready',
            note: 'profiles ready for outreach packets',
            color: AppColors.success,
          ),
        ),
        SizedBox(
          width: 260,
          child: _RecruitingMetricCard(
            label: 'Missing media',
            value: '$missing',
            note: 'athletes blocking cleaner recruiting pages',
            color: const Color(0xFFEF4444),
          ),
        ),
        SizedBox(
          width: 260,
          child: _RecruitingMetricCard(
            label: 'Senior push',
            value: '$seniors',
            note: 'upperclassmen needing active outreach',
            color: const Color(0xFFF59E0B),
          ),
        ),
      ],
    );
  }
}
