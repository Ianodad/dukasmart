import 'dart:async';

import 'package:dukasmart/core/database/database.dart';
import 'package:dukasmart/core/database/enums.dart';
import 'package:dukasmart/core/providers.dart';
import 'package:dukasmart/features/sales/cart_notifier.dart';
import 'package:dukasmart/features/sales/payment_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Product _product({
  int id = 1,
  String name = 'Item',
  int? sellingPrice = 10000,
  int quantity = 5,
}) {
  final now = DateTime(2026, 1, 1);
  return Product(
    id: id,
    name: name,
    sellingPrice: sellingPrice,
    quantity: quantity,
    unit: ProductUnit.piece,
    lowStockThreshold: 5,
    createdAt: now,
    updatedAt: now,
  );
}

const _amountField = Key('payment-amount-field');

// `NumericInputField.money` (the [_amountField]-keyed widget) wraps a plain
// [TextField] without forwarding its key, so reach the actual [TextField]
// through the descendant finder to read its controller text.
String _amountText(WidgetTester tester) => tester
    .widget<TextField>(
      find.descendant(of: find.byKey(_amountField), matching: find.byType(TextField)),
    )
    .controller!
    .text;

void main() {
  testWidgets(
    'M-PESA prefill happens once; a user edit survives a total-change rebuild '
    'and a mismatch surfaces the validation error',
    (tester) async {
      final productsController = StreamController<List<Product>>.broadcast();
      addTearDown(productsController.close);

      final container = ProviderContainer(
        overrides: [
          productsProvider.overrideWith((ref) => productsController.stream),
        ],
      );
      addTearDown(container.dispose);

      final product = _product(id: 1, sellingPrice: 10000, quantity: 5); // KES 100/unit
      container.read(cartProvider.notifier).add(product); // cart total = KES 100

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: PaymentScreen()),
        ),
      );
      // Only now (after the widget tree has built and subscribed to the
      // provider override) does the broadcast stream have a listener —
      // emit the initial product list after that subscription exists.
      productsController.add([product]);
      await tester.pump();
      await tester.pump();

      // Prefill happens once: switching to M-PESA fills the amount with the
      // current total.
      await tester.tap(find.text('M-PESA'));
      await tester.pump();
      expect(_amountText(tester), '100');

      // A user edit sticks: type a different amount than the total.
      await tester.enterText(find.byKey(_amountField), '250');
      await tester.pump();
      expect(_amountText(tester), '250');

      // Trigger a rebuild via a cart-total change (the same trigger the
      // screen's own "keep the M-PESA prefill in sync" comment describes).
      // Before the Codex fix, this rebuild would silently overwrite the
      // user's '250' back to the new total because `_mpesaPrefilled` was
      // never cleared by editing the field.
      productsController.add([_product(id: 1, sellingPrice: 20000, quantity: 5)]); // KES 200/unit
      await tester.pump();
      await tester.pump();

      expect(find.text('KES 200'), findsOneWidget); // total really did change
      expect(_amountText(tester), '250'); // user's edit was NOT clobbered

      // Mismatched amount (250 != 200) surfaces the validation error.
      expect(find.text('M-PESA amount must equal the total.'), findsOneWidget);
    },
  );
}
