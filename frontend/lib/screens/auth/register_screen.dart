import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/branded_header_card.dart';
import 'role_select_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, required this.onLoginTap});

  final VoidCallback onLoginTap;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  String _role = 'coach';
  String? _error;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
      body: AppShell(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: width >= 1100 ? 500 : 560),
            child: ListView(
              shrinkWrap: true,
              children: [
                const BrandedHeaderCard(
                  eyebrow: 'Program Setup',
                  title: 'Create your account',
                  subtitle: 'Start with the right role, then connect to your team, roster, and communication tools.',
                ),
                const SizedBox(height: AppSpacing.lg),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  decoration: BoxDecoration(
                    color: AppColors.surface.withValues(alpha: 0.96),
                    borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                    border: Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.16),
                        blurRadius: 28,
                        offset: const Offset(0, 14),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Account details', style: AppTextStyles.cardTitle.copyWith(fontSize: 24)),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  'This account determines the screens and permissions you see first.',
                                  style: AppTextStyles.body,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.xs,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Text(
                              '4 roles ready',
                              style: AppTextStyles.caption.copyWith(color: AppColors.textPrimary),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      const Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xs,
                        children: [
                          _RegisterTag(label: 'Coach'),
                          _RegisterTag(label: 'Athlete'),
                          _RegisterTag(label: 'Parent'),
                          _RegisterTag(label: 'Admin'),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      AutofillGroup(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextFormField(
                              controller: _name,
                              decoration: const InputDecoration(labelText: 'Full name'),
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.name],
                            ),
                            const SizedBox(height: AppSpacing.md),
                            TextFormField(
                              controller: _email,
                              decoration: const InputDecoration(labelText: 'Email'),
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.email],
                            ),
                            const SizedBox(height: AppSpacing.md),
                            TextFormField(
                              controller: _phone,
                              decoration: const InputDecoration(labelText: 'Phone (optional)'),
                              keyboardType: TextInputType.phone,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.telephoneNumber],
                            ),
                            const SizedBox(height: AppSpacing.md),
                            TextFormField(
                              controller: _password,
                              obscureText: true,
                              decoration: const InputDecoration(labelText: 'Password'),
                              textInputAction: TextInputAction.done,
                              autofillHints: const [AutofillHints.password],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text('Choose your role', style: AppTextStyles.bodyStrong),
                      const SizedBox(height: AppSpacing.sm),
                      RoleSelectScreen(
                        selectedRole: _role,
                        onSelected: (role) => setState(() => _role = role),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: AppSpacing.md),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: AppColors.danger.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.danger.withValues(alpha: 0.28)),
                          ),
                          child: Text(
                            _error!.replaceFirst('Exception: ', ''),
                            style: AppTextStyles.body.copyWith(color: AppColors.danger),
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.lg),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: appState.isBusy
                              ? null
                              : () async {
                                  try {
                                    setState(() => _error = null);
                                    await context.read<AppState>().register(
                                          fullName: _name.text.trim(),
                                          email: _email.text.trim(),
                                          password: _password.text,
                                          role: _role,
                                          phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
                                        );
                                  } catch (e) {
                                    setState(() => _error = e.toString());
                                  }
                                },
                          child: Text(appState.isBusy ? 'Creating...' : 'Create account'),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: widget.onLoginTap,
                          child: const Text('Already have an account? Sign in'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RegisterTag extends StatelessWidget {
  const _RegisterTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(color: AppColors.textPrimary),
      ),
    );
  }
}
