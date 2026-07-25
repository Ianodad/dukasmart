import 'package:dukasmart/core/database/database.dart';
import 'package:dukasmart/core/database/enums.dart';
import 'package:dukasmart/core/database/errors.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

ProductsCompanion _product({
  String name = 'Test Product',
  String? barcode,
  int? buyingPrice,
  int? sellingPrice,
  ProductUnit unit = ProductUnit.piece,
  int lowStockThreshold = 5,
}) {
  final now = DateTime.now();
  return ProductsCompanion.insert(
    name: name,
    barcode: Value(barcode),
    buyingPrice: Value(buyingPrice),
    sellingPrice: Value(sellingPrice),
    unit: unit,
    lowStockThreshold: Value(lowStockThreshold),
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forExecutor(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('createProduct', () {
    test('inserts product and an openingStock movement when qty > 0', () async {
      final id = await db.productsDao.createProduct(
        _product(name: 'Rice 2kg'),
        openingQty: 10,
      );

      final product = await (db.select(db.products)..where((t) => t.id.equals(id))).getSingle();
      expect(product.name, 'Rice 2kg');
      expect(product.quantity, 10, reason: 'opening qty must be reflected on the product row');

      final movements =
          await (db.select(db.stockMovements)..where((t) => t.productId.equals(id))).get();
      expect(movements, hasLength(1));
      expect(movements.single.movementType, MovementType.openingStock);
      expect(movements.single.quantity, 10);
      expect(movements.single.productId, id);
    });

    test('does not write a movement when openingQty is 0', () async {
      final id = await db.productsDao.createProduct(_product(name: 'Rice 2kg'), openingQty: 0);
      final movements =
          await (db.select(db.stockMovements)..where((t) => t.productId.equals(id))).get();
      expect(movements, isEmpty);
    });

    test('rejects duplicate non-empty barcode', () async {
      final before = await db.select(db.products).get();

      await db.productsDao.createProduct(
        _product(name: 'First', barcode: '12345'),
        openingQty: 0,
      );

      expect(
        () => db.productsDao.createProduct(
          _product(name: 'Second', barcode: '12345'),
          openingQty: 0,
        ),
        throwsA(isA<DukaError>()),
      );

      final products = await db.select(db.products).get();
      expect(products.length, before.length + 1, reason: 'only the first insert should persist');
    });

    test('allows multiple products with empty/null barcode', () async {
      final before = await db.select(db.products).get();
      await db.productsDao.createProduct(_product(name: 'A'), openingQty: 0);
      await db.productsDao.createProduct(_product(name: 'B'), openingQty: 0);
      final products = await db.select(db.products).get();
      expect(products.length, before.length + 2);
    });

    test('rejects an empty or whitespace-only name and persists nothing', () async {
      final beforeProducts = await db.select(db.products).get();
      final beforeMovements = await db.select(db.stockMovements).get();

      expect(
        () => db.productsDao.createProduct(_product(name: ''), openingQty: 0),
        throwsA(isA<DukaError>()),
      );
      expect(
        () => db.productsDao.createProduct(_product(name: '   '), openingQty: 0),
        throwsA(isA<DukaError>()),
      );

      final products = await db.select(db.products).get();
      final movements = await db.select(db.stockMovements).get();
      expect(products.length, beforeProducts.length);
      expect(movements.length, beforeMovements.length);
    });

    test('rejects a negative buying price and persists nothing', () async {
      final beforeProducts = await db.select(db.products).get();
      final beforeMovements = await db.select(db.stockMovements).get();

      expect(
        () => db.productsDao.createProduct(
          _product(name: 'Bad Price', buyingPrice: -1),
          openingQty: 0,
        ),
        throwsA(isA<DukaError>()),
      );

      final products = await db.select(db.products).get();
      final movements = await db.select(db.stockMovements).get();
      expect(products.length, beforeProducts.length);
      expect(movements.length, beforeMovements.length);
    });

    test('rejects a negative selling price and persists nothing', () async {
      final beforeProducts = await db.select(db.products).get();
      final beforeMovements = await db.select(db.stockMovements).get();

      expect(
        () => db.productsDao.createProduct(
          _product(name: 'Bad Price', sellingPrice: -1),
          openingQty: 0,
        ),
        throwsA(isA<DukaError>()),
      );

      final products = await db.select(db.products).get();
      final movements = await db.select(db.stockMovements).get();
      expect(products.length, beforeProducts.length);
      expect(movements.length, beforeMovements.length);
    });

    test('allows a null buying/selling price (only negatives are rejected)', () async {
      final id = await db.productsDao.createProduct(
        _product(name: 'No Price'),
        openingQty: 0,
      );
      final product = await (db.select(db.products)..where((t) => t.id.equals(id))).getSingle();
      expect(product.buyingPrice, isNull);
      expect(product.sellingPrice, isNull);
    });

    test('rejects a negative openingQty and persists nothing', () async {
      final beforeProducts = await db.select(db.products).get();
      final beforeMovements = await db.select(db.stockMovements).get();

      expect(
        () => db.productsDao.createProduct(_product(name: 'Bad Qty'), openingQty: -1),
        throwsA(isA<DukaError>()),
      );

      final products = await db.select(db.products).get();
      final movements = await db.select(db.stockMovements).get();
      expect(products.length, beforeProducts.length);
      expect(movements.length, beforeMovements.length);
    });

    test('rejects a negative lowStockThreshold and persists nothing', () async {
      final beforeProducts = await db.select(db.products).get();
      final beforeMovements = await db.select(db.stockMovements).get();

      expect(
        () => db.productsDao.createProduct(
          _product(name: 'Bad Threshold', lowStockThreshold: -1),
          openingQty: 0,
        ),
        throwsA(isA<DukaError>()),
      );

      final products = await db.select(db.products).get();
      final movements = await db.select(db.stockMovements).get();
      expect(products.length, beforeProducts.length);
      expect(movements.length, beforeMovements.length);
    });
  });

  group('updateProduct', () {
    test('never writes the quantity column', () async {
      final id = await db.productsDao.createProduct(
        _product(name: 'Original', sellingPrice: 1000),
        openingQty: 20,
      );

      final before = await (db.select(db.products)..where((t) => t.id.equals(id))).getSingle();
      expect(before.quantity, 20);

      final mutated = before.copyWith(
        name: 'Renamed',
        sellingPrice: const Value(1500),
        quantity: 999, // attacker/UI-supplied value — must be ignored
      );
      await db.productsDao.updateProduct(mutated);

      final after = await (db.select(db.products)..where((t) => t.id.equals(id))).getSingle();
      expect(after.name, 'Renamed');
      expect(after.sellingPrice, 1500);
      expect(after.quantity, 20, reason: 'quantity must never be touched by updateProduct');
    });
  });

  group('getByBarcode', () {
    test('finds a product by exact barcode', () async {
      await db.productsDao.createProduct(_product(name: 'Match', barcode: 'AB123'), openingQty: 0);
      final found = await db.productsDao.getByBarcode('AB123');
      expect(found, isNotNull);
      expect(found!.name, 'Match');
    });

    test('returns null when no product matches', () async {
      final found = await db.productsDao.getByBarcode('nope');
      expect(found, isNull);
    });
  });
}
