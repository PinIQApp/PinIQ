import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_shell.dart';

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
    _DemoAccount(
        'Coach', 'Program command', 'coach@wrestlingos.com', 'Password123'),
    _DemoAccount(
        'Athlete', 'Training view', 'athlete@wrestlingos.com', 'Password123'),
    _DemoAccount(
        'Parent', 'Family access', 'parent@wrestlingos.com', 'Password123'),
    _DemoAccount('Assistant', 'Staff workflow', 'assistant@wrestlingos.com',
        'Password123'),
  ];

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
                      const Expanded(child: _ProductPanel()),
                      const SizedBox(width: AppSpacing.xl),
                      SizedBox(width: 430, child: _LoginPanel(state: this)),
                    ],
                  )
                : ListView(
                    shrinkWrap: true,
                    children: [
                      const _CompactBrand(),
                      const SizedBox(height: AppSpacing.md),
                      _LoginPanel(state: this),
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

class _LoginPanel extends StatelessWidget {
  const _LoginPanel({required this.state});

  final _LoginScreenState state;

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
                    Text('Pin IQ',
                        style: AppTextStyles.cardTitle.copyWith(fontSize: 22)),
                    Text('Program OS', style: AppTextStyles.caption),
                  ],
                ),
              ),
              _StatusPill(label: 'Beta live', color: accent),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Access your program', style: AppTextStyles.sectionTitle),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Sign in with a seeded role or create your own beta account.',
            style: AppTextStyles.body,
          ),
          const SizedBox(height: AppSpacing.lg),
          TextFormField(
            controller: state._email,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            decoration: const InputDecoration(
              labelText: 'Email',
              hintText: 'coach@wrestlingos.com',
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: state._password,
            obscureText: true,
            autofillHints: const [AutofillHints.password],
            decoration: const InputDecoration(
              labelText: 'Password',
              hintText: 'Enter your password',
            ),
          ),
          if (state._error != null) ...[
            const SizedBox(height: AppSpacing.md),
            _ErrorCallout(
                message: state._error!.replaceFirst('Exception: ', '')),
          ],
          const SizedBox(height: AppSpacing.lg),
          ElevatedButton(
            onPressed: appState.isBusy ? null : state._loginWithCurrentFields,
            child: Text(appState.isBusy ? 'Signing in...' : 'Sign in'),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: appState.isBusy
                      ? null
                      : () => state._loginWithDemo(
                          _LoginScreenState._demoAccounts.first),
                  child: const Text('Coach demo'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: TextButton(
                  onPressed: state.widget.onRegisterTap,
                  child: const Text('Create account'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: _LoginScreenState._demoAccounts
                .map(
                  (account) => _DemoRoleButton(
                    account: account,
                    disabled: appState.isBusy,
                    onTap: () => state._loginWithDemo(account),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _ProductPanel extends StatelessWidget {
  const _ProductPanel();

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
            AppColors.surfaceElevated.withValues(alpha: 0.96),
            const Color(0xFF101827),
            primary.withValues(alpha: 0.20),
          ],
        ),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.70)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset('assets/images/wrestletech_logo.png', height: 52),
              const Spacer(),
              const _MetricBadge(value: '4', label: 'roles'),
              const SizedBox(width: AppSpacing.sm),
              const _MetricBadge(value: '1', label: 'team'),
            ],
          ),
          const Spacer(),
          Text(
            'A sharper command center for modern wrestling programs.',
            style: AppTextStyles.pageTitle.copyWith(fontSize: 42, height: 1.05),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: 560,
            child: Text(
              'Pin IQ brings roster, messaging, training, weight, recruiting, and team operations into one branded workspace.',
              style: AppTextStyles.body.copyWith(fontSize: 17),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          const _FeatureRail(),
        ],
      ),
    );
  }
}

class _CompactBrand extends StatelessWidget {
  const _CompactBrand();

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
              'Pin IQ',
              style: AppTextStyles.pageTitle.copyWith(fontSize: 28),
            ),
          ),
          const _StatusPill(label: 'Beta', color: AppColors.success),
        ],
      ),
    );
  }
}

class _FeatureRail extends StatelessWidget {
  const _FeatureRail();

  static const features = [
    ('Roster', 'Eligibility, roles, families'),
    ('Messaging', 'Coach-led communication'),
    ('Performance', 'Training and weight signals'),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: features
          .map(
            (item) => Expanded(
              child: Container(
                margin: const EdgeInsets.only(right: AppSpacing.sm),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.bg.withValues(alpha: 0.28),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                      color: AppColors.border.withValues(alpha: 0.7)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.$1, style: AppTextStyles.bodyStrong),
                    const SizedBox(height: AppSpacing.xs),
                    Text(item.$2, style: AppTextStyles.caption),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _MetricBadge extends StatelessWidget {
  const _MetricBadge({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 82,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.bg.withValues(alpha: 0.30),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.68)),
      ),
      child: Column(
        children: [
          Text(value, style: AppTextStyles.cardTitle),
          Text(label, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

class _DemoRoleButton extends StatelessWidget {
  const _DemoRoleButton({
    required this.account,
    required this.disabled,
    required this.onTap,
  });

  final _DemoAccount account;
  final bool disabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(account.label),
      avatar: const Icon(Icons.arrow_forward_rounded, size: 16),
      onPressed: disabled ? null : onTap,
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

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

class _ErrorCallout extends StatelessWidget {
  const _ErrorCallout({required this.message});

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

class _DemoAccount {
  const _DemoAccount(this.label, this.subtitle, this.email, this.password);

  final String label;
  final String subtitle;
  final String email;
  final String password;
}
