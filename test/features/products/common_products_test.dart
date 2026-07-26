import 'package:dukasmart/features/products/common_products.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('commonProducts catalog', () {
    test('has exactly 15 entries', () {
      expect(commonProducts.length, 15);
    });

    test('every entry has a positive buying price in cents', () {
      for (final item in commonProducts) {
        expect(
          item.buyingPriceCents,
          greaterThan(0),
          reason: '${item.name} buying price must be > 0 cents',
        );
      }
    });

    test('every entry has a positive selling price in cents', () {
      for (final item in commonProducts) {
        expect(
          item.sellingPriceCents,
          greaterThan(0),
          reason: '${item.name} selling price must be > 0 cents',
        );
      }
    });

    test('selling price is >= buying price for every entry', () {
      for (final item in commonProducts) {
        expect(
          item.sellingPriceCents,
          greaterThanOrEqualTo(item.buyingPriceCents),
          reason: '${item.name} sell must be >= buy',
        );
      }
    });

    test('every entry has a positive low-stock threshold', () {
      for (final item in commonProducts) {
        expect(
          item.threshold,
          greaterThan(0),
          reason: '${item.name} threshold must be > 0',
        );
      }
    });

    test('all names are unique', () {
      final names = commonProducts.map((e) => e.name).toSet();
      expect(names.length, commonProducts.length);
    });

    test('all names are non-empty', () {
      for (final item in commonProducts) {
        expect(item.name.trim(), isNotEmpty);
      }
    });
  });
}
