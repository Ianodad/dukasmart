import 'package:dukasmart/core/ai/ai_providers.dart';
import 'package:dukasmart/core/database/database.dart';
import 'package:dukasmart/core/models/daily_metrics.dart';
import 'package:dukasmart/core/providers.dart';
import 'package:dukasmart/features/dashboard/dashboard_screen.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// A widget-render smoke test for the dashboard showpiece. Feeds
/// [dailyMetricsProvider] a fixed one-shot [Stream.value] fixture instead
/// of a real Drift `.watch()` query, so the test only exercises layout —
/// it never touches Drift's stream-query lifecycle (whose async teardown
/// timing is orthogonal to this screen's presentation code).
const _fixtureMetrics = DailyMetrics(
  totalSales: 543200,
  cashSales: 320000,
  mpesaSales: 223200,
  expensesTotal: 15000,
  cashExpenses: 15000,
  cogs: 200000,
  grossProfit: 343200,
  netResult: 328200,
  txCount: 12,
  lowStockCount: 0,
  lowStock: [],
  outOfStock: [],
  missingBuyingPrice: [],
  missingSellingPrice: [],
  bestSeller: null,
);

void main() {
  testWidgets('renders the hero total, dot-chips, and quick actions without overflow', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [dailyMetricsProvider.overrideWith((ref) => Stream.value(_fixtureMetrics))],
        child: const MaterialApp(home: DashboardScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text("TODAY'S SALES"), findsOneWidget);
    expect(find.text('Cash'), findsOneWidget);
    expect(find.text('M-PESA'), findsOneWidget);
    expect(find.text('New Sale'), findsOneWidget);
    expect(find.text('Add Product'), findsOneWidget);
    expect(find.text('Add Stock'), findsOneWidget);
    expect(find.text('Record Expense'), findsOneWidget);
    expect(find.text('Close Day'), findsOneWidget);
    expect(find.text('Daily Report'), findsOneWidget);
    expect(find.text('All good!'), findsOneWidget);
  });

  testWidgets('Daily Report quick action shows "No closed day yet" when nothing has been closed', (tester) async {
    final db = AppDatabase.forExecutor(NativeDatabase.memory());
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dailyMetricsProvider.overrideWith((ref) => Stream.value(_fixtureMetrics)),
          dailyCloseDaoProvider.overrideWithValue(db.dailyCloseDao),
        ],
        child: const MaterialApp(home: DashboardScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();

    // The quick-actions grid sits below the fold on the default test
    // viewport — scroll it into view before tapping.
    await tester.ensureVisible(find.text('Daily Report'));
    await tester.pump();

    await tester.tap(find.text('Daily Report'));
    await tester.pump();
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('No closed day yet'), findsOneWidget);
  });

  testWidgets('ask bar is hidden when AI is not configured', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dailyMetricsProvider.overrideWith((ref) => Stream.value(_fixtureMetrics)),
          // A10.1: explicit override for the negative case too — never rely
          // on the test environment merely lacking --dart-define.
          aiAvailableProvider.overrideWithValue(false),
        ],
        child: const MaterialApp(home: DashboardScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();

    // No --dart-define in tests -> AiConfig.isConfigured is false.
    expect(find.text('Ask about your duka…'), findsNothing);
  });

  testWidgets('ask bar renders when AI is configured', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dailyMetricsProvider.overrideWith((ref) => Stream.value(_fixtureMetrics)),
          aiAvailableProvider.overrideWithValue(true),
        ],
        child: const MaterialApp(home: DashboardScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Ask about your duka…'), findsOneWidget);
  });
}
