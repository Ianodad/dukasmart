import 'package:flutter/material.dart';

import '../../core/widgets/empty_state.dart';

/// Home Dashboard (route `/home`). Stub — Track T3 replaces this body
/// (design D6 write rule).
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: const EmptyState(title: 'Home Dashboard — under construction'),
    );
  }
}
