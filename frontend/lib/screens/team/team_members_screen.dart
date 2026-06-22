import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../models/team_member_model.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/empty_state_card.dart';
import '../../widgets/section_header.dart';
import '../../widgets/subpage_header.dart';

class TeamMembersScreen extends StatefulWidget {
  const TeamMembersScreen({super.key});

  @override
  State<TeamMembersScreen> createState() => _TeamMembersScreenState();
}

class _TeamMembersScreenState extends State<TeamMembersScreen> {
  final _searchController = TextEditingController();
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    context.read<AppState>().refreshTeamMembers();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final team = appState.activeTeam;
    final members = team?.members ?? [];
    final pendingMembers = members.where((member) => member.status == 'pending').toList();
    final approvedMembers = members.where((member) => member.status == 'approved').toList();
    final visibleApproved = approvedMembers.where(_matchesFilter).where(_matchesSearch).toList();
    final visiblePending = pendingMembers.where(_matchesFilter).where(_matchesSearch).toList();
    final athleteCount = approvedMembers.where((member) => !member.isStaff).length;
    final staffCount = approvedMembers.where((member) => member.isStaff).length;
    final missingPhoneCount = approvedMembers.where((member) => !member.hasLikelyValidPhone).length;
    final searchQuery = _searchController.text.trim();
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= 980;
    final rosterColumns = width >= 1280 ? 2 : 1;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          SubpageHeader(
            title: 'Team',
            subtitle:
                'Join code ${team?.joinCode ?? '--'} • Search the roster, review approvals, and keep visibility tight.',
          ),
          const SizedBox(height: AppSpacing.md),
          _TeamCommandDeck(
            athleteCount: athleteCount,
            staffCount: staffCount,
            pendingCount: pendingMembers.length,
            missingPhoneCount: missingPhoneCount,
            canManageMembers: appState.canManageMembers,
            onAddAthlete: () => _showInviteDialog(context, team?.joinCode ?? '--'),
          ),
          const SizedBox(height: AppSpacing.md),
          if (isWide)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 5,
                  child: _TeamControlsCard(
                    searchController: _searchController,
                    selectedFilter: _selectedFilter,
                    onSearchChanged: (_) => setState(() {}),
                    onFilterSelected: (filter) => setState(() => _selectedFilter = filter),
                    showAddAthlete: appState.canManageMembers,
                    onAddAthlete: () => _showInviteDialog(context, team?.joinCode ?? '--'),
                    labelForFilter: _labelForFilter,
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                SizedBox(
                  width: 280,
                  child: Column(
                    children: [
                      _TeamSummaryChip(label: 'Athletes', value: '$athleteCount'),
                      const SizedBox(height: AppSpacing.sm),
                      _TeamSummaryChip(label: 'Staff', value: '$staffCount'),
                      const SizedBox(height: AppSpacing.sm),
                      _TeamSummaryChip(
                        label: 'Pending',
                        value: '${pendingMembers.length}',
                        highlight: pendingMembers.isNotEmpty,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _TeamSummaryChip(
                        label: 'Missing phones',
                        value: '$missingPhoneCount',
                        highlight: missingPhoneCount > 0,
                      ),
                    ],
                  ),
                ),
              ],
            )
          else ...[
            _TeamControlsCard(
              searchController: _searchController,
              selectedFilter: _selectedFilter,
              onSearchChanged: (_) => setState(() {}),
              onFilterSelected: (filter) => setState(() => _selectedFilter = filter),
              showAddAthlete: appState.canManageMembers,
              onAddAthlete: () => _showInviteDialog(context, team?.joinCode ?? '--'),
              labelForFilter: _labelForFilter,
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(child: _TeamSummaryChip(label: 'Athletes', value: '$athleteCount')),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: _TeamSummaryChip(label: 'Staff', value: '$staffCount')),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _TeamSummaryChip(
                    label: 'Pending',
                    value: '${pendingMembers.length}',
                    highlight: pendingMembers.isNotEmpty,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _TeamSummaryChip(
                    label: 'Missing phones',
                    value: '$missingPhoneCount',
                    highlight: missingPhoneCount > 0,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          _RosterOpsRow(
            athleteCount: athleteCount,
            staffCount: staffCount,
            pendingCount: pendingMembers.length,
            visibleApprovedCount: visibleApproved.length,
            activeFilter: _labelForFilter(_selectedFilter),
            hasSearch: searchQuery.isNotEmpty,
            searchQuery: searchQuery,
          ),
          const SizedBox(height: AppSpacing.xl),
          _RosterInsightBand(
            athleteCount: athleteCount,
            staffCount: staffCount,
            pendingCount: pendingMembers.length,
            currentFilter: _labelForFilter(_selectedFilter),
          ),
          const SizedBox(height: AppSpacing.xl),
          if (_selectedFilter == 'pending' || visiblePending.isNotEmpty) ...[
            const SectionHeader(title: 'Pending approvals'),
            const SizedBox(height: AppSpacing.md),
            if (visiblePending.isEmpty)
              const EmptyStateCard(
                title: 'No pending requests',
                message: 'New athlete, parent, and assistant coach join requests will appear here.',
                icon: Icons.hourglass_empty_rounded,
              )
            else
              _MemberGrid(
                members: visiblePending,
                columns: rosterColumns,
              ),
            const SizedBox(height: AppSpacing.xl),
          ],
          const SectionHeader(title: 'Roster'),
          const SizedBox(height: AppSpacing.md),
          if (visibleApproved.isEmpty)
            const EmptyStateCard(
              title: 'No athletes added',
              message: 'Approved athletes and staff will appear here once the roster is built.',
              icon: Icons.groups_2_outlined,
            )
          else
            _MemberGrid(
              members: visibleApproved,
              columns: rosterColumns,
            ),
          const SizedBox(height: 96),
        ],
      ),
    );
  }

  bool _matchesFilter(TeamMemberModel member) {
    switch (_selectedFilter) {
      case 'athletes':
        return !member.isStaff && member.status == 'approved';
      case 'staff':
        return member.isStaff && member.status == 'approved';
      case 'pending':
        return member.status == 'pending';
      default:
        return true;
    }
  }

  bool _matchesSearch(TeamMemberModel member) {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return true;
    return member.user.fullName.toLowerCase().contains(query) ||
        member.user.email.toLowerCase().contains(query) ||
        member.roleLabel.toLowerCase().contains(query);
  }

  String _labelForFilter(String filter) {
    switch (filter) {
      case 'athletes':
        return 'Athletes';
      case 'staff':
        return 'Staff';
      case 'pending':
        return 'Pending';
      default:
        return 'All';
    }
  }

  Future<void> _showInviteDialog(BuildContext context, String joinCode) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add athlete'),
        content: Text(
          'Share join code $joinCode with the athlete or parent. Their request will appear here for staff approval.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _TeamControlsCard extends StatelessWidget {
  const _TeamControlsCard({
    required this.searchController,
    required this.selectedFilter,
    required this.onSearchChanged,
    required this.onFilterSelected,
    required this.showAddAthlete,
    required this.onAddAthlete,
    required this.labelForFilter,
  });

  final TextEditingController searchController;
  final String selectedFilter;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onFilterSelected;
  final bool showAddAthlete;
  final VoidCallback onAddAthlete;
  final String Function(String) labelForFilter;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surface.withValues(alpha: 0.9),
            AppColors.surfaceElevated.withValues(alpha: 0.82),
          ],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Roster controls', style: AppTextStyles.bodyStrong),
              const Spacer(),
              Text(
                selectedFilter == 'all' ? 'Showing all' : labelForFilter(selectedFilter),
                style: AppTextStyles.caption,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            decoration: const InputDecoration(
              hintText: 'Search athletes, parents, and staff',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final filter in const ['all', 'athletes', 'staff', 'pending'])
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.xs),
                    child: ChoiceChip(
                      label: Text(labelForFilter(filter)),
                      selected: selectedFilter == filter,
                      onSelected: (_) => onFilterSelected(filter),
                    ),
                  ),
              ],
            ),
          ),
          if (showAddAthlete) ...[
            const SizedBox(height: AppSpacing.md),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: onAddAthlete,
                icon: const Icon(Icons.person_add_alt_1_rounded),
                label: const Text('Add athlete'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TeamCommandDeck extends StatelessWidget {
  const _TeamCommandDeck({
    required this.athleteCount,
    required this.staffCount,
    required this.pendingCount,
    required this.missingPhoneCount,
    required this.canManageMembers,
    required this.onAddAthlete,
  });

  final int athleteCount;
  final int staffCount;
  final int pendingCount;
  final int missingPhoneCount;
  final bool canManageMembers;
  final VoidCallback onAddAthlete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stacked = constraints.maxWidth < 980;
          final summary = Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [
              _TeamCommandMetric(
                label: 'Athletes',
                value: '$athleteCount',
                note: 'approved athletes',
                color: const Color(0xFF60A5FA),
              ),
              _TeamCommandMetric(
                label: 'Staff',
                value: '$staffCount',
                note: 'approved staff',
                color: const Color(0xFF38BDF8),
              ),
              _TeamCommandMetric(
                label: 'Pending',
                value: '$pendingCount',
                note: 'awaiting review',
                color: pendingCount > 0 ? AppColors.warning : AppColors.success,
              ),
              _TeamCommandMetric(
                label: 'Missing phones',
                value: '$missingPhoneCount',
                note: 'follow-up needed',
                color: missingPhoneCount > 0 ? AppColors.danger : AppColors.success,
              ),
            ],
          );

          final actions = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Roster command', style: AppTextStyles.bodyStrong),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Use Team to approve athletes fast, keep parent contact details complete, and make the room easier to manage.',
                style: AppTextStyles.body,
              ),
              if (canManageMembers) ...[
                const SizedBox(height: AppSpacing.md),
                ElevatedButton.icon(
                  onPressed: onAddAthlete,
                  icon: const Icon(Icons.person_add_alt_1_rounded),
                  label: const Text('Invite athlete'),
                ),
              ],
            ],
          );

          if (stacked) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                actions,
                const SizedBox(height: AppSpacing.lg),
                summary,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 4, child: actions),
              const SizedBox(width: AppSpacing.xl),
              Expanded(flex: 6, child: summary),
            ],
          );
        },
      ),
    );
  }
}

