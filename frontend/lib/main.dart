import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/app_state.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/onboarding_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/dashboard/home_dashboard_shell.dart';
import 'screens/splash_screen.dart';
import 'screens/team/join_team_screen.dart';
import 'screens/team/pending_approval_screen.dart';
import 'screens/team/team_setup_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const WrestlingOsApp(),
    ),
  );
}

class WrestlingOsApp extends StatefulWidget {
  const WrestlingOsApp({super.key});

  @override
  State<WrestlingOsApp> createState() => _WrestlingOsAppState();
}

class _WrestlingOsAppState extends State<WrestlingOsApp> {
  bool showRegister = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AppState>().bootstrap();
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pin IQ',
      theme: appState.theme,
      builder: (context, child) {
        return Stack(
          children: [
            if (child != null)
              Material(
                type: MaterialType.transparency,
                child: child,
              ),
            if (appState.screenCaptureActive)
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.86),
                    alignment: Alignment.center,
                    child: const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Screen recording detected.\nSensitive wrestling communications are hidden during active capture.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            if (appState.privacyNotice != null && !appState.screenCaptureActive)
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7F1D1D),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.privacy_tip_outlined,
                            color: Colors.white),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            appState.privacyNotice!,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        IconButton(
                          onPressed: () =>
                              context.read<AppState>().dismissPrivacyNotice(),
                          icon: const Icon(Icons.close, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
      home: Builder(
        builder: (context) {
          if (!appState.isReady) return const SplashScreen();
          if (appState.user == null) {
            return showRegister
                ? RegisterScreen(
                    onLoginTap: () => setState(() => showRegister = false))
                : LoginScreen(
                    onRegisterTap: () => setState(() => showRegister = true));
          }
          if (appState.needsTeamSetup) return const TeamSetupScreen();
          if (appState.needsJoinTeam) return const JoinTeamScreen();
          if (appState.needsApproval) return const PendingApprovalScreen();
          if (appState.needsOnboarding) return const OnboardingScreen();
          return const HomeDashboardShell();
        },
      ),
    );
  }
}
