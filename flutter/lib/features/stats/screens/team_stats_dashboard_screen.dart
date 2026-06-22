import 'package:flutter/material.dart';

import '../models/stats_models.dart';
import '../services/stats_api_service.dart';
import '../widgets/stats_cards.dart';

class TeamStatsDashboardScreen extends StatefulWidget {
  const TeamStatsDashboardScreen({
    super.key,
    required this.api,
    required this.teamId,
    required this.schoolPrimaryColor,
    required this.schoolAccentColor,
  });

  final StatsApiService api;
  final int teamId;
  final Color schoolPrimaryColor;
  final Color schoolAccentColor;

  @override
  State<TeamStatsDashboardScreen> createState() => _TeamStatsDashboardScreenState();
}

class _TeamStatsDashboardScreenState extends State<TeamStatsDashboardScreen> {
  late Future<TeamStatsDashboard> _dashboardFuture;
  late Future<TeamLeaders> _leadersFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _dashboardFuture = widget.api.fetchTeamStats(teamId: widget.teamId);
    _leadersFuture = widget.api.fetchTeamLeaders(teamId: widget.teamId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090D12),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text('Team Stats Dashboard'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(_reload);
          await Future.wait([_dashboardFuture, _leadersFuture]);
        },
        child: FutureBuilder<TeamStatsDashboard>(
          future: _dashboardFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    snapshot.error.toString(),
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ],
              );
            }
            final data = snapshot.data!;
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _hero(data),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: 160,
                      child: StatsMetricCard(
                        label: 'Record',
                        value: '${data.record.wins}-${data.record.losses}',
                        accentColor: widget.schoolAccentColor,
                      ),
                    ),
                    SizedBox(
                      width: 160,
                      child: StatsMetricCard(
                        label: 'Win %',
                        value: '${(data.record.winPercentage * 100).round()}%',
                        accentColor: widget.schoolPrimaryColor,
                      ),
                    ),
                    SizedBox(
                      width: 160,
                      child: StatsMetricCard(label: 'Pins', value: '${data.totalPins}'),
                    ),
                    SizedBox(
                      width: 160,
                      child: StatsMetricCard(
                        label: 'Bonus Rate',
                        value: '${(data.bonusPointRate * 100).round()}%',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                const Text(
                  'Leaderboards',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                FutureBuilder<TeamLeaders>(
                  future: _leadersFuture,
                  builder: (context, leaderSnapshot) {
                    final leaders = leaderSnapshot.data;
                    if (leaders == null) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    return Column(
                      children: [
                        ...leaders.mostPins.map((entry) => LeaderTile(entry: entry)),
                        ...leaders.bestWinPercentage.map((entry) => LeaderTile(entry: entry)),
                        ...leaders.bonusPointLeaders.map((entry) => LeaderTile(entry: entry)),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 22),
                const Text(
                  'Weight Class Breakdown',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                ...data.weightClassBreakdown.map(
                  (item) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF121821),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.weightClass,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Text(
                          '${item.wins}-${item.losses} • ${(item.winPercentage * 100).round()}%',
                          style: const TextStyle(color: Color(0xFFB8C2D4)),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                const Text(
                  'Recent Team Matches',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                ...data.recentMatches.map((match) => MatchHistoryTile(match: match)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _hero(TeamStatsDashboard data) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            widget.schoolPrimaryColor.withOpacity(0.42),
            widget.schoolAccentColor.withOpacity(0.24),
            const Color(0xFF101721),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data.teamName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Recent trend: ${data.recentTrend.trendLabel} • ${data.recentTrend.lastFive.join('-')}',
            style: const TextStyle(color: Color(0xFFD7E0EF), height: 1.4),
          ),
          const SizedBox(height: 8),
          Text(
            'Coach view built for fast scanning: team record, leaders, bonus production, and weight-class health in one place.',
            style: const TextStyle(color: Color(0xFFBBC8D9), height: 1.4),
          ),
        ],
      ),
    );
  }
}
