import 'package:flutter/material.dart';

import '../../core/widgets/empty_state.dart';

/// Close Day (route `/home/close-day`). Stub — Track T4 replaces this
/// body (design D6 write rule).
class CloseDayScreen extends StatelessWidget {
  const CloseDayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Close Day')),
      body: const EmptyState(title: 'Close Day — under construction'),
    );
  }
}
