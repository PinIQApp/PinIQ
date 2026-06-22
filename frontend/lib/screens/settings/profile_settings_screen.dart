import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../widgets/branded_header_card.dart';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  late final TextEditingController _fullName;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  late final TextEditingController _role;
  final _currentPassword = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();
  String? _message;
  String? _error;

  @override
  void initState() {
    super.initState();
    final user = context.read<AppState>().user!;
    _fullName = TextEditingController(text: user.fullName);
    _email = TextEditingController(text: user.email);
    _phone = TextEditingController(text: user.phone ?? '');
    _role = TextEditingController(text: user.role.replaceAll('_', ' '));
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final user = appState.user;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BrandedHeaderCard(
                title: 'Profile Settings',
                subtitle:
                    'Update your name and contact details for ${user?.role.replaceAll('_', ' ') ?? 'account'} access in Pin IQ.',
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _field(_fullName, 'Full Name'),
                  _field(_email, 'Email', enabled: false),
                  _field(_phone, 'Phone'),
                  _field(_role, 'Role', enabled: false),
                ],
              ),
              if (_message != null) ...[
                const SizedBox(height: 12),
                Text(_message!,
                    style: const TextStyle(color: Colors.greenAccent)),
              ],
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
                          setState(() {
                            _error = null;
                            _message = null;
                          });
                          await context.read<AppState>().updateProfile(
                                fullName: _fullName.text.trim(),
                                phone: _phone.text.trim().isEmpty
                                    ? null
                                    : _phone.text.trim(),
                              );
                          setState(() => _message = 'Profile updated.');
                        } catch (e) {
                          setState(() => _error = e.toString());
                        }
                      },
                child: Text(appState.isBusy ? 'Saving...' : 'Save Profile'),
              ),
              const SizedBox(height: 28),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Change Password',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          _field(_currentPassword, 'Current Password',
                              obscureText: true),
                          _field(_newPassword, 'New Password',
                              obscureText: true),
                          _field(_confirmPassword, 'Confirm New Password',
                              obscureText: true),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: appState.isBusy
                            ? null
                            : () async {
                                if (_newPassword.text !=
                                    _confirmPassword.text) {
                                  setState(() =>
                                      _error = 'New passwords do not match.');
                                  return;
                                }
                                try {
                                  setState(() {
                                    _error = null;
                                    _message = null;
                                  });
                                  await context.read<AppState>().changePassword(
                                        currentPassword: _currentPassword.text,
                                        newPassword: _newPassword.text,
                                      );
                                  _currentPassword.clear();
                                  _newPassword.clear();
                                  _confirmPassword.clear();
                                  setState(
                                      () => _message = 'Password updated.');
                                } catch (e) {
                                  setState(() => _error = e.toString());
                                }
                              },
                        child: Text(appState.isBusy
                            ? 'Updating...'
                            : 'Update Password'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool enabled = true,
    bool obscureText = false,
  }) {
    return SizedBox(
      width: 360,
      child: TextField(
        controller: controller,
        enabled: enabled,
        obscureText: obscureText,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}
