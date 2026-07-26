import 'package:dukasmart/app/theme.dart';
import 'package:dukasmart/core/database/database.dart';
import 'package:dukasmart/core/database/enums.dart';
import 'package:dukasmart/core/models/best_seller.dart';
import 'package:dukasmart/core/models/closed_day_report.dart';
import 'package:dukasmart/core/providers.dart';
import 'package:dukasmart/core/widgets/money_text.dart';
import 'package:dukasmart/features/daily_close/daily_report_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// A widget-render smoke test for the restyled Daily Report ledger. Feeds
/// [closedDayReportProvider] a fixed [ClosedDayReport] fixture instead of
/// a real DB read, so the test only exercises layout.
final _fixedDate = DateTime(2026, 7, 1);

final _fixtureReport = ClosedDayReport(
  close: DailyClose(
    id: 1,
    date: _fixedDate,
    totalSales: 150000,
    cashSales: 100000,
    mpesaSales: 50000,
    expenses: 10000,
    costOfGoods: 40000,
    grossProfit: 110000,
    netResult: 100000,
    expectedCash: 80000,
    actualCash: 20000,
    cashDifference: -60000,
    note: null,
    createdAt: _fixedDate,
  ),
  bestSeller: const BestSeller(productId: 1, name: 'Sugar 1kg', qtySold: 12, revenue: 24000),
  lowStockNow: [
    Product(
      id: 1,
      name: 'Cooking Oil 1L',
      quantity: 2,
      unit: ProductUnit.piece,
      lowStockThreshold: 5,
      createdAt: _fixedDate,
      updatedAt: _fixedDate,
    ),
  ],
);

void main() {
  testWidgets('Daily Report renders the ledger, best seller, and amber low-stock row', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          closedDayReportProvider(_fixedDate).overrideWith((ref) async => _fixtureReport),
        ],
        child: MaterialApp(home: DailyReportScreen(date: _fixedDate)),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Financials'), findsOneWidget);
    expect(find.text('— as at close'), findsOneWidget);
    expect(find.text('— for the day'), findsOneWidget);
    expect(find.text('— current'), findsOneWidget);
    expect(find.text('Sugar 1kg'), findsOneWidget);
    expect(find.text('12 sold'), findsOneWidget);
    expect(find.text('Cooking Oil 1L'), findsOneWidget);

    // The cash shortfall (-60000 cents) renders straight through
    // formatCents (no manual sign handling) as the red pair.
    expect(find.text('KES -600'), findsOneWidget);
    final diffMoneyText = tester.widget<MoneyText>(
      find.ancestor(of: find.text('KES -600'), matching: find.byType(MoneyText)),
    );
    expect(diffMoneyText.style?.color, AppTokens.red);

    // The low-stock row renders as an amber pair (name + quantity).
    final lowStockName = tester.widget<Text>(find.text('Cooking Oil 1L'));
    expect(lowStockName.style?.color, AppTokens.amber);
  });

  testWidgets('a non-negative cash difference renders the emerald pair', (tester) async {
    final okReport = ClosedDayReport(
      close: DailyClose(
        id: 2,
        date: _fixedDate,
        totalSales: 150000,
        cashSales: 100000,
        mpesaSales: 50000,
        expenses: 10000,
        costOfGoods: 40000,
        grossProfit: 110000,
        netResult: 100000,
        expectedCash: 80000,
        actualCash: 80000,
        cashDifference: 0,
        note: null,
        createdAt: _fixedDate,
      ),
      bestSeller: null,
      lowStockNow: const [],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          closedDayReportProvider(_fixedDate).overrideWith((ref) async => okReport),
        ],
        child: MaterialApp(home: DailyReportScreen(date: _fixedDate)),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('No sales recorded.'), findsOneWidget);
    expect(find.text('No low-stock products. Well stocked!'), findsOneWidget);

    expect(find.text('KES 0'), findsOneWidget);
    final diffMoneyText = tester.widget<MoneyText>(
      find.ancestor(of: find.text('KES 0'), matching: find.byType(MoneyText)),
    );
    expect(diffMoneyText.style?.color, AppTokens.emerald);
  });
}
