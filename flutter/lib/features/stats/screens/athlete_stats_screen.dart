import 'package:flutter/material.dart';

import '../models/stats_models.dart';
import '../services/stats_api_service.dart';
import '../widgets/stats_cards.dart';

class AthleteStatsScreen extends StatefulWidget {
  const AthleteStatsScreen({
    super.key,
    required this.api,
    required this.teamId,
    required this.athleteId,
    required this.schoolPrimaryColor,
    required this.schoolAccentColor,
  });

  final StatsApiService api;
  final int teamId;
  final int athleteId;
  final Color schoolPrimaryColor;
  final Color schoolAccentColor;

  @override
  State<AthleteStatsScreen> createState() => _AthleteStatsScreenState();
}

class _AthleteStatsScreenState extends State<AthleteStatsScreen> {
  late Future<AthleteStatsDashboard> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.api.fetchAthleteStats(
      athleteId: widget.athleteId,
      teamId: widget.teamId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E13),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text('Athlete Stats'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _future = widget.api.fetchAthleteStats(
              athleteId: widget.athleteId,
              teamId: widget.teamId,
            );
          });
          await _future;
        },
        child: FutureBuilder<AthleteStatsDashboard>(
          future: _future,
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
                _header(data),
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
                      child: StatsMetricCard(
                        label: 'Pin Rate',
                        value: '${(data.resultTypes.pinRate * 100).round()}%',
                      ),
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
                const SizedBox(height: 18),
                _trendSection(data),
                const SizedBox(height: 18),
                _averageSection(data),
                const SizedBox(height: 18),
                SummaryTextPanel(
                  title: 'Strengths',
                  lines: data.strengthsWeaknesses.strengths,
                ),
                const SizedBox(height: 12),
                SummaryTextPanel(
                  title: 'Weakness Focus',
                  lines: data.strengthsWeaknesses.weaknesses,
                ),
                const SizedBox(height: 18),
                const Text(
                  'Last 5 Matches',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                ...data.lastFiveMatches.map((match) => MatchHistoryTile(match: match)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _header(AthleteStatsDashboard data) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            widget.schoolPrimaryColor.withOpacity(0.42),
            widget.schoolAccentColor.withOpacity(0.24),
            const Color(0xFF101722),
          ],
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data.athleteName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Trend: ${data.recentTrend.trendLabel} • Last 5: ${data.recentTrend.lastFive.join('-')}',
            style: const TextStyle(color: Color(0xFFD9E1EE), height: 1.4),
          ),
          const SizedBox(height: 8),
          Text(
            data.strengthsWeaknesses.coachSummary,
            style: const TextStyle(color: Color(0xFFBDC9DA), height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _trendSection(AthleteStatsDashboard data) {
    return Row(
      children: [
        Expanded(
          child: StatsMetricCard(
            label: 'Decision Rate',
            value: '${(data.resultTypes.decisionRate * 100).round()}%',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StatsMetricCard(
            label: 'Tech Rate',
            value: '${(data.resultTypes.techFallRate * 100).round()}%',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StatsMetricCard(
            label: 'Major Rate',
            value: '${(data.resultTypes.majorDecisionRate * 100).round()}%',
          ),
        ),
      ],
    );
  }

  Widget _averageSection(AthleteStatsDashboard data) {
    final averages = data.statAverages;
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        SizedBox(
          width: 160,
          child: StatsMetricCard(label: 'TD / Match', value: averages.takedownsPerMatch.toStringAsFixed(1)),
        ),
        SizedBox(
          width: 160,
          child: StatsMetricCard(label: 'Esc / Match', value: averages.escapesPerMatch.toStringAsFixed(1)),
        ),
        SizedBox(
          width: 160,
          child: StatsMetricCard(label: 'Rev / Match', value: averages.reversalsPerMatch.toStringAsFixed(1)),
        ),
        SizedBox(
          width: 160,
          child: StatsMetricCard(label: 'NF / Match', value: averages.nearfallPointsPerMatch.toStringAsFixed(1)),
        ),
      ],
    );
  }
}
