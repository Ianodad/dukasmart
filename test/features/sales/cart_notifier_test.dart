import 'package:dukasmart/core/database/database.dart';
import 'package:dukasmart/core/database/enums.dart';
import 'package:dukasmart/core/providers.dart';
import 'package:dukasmart/features/sales/cart_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Product _product({
  int id = 1,
  String name = 'Item',
  int? sellingPrice = 200,
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

void main() {
  test('add/increment builds cart lines with computed line totals', () async {
    final container = ProviderContainer(
      overrides: [
        productsProvider.overrideWith((ref) => Stream.value([_product(id: 1, sellingPrice: 200)])),
      ],
    );
    addTearDown(container.dispose);

    // Let the overridden products stream emit its first value before
    // reading the derived cart providers.
    await container.read(productsProvider.future);

    final product = _product(id: 1, sellingPrice: 200, quantity: 5);
    container.read(cartProvider.notifier).add(product);
    container.read(cartProvider.notifier).increment(product);

    final lines = container.read(cartLinesProvider);
    expect(lines, hasLength(1));
    expect(lines.single.quantity, 2);
    expect(lines.single.lineTotalCents, 400);
    expect(container.read(cartTotalCentsProvider), 400);
  });

  test('add() is capped at the product stock and reports a no-op', () {
    final container = ProviderContainer(
      overrides: [
        productsProvider.overrideWith((ref) => Stream.value([_product(id: 1, quantity: 2)])),
      ],
    );
    addTearDown(container.dispose);

    final product = _product(id: 1, quantity: 2);
    expect(container.read(cartProvider.notifier).add(product), isTrue);
    expect(container.read(cartProvider.notifier).add(product), isTrue);
    // Cart already at stock limit (2) -> no-op.
    expect(container.read(cartProvider.notifier).add(product), isFalse);
    expect(container.read(cartProvider)[1], 2);
  });

  test('decrement removes the line once quantity reaches zero', () {
    final container = ProviderContainer(
      overrides: [
        productsProvider.overrideWith((ref) => Stream.value([_product(id: 1, quantity: 5)])),
      ],
    );
    addTearDown(container.dispose);

    final product = _product(id: 1, quantity: 5);
    container.read(cartProvider.notifier).add(product);
    container.read(cartProvider.notifier).decrement(product.id);
    expect(container.read(cartProvider), isEmpty);
  });

  test('toLines() converts the cart map to CartLine records', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final product = _product(id: 7, quantity: 5);
    container.read(cartProvider.notifier).add(product, quantity: 3);
    final lines = container.read(cartProvider.notifier).toLines();
    expect(lines, [(productId: 7, quantity: 3)]);
  });
}
