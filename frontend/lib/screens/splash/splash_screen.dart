import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/user_profile_provider.dart';
import '../../utils/constants.dart';
import '../onboarding/onboarding_screen.dart';
import '../shell/app_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    Timer(const Duration(milliseconds: 1800), _handleNavigation);
  }

  void _handleNavigation() {
    final UserProfileProvider provider = context.read<UserProfileProvider>();
    if (provider.isProfileComplete) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AppShell()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations loc = context.loc;
    return Scaffold(
      backgroundColor: primaryBlue,
      body: SafeArea(
        child: Center(
          child: FadeTransition(
            opacity: _animation,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  height: 110,
                  width: 110,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x331234FF),
                        blurRadius: 24,
                        offset: Offset(0, 12),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.layers_rounded, color: primaryBlue, size: 60),
                ),
                const SizedBox(height: 32),
                Text(
                  loc.translate('appName'),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 12),
                Text(
                  loc.translate('splash_tagline'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: const Color(0xFFEAF2FF),
                        letterSpacing: 0.4,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),
                Text(
                  loc.translate('made_in_india'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFFCADBFF),
                        letterSpacing: 0.6,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 40),
                const CircularProgressIndicator(color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
