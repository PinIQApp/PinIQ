import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../widgets/branded_header_card.dart';
import '../../widgets/school_logo_badge.dart';

class PendingApprovalScreen extends StatelessWidget {
  const PendingApprovalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final team = appState.activeTeam;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Awaiting Approval'),
        actions: [
          TextButton(
            onPressed: appState.isBusy ? null : () => context.read<AppState>().refreshTeamMembers(),
            child: const Text('Refresh'),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BrandedHeaderCard(
                    title: 'Approval Pending',
                    subtitle:
                        'Your request to join ${team?.schoolName ?? 'the team'} is waiting for a coach or school staff member to approve it.',
                  ),
                  const SizedBox(height: 20),
                  SchoolLogoBadge(
                    team: team,
                    radius: 38,
                    showLabel: true,
                  ),
                  const SizedBox(height: 20),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Team', style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 8),
                          Text('${team?.name ?? ''} • Join code ${team?.joinCode ?? '--'}'),
                          const SizedBox(height: 16),
                          const Text(
                            'Once approved, you will automatically land inside the school dashboard on next refresh.',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
