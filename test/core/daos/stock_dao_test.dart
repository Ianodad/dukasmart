import 'package:dukasmart/core/database/database.dart';
import 'package:dukasmart/core/database/enums.dart';
import 'package:dukasmart/core/database/errors.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forExecutor(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Future<int> insertProduct({int quantity = 5, int? buyingPrice = 100}) async {
    final now = DateTime.now();
    return db.into(db.products).insert(
          ProductsCompanion.insert(
            name: 'Item',
            buyingPrice: Value(buyingPrice),
            sellingPrice: const Value(200),
            quantity: Value(quantity),
            unit: ProductUnit.piece,
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  group('receiveStock', () {
    test('increments quantity and writes a stockReceived movement', () async {
      final id = await insertProduct(quantity: 5);

      await db.stockDao.receiveStock(productId: id, qty: 10, note: 'restock');

      final product = await (db.select(db.products)..where((t) => t.id.equals(id))).getSingle();
      expect(product.quantity, 15);

      final movements =
          await (db.select(db.stockMovements)..where((t) => t.productId.equals(id))).get();
      expect(movements, hasLength(1));
      expect(movements.single.movementType, MovementType.stockReceived);
      expect(movements.single.quantity, 10);
      expect(movements.single.note, 'restock');
    });

    test('updates buying price when provided', () async {
      final id = await insertProduct(buyingPrice: 100);
      await db.stockDao.receiveStock(productId: id, qty: 5, newBuyingPriceCents: 150);
      final product = await (db.select(db.products)..where((t) => t.id.equals(id))).getSingle();
      expect(product.buyingPrice, 150);
    });

    test('leaves buying price untouched when not provided', () async {
      final id = await insertProduct(buyingPrice: 100);
      await db.stockDao.receiveStock(productId: id, qty: 5);
      final product = await (db.select(db.products)..where((t) => t.id.equals(id))).getSingle();
      expect(product.buyingPrice, 100);
    });

    test('rejects qty <= 0', () async {
      final id = await insertProduct();
      expect(
        () => db.stockDao.receiveStock(productId: id, qty: 0),
        throwsA(isA<DukaError>()),
      );
      expect(
        () => db.stockDao.receiveStock(productId: id, qty: -1),
        throwsA(isA<DukaError>()),
      );
    });
  });
}
