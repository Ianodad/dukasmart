import 'package:flutter/material.dart';

import '../../core/widgets/empty_state.dart';

/// New Sale / POS (route `/sell`). Stub — Track T2 replaces this body
/// (design D6 write rule).
class SellScreen extends StatelessWidget {
  const SellScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sell')),
      body: const EmptyState(title: 'New Sale — under construction'),
    );
  }
}
