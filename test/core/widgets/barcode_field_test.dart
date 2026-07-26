import 'package:dukasmart/core/widgets/barcode_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BarcodeField manual entry', () {
    testWidgets('submitting the keyboard invokes onScanned with the trimmed value', (tester) async {
      final controller = TextEditingController();
      String? scanned;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BarcodeField(controller: controller, onScanned: (value) => scanned = value),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), '  12345  ');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(scanned, '12345');
    });

    testWidgets('the trailing search icon invokes onScanned with the trimmed value', (tester) async {
      final controller = TextEditingController(text: '  99887  ');
      String? scanned;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BarcodeField(controller: controller, onScanned: (value) => scanned = value),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.search));
      await tester.pump();

      expect(scanned, '99887');
    });

    testWidgets('blank input never invokes onScanned', (tester) async {
      final controller = TextEditingController(text: '   ');
      var called = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BarcodeField(controller: controller, onScanned: (_) => called = true),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.search));
      await tester.pump();
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(called, isFalse);
    });
  });
}
