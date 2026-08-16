import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../models/athlete_invitation_model.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/empty_state_card.dart';
import '../../widgets/subpage_header.dart';

class ParentAthleteManagementScreen extends StatefulWidget {
  const ParentAthleteManagementScreen({super.key});

  @override
  State<ParentAthleteManagementScreen> createState() =>
      _ParentAthleteManagementScreenState();
}

class _ParentAthleteManagementScreenState
    extends State<ParentAthleteManagementScreen> {
  final _fullName = TextEditingController();
  final _phone = TextEditingController();
  final _hometown = TextEditingController();
  final _graduationYear = TextEditingController();
  final _weightClass = TextEditingController();
  final _bio = TextEditingController();
  int? _loadedAthleteId;
  String? _message;
  String? _error;

  @override
  void initState() {
    super.initState();
    final appState = context.read<AppState>();
    Future.microtask(() async {
      await appState.refreshWeightData();
      final selected = appState.selectedLinkedAthlete;
      if (selected != null) {
        await appState.loadManagedAthleteProfile(selected.athleteId);
      }
    });
  }

  @override
  void dispose() {
    _fullName.dispose();
    _phone.dispose();
    _hometown.dispose();
    _graduationYear.dispose();
    _weightClass.dispose();
    _bio.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final linkedAthletes = appState.linkedAthletes;
    final selected = appState.selectedLinkedAthlete;
    final profile = appState.managedAthleteProfile;
    _syncControllers(profile);

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        const SubpageHeader(
          title: 'Manage athlete',
          subtitle:
              'Update the roster profile for athletes whose coach invitation you accepted.',
        ),
        const SizedBox(height: AppSpacing.lg),
        if (linkedAthletes.isEmpty)
          const EmptyStateCard(
            title: 'No managed athletes',
            message:
                'A coach invitation must be accepted before an athlete can be managed here.',
            icon: Icons.supervised_user_circle_outlined,
          )
        else ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: DropdownButtonFormField<int>(
                initialValue: selected?.athleteId,
                decoration: const InputDecoration(labelText: 'Managed athlete'),
                items: linkedAthletes
                    .map(
                      (athlete) => DropdownMenuItem<int>(
                        value: athlete.athleteId,
                        child: Text(
                          '${athlete.athleteName} • ${athlete.relationshipLabel}',
                        ),
                      ),
                    )
                    .toList(),
                onChanged: appState.isBusy
                    ? null
                    : (athleteId) async {
                        if (athleteId == null) return;
                        setState(() {
                          _loadedAthleteId = null;
                          _message = null;
                          _error = null;
                        });
                        try {
                          await context
                              .read<AppState>()
                              .selectParentAthlete(athleteId);
                        } catch (error) {
                          if (mounted) {
                            setState(() => _error = error.toString());
                          }
                        }
                      },
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (profile == null || profile.userId != selected?.athleteId)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: CircularProgressIndicator(),
              ),
            )
          else
            _buildProfileForm(context, appState, profile),
        ],
        const SizedBox(height: 96),
      ],
    );
  }

  Widget _buildProfileForm(
    BuildContext context,
    AppState appState,
    ManagedAthleteProfileModel profile,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Roster profile',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.xs),
            const Text(
              'Contact and roster details are editable. Athlete email is not required.',
            ),
            const SizedBox(height: AppSpacing.lg),
            LayoutBuilder(
              builder: (context, constraints) {
                final fieldWidth = constraints.maxWidth >= 760
                    ? (constraints.maxWidth - AppSpacing.md) / 2
                    : constraints.maxWidth;
                return Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.md,
                  children: [
                    _field(_fullName, 'Full name', fieldWidth),
                    _field(_phone, 'Phone', fieldWidth),
                    _field(_hometown, 'Hometown', fieldWidth),
                    _field(
                      _graduationYear,
                      'Graduation year',
                      fieldWidth,
                      keyboardType: TextInputType.number,
                    ),
                    _field(_weightClass, 'Weight class', fieldWidth),
                    SizedBox(
                      width: constraints.maxWidth,
                      child: TextField(
                        controller: _bio,
                        minLines: 3,
                        maxLines: 5,
                        decoration: const InputDecoration(labelText: 'Bio'),
                      ),
                    ),
                  ],
                );
              },
            ),
            if (_message != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(_message!,
                  style: const TextStyle(color: Colors.greenAccent)),
            ],
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(_error!, style: const TextStyle(color: Colors.redAccent)),
            ],
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton.icon(
              onPressed: appState.isBusy ? null : () => _save(context),
              icon: const Icon(Icons.save_rounded),
              label: Text(appState.isBusy ? 'Saving...' : 'Save athlete'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    double width, {
    bool enabled = true,
    TextInputType? keyboardType,
  }) {
    return SizedBox(
      width: width,
      child: TextField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }

  void _syncControllers(ManagedAthleteProfileModel? profile) {
    if (profile == null || profile.userId == _loadedAthleteId) return;
    _loadedAthleteId = profile.userId;
    _fullName.text = profile.fullName;
    _phone.text = profile.phone ?? '';
    _hometown.text = profile.hometown ?? '';
    _graduationYear.text = profile.graduationYear?.toString() ?? '';
    _weightClass.text = profile.weightClass ?? '';
    _bio.text = profile.bio ?? '';
  }

  Future<void> _save(BuildContext context) async {
    final graduationYearText = _graduationYear.text.trim();
    final graduationYear =
        graduationYearText.isEmpty ? null : int.tryParse(graduationYearText);
    if (_fullName.text.trim().length < 2) {
      setState(() => _error = 'Enter the athlete’s full name.');
      return;
    }
    if (graduationYearText.isNotEmpty && graduationYear == null) {
      setState(() => _error = 'Graduation year must be a number.');
      return;
    }

    try {
      setState(() {
        _message = null;
        _error = null;
      });
      await context.read<AppState>().updateManagedAthleteProfile(
            fullName: _fullName.text.trim(),
            phone: _nullable(_phone.text),
            hometown: _nullable(_hometown.text),
            graduationYear: graduationYear,
            weightClass: _nullable(_weightClass.text),
            bio: _nullable(_bio.text),
          );
      if (mounted) {
        setState(() => _message = 'Athlete profile updated.');
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = error.toString());
      }
    }
  }

  String? _nullable(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
