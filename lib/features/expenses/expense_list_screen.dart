import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/theme.dart';
import '../../core/database/day_bounds.dart';
import '../../core/providers.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/money_text.dart';

/// Expense List (route `/expenses`). Track T3 body.
class ExpenseListScreen extends ConsumerWidget {
  const ExpenseListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsAsync = ref.watch(dailyMetricsProvider);
    final recentExpensesAsync = ref.watch(recentExpensesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Expenses')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Today's Expenses"),
                    metricsAsync.when(
                      data: (metrics) =>
                          MoneyText(metrics.expensesTotal, style: AppTextStyles.totalMedium),
                      loading: () => const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      error: (error, stackTrace) => const Text('—'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: recentExpensesAsync.when(
              data: (expenses) {
                if (expenses.isEmpty) {
                  return EmptyState(
                    title: 'No expenses recorded yet.',
                    icon: Icons.receipt_long_outlined,
                    actionLabel: 'Record Expense',
                    onAction: () => context.pushNamed('expense-add'),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: expenses.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final expense = expenses[index];
                    final createdAtLocal =
                        expense.createdAt.isUtc ? expense.createdAt.toLocal() : expense.createdAt;
                    final isToday =
                        localMidnight(createdAtLocal) == localMidnight(DateTime.now());
                    final whenLabel = isToday
                        ? DateFormat.jm().format(createdAtLocal)
                        : DateFormat.yMMMd().format(createdAtLocal);
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(expense.category.label),
                      subtitle: Text('${expense.paymentMethod.label} • $whenLabel'),
                      trailing: MoneyText(expense.amount),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) =>
                  Center(child: Text('Failed to load expenses: $error')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.pushNamed('expense-add'),
        icon: const Icon(Icons.add),
        label: const Text('Record Expense'),
      ),
    );
  }
}
