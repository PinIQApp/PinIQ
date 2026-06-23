import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_shell.dart';
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
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= 980;

    return Scaffold(
      body: AppShell(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1120),
            child: isWide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Expanded(child: _RegisterBrandPanel()),
                      const SizedBox(width: AppSpacing.xl),
                      SizedBox(width: 450, child: _RegisterPanel(state: this)),
                    ],
                  )
                : ListView(
                    shrinkWrap: true,
                    children: [
                      const _RegisterMobileHeader(),
                      const SizedBox(height: AppSpacing.md),
                      _RegisterPanel(state: this),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
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
  }

  void _selectRole(String role) {
    setState(() => _role = role);
  }
}

class _RegisterPanel extends StatelessWidget {
  const _RegisterPanel({required this.state});

  final _RegisterScreenState state;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final accent = Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.82)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.24),
            blurRadius: 34,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Image.asset('assets/images/wrestletech_icon.png',
                  width: 42, height: 42),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Create account',
                        style: AppTextStyles.cardTitle.copyWith(fontSize: 22)),
                    Text('Beta workspace access', style: AppTextStyles.caption),
                  ],
                ),
              ),
              _SmallPill(label: 'Secure', color: accent),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          AutofillGroup(
            child: Column(
              children: [
                TextFormField(
                  controller: state._name,
                  decoration: const InputDecoration(labelText: 'Full name'),
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.name],
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: state._email,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: state._phone,
                  decoration:
                      const InputDecoration(labelText: 'Phone (optional)'),
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.telephoneNumber],
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: state._password,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password'),
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.newPassword],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Starting role', style: AppTextStyles.bodyStrong),
          const SizedBox(height: AppSpacing.sm),
          RoleSelectScreen(
            selectedRole: state._role,
            onSelected: state._selectRole,
          ),
          if (state._error != null) ...[
            const SizedBox(height: AppSpacing.md),
            _RegisterError(
                message: state._error!.replaceFirst('Exception: ', '')),
          ],
          const SizedBox(height: AppSpacing.lg),
          ElevatedButton(
            onPressed: appState.isBusy ? null : state._submit,
            child: Text(appState.isBusy ? 'Creating...' : 'Create account'),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: state.widget.onLoginTap,
            child: const Text('Already have an account? Sign in'),
          ),
        ],
      ),
    );
  }
}

class _RegisterBrandPanel extends StatelessWidget {
  const _RegisterBrandPanel();

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      constraints: const BoxConstraints(minHeight: 620),
      padding: const EdgeInsets.all(34),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primary.withValues(alpha: 0.22),
            const Color(0xFF101827),
            AppColors.surfaceElevated.withValues(alpha: 0.96),
          ],
        ),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.70)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset('assets/images/wrestletech_logo.png', height: 52),
          const Spacer(),
          Text(
            'Launch a team workspace that feels ready on day one.',
            style: AppTextStyles.pageTitle.copyWith(fontSize: 40, height: 1.06),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: 540,
            child: Text(
              'Set your role, create your account, then connect a team, roster, and communication flow from one clean entry point.',
              style: AppTextStyles.body.copyWith(fontSize: 17),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          const Row(
            children: [
              Expanded(child: _SetupStep(number: '01', label: 'Account')),
              SizedBox(width: AppSpacing.sm),
              Expanded(child: _SetupStep(number: '02', label: 'Team')),
              SizedBox(width: AppSpacing.sm),
              Expanded(child: _SetupStep(number: '03', label: 'Roster')),
            ],
          ),
        ],
      ),
    );
  }
}

class _RegisterMobileHeader extends StatelessWidget {
  const _RegisterMobileHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: Row(
        children: [
          Image.asset('assets/images/wrestletech_icon.png',
              width: 42, height: 42),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Join Pin IQ',
              style: AppTextStyles.pageTitle.copyWith(fontSize: 28),
            ),
          ),
          const _SmallPill(label: 'Beta', color: AppColors.success),
        ],
      ),
    );
  }
}

class _SetupStep extends StatelessWidget {
  const _SetupStep({required this.number, required this.label});

  final String number;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.bg.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.70)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(number,
              style:
                  AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
          const SizedBox(height: AppSpacing.xs),
          Text(label, style: AppTextStyles.bodyStrong),
        ],
      ),
    );
  }
}

class _SmallPill extends StatelessWidget {
  const _SmallPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Text(label,
          style: AppTextStyles.caption.copyWith(color: AppColors.textPrimary)),
    );
  }
}

class _RegisterError extends StatelessWidget {
  const _RegisterError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.28)),
      ),
      child: Text(
        message,
        style: AppTextStyles.body.copyWith(color: AppColors.danger),
      ),
    );
  }
}
