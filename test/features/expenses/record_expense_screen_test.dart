import 'package:dukasmart/features/expenses/record_expense_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// A widget-render smoke test for the restyled Record Expense form: the
/// category wrap of choice chips and the stockPurchase helper caption
/// (DESIGN.md "Screen notes -> Forms").
void main() {
  testWidgets('selecting the Stock purchase chip reveals the till cash-out helper caption', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: RecordExpenseScreen()),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Category'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'Stock purchase'), findsOneWidget);
    expect(find.textContaining('Cash taken from the till for stock'), findsNothing);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Stock purchase'));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.textContaining('Cash taken from the till for stock'), findsOneWidget);
  });

  testWidgets('submitting with no category/amount surfaces validation errors', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: RecordExpenseScreen()),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Save Expense'));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Select a category'), findsOneWidget);
    expect(find.text('Enter a valid amount greater than zero'), findsOneWidget);
  });
}
