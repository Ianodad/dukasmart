import 'package:flutter/material.dart';

import '../../core/widgets/empty_state.dart';

/// Product List (route `/products`). Stub — Track T1 replaces this body
/// (design D6 write rule).
class ProductListScreen extends StatelessWidget {
  const ProductListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Products')),
      body: const EmptyState(title: 'Product List — under construction'),
    );
  }
}
