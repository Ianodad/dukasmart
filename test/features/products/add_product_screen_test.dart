import 'package:dukasmart/features/products/add_product_screen.dart';
import 'package:flutter_test/flutter_test.dart';

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
}
