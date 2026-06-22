import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import 'body_fat_calculator_screen.dart';
import '../../widgets/empty_state_card.dart';
import '../../widgets/subpage_header.dart';
import '../../widgets/weight_status_chip.dart';

class AthleteWeightPlanScreen extends StatefulWidget {
  const AthleteWeightPlanScreen({super.key});

  @override
  State<AthleteWeightPlanScreen> createState() => _AthleteWeightPlanScreenState();
}

class _AthleteWeightPlanScreenState extends State<AthleteWeightPlanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentWeightController = TextEditingController();
  final _bodyFatController = TextEditingController();
  final _targetClassController = TextEditingController();
  DateTime? _targetDate;
  bool _seeded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AppState>().refreshWeightData();
    });
  }

  @override
  void dispose() {
    _currentWeightController.dispose();
    _bodyFatController.dispose();
    _targetClassController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _targetDate ?? now.add(const Duration(days: 14)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 180)),
    );
    if (picked != null) {
      setState(() => _targetDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _targetDate == null) return;
    await context.read<AppState>().calculateWeightPlan(
          currentWeight: double.parse(_currentWeightController.text.trim()),
          bodyFatPercentage: _bodyFatController.text.trim().isEmpty
              ? null
              : double.parse(_bodyFatController.text.trim()),
          targetWeightClass: double.parse(_targetClassController.text.trim()),
          targetDate: _targetDate!,
        );
  }

  Future<void> _openBodyFatCalculator() async {
    final result = await Navigator.of(context).push<double>(
      MaterialPageRoute(
        builder: (_) => BodyFatCalculatorScreen(
          initialWeight: double.tryParse(_currentWeightController.text.trim()),
        ),
      ),
    );
    if (!mounted || result == null) return;
    setState(() => _bodyFatController.text = result.toStringAsFixed(1));
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final plan = appState.athleteWeightPlan;
    final latestLog = appState.weightHistory.isNotEmpty ? appState.weightHistory.first : null;

    if (!_seeded) {
      _currentWeightController.text = latestLog?.weight.toStringAsFixed(1) ?? '';
      _bodyFatController.text = latestLog?.bodyFatPercentage?.toStringAsFixed(1) ?? '';
      _targetClassController.text = plan?.targetWeightClass.toStringAsFixed(0) ?? '';
      _targetDate = plan?.targetDate;
      _seeded = true;
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SubpageHeader(
          title: 'Safe Descent Planner',
          subtitle: 'Build a safer plan, review status, and keep the target date visible.',
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _currentWeightController,
                    decoration: const InputDecoration(labelText: 'Current weight (lbs)'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) => (value == null || double.tryParse(value) == null) ? 'Enter current weight' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _bodyFatController,
                    decoration: const InputDecoration(labelText: 'Body fat %'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _openBodyFatCalculator,
                    icon: const Icon(Icons.calculate_outlined),
                    label: const Text('Open body fat calculator'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _targetClassController,
                    decoration: const InputDecoration(labelText: 'Target weight class'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) => (value == null || double.tryParse(value) == null) ? 'Enter target class' : null,
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: _pickDate,
                    child: Text(
                      _targetDate == null
                          ? 'Choose weigh-in date'
                          : 'Weigh-in date: ${_targetDate!.month}/${_targetDate!.day}/${_targetDate!.year}',
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: appState.isBusy ? null : _submit,
                    child: Text(appState.isBusy ? 'Calculating...' : 'Calculate Plan'),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (plan == null)
          const EmptyStateCard(
            title: 'No Plan Yet',
            message: 'Create a target class and weigh-in date to see a safe descent summary.',
            icon: Icons.timeline_outlined,
          )
        else
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Current Plan', style: Theme.of(context).textTheme.titleLarge),
                      WeightStatusChip(status: plan.status),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _MetricCard(label: 'Current', value: '${plan.currentWeight.toStringAsFixed(1)} lbs'),
                      _MetricCard(label: 'Target Class', value: '${plan.targetWeightClass.toStringAsFixed(0)} lbs'),
                      _MetricCard(label: 'Weekly Allowed', value: '${plan.weeklyAllowedLoss.toStringAsFixed(1)} lbs'),
                      _MetricCard(label: 'Reachable Class', value: '${plan.estimatedReachableClass.toStringAsFixed(0)} lbs'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(plan.summary, style: const TextStyle(color: Colors.white)),
                  const SizedBox(height: 10),
                  Text(
                    'Projected target date: ${plan.projectedTargetDate.month}/${plan.projectedTargetDate.day}/${plan.projectedTargetDate.year}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  if (plan.warningMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7A1E1E).withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFFF6B6B).withValues(alpha: 0.4)),
                      ),
                      child: Text(plan.warningMessage!, style: const TextStyle(color: Colors.white)),
                    ),
                  ],
                  if (appState.weightAlerts.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    ...appState.weightAlerts.take(3).map(
                      (alert) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text('• ${alert.alertMessage}', style: const TextStyle(color: Colors.white70)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12)),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
