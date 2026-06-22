import 'package:flutter/material.dart';

import '../models/weight_models.dart';
import '../services/weight_api_service.dart';
import '../widgets/weight_cards.dart';

class TeamWeightDashboardScreen extends StatefulWidget {
  const TeamWeightDashboardScreen({
    super.key,
    required this.api,
    required this.teamId,
    required this.schoolPrimaryColor,
    required this.schoolAccentColor,
  });

  final WeightApiService api;
  final int teamId;
  final Color schoolPrimaryColor;
  final Color schoolAccentColor;

  @override
  State<TeamWeightDashboardScreen> createState() => _TeamWeightDashboardScreenState();
}

class _TeamWeightDashboardScreenState extends State<TeamWeightDashboardScreen> {
  final _groupController = TextEditingController();
  final _weightClassController = TextEditingController();
  int? _gradeFilter;

  late Future<List<AthleteWeightSnapshot>> _dashboardFuture;
  late Future<List<WeightAlertItem>> _alertsFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _groupController.dispose();
    _weightClassController.dispose();
    super.dispose();
  }

  void _reload() {
    _dashboardFuture = widget.api.fetchTeamDashboard(
      teamId: widget.teamId,
      group: _groupController.text.trim().isEmpty ? null : _groupController.text.trim(),
      grade: _gradeFilter,
      weightClass: _weightClassController.text.trim().isEmpty
          ? null
          : _weightClassController.text.trim(),
    );
    _alertsFuture = widget.api.fetchTeamAlerts(teamId: widget.teamId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E13),
      appBar: AppBar(
        title: const Text('Team Weight Dashboard'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(_reload);
          await Future.wait([_dashboardFuture, _alertsFuture]);
        },
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildHeader(),
            const SizedBox(height: 18),
            _buildFilters(),
            const SizedBox(height: 22),
            FutureBuilder<List<WeightAlertItem>>(
              future: _alertsFuture,
              builder: (context, snapshot) {
                final alerts = snapshot.data ?? const <WeightAlertItem>[];
                return Row(
                  children: [
                    Expanded(
                      child: WeightMetricCard(
                        label: 'Active Alerts',
                        value: '${alerts.length}',
                        caption: 'Team-level visibility for missing logs and unsafe pace',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FutureBuilder<List<AthleteWeightSnapshot>>(
                        future: _dashboardFuture,
                        builder: (context, dashboardSnapshot) {
                          final roster = dashboardSnapshot.data ?? const <AthleteWeightSnapshot>[];
                          final redCount = roster
                              .where((item) => item.status == WeightPlanStatus.red)
                              .length;
                          return WeightMetricCard(
                            label: 'Red Status',
                            value: '$redCount',
                            caption: 'Athletes who need immediate coach review',
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 22),
            const Text(
              'Athletes',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<AthleteWeightSnapshot>>(
              future: _dashboardFuture,
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
                final athletes = snapshot.data ?? const <AthleteWeightSnapshot>[];
                if (athletes.isEmpty) {
                  return const Text(
                    'No athletes match the current filter set.',
                    style: TextStyle(color: Color(0xFF97A1B4)),
                  );
                }
                return Column(
                  children: athletes
                      .map((snapshot) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: AthleteSnapshotCard(snapshot: snapshot),
                          ))
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            widget.schoolPrimaryColor.withOpacity(0.45),
            widget.schoolAccentColor.withOpacity(0.2),
            const Color(0xFF101721),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white10),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'WrestleTech Weight Room',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Coach-facing planning dashboard for logging consistency, safe descent pacing, and parent-visible accountability.',
            style: TextStyle(color: Color(0xFFD7E0EF), height: 1.45),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF121821),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _textField(_groupController, 'Team group'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<int?>(
                  value: _gradeFilter,
                  dropdownColor: const Color(0xFF1A2230),
                  style: const TextStyle(color: Colors.white),
                  decoration: _decoration('Grade'),
                  items: const [
                    DropdownMenuItem<int?>(value: null, child: Text('All grades')),
                    DropdownMenuItem<int?>(value: 9, child: Text('Grade 9')),
                    DropdownMenuItem<int?>(value: 10, child: Text('Grade 10')),
                    DropdownMenuItem<int?>(value: 11, child: Text('Grade 11')),
                    DropdownMenuItem<int?>(value: 12, child: Text('Grade 12')),
                  ],
                  onChanged: (value) => setState(() => _gradeFilter = value),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _textField(_weightClassController, 'Weight class'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: widget.schoolAccentColor,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () => setState(_reload),
                  child: const Text('Apply Filters'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _textField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: _decoration(label),
    );
  }

  InputDecoration _decoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFF9AA3B2)),
      filled: true,
      fillColor: const Color(0xFF1A2230),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.white10),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: widget.schoolAccentColor),
      ),
    );
  }
}
