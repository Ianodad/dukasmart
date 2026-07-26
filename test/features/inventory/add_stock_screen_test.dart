import 'package:dukasmart/core/database/database.dart';
import 'package:dukasmart/core/database/enums.dart';
import 'package:dukasmart/core/providers.dart';
import 'package:dukasmart/features/inventory/add_stock_screen.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('centsToInputString', () {
    test('whole shillings have no decimal part', () {
      expect(centsToInputString(5500), '55');
    });

    test('fractional cents are shown with two decimal digits', () {
      expect(centsToInputString(5550), '55.50');
    });

    test('zero renders as "0"', () {
      expect(centsToInputString(0), '0');
    });

    test('single-digit cents are zero-padded', () {
      expect(centsToInputString(5505), '55.05');
    });
  });

  group('computeTillPrefillCents', () {
    test('entered price wins over product price', () {
      expect(computeTillPrefillCents(3, 200, 100), 600);
    });

    test('falls back to product price when none entered', () {
      expect(computeTillPrefillCents(3, null, 100), 300);
    });

    test('null when no price is known', () {
      expect(computeTillPrefillCents(3, null, null), isNull);
    });

    test('null when qty <= 0', () {
      expect(computeTillPrefillCents(0, 200, 100), isNull);
      expect(computeTillPrefillCents(-1, 200, 100), isNull);
    });
  });

  group('Confirm Stock Receipt dialog', () {
    testWidgets(
      'renders money via the frozen formatCents ("KES 55.50"), never the raw '
      'centsToInputString ("55.50 KES") — Codex finding',
      (tester) async {
        final db = AppDatabase.forExecutor(NativeDatabase.memory());
        addTearDown(db.close);
        final now = DateTime(2026, 1, 1);
        final productId = await db.into(db.products).insert(
              ProductsCompanion.insert(
                name: 'Rice 2kg',
                unit: ProductUnit.piece,
                quantity: const Value(10),
                buyingPrice: const Value(5000),
                createdAt: now,
                updatedAt: now,
              ),
            );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [databaseProvider.overrideWithValue(db)],
            child: MaterialApp(home: AddStockScreen(productId: productId)),
          ),
        );
        await tester.pump();
        await tester.pump();

        await tester.enterText(find.widgetWithText(TextField, 'Quantity received'), '3');
        await tester.enterText(
          find.widgetWithText(TextField, 'Latest buying price (optional)'),
          '55.50',
        );
        await tester.pump();

        // Also exercises the "Paid from till" line (the second Codex-flagged
        // display usage).
        await tester.tap(find.text('Paid from till (cash)'));
        await tester.pump();

        // `pumpAndSettle` never returns while an indeterminate spinner is in
        // the tree elsewhere in this app, so this test — like the rest of
        // the suite — settles the dialog's route transition with explicit
        // finite pumps instead.
        await tester.tap(find.text('Receive Stock'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.textContaining('New buying price: KES 55.50'), findsOneWidget);
        expect(find.textContaining('Paid from till: KES'), findsOneWidget);
        expect(find.textContaining('55.50 KES'), findsNothing);

        // Close the dialog cleanly.
        await tester.tap(find.text('Cancel'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Dispose the widget tree (and with it, the live Drift `.watch()`
        // subscription behind `productsProvider`) while the test is still
        // active, then pump with an explicit (even zero) Duration so
        // `AutomatedTestWidgetsFlutterBinding.pump` actually calls
        // `FakeAsync.elapse` — a bare `tester.pump()` only flushes
        // microtasks, it never elapses fake time, so Drift's async
        // stream-cancellation cleanup (a zero-duration Timer) would
        // otherwise still be pending when the test framework's own
        // end-of-test "no pending timers" check runs.
        await tester.pumpWidget(const SizedBox());
        await tester.pump(Duration.zero);
      },
    );
  });
}
