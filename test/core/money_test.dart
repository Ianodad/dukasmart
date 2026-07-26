import 'package:dukasmart/core/formatting/money.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseKesToCents', () {
    test('parses whole shillings', () {
      expect(parseKesToCents('55'), 5500);
    });

    test('parses one decimal digit', () {
      expect(parseKesToCents('55.5'), 5550);
    });

    test('parses two decimal digits', () {
      expect(parseKesToCents('55.50'), 5550);
    });

    test('empty string returns null', () {
      expect(parseKesToCents(''), isNull);
    });

    test('negative number returns null', () {
      expect(parseKesToCents('-5'), isNull);
    });

    test('more than two decimal digits returns null', () {
      expect(parseKesToCents('1.234'), isNull);
    });
  });

  group('formatCents', () {
    test('formats whole shillings without decimals', () {
      expect(formatCents(1245000), 'KES 12,450');
    });

    test('formats cents with two decimal digits', () {
      expect(formatCents(5550), 'KES 55.50');
    });

    test('formats zero', () {
      expect(formatCents(0), 'KES 0');
    });

    test('formats a negative amount with cents, keeping the sign', () {
      expect(formatCents(-125), 'KES -1.25');
    });

    test('formats a negative amount under one shilling, keeping the sign', () {
      expect(formatCents(-50), 'KES -0.50');
    });

    test('formats a negative whole-shilling amount without decimals', () {
      expect(formatCents(-100), 'KES -1');
    });

    test('formats a large negative amount with grouping', () {
      expect(formatCents(-1245000), 'KES -12,450');
    });
  });
}
