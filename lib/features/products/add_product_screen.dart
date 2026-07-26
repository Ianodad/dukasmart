import 'package:flutter/material.dart';

import '../../core/widgets/empty_state.dart';

/// Add Product (route `/products/add`). Stub — Track T1 replaces this
/// body (design D6 write rule).
class AddProductScreen extends StatelessWidget {
  const AddProductScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Product')),
      body: const EmptyState(title: 'Add Product — under construction'),
    );
  }
}
