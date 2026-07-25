import 'package:flutter/material.dart';

import '../../core/widgets/empty_state.dart';

/// Record Expense (route `/expenses/add`). Stub — Track T3 replaces this
/// body (design D6 write rule).
class RecordExpenseScreen extends StatelessWidget {
  const RecordExpenseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Record Expense')),
      body: const EmptyState(title: 'Record Expense — under construction'),
    );
  }
}
