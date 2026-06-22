import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../widgets/empty_state_card.dart';
import '../../widgets/subpage_header.dart';
import '../../widgets/weight_status_chip.dart';

class ParentWeightViewScreen extends StatefulWidget {
  const ParentWeightViewScreen({super.key});

  @override
  State<ParentWeightViewScreen> createState() => _ParentWeightViewScreenState();
}

class _ParentWeightViewScreenState extends State<ParentWeightViewScreen> {
  @override
  void initState() {
    super.initState();
    final appState = context.read<AppState>();
    Future.microtask(appState.refreshWeightData);
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final linkedAthletes = appState.linkedAthletes;
    final selectedAthlete = appState.selectedLinkedAthlete;
    final plan = appState.athleteWeightPlan;
    final logs = appState.weightHistory;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SubpageHeader(
          title: 'Parent Weight View',
          subtitle:
              'Read-only visibility into linked athlete logs, plan details, and active warnings.',
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (linkedAthletes.isEmpty)
                  const Text('No linked athletes available.',
                      style: TextStyle(color: Colors.white70))
                else
                  DropdownButtonFormField<int>(
                    initialValue: selectedAthlete?.athleteId,
                    items: linkedAthletes
                        .map(
                          (athlete) => DropdownMenuItem<int>(
                            value: athlete.athleteId,
                            child: Text(
                                '${athlete.athleteName} • ${athlete.relationshipLabel}'),
                          ),
                        )
                        .toList(),
                    onChanged: (value) async {
                      if (value != null) {
                        await context
                            .read<AppState>()
                            .selectParentAthlete(value);
                      }
                    },
                    decoration:
                        const InputDecoration(labelText: 'Linked athlete'),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (selectedAthlete == null)
          const EmptyStateCard(
            title: 'No Athlete Selected',
            message: 'Choose a linked athlete to view plan and logs.',
            icon: Icons.supervised_user_circle_outlined,
          )
        else ...[
          if (plan != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(selectedAthlete.athleteName,
                            style: Theme.of(context).textTheme.titleLarge),
                        WeightStatusChip(status: plan.status),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(plan.summary,
                        style: const TextStyle(color: Colors.white)),
                    const SizedBox(height: 8),
                    Text(
                      'Current ${plan.currentWeight.toStringAsFixed(1)} lbs • Target ${plan.targetWeightClass.toStringAsFixed(0)} lbs',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    if (plan.warningMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(plan.warningMessage!,
                          style: const TextStyle(color: Color(0xFFF4C95D))),
                    ],
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          Text('Recent Logs', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          if (logs.isEmpty)
            const EmptyStateCard(
              title: 'No Logs Shared Yet',
              message:
                  'Weight logs will appear here once the athlete starts tracking.',
              icon: Icons.monitor_weight_outlined,
            )
          else
            ...logs.map(
              (log) => Card(
                child: ListTile(
                  title: Text('${log.weight.toStringAsFixed(1)} lbs'),
                  subtitle: Text(
                      '${log.loggedAt.month}/${log.loggedAt.day}/${log.loggedAt.year}'),
                  trailing: log.hydrationNote == null
                      ? null
                      : SizedBox(
                          width: 130,
                          child: Text(
                            log.hydrationNote!,
                            textAlign: TextAlign.right,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white60),
                          ),
                        ),
                ),
              ),
            ),
        ],
      ],
    );
  }
}
