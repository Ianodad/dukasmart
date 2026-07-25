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
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.storefront, size: 72, color: Colors.white),
            const SizedBox(height: 16),
            const Text(
              'DukaSmart',
              style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Know your stock. Grow your business.',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}
