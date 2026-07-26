import 'package:dukasmart/core/database/database.dart';
import 'package:dukasmart/core/database/enums.dart';
import 'package:dukasmart/core/models/daily_metrics.dart';
import 'package:dukasmart/core/providers.dart';
import 'package:dukasmart/features/expenses/expense_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// A widget-render smoke test for the restyled Expense List. Feeds
/// [dailyMetricsProvider]/[recentExpensesProvider] fixed one-shot
/// [Stream.value] fixtures instead of real Drift `.watch()` queries.
const _fixtureMetrics = DailyMetrics(
  totalSales: 0,
  cashSales: 0,
  mpesaSales: 0,
  expensesTotal: 15000,
  cashExpenses: 15000,
  cogs: 0,
  grossProfit: 0,
  netResult: -15000,
  txCount: 0,
  lowStockCount: 0,
  lowStock: [],
  outOfStock: [],
  missingBuyingPrice: [],
  missingSellingPrice: [],
  bestSeller: null,
);

final _now = DateTime.now();

final _fixtureExpenses = [
  Expense(
    id: 1,
    amount: 5000,
    category: ExpenseCategory.stockPurchase,
    description: 'Restock sugar',
    paymentMethod: PaymentMethod.cash,
    createdAt: _now,
  ),
  Expense(
    id: 2,
    amount: 10000,
    category: ExpenseCategory.rent,
    paymentMethod: PaymentMethod.mpesa,
    createdAt: _now,
  ),
];

void main() {
  testWidgets('renders the hero total, rows with method chips, and the stockPurchase caption', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dailyMetricsProvider.overrideWith((ref) => Stream.value(_fixtureMetrics)),
          recentExpensesProvider.overrideWith((ref) => Stream.value(_fixtureExpenses)),
        ],
        child: const MaterialApp(home: ExpenseListScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text("TODAY'S EXPENSES"), findsOneWidget);
    expect(find.text('Stock purchase'), findsOneWidget);
    expect(find.text('Restock sugar'), findsOneWidget);
    expect(find.text('Till cash-out'), findsOneWidget);
    expect(find.text('Rent'), findsOneWidget);
    expect(find.text('Cash'), findsOneWidget);
    expect(find.text('M-PESA'), findsOneWidget);
  });

  testWidgets('teaches with an EmptyState when there are no expenses', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dailyMetricsProvider.overrideWith((ref) => Stream.value(_fixtureMetrics)),
          recentExpensesProvider.overrideWith((ref) => Stream.value(const [])),
        ],
        child: const MaterialApp(home: ExpenseListScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('No expenses today'), findsOneWidget);
    expect(find.text('Record Expense'), findsWidgets);
  });
}
