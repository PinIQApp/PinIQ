import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../widgets/branded_header_card.dart';
import '../../widgets/school_logo_badge.dart';

class JoinTeamScreen extends StatefulWidget {
  const JoinTeamScreen({super.key});

  @override
  State<JoinTeamScreen> createState() => _JoinTeamScreenState();
}

class _JoinTeamScreenState extends State<JoinTeamScreen> {
  final _joinCode = TextEditingController();
  String? _error;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(title: const Text('Join Team')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const BrandedHeaderCard(
                    title: 'Join Your Program',
                    subtitle: 'Enter the team join code provided by your coach or school staff.',
                  ),
                  const SizedBox(height: 24),
                  SchoolLogoBadge(
                    team: appState.activeTeam,
                    radius: 34,
                    showLabel: true,
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _joinCode,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'Team Join Code',
                      hintText: 'Example: RHS2026',
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: const TextStyle(color: Colors.redAccent)),
                  ],
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: appState.isBusy
                        ? null
                        : () async {
                            try {
                              setState(() => _error = null);
                              await context.read<AppState>().joinTeam(_joinCode.text.trim());
                            } catch (e) {
                              setState(() => _error = e.toString());
                            }
                          },
                    child: Text(appState.isBusy ? 'Joining...' : 'Join Team'),
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
