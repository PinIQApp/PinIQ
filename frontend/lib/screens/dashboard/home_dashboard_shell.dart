import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../models/messaging_models.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/app_header.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/empty_state_card.dart';
import '../../widgets/hero_program_card.dart';
import '../../widgets/program_tool_tile.dart';
import '../../widgets/quick_action_tile.dart';
import '../../widgets/section_header.dart';
import '../../widgets/stat_card.dart';
import '../branding/branding_edit_screen.dart';
import '../messaging/announcements_screen.dart';
import '../messaging/message_threads_screen.dart';
import '../dashboard/ai_assistant_center_screen.dart';
import '../dashboard/nutrition_center_screen.dart';
import '../dashboard/operations_center_screen.dart';
import '../dashboard/recruiting_center_screen.dart';
import '../dashboard/stance_motion_workout_screen.dart';
import '../dashboard/store_center_screen.dart';
import '../dashboard/tournament_center_screen.dart';
import '../dashboard/workout_center_screen.dart';
import '../settings/coach_settings_screen.dart';
import '../team/team_members_screen.dart';
import '../weights/athlete_weight_log_screen.dart';
import '../weights/athlete_weight_plan_screen.dart';
import '../weights/parent_weight_view_screen.dart';
import '../weights/team_weight_dashboard_screen.dart';

class HomeDashboardShell extends StatefulWidget {
  const HomeDashboardShell({super.key});

  @override
  State<HomeDashboardShell> createState() => _HomeDashboardShellState();
}

const bool _tournamentModeEnabled = true;

class _HomeDashboardShellState extends State<HomeDashboardShell> {
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final team = appState.activeTeam;
    final user = appState.user;

    final tabs = [
      _AppTab(
        label: 'Home',
        icon: Icons.home_outlined,
        activeIcon: Icons.home_rounded,
        body: _DashboardHomeView(appState: appState),
      ),
      _AppTab(
        label: 'Team',
        icon: Icons.groups_2_outlined,
        activeIcon: Icons.groups_2_rounded,
        body: const TeamMembersScreen(),
      ),
      _AppTab(
        label: 'Chat',
        icon: Icons.chat_bubble_outline_rounded,
        activeIcon: Icons.chat_bubble_rounded,
        body: _MessagingOverview(appState: appState),
      ),
      _AppTab(
        label: 'Hub',
        icon: Icons.grid_view_rounded,
        activeIcon: Icons.grid_view_rounded,
        body: _ProgramToolsView(appState: appState),
      ),
    ];

    final safeIndex = currentIndex.clamp(0, tabs.length - 1);

