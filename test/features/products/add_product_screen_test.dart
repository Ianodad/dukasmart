import 'package:dukasmart/core/database/database.dart';
import 'package:dukasmart/core/database/enums.dart';
import 'package:dukasmart/features/products/add_product_screen.dart';
import 'package:flutter_test/flutter_test.dart';

Product _product({int id = 1, required String name}) {
  final now = DateTime(2026, 1, 1);
  return Product(
    id: id,
    name: name,
    quantity: 0,
    unit: ProductUnit.piece,
    lowStockThreshold: 5,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('computeProfitPerUnitCents', () {
    test('returns null when buying price is unset', () {
      expect(
        computeProfitPerUnitCents(buyingPriceCents: null, sellingPriceCents: 7000),
        isNull,
      );
    });

    test('returns null when selling price is unset', () {
      expect(
        computeProfitPerUnitCents(buyingPriceCents: 5500, sellingPriceCents: null),
        isNull,
      );
    });

    test('returns selling minus buying when both are set', () {
      expect(
        computeProfitPerUnitCents(buyingPriceCents: 5500, sellingPriceCents: 7000),
        1500,
      );
    });

    test('can be negative when selling below buying', () {
      expect(
        computeProfitPerUnitCents(buyingPriceCents: 7000, sellingPriceCents: 5500),
        -1500,
      );
    });
  });

  group('findExactNameMatch', () {
    test('finds a product with the exact same name', () {
      final products = [_product(id: 1, name: 'Rice 2kg'), _product(id: 2, name: 'Sugar 1kg')];
      final match = findExactNameMatch('Rice 2kg', products);
      expect(match?.id, 1);
    });

    test('matches case-insensitively', () {
      final products = [_product(id: 1, name: 'Rice 2kg')];
      final match = findExactNameMatch('rice 2KG', products);
      expect(match?.id, 1);
    });

    test('trims leading/trailing whitespace on both sides before comparing', () {
      final products = [_product(id: 1, name: '  Rice 2kg  ')];
      final match = findExactNameMatch('  rice 2kg', products);
      expect(match?.id, 1);
    });

    test('returns null when no product matches', () {
      final products = [_product(id: 1, name: 'Rice 2kg')];
      expect(findExactNameMatch('Sugar 1kg', products), isNull);
    });

    test('returns null for a blank name', () {
      final products = [_product(id: 1, name: 'Rice 2kg')];
      expect(findExactNameMatch('   ', products), isNull);
    });

    test('returns null for an empty product list', () {
      expect(findExactNameMatch('Rice 2kg', const []), isNull);
    });
  });
}
