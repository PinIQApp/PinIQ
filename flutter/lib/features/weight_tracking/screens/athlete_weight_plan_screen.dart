import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/weight_models.dart';
import '../services/weight_api_service.dart';
import '../widgets/weight_cards.dart';
import '../widgets/weight_status_chip.dart';

class AthleteWeightPlanScreen extends StatefulWidget {
  const AthleteWeightPlanScreen({
    super.key,
    required this.api,
    required this.athleteId,
    required this.teamId,
    required this.schoolAccentColor,
  });

  final WeightApiService api;
  final int athleteId;
  final int teamId;
  final Color schoolAccentColor;

  @override
  State<AthleteWeightPlanScreen> createState() => _AthleteWeightPlanScreenState();
}

class _AthleteWeightPlanScreenState extends State<AthleteWeightPlanScreen> {
  final _currentWeightController = TextEditingController();
  final _bodyFatController = TextEditingController();
  final _targetClassController = TextEditingController();

  DateTime _targetDate = DateTime.now().add(const Duration(days: 28));
  bool _calculating = false;
  bool _didPrefill = false;
  late Future<WeightPlanBundle> _bundleFuture;

  @override
  void initState() {
    super.initState();
    _bundleFuture = _loadBundle();
  }

  @override
  void dispose() {
    _currentWeightController.dispose();
    _bodyFatController.dispose();
    _targetClassController.dispose();
    super.dispose();
  }

  Future<WeightPlanBundle> _loadBundle() {
    return widget.api.fetchWeightPlan(
      athleteId: widget.athleteId,
      teamId: widget.teamId,
    );
  }

  Future<void> _calculatePlan() async {
    if (_currentWeightController.text.trim().isEmpty ||
        _targetClassController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Current weight and target class are required.')),
      );
      return;
    }
    setState(() => _calculating = true);
    try {
      await widget.api.calculatePlan(
        athleteId: widget.athleteId,
        teamId: widget.teamId,
        currentWeight: double.parse(_currentWeightController.text.trim()),
        bodyFatPercentage: _bodyFatController.text.trim().isEmpty
            ? null
            : double.parse(_bodyFatController.text.trim()),
        targetWeightClass: double.parse(_targetClassController.text.trim()),
        targetDate: _targetDate,
      );
      setState(() => _bundleFuture = _loadBundle());
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _calculating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F14),
      appBar: AppBar(
        title: const Text('Weight Plan'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<WeightPlanBundle>(
        future: _bundleFuture,
        builder: (context, snapshot) {
          final bundle = snapshot.data;
          final plan = bundle?.latestPlan;
          if (plan != null && !_didPrefill) {
            _didPrefill = true;
            _currentWeightController.text = plan.currentWeight.toStringAsFixed(1);
            _bodyFatController.text =
                plan.bodyFatPercentage?.toStringAsFixed(1) ?? '';
            _targetClassController.text =
                plan.targetWeightClass.toStringAsFixed(1);
            _targetDate = plan.targetDate;
          }
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _buildPlannerForm(),
              const SizedBox(height: 20),
              if (plan != null) ...[
                Row(
                  children: [
                    WeightStatusChip(status: plan.status),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        plan.summary,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.25,
                  children: [
                    WeightMetricCard(
                      label: 'Weekly Allowed Drop',
                      value: '${plan.weeklyAllowedLoss.toStringAsFixed(1)} lbs',
                      caption: 'Configured weekly planning cap',
                    ),
                    WeightMetricCard(
                      label: 'Required Weekly Drop',
                      value: '${plan.requiredWeeklyLoss.toStringAsFixed(1)} lbs',
                      caption: 'Current pace needed to hit target',
                    ),
                    WeightMetricCard(
                      label: 'Reachable Weight',
                      value: '${plan.projectedReachableWeight.toStringAsFixed(1)} lbs',
                      caption: 'Projected safe reach by target date',
                    ),
                    WeightMetricCard(
                      label: 'Reachable Class',
                      value: '${plan.estimatedReachableClass.toStringAsFixed(1)}',
                      caption: 'Nearest class within pacing rules',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141A22),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Planning Notes',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Projected target date: ${DateFormat('MMM d, yyyy').format(plan.projectedTargetDate.toLocal())}',
                        style: const TextStyle(color: Color(0xFFE5EBF5)),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        plan.warningMessage ??
                            'No active warnings. Continue consistent logging so coaches and parents can track progress.',
                        style: TextStyle(
                          color: plan.warningMessage == null
                              ? const Color(0xFFB6C1D3)
                              : const Color(0xFFFFC9A5),
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (snapshot.connectionState == ConnectionState.waiting) ...[
                const Center(child: CircularProgressIndicator()),
              ] else ...[
                const Text(
                  'No plan calculated yet. Enter a target to build a descent plan for coach and parent visibility.',
                  style: TextStyle(color: Color(0xFF9AA3B2), height: 1.4),
                ),
              ],
              const SizedBox(height: 24),
              if ((bundle?.activeAlerts ?? const <WeightAlertItem>[]).isNotEmpty) ...[
                const Text(
                  'Current Alerts',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                ...bundle!.activeAlerts.map((alert) => AlertTile(alert: alert)),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildPlannerForm() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF111720),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Safe Descent Planner',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Use this as a planning and education tool aligned to school visibility workflows.',
            style: TextStyle(color: Color(0xFF9FAABD), height: 1.4),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _currentWeightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: Colors.white),
            decoration: _inputDecoration('Current weight'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _bodyFatController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('Body fat %'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _targetClassController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('Target class'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: _pickTargetDate,
            child: InputDecorator(
              decoration: _inputDecoration('Weigh-in date'),
              child: Text(
                DateFormat('MMM d, yyyy').format(_targetDate),
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: widget.schoolAccentColor,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: _calculating ? null : _calculatePlan,
              child: Text(_calculating ? 'Calculating...' : 'Build Weight Plan'),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFF9AA3B2)),
      filled: true,
      fillColor: const Color(0xFF1B2230),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.white10),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: widget.schoolAccentColor),
      ),
    );
  }

  Future<void> _pickTargetDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _targetDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 180)),
    );
    if (picked == null) {
      return;
    }
    setState(() => _targetDate = picked);
  }
}