    return Scaffold(
      body: AppShell(
        child: Column(
          children: [
            AppHeader(
              team: team,
              title: team?.name ?? 'Pin IQ',
              subtitle:
                  '${team?.mascotName ?? 'Program'} • ${_roleLabel(user?.role)}',
              trailing: IconButton(
                tooltip: 'Logout',
                onPressed: () => context.read<AppState>().logout(),
                icon: const Icon(
                  Icons.logout_rounded,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            Expanded(child: tabs[safeIndex].body),
            AppBottomNav(
              selectedIndex: safeIndex,
              onSelected: (index) => setState(() => currentIndex = index),
              items: tabs
                  .map(
                    (tab) => AppBottomNavItem(
                      icon: tab.icon,
                      activeIcon: tab.activeIcon,
                      label: tab.label,
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppTab {
  const _AppTab({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.body,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
  final Widget body;
}

class _DashboardHomeView extends StatelessWidget {
  const _DashboardHomeView({required this.appState});

  final AppState appState;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final team = appState.activeTeam;

    final approvedCount =
        team?.members.where((member) => member.status == 'approved').length ??
            0;
    final pendingCount =
        team?.members.where((member) => member.status == 'pending').length ?? 0;
    final unreadThreads =
        appState.threads.where((thread) => _isUnread(thread)).length;
    final alerts = appState.weightAlerts
        .where((alert) => alert.status != 'resolved')
        .toList();
    final announcements = appState.announcements;
    final latestAnnouncement =
        announcements.isEmpty ? null : announcements.first;
    final latestThread =
        appState.threads.isEmpty ? null : appState.threads.first;
    final canManageProgram = appState.canManageMembers;
    final isAthlete = appState.isAthlete;
    final isParent = appState.isParent;
    final width = MediaQuery.of(context).size.width;
    final isPhone = width < 560;

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        HeroProgramCard(
          team: team,
          title: team?.name ?? 'Pin IQ',
          subtitle:
              '${team?.mascotName ?? 'Team'} • ${appState.user?.fullName ?? 'Staff'}',
          description: team?.tagline?.trim().isNotEmpty == true
              ? team!.tagline!.trim()
              : 'Run your wrestling program with one clean dashboard for updates, roster, weights, and staff tools.',
          badge: _roleLabel(appState.user?.role),
          primaryAction: ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => canManageProgram
                      ? const AnnouncementsScreen()
                      : isParent
                          ? const ParentWeightViewScreen()
                          : const AthleteWeightPlanScreen(),
                ),
              );
            },
            icon: Icon(
              canManageProgram
                  ? Icons.campaign_rounded
                  : Icons.monitor_weight_outlined,
            ),
            label: Text(
              canManageProgram
                  ? 'Send update'
                  : isParent
                      ? 'View athlete plan'
                      : 'View weight plan',
            ),
          ),
          secondaryAction: OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => canManageProgram
                      ? const TeamMembersScreen()
                      : const MessageThreadsScreen(),
                ),
              );
            },
            icon: Icon(
              canManageProgram ? Icons.groups_2_rounded : Icons.forum_rounded,
            ),
            label: Text(canManageProgram ? 'Open team' : 'Open chat'),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        _CoachCommandDeck(
          unreadThreads: unreadThreads,
          pendingCount: pendingCount,
          alertsCount: alerts.length,
          onOpenTeam: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const TeamMembersScreen()),
            );
          },
          onOpenChat: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MessageThreadsScreen()),
            );
          },
          onOpenWeights: appState.canManageWeights
              ? () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const TeamWeightDashboardScreen(),
                    ),
                  );
                }
              : null,
        ),
        const SizedBox(height: AppSpacing.xl),
        const SectionHeader(title: 'Today'),
        const SizedBox(height: AppSpacing.md),
        _TodayCard(
          title: alerts.isNotEmpty
              ? '${alerts.length} weight alerts need attention'
              : canManageProgram && pendingCount > 0
                  ? '$pendingCount approvals are waiting'
                  : 'No urgent program issues right now',
          subtitle: latestAnnouncement != null
              ? 'Latest update: ${latestAnnouncement.title}'
              : approvedCount == 0
                  ? 'Start by adding athletes, assistants, and parents to build your roster.'
                  : 'You’re clear right now. Use Team, Chat, and Hub to manage the day.',
          actionLabel: unreadThreads > 0 ? 'Open chat' : 'Open team',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => unreadThreads > 0
                    ? const MessageThreadsScreen()
                    : const TeamMembersScreen(),
              ),
            );
          },
          pills: [
            _MiniStatusPill(
              label: unreadThreads == 0
                  ? 'No unread threads'
                  : '$unreadThreads unread',
              color: unreadThreads == 0
                  ? AppColors.textMuted
                  : theme.colorScheme.primary,
            ),
            _MiniStatusPill(
              label: announcements.isEmpty
                  ? 'No announcements yet'
                  : '${announcements.length} updates posted',
              color: AppColors.textSecondary,
            ),
            _MiniStatusPill(
              label: canManageProgram
                  ? approvedCount == 0
                      ? 'Roster not built'
                      : '$approvedCount active members'
                  : appState.activeTeam == null
                      ? 'No team linked'
                      : 'Team linked',
              color: approvedCount == 0 ? AppColors.warning : AppColors.success,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        const SectionHeader(title: 'Program snapshot'),
        const SizedBox(height: AppSpacing.md),
        GridView.count(
          crossAxisCount: width > 900
              ? 4
              : isPhone
                  ? 1
                  : 2,
          crossAxisSpacing: isPhone ? AppSpacing.sm : AppSpacing.md,
          mainAxisSpacing: isPhone ? AppSpacing.sm : AppSpacing.md,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: width > 900
              ? 1.18
              : isPhone
                  ? 2.65
                  : 1.35,
          children: [
            StatCard(
              label: 'Roster',
              value: '$approvedCount',
              sublabel: 'approved athletes and staff',
            ),
            StatCard(
              label: 'Unread',
              value: '$unreadThreads',
              sublabel: 'conversation threads',
              highlightColor:
                  unreadThreads > 0 ? theme.colorScheme.primary : null,
            ),
            StatCard(
              label: 'Alerts',
              value: '${alerts.length}',
              sublabel: 'weight items to review',
              highlightColor: alerts.isNotEmpty ? AppColors.warning : null,
            ),
            StatCard(
              label: 'Updates',
              value: '${announcements.length}',
              sublabel: 'announcements posted',
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        const SectionHeader(title: 'Quick actions'),
        const SizedBox(height: AppSpacing.md),
        GridView.count(
          crossAxisCount: isPhone ? 1 : 2,
          crossAxisSpacing: isPhone ? AppSpacing.sm : AppSpacing.md,
          mainAxisSpacing: isPhone ? AppSpacing.sm : AppSpacing.md,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: isPhone ? 2.65 : 1.55,
          children: [
            if (canManageProgram) ...[
              QuickActionTile(
                icon: Icons.campaign_rounded,
                title: 'Send announcement',
                subtitle: 'Post one clear team update.',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const AnnouncementsScreen()),
                  );
                },
              ),
              QuickActionTile(
                icon: Icons.person_add_alt_1_rounded,
                title: 'Add athlete',
                subtitle: 'Open roster and approvals.',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const TeamMembersScreen()),
                  );
                },
              ),
            ] else ...[
              QuickActionTile(
                icon: Icons.monitor_weight_outlined,
                title: isParent ? 'View athlete plan' : 'View weight plan',
                subtitle: isParent
                    ? 'Check linked athlete safety status.'
                    : 'Review your plan and recent logs.',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => isParent
                          ? const ParentWeightViewScreen()
                          : const AthleteWeightPlanScreen(),
                    ),
                  );
                },
              ),
              QuickActionTile(
                icon: Icons.restaurant_menu_rounded,
                title: 'Nutrition',
                subtitle: 'Open meal timing and hydration help.',
                color: const Color(0xFF14B8A6),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const NutritionCenterScreen()),
                  );
                },
              ),
            ],
            QuickActionTile(
              icon: Icons.monitor_weight_outlined,
              title: canManageProgram
                  ? 'Review weights'
                  : isAthlete
                      ? 'Log weight'
                      : 'Open weight view',
              subtitle: canManageProgram
                  ? 'Check plans and alerts.'
                  : isAthlete
                      ? 'Add today’s check-in.'
                      : 'Review linked athlete status.',
              color: AppColors.warning,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => canManageProgram
                        ? const TeamWeightDashboardScreen()
                        : isAthlete
                            ? const AthleteWeightLogScreen()
                            : const ParentWeightViewScreen(),
                  ),
                );
              },
            ),
            QuickActionTile(
              icon: Icons.forum_rounded,
              title: 'Open chat',
              subtitle: 'Jump into live threads.',
              color: const Color(0xFF38BDF8),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const MessageThreadsScreen(),
                  ),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        const SectionHeader(title: 'Alerts'),
        const SizedBox(height: AppSpacing.md),
        if (alerts.isEmpty && pendingCount == 0 && unreadThreads == 0)
          const EmptyStateCard(
            title: 'No urgent alerts',
            message:
                'Approvals, weight issues, and unread conversations will show up here.',
            icon: Icons.notifications_none_rounded,
          )
        else
          Column(
            children: [
              for (final alert in alerts.take(3)) ...[
                _AlertRow(
                  title: _alertTitle(alert.alertType),
                  subtitle: alert.alertMessage,
                  color: _alertColor(alert.severity),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              if (pendingCount > 0) ...[
                _AlertRow(
                  title: '$pendingCount pending approvals',
                  subtitle: 'New team members are waiting for staff review.',
                  color: AppColors.warning,
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              if (unreadThreads > 0)
                _AlertRow(
                  title: '$unreadThreads unread parent-visible threads',
                  subtitle: 'Open chat to respond to the latest conversations.',
                  color: theme.colorScheme.primary,
                ),
            ],
          ),
        const SizedBox(height: AppSpacing.xl),
        const SectionHeader(title: 'Recent activity'),
        const SizedBox(height: AppSpacing.md),
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              _ActivityRow(
                icon: Icons.campaign_rounded,
                title:
                    latestAnnouncement?.title ?? 'No announcements posted yet',
                subtitle: latestAnnouncement == null
                    ? 'Use announcements when the team needs one clear update.'
                    : '${latestAnnouncement.sender.fullName} • ${_formatDate(latestAnnouncement.createdAt)}',
              ),
              const SizedBox(height: AppSpacing.md),
              _ActivityRow(
                icon: Icons.group_add_rounded,
                title: pendingCount > 0
                    ? '$pendingCount roster requests waiting'
                    : 'Roster is up to date',
                subtitle: pendingCount > 0
                    ? 'Approve athletes, parents, and assistants from Team.'
                    : 'No pending join requests right now.',
              ),
              const SizedBox(height: AppSpacing.md),
              _ActivityRow(
                icon: Icons.chat_bubble_outline_rounded,
                title: latestThread?.title ?? 'No recent conversation activity',
                subtitle: latestThread == null
                    ? 'Team and parent-visible threads will appear here.'
                    : (latestThread.lastMessagePreview?.trim().isNotEmpty ??
                            false)
                        ? latestThread.lastMessagePreview!
                        : 'Open the thread to view the latest reply.',
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}

class _MessagingOverview extends StatelessWidget {
  const _MessagingOverview({required this.appState});

  final AppState appState;

  @override
  Widget build(BuildContext context) {
    final threads = appState.threads;
    final announcements = appState.announcements;

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated.withValues(alpha: 0.98),
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Messaging',
                style: AppTextStyles.pageTitle.copyWith(fontSize: 28),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Keep announcements separate from live conversations so coaches can scan what needs action fast.',
                style: AppTextStyles.body,
              ),
              const SizedBox(height: AppSpacing.lg),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AnnouncementsScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.campaign_rounded),
                    label: const Text('Announcements'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const MessageThreadsScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.forum_rounded),
                    label: const Text('Conversations'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        const SectionHeader(title: 'Announcements'),
        const SizedBox(height: AppSpacing.md),
        if (announcements.isEmpty)
          const EmptyStateCard(
            title: 'No announcements yet',
            message:
                'Post a team-wide update when everyone needs the same message.',
            icon: Icons.campaign_outlined,
          )
        else
          ...announcements.take(3).map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _AlertRow(
                    title: item.title,
                    subtitle:
                        '${item.audienceLabel} • ${_formatDate(item.createdAt)}',
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
        const SizedBox(height: AppSpacing.xl),
        const SectionHeader(title: 'Conversations'),
        const SizedBox(height: AppSpacing.md),
        if (threads.isEmpty)
          const EmptyStateCard(
            title: 'No conversations yet',
            message:
                'Team and parent-visible threads will appear here once a conversation starts.',
            icon: Icons.chat_bubble_outline_rounded,
          )
        else
          ...threads.take(4).map(
                (thread) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _ThreadPreviewRow(thread: thread),
                ),
              ),
      ],
    );
  }
}

class _ProgramToolsView extends StatelessWidget {
  const _ProgramToolsView({required this.appState});

  final AppState appState;

  @override
  Widget build(BuildContext context) {
    final unreadCount = appState.threads.where(_isUnread).length;
    final rosterCount = appState.activeTeam?.members.length ?? 0;

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated.withValues(alpha: 0.98),
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Program tools',
                style: AppTextStyles.pageTitle.copyWith(fontSize: 28),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Run communication, athlete management, branding, and admin controls from one clean tool hub.',
                style: AppTextStyles.body,
              ),
              const SizedBox(height: AppSpacing.lg),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  _MiniStatusPill(
                    label: '${appState.announcements.length} updates',
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  _MiniStatusPill(
                    label: '$unreadCount unread threads',
                    color: const Color(0xFF38BDF8),
                  ),
                  _MiniStatusPill(
                    label: '$rosterCount roster records',
                    color: const Color(0xFF60A5FA),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        const SectionHeader(title: 'Release readiness'),
        const SizedBox(height: AppSpacing.md),
        const _ReleaseReadinessPanel(),
        const SizedBox(height: AppSpacing.xl),
        const SectionHeader(title: 'Start here'),
        const SizedBox(height: AppSpacing.md),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth > 920 ? 3 : 1;
            final phone = constraints.maxWidth < 560;
            return GridView.count(
              crossAxisCount: columns,
              crossAxisSpacing: phone ? AppSpacing.sm : AppSpacing.md,
              mainAxisSpacing: phone ? AppSpacing.sm : AppSpacing.md,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: columns == 1
                  ? phone
                      ? 1.55
                      : 2.2
                  : 1.28,
              children: [
                _HubCategoryCard(
                  icon: Icons.campaign_rounded,
                  title: 'Communication',
                  subtitle: 'Keep team updates and conversations organized.',
                  accent: Theme.of(context).colorScheme.primary,
                  actions: [
                    _HubAction(
                      label: 'Announcements',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const AnnouncementsScreen()),
                        );
                      },
                    ),
                    _HubAction(
                      label: 'Messages',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const MessageThreadsScreen()),
                        );
                      },
                    ),
                  ],
                ),
                _HubCategoryCard(
                  icon: Icons.groups_2_rounded,
                  title: 'Athletes',
                  subtitle:
                      'Open roster, approvals, weights, safety, and recruiting.',
                  accent: const Color(0xFF60A5FA),
                  actions: [
                    _HubAction(
                      label: 'Roster',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const TeamMembersScreen()),
                        );
                      },
                    ),
                    _HubAction(
                      label: 'Recruiting',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const RecruitingCenterScreen()),
                        );
                      },
                    ),
                  ],
                ),
                _HubCategoryCard(
                  icon: Icons.auto_awesome_rounded,
                  title: 'AI tools',
                  subtitle:
                      'Open the coaching assistant and replay review surfaces.',
                  accent: const Color(0xFF8B5CF6),
                  actions: [
                    _HubAction(
                      label: 'AI Assistant',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const AiAssistantCenterScreen()),
                        );
                      },
                    ),
                    _HubAction(
                      label: 'Coach prompts',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const AiAssistantCenterScreen()),
                        );
                      },
                    ),
                  ],
                ),
                _HubCategoryCard(
                  icon: Icons.emoji_events_rounded,
                  title: 'Performance',
                  subtitle: _tournamentModeEnabled
                      ? 'Move straight into nutrition and tournament work.'
                      : 'Nutrition is live. Tournament tools are paused for beta feedback.',
                  accent: const Color(0xFFF97316),
                  actions: [
                    _HubAction(
                      label: 'Nutrition',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const NutritionCenterScreen()),
                        );
                      },
                    ),
                    if (_tournamentModeEnabled)
                      _HubAction(
                        label: 'Tournaments',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const TournamentCenterScreen()),
                          );
                        },
                      ),
                  ],
                ),
                _HubCategoryCard(
                  icon: Icons.directions_run_rounded,
                  title: 'Today\'s Training',
                  subtitle:
                      'Open parent-friendly workouts, callout rounds, weekly plans, and athlete check-ins.',
                  accent: const Color(0xFF22C55E),
                  actions: [
                    _HubAction(
                      label: 'Today\'s plan',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const WorkoutCenterScreen(),
                          ),
                        );
                      },
                    ),
                    _HubAction(
                      label: 'Stance + motion',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const StanceMotionWorkoutScreen(),
                          ),
                        );
                      },
                    ),
                    _HubAction(
                      label: '1-3 min rounds',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const StanceMotionWorkoutScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                _HubCategoryCard(
                  icon: Icons.storefront_rounded,
                  title: 'Store',
                  subtitle:
                      'Open the storefront, plans, and operator-side store controls.',
                  accent: const Color(0xFF14B8A6),
                  actions: [
                    _HubAction(
                      label: 'Store',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const StoreCenterScreen()),
                        );
                      },
                    ),
                    _HubAction(
                      label: 'Plans',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const StoreCenterScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ],
            );
          },
        ),
        const SizedBox(height: AppSpacing.xl),
        const SectionHeader(title: 'Communication'),
        const SizedBox(height: AppSpacing.md),
        ProgramToolTile(
          icon: Icons.campaign_rounded,
          title: 'Announcements',
          subtitle: 'Post updates for the team feed.',
          badge: '${appState.announcements.length}',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AnnouncementsScreen()),
            );
          },
        ),
        const SizedBox(height: AppSpacing.sm),
        ProgramToolTile(
          icon: Icons.forum_rounded,
          title: 'Messages',
          subtitle: 'Open direct, group, and parent-visible threads.',
          badge: '${appState.threads.where(_isUnread).length}',
          color: const Color(0xFF38BDF8),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MessageThreadsScreen()),
            );
          },
        ),
        const SizedBox(height: AppSpacing.xl),
        const SectionHeader(title: 'Athlete management'),
        const SizedBox(height: AppSpacing.md),
        ProgramToolTile(
          icon: Icons.groups_2_rounded,
          title: 'Roster',
          subtitle: 'Manage athletes, staff, and approvals.',
          badge: '${appState.activeTeam?.members.length ?? 0}',
          color: const Color(0xFF60A5FA),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const TeamMembersScreen()),
            );
          },
        ),
        const SizedBox(height: AppSpacing.sm),
        ProgramToolTile(
          icon: Icons.monitor_weight_outlined,
          title: 'Weights',
          subtitle: 'Review alerts, plans, and dashboard status.',
          badge: '${appState.weightAlerts.length}',
          color: AppColors.warning,
          onTap: appState.canManageWeights
              ? () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const TeamWeightDashboardScreen(),
                    ),
                  );
                }
              : null,
        ),
        const SizedBox(height: AppSpacing.sm),
        ProgramToolTile(
          icon: Icons.school_rounded,
          title: 'Recruiting Center',
          subtitle:
              'Track athlete readiness, outreach, college interest, and recruiting pages.',
          color: const Color(0xFF38BDF8),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const RecruitingCenterScreen()),
            );
          },
        ),
        const SizedBox(height: AppSpacing.xl),
        const SectionHeader(title: 'AI tools'),
        const SizedBox(height: AppSpacing.md),
        ProgramToolTile(
          icon: Icons.auto_awesome_rounded,
          title: 'AI Assistant',
          subtitle:
              'Open coach prompts, drafting helpers, and practice support workflows.',
          color: const Color(0xFF8B5CF6),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => const AiAssistantCenterScreen()),
            );
          },
        ),
        const SizedBox(height: AppSpacing.xl),
        const SectionHeader(title: 'Performance + events'),
        const SizedBox(height: AppSpacing.md),
        ProgramToolTile(
          icon: Icons.fitness_center_rounded,
          title: 'Today\'s Training',
          subtitle:
              'Open simple workouts, weekly plans, safety notes, and athlete check-ins.',
          color: const Color(0xFF22C55E),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const WorkoutCenterScreen()),
            );
          },
        ),
        const SizedBox(height: AppSpacing.sm),
        ProgramToolTile(
          icon: Icons.directions_run_rounded,
          title: 'Stance + motion workout',
          subtitle:
              'Pick 1, 2, or 3 minutes and react to random shot, sprawl, and down block calls.',
          color: const Color(0xFF22C55E),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const StanceMotionWorkoutScreen(),
              ),
            );
          },
        ),
        const SizedBox(height: AppSpacing.sm),
        ProgramToolTile(
          icon: Icons.restaurant_menu_rounded,
          title: 'Nutrition Center',
          subtitle:
              'Build meal plans, review safety flags, and open the wrestler nutrition planner.',
          color: const Color(0xFF14B8A6),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NutritionCenterScreen()),
            );
          },
        ),
        const SizedBox(height: AppSpacing.sm),
        if (_tournamentModeEnabled) ...[
          ProgramToolTile(
            icon: Icons.emoji_events_rounded,
            title: 'Tournament Center',
            subtitle:
                'Open tournament discovery, saved events, duals, and bracket operations.',
            color: const Color(0xFFF97316),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => const TournamentCenterScreen()),
              );
            },
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        ProgramToolTile(
          icon: Icons.storefront_rounded,
          title: 'Store',
          subtitle:
              'Browse wrestling products, plans, branding services, and store operations.',
          color: const Color(0xFF14B8A6),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const StoreCenterScreen()),
            );
          },
        ),
        const SizedBox(height: AppSpacing.xl),
        const SectionHeader(title: 'Brand + admin'),
        const SizedBox(height: AppSpacing.md),
        if (appState.canManageBranding) ...[
          ProgramToolTile(
            icon: Icons.palette_outlined,
            title: 'School branding',
            subtitle: 'Update logo, mascot, and school colors.',
            color: const Color(0xFFF472B6),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const BrandingEditScreen()),
              );
            },
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        ProgramToolTile(
          icon: Icons.map_outlined,
          title: 'Operations map',
          subtitle:
              'See which modules are live, partially wired, or still planned.',
          color: const Color(0xFF8B5CF6),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const OperationsCenterScreen()),
            );
          },
        ),
        const SizedBox(height: AppSpacing.sm),
        ProgramToolTile(
          icon: Icons.settings_outlined,
          title: 'Settings',
          subtitle: 'Manage profile, join code, and program controls.',
          color: AppColors.textSecondary,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CoachSettingsScreen()),
            );
          },
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}

