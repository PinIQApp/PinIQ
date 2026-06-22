import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../widgets/empty_state_card.dart';
import '../../widgets/subpage_header.dart';
import '../../widgets/weight_trend_chart.dart';
import 'body_fat_calculator_screen.dart';

class AthleteWeightLogScreen extends StatefulWidget {
  const AthleteWeightLogScreen({super.key});

  @override
  State<AthleteWeightLogScreen> createState() => _AthleteWeightLogScreenState();
}

class _AthleteWeightLogScreenState extends State<AthleteWeightLogScreen> {
  final _formKey = GlobalKey<FormState>();
  final _weightController = TextEditingController();
  final _bodyFatController = TextEditingController();
  final _hydrationController = TextEditingController();
  final _commentsController = TextEditingController();

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
    _weightController.dispose();
    _bodyFatController.dispose();
    _hydrationController.dispose();
    _commentsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final appState = context.read<AppState>();
    await appState.logWeight(
      weight: double.parse(_weightController.text.trim()),
      bodyFatPercentage: _bodyFatController.text.trim().isEmpty
          ? null
          : double.parse(_bodyFatController.text.trim()),
      hydrationNote: _hydrationController.text.trim().isEmpty ? null : _hydrationController.text.trim(),
      comments: _commentsController.text.trim().isEmpty ? null : _commentsController.text.trim(),
    );
    _weightController.clear();
    _bodyFatController.clear();
    _hydrationController.clear();
    _commentsController.clear();
  }

  Future<void> _openBodyFatCalculator() async {
    final result = await Navigator.of(context).push<double>(
      MaterialPageRoute(
        builder: (_) => BodyFatCalculatorScreen(
          initialWeight: double.tryParse(_weightController.text.trim()),
        ),
      ),
    );
    if (!mounted || result == null) return;
    setState(() => _bodyFatController.text = result.toStringAsFixed(1));
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final logs = appState.weightHistory;
    final chartValues = logs.reversed.map((log) => log.weight).toList();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SubpageHeader(
          title: 'Daily Weight Log',
          subtitle: 'Track current weight, hydration notes, and anything staff should see at a glance.',
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
                    controller: _weightController,
                    decoration: const InputDecoration(labelText: 'Current weight (lbs)'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) => (value == null || double.tryParse(value) == null) ? 'Enter a weight' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _bodyFatController,
                    decoration: const InputDecoration(labelText: 'Body fat % (optional)'),
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
                    controller: _hydrationController,
                    decoration: const InputDecoration(labelText: 'Hydration note'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _commentsController,
                    decoration: const InputDecoration(labelText: 'Comments'),
                    minLines: 2,
                    maxLines: 4,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: appState.isBusy ? null : _submit,
                    child: Text(appState.isBusy ? 'Saving...' : 'Save Weight Log'),
                  ),
                ],
              ),
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
                Text('Trend', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                WeightTrendChart(values: chartValues),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text('Recent History', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        if (logs.isEmpty)
          const EmptyStateCard(
            title: 'No Weight Logs Yet',
            message: 'Daily logs will appear here once the athlete starts tracking.',
            icon: Icons.monitor_weight_outlined,
          )
        else
          ...logs.map(
            (log) => Card(
              child: ListTile(
                title: Text('${log.weight.toStringAsFixed(1)} lbs'),
                subtitle: Text(
                  '${log.loggedAt.month}/${log.loggedAt.day}/${log.loggedAt.year} • ${log.hydrationNote ?? 'No hydration note'}',
                ),
                trailing: log.bodyFatPercentage == null
                    ? null
                    : Text('${log.bodyFatPercentage!.toStringAsFixed(1)}% BF'),
              ),
            ),
          ),
      ],
    );
  }
}
