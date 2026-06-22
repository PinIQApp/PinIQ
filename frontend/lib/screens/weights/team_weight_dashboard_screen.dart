import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../widgets/empty_state_card.dart';
import '../../widgets/subpage_header.dart';
import '../../widgets/weight_status_chip.dart';

class TeamWeightDashboardScreen extends StatefulWidget {
  const TeamWeightDashboardScreen({super.key});

  @override
  State<TeamWeightDashboardScreen> createState() =>
      _TeamWeightDashboardScreenState();
}

class _TeamWeightDashboardScreenState extends State<TeamWeightDashboardScreen> {
  final _groupController = TextEditingController();
  final _gradeController = TextEditingController();
  final _weightClassController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final appState = context.read<AppState>();
    Future.microtask(appState.refreshWeightData);
  }

  @override
  void dispose() {
    _groupController.dispose();
    _gradeController.dispose();
    _weightClassController.dispose();
    super.dispose();
  }

  Future<void> _applyFilters() async {
    await context.read<AppState>().refreshWeightData(
          group: _groupController.text.trim().isEmpty
              ? null
              : _groupController.text.trim(),
          grade: int.tryParse(_gradeController.text.trim()),
          weightClass: _weightClassController.text.trim().isEmpty
              ? null
              : _weightClassController.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final rows = appState.teamWeightDashboard;
    final alerts = appState.weightAlerts;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SubpageHeader(
          title: 'Team Weight Dashboard',
          subtitle:
              'Coach-facing planning board for visibility, pacing, and log consistency.',
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _groupController,
                  decoration: const InputDecoration(labelText: 'Team group'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _gradeController,
                  decoration:
                      const InputDecoration(labelText: 'Graduation year'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _weightClassController,
                  decoration:
                      const InputDecoration(labelText: 'Weight class label'),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: appState.isBusy ? null : _applyFilters,
                        child: const Text('Apply Filters'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          _groupController.clear();
                          _gradeController.clear();
                          _weightClassController.clear();
                          await context.read<AppState>().refreshWeightData();
                        },
                        child: const Text('Clear'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Alerts', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                if (alerts.isEmpty)
                  const Text('No active alerts right now.',
                      style: TextStyle(color: Colors.white70))
                else
                  ...alerts.take(6).map(
                        (alert) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text('• ${alert.alertMessage}',
                              style: const TextStyle(color: Colors.white70)),
                        ),
                      ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (rows.isEmpty)
          const EmptyStateCard(
            title: 'No Athletes Matched These Filters',
            message:
                'Clear the filters or add more logs and plans to populate the dashboard.',
            icon: Icons.filter_alt_off_outlined,
          )
        else
          ...rows.map(
            (row) => Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(row.athleteName,
                                  style:
                                      Theme.of(context).textTheme.titleLarge),
                              const SizedBox(height: 4),
                              Text(
                                '${row.teamGroup ?? 'Athlete'} • ${row.gradeLabel ?? 'No grade'}',
                                style: const TextStyle(color: Colors.white60),
                              ),
                            ],
                          ),
                        ),
                        WeightStatusChip(status: row.status),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _DashboardMetric(
                            label: 'Current',
                            value: row.currentWeight == null
                                ? '--'
                                : '${row.currentWeight!.toStringAsFixed(1)} lbs'),
                        _DashboardMetric(
                            label: 'Projected Class',
                            value: row.projectedClass == null
                                ? '--'
                                : '${row.projectedClass!.toStringAsFixed(0)} lbs'),
                        _DashboardMetric(
                            label: 'Target',
                            value: row.targetWeightClass == null
                                ? '--'
                                : '${row.targetWeightClass!.toStringAsFixed(0)} lbs'),
                        _DashboardMetric(
                            label: 'Allowed / Week',
                            value: row.weeklyAllowedLoss == null
                                ? '--'
                                : '${row.weeklyAllowedLoss!.toStringAsFixed(1)} lbs'),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(row.statusSummary,
                        style: const TextStyle(color: Colors.white)),
                    if (row.warningMessage != null) ...[
                      const SizedBox(height: 8),
                      Text(row.warningMessage!,
                          style: const TextStyle(color: Color(0xFFF4C95D))),
                    ],
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _DashboardMetric extends StatelessWidget {
  const _DashboardMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
