import 'package:flutter/material.dart';

import '../../core/widgets/empty_state.dart';

/// Sale Success (route `/sell/success/:saleId`). Stub — Track T2 replaces
/// this body (design D6 write rule).
class SaleSuccessScreen extends StatelessWidget {
  const SaleSuccessScreen({super.key, required this.saleId});

  final int saleId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sale Complete')),
      body: const EmptyState(title: 'Sale Success — under construction'),
    );
  }
}
