import 'package:flutter/material.dart';

import '../../core/widgets/empty_state.dart';

/// Expense List (route `/expenses`). Stub — Track T3 replaces this body
/// (design D6 write rule).
class ExpenseListScreen extends StatelessWidget {
  const ExpenseListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Expenses')),
      body: const EmptyState(title: 'Expense List — under construction'),
    );
  }
}
