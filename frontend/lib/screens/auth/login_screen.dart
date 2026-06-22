import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/branded_header_card.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.onRegisterTap});

  final VoidCallback onRegisterTap;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController(text: 'coach@wrestlingos.com');
  final _password = TextEditingController(text: 'Password123');
  String? _error;

  static const _demoAccounts = [
    _DemoAccount('Coach Demo', 'Coach', 'coach@wrestlingos.com', 'Password123'),
    _DemoAccount(
        'Athlete Demo', 'Athlete', 'athlete@wrestlingos.com', 'Password123'),
    _DemoAccount(
        'Parent Demo', 'Parent', 'parent@wrestlingos.com', 'Password123'),
    _DemoAccount('Assistant Demo', 'Assistant', 'assistant@wrestlingos.com',
        'Password123'),
  ];

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final accent = Theme.of(context).colorScheme.primary;
    final width = MediaQuery.of(context).size.width;
    final cardWidth = width >= 1100 ? 460.0 : 540.0;
    return Scaffold(
      body: AppShell(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: cardWidth),
            child: ListView(
              shrinkWrap: true,
              children: [
                const BrandedHeaderCard(
                  eyebrow: 'Team Operations',
                  title: 'Sign into Pin IQ',
                  subtitle:
                      'Review coach, athlete, and parent experiences from one shared, school-ready platform.',
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
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: 30,
                        offset: const Offset(0, 16),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Access your program',
                                    style: AppTextStyles.cardTitle
                                        .copyWith(fontSize: 24)),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  'Use a seeded demo account to explore coaching, athlete, parent, and assistant workflows.',
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
                              color: accent.withValues(alpha: 0.12),
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.chipRadius),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Text(
                              '4 roles ready',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xs,
                        children: const [
                          _AuthTag(label: 'Coach'),
                          _AuthTag(label: 'Athlete'),
                          _AuthTag(label: 'Parent'),
                          _AuthTag(label: 'Assistant'),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          hintText: 'coach@wrestlingos.com',
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: _password,
                        obscureText: true,
                        autofillHints: const [AutofillHints.password],
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          hintText: 'Enter your password',
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: AppColors.danger.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color:
                                    AppColors.danger.withValues(alpha: 0.28)),
                          ),
                          child: Text(
                            _error!.replaceFirst('Exception: ', ''),
                            style: AppTextStyles.body
                                .copyWith(color: AppColors.danger),
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.lg),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed:
                              appState.isBusy ? null : _loginWithCurrentFields,
                          child: Text(
                              appState.isBusy ? 'Signing in...' : 'Sign in'),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.xs,
                        children: [
                          TextButton(
                            onPressed: widget.onRegisterTap,
                            child: const Text('Create an account'),
                          ),
                          TextButton(
                            onPressed: appState.isBusy
                                ? null
                                : () => _loginWithDemo(_demoAccounts.first),
                            child: const Text('Sign in as coach demo'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Text('Quick demo access', style: AppTextStyles.cardTitle),
                    const Spacer(),
                    Text(
                      '4 roles',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                GridView.count(
                  crossAxisCount: width >= 720 ? 2 : 1,
                  crossAxisSpacing: AppSpacing.md,
                  mainAxisSpacing: AppSpacing.md,
                  childAspectRatio: width >= 720 ? 1.12 : 2.05,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: _demoAccounts
                      .map(
                        (account) => InkWell(
                          borderRadius: BorderRadius.circular(24),
                          onTap: appState.isBusy
                              ? null
                              : () => _loginWithDemo(account),
                          child: Ink(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  accent.withValues(alpha: 0.18),
                                  AppColors.surfaceElevated
                                      .withValues(alpha: 0.98),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: AppColors.border),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.12),
                                  blurRadius: 18,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.sm,
                                    vertical: AppSpacing.xxs,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface
                                        .withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(
                                        AppSpacing.chipRadius),
                                  ),
                                  child: Text(
                                    account.role,
                                    style: AppTextStyles.caption
                                        .copyWith(color: AppColors.textPrimary),
                                  ),
                                ),
                                const Spacer(),
                                Text(account.label,
                                    style: AppTextStyles.bodyStrong),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  account.email,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.body
                                      .copyWith(color: AppColors.textSecondary),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  'Tap to sign in',
                                  style: AppTextStyles.caption
                                      .copyWith(color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _loginWithCurrentFields() async {
    try {
      setState(() => _error = null);
      await context.read<AppState>().login(_email.text.trim(), _password.text);
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  Future<void> _loginWithDemo(_DemoAccount account) async {
    _email.text = account.email;
    _password.text = account.password;
    await _loginWithCurrentFields();
  }
}

class _DemoAccount {
  const _DemoAccount(this.label, this.role, this.email, this.password);

  final String label;
  final String role;
  final String email;
  final String password;
}

class _AuthTag extends StatelessWidget {
  const _AuthTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
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
