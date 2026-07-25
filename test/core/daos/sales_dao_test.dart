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

  Future<int> insertProduct({
    String name = 'Item',
    int quantity = 10,
    int? buyingPrice = 100,
    int? sellingPrice = 200,
  }) async {
    final now = DateTime.now();
    return db.into(db.products).insert(
          ProductsCompanion.insert(
            name: name,
            buyingPrice: Value(buyingPrice),
            sellingPrice: Value(sellingPrice),
            quantity: Value(quantity),
            unit: ProductUnit.piece,
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  group('completeSale', () {
    test('reduces stock and writes sale movements with referenceId = saleId', () async {
      final id = await insertProduct(quantity: 10, sellingPrice: 200);

      final saleId = await db.salesDao.completeSale(
        lines: [(productId: id, quantity: 3)],
        method: PaymentMethod.cash,
        amountReceivedCents: 600,
      );

      final product = await (db.select(db.products)..where((t) => t.id.equals(id))).getSingle();
      expect(product.quantity, 7);

      final movements =
          await (db.select(db.stockMovements)..where((t) => t.productId.equals(id))).get();
      expect(movements, hasLength(1));
      expect(movements.single.movementType, MovementType.sale);
      expect(movements.single.quantity, -3);
      expect(movements.single.referenceId, saleId);
    });

    test('aborts entirely (no partial writes) when one line exceeds stock', () async {
      final okProduct = await insertProduct(name: 'Ok', quantity: 10, sellingPrice: 200);
      final shortProduct = await insertProduct(name: 'Short', quantity: 1, sellingPrice: 200);

      await expectLater(
        db.salesDao.completeSale(
          lines: [
            (productId: okProduct, quantity: 2),
            (productId: shortProduct, quantity: 5),
          ],
          method: PaymentMethod.cash,
          amountReceivedCents: 10000,
        ),
        throwsA(isA<DukaError>()),
      );

      // Neither product's stock changed, no sale/items/movements were written.
      final okAfter = await (db.select(db.products)..where((t) => t.id.equals(okProduct))).getSingle();
      final shortAfter =
          await (db.select(db.products)..where((t) => t.id.equals(shortProduct))).getSingle();
      expect(okAfter.quantity, 10);
      expect(shortAfter.quantity, 1);

      expect(await db.select(db.sales).get(), isEmpty);
      expect(await db.select(db.saleItems).get(), isEmpty);
      final movementsForThisTest = await (db.select(db.stockMovements)
            ..where((t) => t.productId.isIn([okProduct, shortProduct])))
          .get();
      expect(movementsForThisTest, isEmpty);
    });

    test('rejects an empty cart', () async {
      expect(
        () => db.salesDao.completeSale(
          lines: const [],
          method: PaymentMethod.cash,
          amountReceivedCents: 0,
        ),
        throwsA(isA<DukaError>()),
      );
    });

    test('rejects a product with a null selling price', () async {
      final id = await insertProduct(sellingPrice: null);
      expect(
        () => db.salesDao.completeSale(
          lines: [(productId: id, quantity: 1)],
          method: PaymentMethod.cash,
          amountReceivedCents: 100,
        ),
        throwsA(isA<DukaError>()),
      );
    });

    test('cash: rejects amountReceived < total', () async {
      final id = await insertProduct(sellingPrice: 200);
      expect(
        () => db.salesDao.completeSale(
          lines: [(productId: id, quantity: 2)],
          method: PaymentMethod.cash,
          amountReceivedCents: 399,
        ),
        throwsA(isA<DukaError>()),
      );
    });

    test('mpesa: rejects amountReceived != total', () async {
      final id = await insertProduct(sellingPrice: 200);
      expect(
        () => db.salesDao.completeSale(
          lines: [(productId: id, quantity: 2)],
          method: PaymentMethod.mpesa,
          amountReceivedCents: 399,
        ),
        throwsA(isA<DukaError>()),
      );
      expect(
        () => db.salesDao.completeSale(
          lines: [(productId: id, quantity: 2)],
          method: PaymentMethod.mpesa,
          amountReceivedCents: 401,
        ),
        throwsA(isA<DukaError>()),
      );
    });

    test('recomputes totals from DB prices, ignoring any caller-side total', () async {
      final id = await insertProduct(sellingPrice: 200);
      // completeSale has no "total" input at all — the DAO always derives
      // it from stored prices. This test locks that behaviour in via the
      // returned sale record.
      final saleId = await db.salesDao.completeSale(
        lines: [(productId: id, quantity: 3)],
        method: PaymentMethod.cash,
        amountReceivedCents: 600,
      );
      final sale = await db.salesDao.getSale(saleId);
      expect(sale.sale.subtotal, 600);
      expect(sale.sale.total, 600);
      expect(sale.items.single.sellingPriceSnapshot, 200);
      expect(sale.items.single.total, 600);
    });

    test('snapshots buyingPrice as 0 when product has no buying price', () async {
      final id = await insertProduct(buyingPrice: null, sellingPrice: 200);
      final saleId = await db.salesDao.completeSale(
        lines: [(productId: id, quantity: 1)],
        method: PaymentMethod.cash,
        amountReceivedCents: 200,
      );
      final sale = await db.salesDao.getSale(saleId);
      expect(sale.items.single.buyingPriceSnapshot, 0);
    });
  });
}
