import 'package:flutter/material.dart';

import '../../core/widgets/empty_state.dart';

/// Low Stock (route `/home/low-stock`). Stub — Track T1 replaces this
/// body (design D6 write rule).
class LowStockScreen extends StatelessWidget {
  const LowStockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Low Stock')),
      body: const EmptyState(title: 'Low Stock — under construction'),
    );
  }
}
