import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/weight_models.dart';
import '../services/weight_api_service.dart';
import '../widgets/weight_cards.dart';
import '../widgets/weight_status_chip.dart';

class ParentWeightViewScreen extends StatefulWidget {
  const ParentWeightViewScreen({
    super.key,
    required this.api,
    required this.schoolAccentColor,
  });

  final WeightApiService api;
  final Color schoolAccentColor;

  @override
  State<ParentWeightViewScreen> createState() => _ParentWeightViewScreenState();
}

class _ParentWeightViewScreenState extends State<ParentWeightViewScreen> {
  late Future<List<LinkedAthlete>> _linkedAthletesFuture;
  Future<WeightPlanBundle>? _selectedBundleFuture;
  LinkedAthlete? _selectedAthlete;

  @override
  void initState() {
    super.initState();
    _linkedAthletesFuture = widget.api.fetchLinkedAthletes();
  }

  Future<void> _loadAthlete(LinkedAthlete athlete) async {
    setState(() {
      _selectedAthlete = athlete;
      _selectedBundleFuture = widget.api.fetchWeightPlan(
        athleteId: athlete.athleteId,
        teamId: athlete.teamId,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F14),
      appBar: AppBar(
        title: const Text('Parent Weight View'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF121822),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white10),
            ),
            child: const Text(
              'Parents can view linked athlete logs, active planning targets, and alerts. Parents cannot create logs or change plans.',
              style: TextStyle(color: Color(0xFFD6DEEB), height: 1.45),
            ),
          ),
          const SizedBox(height: 18),
          FutureBuilder<List<LinkedAthlete>>(
            future: _linkedAthletesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Text(
                  snapshot.error.toString(),
                  style: const TextStyle(color: Colors.redAccent),
                );
              }
              final athletes = snapshot.data ?? const <LinkedAthlete>[];
              if (athletes.isEmpty) {
                return const Text(
                  'No linked athletes were found for this parent account.',
                  style: TextStyle(color: Color(0xFF98A2B5)),
                );
              }
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: athletes
                    .map(
                      (athlete) => ChoiceChip(
                        label: Text(athlete.athleteName),
                        selected: _selectedAthlete?.athleteId == athlete.athleteId,
                        onSelected: (_) => _loadAthlete(athlete),
                        selectedColor: widget.schoolAccentColor,
                        backgroundColor: const Color(0xFF1A202C),
                        labelStyle: TextStyle(
                          color: _selectedAthlete?.athleteId == athlete.athleteId
                              ? Colors.black
                              : Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 20),
          if (_selectedBundleFuture != null)
            FutureBuilder<WeightPlanBundle>(
              future: _selectedBundleFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Text(
                    snapshot.error.toString(),
                    style: const TextStyle(color: Colors.redAccent),
                  );
                }
                final bundle = snapshot.data;
                final plan = bundle?.latestPlan;
                if (bundle == null) {
                  return const SizedBox.shrink();
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (plan != null) ...[
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${_selectedAthlete?.athleteName ?? 'Athlete'} plan',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          WeightStatusChip(status: plan.status),
                        ],
                      ),
                      const SizedBox(height: 14),
                      WeightMetricCard(
                        label: 'Projected Reachable Class',
                        value: '${plan.estimatedReachableClass.toStringAsFixed(1)}',
                        caption:
                            'Target date ${DateFormat('MMM d, yyyy').format(plan.targetDate.toLocal())}',
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (bundle.activeAlerts.isNotEmpty) ...[
                      const Text(
                        'Alerts',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...bundle.activeAlerts.map((alert) => AlertTile(alert: alert)),
                      const SizedBox(height: 12),
                    ],
                    const Text(
                      'Recent Logs',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...bundle.recentLogs.map((log) => WeightLogTile(log: log)),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}