class _TeamCommandMetric extends StatelessWidget {
  const _TeamCommandMetric({
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
      width: 180,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.caption),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: AppTextStyles.cardTitle.copyWith(
              fontSize: 24,
              color: color,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(note, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

class _MemberGrid extends StatelessWidget {
  const _MemberGrid({
    required this.members,
    required this.columns,
  });

  final List<TeamMemberModel> members;
  final int columns;

  @override
  Widget build(BuildContext context) {
    if (columns <= 1) {
      return Column(
        children: members
            .map(
              (member) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _MemberTile(member: member),
              ),
            )
            .toList(),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
        childAspectRatio: 2.5,
      ),
      itemCount: members.length,
      itemBuilder: (context, index) => _MemberTile(member: members[index]),
    );
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({required this.member});

  final TeamMemberModel member;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final accent = member.status == 'pending'
        ? AppColors.warning
        : member.isStaff
            ? const Color(0xFF38BDF8)
            : Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: accent.withValues(alpha: 0.18),
            child: Text(
              member.user.fullName.substring(0, 1).toUpperCase(),
              style: AppTextStyles.bodyStrong.copyWith(color: accent),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(member.user.fullName, style: AppTextStyles.bodyStrong)),
                    if (!member.isStaff)
                      Text(
                        'Athlete',
                        style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(member.user.email, style: AppTextStyles.caption),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    _StatusChip(label: member.roleLabel, color: accent),
                    _StatusChip(
                      label: member.status == 'approved' ? 'Active' : 'Pending',
                      color: member.status == 'approved' ? AppColors.success : AppColors.warning,
                    ),
                    _StatusChip(
                      label: member.hasLikelyValidPhone ? 'Phone ready' : 'Phone missing',
                      color: member.hasLikelyValidPhone ? AppColors.success : AppColors.warning,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _memberNote(member),
                  style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          if (appState.canManageMembers)
            PopupMenuButton<String>(
              color: AppColors.surfaceElevated,
              icon: const Icon(Icons.more_horiz_rounded, color: AppColors.textSecondary),
              onSelected: (value) {
                if (value == 'approve') {
                  context.read<AppState>().approveMember(member.id);
                } else if (value == 'remove') {
                  context.read<AppState>().removeMember(member.id);
                }
              },
              itemBuilder: (context) => [
                if (member.status == 'pending')
                  const PopupMenuItem<String>(
                    value: 'approve',
                    child: Text('Approve'),
                  ),
                if (member.user.id != appState.user?.id)
                  const PopupMenuItem<String>(
                    value: 'remove',
                    child: Text('Remove'),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  String _memberNote(TeamMemberModel member) {
    if (member.status == 'pending') {
      return 'Waiting for coach approval before visibility opens across roster and messaging.';
    }
    if (!member.hasLikelyValidPhone) {
      return 'This member will be excluded from team text alerts until a valid phone number is added.';
    }
    if (member.isStaff) {
      return 'Staff access is active for roster, communication, and program workflows.';
    }
    return 'Athlete record is active and ready for messaging, weight workflows, and event visibility.';
  }
}

class _TeamSummaryChip extends StatelessWidget {
  const _TeamSummaryChip({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final accent = highlight ? Theme.of(context).colorScheme.primary : AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.56),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.caption),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            value,
            style: AppTextStyles.cardTitle.copyWith(
              color: highlight ? accent : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

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

class _RosterInsightBand extends StatelessWidget {
  const _RosterInsightBand({
    required this.athleteCount,
    required this.staffCount,
    required this.pendingCount,
    required this.currentFilter,
  });

  final int athleteCount;
  final int staffCount;
  final int pendingCount;
  final String currentFilter;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 980 ? 3 : 1;
        final cards = [
          _RosterInsight(
            title: 'Roster balance',
            value: '$athleteCount athletes / $staffCount staff',
            note: 'Keep staff visibility lean and athlete records clean enough to scan in seconds.',
            color: const Color(0xFF38BDF8),
          ),
          _RosterInsight(
            title: 'Approval queue',
            value: pendingCount == 0 ? 'Clear' : '$pendingCount waiting',
            note: pendingCount == 0
                ? 'No join-code requests are blocked right now.'
                : 'Parents, athletes, and assistants should be approved before they hit other workflows.',
            color: pendingCount == 0 ? AppColors.success : AppColors.warning,
          ),
          _RosterInsight(
            title: 'Current view',
            value: currentFilter,
            note: 'Search and filters should make it easy to audit the exact slice of the roster you need.',
            color: Theme.of(context).colorScheme.primary,
          ),
        ];

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
            childAspectRatio: columns == 1 ? 2.6 : 1.5,
          ),
          itemCount: cards.length,
          itemBuilder: (context, index) => _RosterInsightCard(item: cards[index]),
        );
      },
    );
  }
}

class _RosterOpsRow extends StatelessWidget {
  const _RosterOpsRow({
    required this.athleteCount,
    required this.staffCount,
    required this.pendingCount,
    required this.visibleApprovedCount,
    required this.activeFilter,
    required this.hasSearch,
    required this.searchQuery,
  });

  final int athleteCount;
  final int staffCount;
  final int pendingCount;
  final int visibleApprovedCount;
  final String activeFilter;
  final bool hasSearch;
  final String searchQuery;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _RosterOpsCard(
        title: 'Roster action',
        value: pendingCount > 0 ? '$pendingCount approvals' : 'Clear',
        note: pendingCount > 0
            ? 'Approve requests before they spill into chat and parent visibility.'
            : 'No blocked roster actions right now.',
        color: pendingCount > 0 ? AppColors.warning : AppColors.success,
        icon: Icons.fact_check_rounded,
      ),
      _RosterOpsCard(
        title: 'Current slice',
        value: '$visibleApprovedCount shown',
        note: hasSearch
            ? 'Search is active for "$searchQuery" under $activeFilter.'
            : 'Filter is set to $activeFilter for faster roster review.',
        color: Theme.of(context).colorScheme.primary,
        icon: Icons.filter_alt_rounded,
      ),
      _RosterOpsCard(
        title: 'Structure',
        value: '$athleteCount athletes / $staffCount staff',
        note: 'Keep staff access lean and athlete records easy to scan at a glance.',
        color: const Color(0xFF38BDF8),
        icon: Icons.groups_2_rounded,
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
                if (i != cards.length - 1) const SizedBox(height: AppSpacing.md),
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

class _RosterOpsCard extends StatelessWidget {
  const _RosterOpsCard({
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
        color: AppColors.surface.withValues(alpha: 0.6),
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
          Text(note, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _RosterInsight {
  const _RosterInsight({
    required this.title,
    required this.value,
    required this.note,
    required this.color,
  });

  final String title;
  final String value;
  final String note;
  final Color color;
}

class _RosterInsightCard extends StatelessWidget {
  const _RosterInsightCard({required this.item});

  final _RosterInsight item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.title, style: AppTextStyles.caption),
          const SizedBox(height: AppSpacing.sm),
          Text(item.value, style: AppTextStyles.cardTitle.copyWith(color: item.color)),
          const SizedBox(height: AppSpacing.sm),
          Text(item.note, style: AppTextStyles.body),
        ],
      ),
    );
  }
}