class _TodayCard extends StatelessWidget {
  const _TodayCard({
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onTap,
    required this.pills,
  });

  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onTap;
  final List<Widget> pills;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated.withValues(alpha: 0.98),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.cardTitle.copyWith(fontSize: 22),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            subtitle,
            style: AppTextStyles.body,
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: pills,
          ),
          const SizedBox(height: AppSpacing.lg),
          GestureDetector(
            onTap: onTap,
            child: Text(
              actionLabel,
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CoachCommandDeck extends StatelessWidget {
  const _CoachCommandDeck({
    required this.unreadThreads,
    required this.pendingCount,
    required this.alertsCount,
    required this.onOpenTeam,
    required this.onOpenChat,
    required this.onOpenWeights,
  });

  final int unreadThreads;
  final int pendingCount;
  final int alertsCount;
  final VoidCallback onOpenTeam;
  final VoidCallback onOpenChat;
  final VoidCallback? onOpenWeights;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _CoachCommandCard(
        title: 'Roster flow',
        value: pendingCount == 0 ? 'Clear' : '$pendingCount waiting',
        note: pendingCount == 0
            ? 'No approvals are stuck right now.'
            : 'Open Team and clear pending athletes, parents, or staff.',
        accent: pendingCount == 0 ? AppColors.success : AppColors.warning,
        onTap: onOpenTeam,
      ),
      _CoachCommandCard(
        title: 'Messages',
        value: unreadThreads == 0 ? 'Quiet' : '$unreadThreads unread',
        note: unreadThreads == 0
            ? 'No unread threads need attention.'
            : 'Open Chat and answer parent-visible threads first.',
        accent: unreadThreads == 0
            ? AppColors.textSecondary
            : Theme.of(context).colorScheme.primary,
        onTap: onOpenChat,
      ),
      _CoachCommandCard(
        title: 'Weight safety',
        value: alertsCount == 0 ? 'Stable' : '$alertsCount alerts',
        note: alertsCount == 0
            ? 'No unresolved alerts on the board.'
            : 'Review flagged athletes and adjust plans before practice.',
        accent: alertsCount == 0 ? AppColors.success : AppColors.warning,
        onTap: onOpenWeights,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 920 ? 3 : 1;
        final phone = constraints.maxWidth < 560;
        return GridView.count(
          crossAxisCount: columns,
          crossAxisSpacing: phone ? AppSpacing.sm : AppSpacing.md,
          mainAxisSpacing: phone ? AppSpacing.sm : AppSpacing.md,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: columns == 1
              ? phone
                  ? 1.75
                  : 2.1
              : 1.28,
          children: cards,
        );
      },
    );
  }
}

