import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/theme.dart';
import '../../core/database/database.dart';
import '../../core/database/day_bounds.dart';
import '../../core/database/enums.dart';
import '../../core/providers.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/money_text.dart';

/// Expense List (route `/expenses`). Track T3 body.
///
/// DESIGN.md "Screen notes": today's total lives directly on bg as an
/// overline + moneyMedium hero (not carded); rows show category
/// (bodyStrong) + description (caption), a tiny method chip, and the
/// right-aligned moneySmall amount; stockPurchase rows keep their "till
/// cash-out" helper semantics visible as a caption.
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
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("TODAY'S EXPENSES", style: AppTextStyles.overline),
                const SizedBox(height: 4),
                metricsAsync.when(
                  data: (metrics) =>
                      MoneyText(metrics.expensesTotal, style: AppTextStyles.moneyMedium),
                  loading: () => const SizedBox(
                    height: 28,
                    width: 28,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  error: (error, stackTrace) =>
                      const Text('—', style: AppTextStyles.moneyMedium),
                ),
              ],
            ),
          ),
          Expanded(
            child: recentExpensesAsync.when(
              data: (expenses) {
                if (expenses.isEmpty) {
                  return EmptyState(
                    title: 'No expenses today',
                    message: 'Record cash or M-PESA spending to track it here.',
                    icon: Icons.receipt_long_outlined,
                    actionLabel: 'Record Expense',
                    onAction: () => context.pushNamed('expense-add'),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: expenses.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) => _ExpenseRow(expense: expenses[index]),
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

/// A single expense row: category + description on the left, the tiny
/// method chip + right-aligned amount on the right. stockPurchase rows
/// surface a "Till cash-out" caption — that cash reduces expected cash at
/// close, not profit (design D4 amendment A1).
class _ExpenseRow extends StatelessWidget {
  const _ExpenseRow({required this.expense});

  final Expense expense;

  @override
  Widget build(BuildContext context) {
    final createdAtLocal = expense.createdAt.isUtc ? expense.createdAt.toLocal() : expense.createdAt;
    final isToday = localMidnight(createdAtLocal) == localMidnight(DateTime.now());
    final whenLabel =
        isToday ? DateFormat.jm().format(createdAtLocal) : DateFormat.yMMMd().format(createdAtLocal);
    final description = expense.description?.trim();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(expense.category.label, style: AppTextStyles.bodyStrong),
                if (description != null && description.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(description, style: AppTextStyles.caption),
                ],
                if (expense.category == ExpenseCategory.stockPurchase) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Till cash-out',
                    style: AppTextStyles.caption.copyWith(color: AppTokens.inkMuted),
                  ),
                ],
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _MethodChip(method: expense.paymentMethod),
                    const SizedBox(width: 8),
                    Text(whenLabel, style: AppTextStyles.caption.copyWith(color: AppTokens.inkMuted)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          MoneyText(expense.amount),
        ],
      ),
    );
  }
}

/// Tiny method chip (DESIGN.md color rule: tint container + deep text
/// pair): Cash is the neutral surfaceMuted/inkSecondary tonal pill;
/// M-PESA is the blueContainer/blue info-only pair.
class _MethodChip extends StatelessWidget {
  const _MethodChip({required this.method});

  final PaymentMethod method;

  @override
  Widget build(BuildContext context) {
    final isMpesa = method == PaymentMethod.mpesa;
    final background = isMpesa ? AppTokens.blueContainer : AppTokens.surfaceMuted;
    final foreground = isMpesa ? AppTokens.blue : AppTokens.inkSecondary;

    return DecoratedBox(
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(999)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Text(
          method.label,
          style: AppTextStyles.caption.copyWith(color: foreground, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
