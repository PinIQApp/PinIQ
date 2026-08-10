import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/branded_header_card.dart';

class AthleteInvitationScreen extends StatefulWidget {
  const AthleteInvitationScreen({super.key});

  @override
  State<AthleteInvitationScreen> createState() =>
      _AthleteInvitationScreenState();
}

class _AthleteInvitationScreenState extends State<AthleteInvitationScreen> {
  String? _error;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final invitations = appState.pendingAthleteInvitations;
    if (invitations.isEmpty) {
      return const SizedBox.shrink();
    }
    final invitation = invitations.first;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Athlete invitation'),
        actions: [
          TextButton(
            onPressed: appState.isBusy
                ? null
                : () => context.read<AppState>().logout(),
            child: const Text('Sign out'),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const BrandedHeaderCard(
                    title: 'A coach invited you',
                    subtitle:
                        'Review the athlete and program before management access is connected to your parent account.',
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            invitation.athleteFullName,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            invitation.teamName,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          _InvitationDetail(
                            label: 'Athlete account',
                            value: invitation.athleteEmail,
                          ),
                          _InvitationDetail(
                            label: 'Your relationship',
                            value: invitation.relationshipLabel,
                          ),
                          _InvitationDetail(
                            label: 'Invited parent email',
                            value: invitation.parentEmail,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          const Text(
                            'Accepting lets you update this athlete’s roster profile and view the parent-safe team, messaging, stats, and weight information already supported by Pin IQ.',
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      _error!,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  ElevatedButton.icon(
                    onPressed: appState.isBusy
                        ? null
                        : () async {
                            try {
                              setState(() => _error = null);
                              await context
                                  .read<AppState>()
                                  .acceptAthleteInvitation(invitation.id);
                            } catch (error) {
                              if (mounted) {
                                setState(() => _error = error.toString());
                              }
                            }
                          },
                    icon: const Icon(Icons.verified_user_rounded),
                    label: Text(
                      appState.isBusy
                          ? 'Connecting...'
                          : 'Accept and manage athlete',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextButton(
                    onPressed: appState.isBusy
                        ? null
                        : () async {
                            try {
                              setState(() => _error = null);
                              await context
                                  .read<AppState>()
                                  .declineAthleteInvitation(invitation.id);
                            } catch (error) {
                              if (mounted) {
                                setState(() => _error = error.toString());
                              }
                            }
                          },
                    child: const Text('This is not my athlete'),
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

class _InvitationDetail extends StatelessWidget {
  const _InvitationDetail({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(label, style: Theme.of(context).textTheme.labelMedium),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
