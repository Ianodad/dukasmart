import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/providers.dart';

/// Splash screen (route `/`, Foundation-owned, never a stub). Shows the
/// logo/name/tagline + loader, waits for the local database to open, then
/// navigates to `/home`.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _openDatabaseThenGoHome();
  }

  Future<void> _openDatabaseThenGoHome() async {
    // Waits for the database to open (and, on first run, finish onCreate
    // seeding) via the core readiness API before we navigate — design F5.
    await ref.read(databaseReadyProvider.future);
    if (!mounted) return;
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    // DESIGN.md "Splash": surfaceDark full-bleed, app name onDark headline,
    // tagline caption, subtle loader — no logo invention, no animation
    // choreography.
    return Scaffold(
      backgroundColor: AppTokens.surfaceDark,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.storefront, size: 56, color: AppTokens.onDark),
            const SizedBox(height: 16),
            Text('DukaSmart', style: AppTextStyles.headline.copyWith(color: AppTokens.onDark)),
            const SizedBox(height: 8),
            Text(
              'Know your stock. Grow your business.',
              style: AppTextStyles.caption.copyWith(color: AppTokens.onDark),
            ),
            const SizedBox(height: 32),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: AppTokens.onDark),
            ),
          ],
        ),
      ),
    );
  }
}
