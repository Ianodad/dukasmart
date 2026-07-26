import 'package:flutter/material.dart';

import '../../core/widgets/empty_state.dart';

/// Add Stock (route `/home/add-stock`). Stub — Track T1 replaces this
/// body (design D6 write rule).
class AddStockScreen extends StatelessWidget {
  const AddStockScreen({super.key, this.productId});

  /// Optional preselected product id, passed via `extra`.
  final int? productId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Stock')),
      body: const EmptyState(title: 'Add Stock — under construction'),
    );
  }
}
