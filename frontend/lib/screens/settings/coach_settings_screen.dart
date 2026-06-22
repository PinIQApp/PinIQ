import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../widgets/school_logo_badge.dart';
import '../../widgets/subpage_header.dart';
import 'profile_settings_screen.dart';

class CoachSettingsScreen extends StatefulWidget {
  const CoachSettingsScreen({super.key});

  @override
  State<CoachSettingsScreen> createState() => _CoachSettingsScreenState();
}

class _CoachSettingsScreenState extends State<CoachSettingsScreen> {
  int sectionIndex = 0;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final team = appState.activeTeam;
    final user = appState.user;
    final sections = [
      const ProfileSettingsScreen(),
      SingleChildScrollView(
        padding: const EdgeInsets.only(top: 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _SettingsCard(
                  title: 'Program Identity',
                  lines: [
                    'School: ${team?.schoolName ?? '--'}',
                    'Mascot: ${team?.mascotName ?? '--'}',
                    'Season: ${team?.name ?? '--'}',
                  ],
                ),
                _SettingsCard(
                  title: 'Access Control',
                  lines: [
                    'Join code: ${team?.joinCode ?? '--'}',
                    'Pending approval required for athletes, parents, and assistant coaches',
                    'Staff can approve or remove members from the Members tab',
                  ],
                ),
                _SettingsCard(
                  title: 'Branding Status',
                  lines: [
                    'Primary: ${team?.primaryColor ?? '--'}',
                    'Secondary: ${team?.secondaryColor ?? '--'}',
                    'Accent: ${team?.accentColor ?? '--'}',
                  ],
                ),
                _SettingsCard(
                  title: 'Signed In',
                  lines: [
                    'User: ${user?.fullName ?? '--'}',
                    'Role: ${user?.role.replaceAll('_', ' ') ?? '--'}',
                    'Email: ${user?.email ?? '--'}',
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Recommended Next Build', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 10),
                    const Text(
                      'The foundation is now strong enough to support roster profiles, profile settings, and richer school admin controls in the next chat.',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SubpageHeader(
                title: 'Settings',
                subtitle:
                    'Manage your account and the core controls for ${team?.schoolName ?? 'your program'} without leaving the foundation layer.',
              ),
              const SizedBox(height: 20),
              SchoolLogoBadge(
                team: team,
                radius: 34,
                showLabel: true,
              ),
              const SizedBox(height: 20),
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment<int>(value: 0, label: Text('Profile')),
                  ButtonSegment<int>(value: 1, label: Text('Program')),
                ],
                selected: {sectionIndex},
                onSelectionChanged: (value) => setState(() => sectionIndex = value.first),
              ),
              const SizedBox(height: 20),
              sections[sectionIndex],
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.title,
    required this.lines,
  });

  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 430,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              ...lines.map(
                (line) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(line, style: const TextStyle(color: Colors.white70)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
