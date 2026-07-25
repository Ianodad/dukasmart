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
}
