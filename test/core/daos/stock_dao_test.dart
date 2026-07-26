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

    test('tillCashOutCents records exactly one stockPurchase cash expense '
        'and still increments stock + writes the movement', () async {
      final id = await insertProduct(quantity: 5);

      await db.stockDao.receiveStock(productId: id, qty: 10, tillCashOutCents: 5000);

      final product = await (db.select(db.products)..where((t) => t.id.equals(id))).getSingle();
      expect(product.quantity, 15);

      final movements =
          await (db.select(db.stockMovements)..where((t) => t.productId.equals(id))).get();
      expect(movements, hasLength(1));
      expect(movements.single.movementType, MovementType.stockReceived);

      final expenses = await db.select(db.expenses).get();
      expect(expenses, hasLength(1));
      expect(expenses.single.amount, 5000);
      expect(expenses.single.category, ExpenseCategory.stockPurchase);
      expect(expenses.single.paymentMethod, PaymentMethod.cash);
    });

    test('without tillCashOutCents -> zero expense rows', () async {
      final id = await insertProduct(quantity: 5);

      await db.stockDao.receiveStock(productId: id, qty: 10);

      final expenses = await db.select(db.expenses).get();
      expect(expenses, isEmpty);
    });

    test('tillCashOutCents <= 0 throws and nothing persists', () async {
      final id = await insertProduct(quantity: 5);

      expect(
        () => db.stockDao.receiveStock(productId: id, qty: 10, tillCashOutCents: 0),
        throwsA(isA<DukaError>()),
      );
      expect(
        () => db.stockDao.receiveStock(productId: id, qty: 10, tillCashOutCents: -100),
        throwsA(isA<DukaError>()),
      );

      final product = await (db.select(db.products)..where((t) => t.id.equals(id))).getSingle();
      expect(product.quantity, 5);
      final movements =
          await (db.select(db.stockMovements)..where((t) => t.productId.equals(id))).get();
      expect(movements, isEmpty);
      final expenses = await db.select(db.expenses).get();
      expect(expenses, isEmpty);
    });

    test('rejects a negative newBuyingPriceCents and rolls back fully', () async {
      final id = await insertProduct(quantity: 5, buyingPrice: 100);

      expect(
        () => db.stockDao.receiveStock(
          productId: id,
          qty: 10,
          newBuyingPriceCents: -1,
          note: 'bad restock',
        ),
        throwsA(isA<DukaError>()),
      );

      final product = await (db.select(db.products)..where((t) => t.id.equals(id))).getSingle();
      expect(product.quantity, 5, reason: 'quantity must not change on rejection');
      expect(product.buyingPrice, 100, reason: 'buying price must not change on rejection');

      final movements =
          await (db.select(db.stockMovements)..where((t) => t.productId.equals(id))).get();
      expect(movements, isEmpty);

      final expenses = await db.select(db.expenses).get();
      expect(expenses, isEmpty);
    });

    test('allows newBuyingPriceCents of exactly zero', () async {
      final id = await insertProduct(quantity: 5, buyingPrice: 100);
      await db.stockDao.receiveStock(productId: id, qty: 5, newBuyingPriceCents: 0);
      final product = await (db.select(db.products)..where((t) => t.id.equals(id))).getSingle();
      expect(product.buyingPrice, 0);
    });

    test('atomicity: a failing call with tillCashOutCents set persists no expense row', () async {
      await expectLater(
        db.stockDao.receiveStock(productId: 9999, qty: 10, tillCashOutCents: 5000),
        throwsA(isA<DukaError>()),
      );

      final expenses = await db.select(db.expenses).get();
      expect(expenses, isEmpty);
    });
  });
}