class _CoachCommandCard extends StatelessWidget {
  const _CoachCommandCard({
    required this.title,
    required this.value,
    required this.note,
    required this.accent,
    required this.onTap,
  });

  final String title;
  final String value;
  final String note;
  final Color accent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.of(context).size.width < 430;
    return Container(
      padding: EdgeInsets.all(isCompact ? AppSpacing.md : AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(title, style: AppTextStyles.bodyStrong),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: AppTextStyles.cardTitle.copyWith(
              fontSize: isCompact ? 21 : 24,
              color: accent,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: Text(
              note,
              maxLines: isCompact ? 3 : 4,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.body,
            ),
          ),
          Align(
            alignment: Alignment.bottomLeft,
            child: OutlinedButton(
              onPressed: onTap,
              child: const Text('Open'),
            ),
          ),
        ],
      ),
    );
  }
}

class _HubCategoryCard extends StatelessWidget {
  const _HubCategoryCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.actions,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final List<_HubAction> actions;

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.of(context).size.width < 430;
    return Container(
      padding: EdgeInsets.all(isCompact ? AppSpacing.md : AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surface.withValues(alpha: 0.92),
            AppColors.surfaceElevated.withValues(alpha: 0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: accent),
          ),
          SizedBox(height: isCompact ? AppSpacing.sm : AppSpacing.md),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.cardTitle.copyWith(
              fontSize: isCompact ? 18 : 22,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Expanded(
            child: Text(
              subtitle,
              maxLines: isCompact ? 3 : 4,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.body,
            ),
          ),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final action in actions)
                OutlinedButton(
                  onPressed: action.onTap,
                  child: Text(action.label),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HubAction {
  const _HubAction({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback? onTap;
}

class _ReleaseReadinessPanel extends StatelessWidget {
  const _ReleaseReadinessPanel();

  @override
  Widget build(BuildContext context) {
    const items = [
      _ReleaseReadinessItem(
        label: 'Web app',
        status: 'Ready',
        icon: Icons.check_circle_rounded,
        color: AppColors.success,
      ),
      _ReleaseReadinessItem(
        label: 'Onboarding',
        status: 'Ready',
        icon: Icons.check_circle_rounded,
        color: AppColors.success,
      ),
      _ReleaseReadinessItem(
        label: 'Payments',
        status: 'Needs Stripe',
        icon: Icons.pending_rounded,
        color: AppColors.warning,
      ),
      _ReleaseReadinessItem(
        label: 'Messages',
        status: 'Needs Twilio',
        icon: Icons.pending_rounded,
        color: AppColors.warning,
      ),
      _ReleaseReadinessItem(
        label: 'Email',
        status: 'Needs Postmark',
        icon: Icons.pending_rounded,
        color: AppColors.warning,
      ),
      _ReleaseReadinessItem(
        label: 'Media',
        status: 'Needs S3/R2',
        icon: Icons.pending_rounded,
        color: AppColors.warning,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth > 900
              ? 3
              : constraints.maxWidth > 560
                  ? 2
                  : 1;
          return GridView.count(
            crossAxisCount: columns,
            crossAxisSpacing: AppSpacing.sm,
            mainAxisSpacing: AppSpacing.sm,
            childAspectRatio: columns == 1 ? 4.8 : 3.7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              for (final item in items) _ReleaseReadinessChip(item: item),
            ],
          );
        },
      ),
    );
  }
}

class _ReleaseReadinessItem {
  const _ReleaseReadinessItem({
    required this.label,
    required this.status,
    required this.icon,
    required this.color,
  });

  final String label;
  final String status;
  final IconData icon;
  final Color color;
}

class _ReleaseReadinessChip extends StatelessWidget {
  const _ReleaseReadinessChip({required this.item});

  final _ReleaseReadinessItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: item.color.withValues(alpha: 0.24)),
      ),
      child: Row(
        children: [
          Icon(item.icon, color: item.color, size: 22),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.label, style: AppTextStyles.bodyStrong),
                const SizedBox(height: AppSpacing.xxs),
                Text(item.status, style: AppTextStyles.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStatusPill extends StatelessWidget {
  const _MiniStatusPill({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(color: AppColors.textPrimary),
      ),
    );
  }
}

class _AlertRow extends StatelessWidget {
  const _AlertRow({
    required this.title,
    required this.subtitle,
    required this.color,
  });

  final String title;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 12,
            height: 12,
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.bodyStrong),
                const SizedBox(height: AppSpacing.xxs),
                Text(subtitle, style: AppTextStyles.body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: accent, size: 20),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.bodyStrong),
              const SizedBox(height: AppSpacing.xxs),
              Text(subtitle, style: AppTextStyles.body),
            ],
          ),
        ),
      ],
    );
  }
}

