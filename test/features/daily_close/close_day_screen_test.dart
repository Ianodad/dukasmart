import 'package:dukasmart/app/theme.dart';
import 'package:dukasmart/core/models/daily_metrics.dart';
import 'package:dukasmart/core/providers.dart';
import 'package:dukasmart/core/widgets/money_text.dart';
import 'package:dukasmart/features/daily_close/close_day_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// A widget-render smoke test for the restyled Close Day ledger. Feeds
/// [dailyMetricsProvider] a fixed one-shot [Stream.value] fixture so the
/// test only exercises layout — never Drift's stream-query lifecycle.
// cashExpenses (200) is intentionally nonzero but not directly rendered
// as its own row — it only shapes `expectedCash` (cashSales - cashExpenses
// = KES 800), keeping every rendered figure distinct so `find.text` below
// can never accidentally match more than one row.
const _fixtureMetrics = DailyMetrics(
  totalSales: 150000,
  cashSales: 100000,
  mpesaSales: 50000,
  expensesTotal: 10000,
  cashExpenses: 20000,
  cogs: 40000,
  grossProfit: 110000,
  netResult: 100000,
  txCount: 3,
  lowStockCount: 0,
  lowStock: [],
  outOfStock: [],
  missingBuyingPrice: [],
  missingSellingPrice: [],
  bestSeller: null,
);

void main() {
  testWidgets('Close Day renders the ledger figures without overflow', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [dailyMetricsProvider.overrideWith((ref) => Stream.value(_fixtureMetrics))],
        child: const MaterialApp(home: CloseDayScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Total sales'), findsOneWidget);
    expect(find.text('Gross profit'), findsOneWidget);
    expect(find.text('Net result'), findsOneWidget);
    expect(find.text('Expected cash'), findsOneWidget);
  });

  testWidgets(
    'a cash shortfall renders a negative KES value via formatCents (no manual sign handling) '
    'in the red pair',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [dailyMetricsProvider.overrideWith((ref) => Stream.value(_fixtureMetrics))],
          child: const MaterialApp(home: CloseDayScreen()),
        ),
      );
      await tester.pump();
      await tester.pump();

      // Expected cash is KES 800 (cashSales 1,000 - cashExpenses 200);
      // enter an actual count of KES 200 -> a KES -600 shortfall.
      await tester.enterText(find.byType(TextField).first, '200');
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('KES -600'), findsOneWidget);

      final moneyText = tester.widget<MoneyText>(
        find.ancestor(of: find.text('KES -600'), matching: find.byType(MoneyText)),
      );
      expect(moneyText.style?.color, AppTokens.red);
    },
  );

  testWidgets('a cash count at/over expected renders the emerald pair', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [dailyMetricsProvider.overrideWith((ref) => Stream.value(_fixtureMetrics))],
        child: const MaterialApp(home: CloseDayScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();

    // Expected cash is KES 800; count exactly that -> zero difference,
    // still treated as the "over/at" emerald case (difference >= 0).
    await tester.enterText(find.byType(TextField).first, '800');
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('KES 0'), findsOneWidget);

    final moneyText = tester.widget<MoneyText>(
      find.ancestor(of: find.text('KES 0'), matching: find.byType(MoneyText)),
    );
    expect(moneyText.style?.color, AppTokens.emerald);
  });
}
