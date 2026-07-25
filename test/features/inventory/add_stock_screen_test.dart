import 'package:dukasmart/features/inventory/add_stock_screen.dart';
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
}