class _ThreadPreviewRow extends StatelessWidget {
  const _ThreadPreviewRow({required this.thread});

  final MessageThreadSummaryModel thread;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              thread.isGroup
                  ? Icons.groups_rounded
                  : Icons.chat_bubble_outline_rounded,
              color: accent,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        thread.title,
                        style: AppTextStyles.bodyStrong,
                      ),
                    ),
                    if (_isUnread(thread))
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  thread.lastMessagePreview ?? 'No messages yet',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

bool _isUnread(MessageThreadSummaryModel thread) {
  return DateTime.now().difference(thread.lastMessageAt).inHours < 24;
}

String _roleLabel(String? role) {
  if (role == null || role.isEmpty) return 'Coach';
  final words = role.split('_');
  return words
      .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
      .join(' ');
}

Color _alertColor(String severity) {
  switch (severity.toLowerCase()) {
    case 'high':
    case 'critical':
      return AppColors.danger;
    case 'medium':
      return AppColors.warning;
    default:
      return AppColors.success;
  }
}

String _alertTitle(String alertType) {
  switch (alertType) {
    case 'missing_weigh_in':
      return 'Missing weigh-in';
    case 'unsafe_rate':
      return 'Unsafe weekly drop';
    case 'stalled_progress':
      return 'Progress stalled';
    default:
      return alertType.replaceAll('_', ' ');
  }
}

String _formatDate(DateTime value) {
  final hour =
      value.hour == 0 ? 12 : (value.hour > 12 ? value.hour - 12 : value.hour);
  final suffix = value.hour >= 12 ? 'PM' : 'AM';
  final minute = value.minute.toString().padLeft(2, '0');
  return '${value.month}/${value.day} $hour:$minute $suffix';
}
