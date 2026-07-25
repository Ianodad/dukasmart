import 'package:drift/drift.dart';

import '../database.dart';
import '../enums.dart';
import '../errors.dart';
import '../tables.dart';

part 'stock_dao.g.dart';

/// Frozen atomic surface (design D3/D9).
@DriftAccessor(tables: [Products, StockMovements])
class StockDao extends DatabaseAccessor<AppDatabase> with _$StockDaoMixin {
  StockDao(super.db);

  /// Increases [productId]'s stock by [qty] (must be > 0), optionally
  /// updates its buying price, and inserts a `stockReceived` movement.
  /// Single Drift transaction (design D3).
  ///
  /// If [tillCashOutCents] is provided (Amendment A1), it must be > 0 and
  /// an `ExpenseCategory.stockPurchase` cash expense for that amount is
  /// recorded atomically in the same transaction — it reduces expected
  /// cash only, never `expensesTotal`/`netResult` (cost reaches profit via
  /// COGS at sale time).
  Future<void> receiveStock({
    required int productId,
    required int qty,
    int? newBuyingPriceCents,
    String? note,
    int? tillCashOutCents,
  }) {
    if (qty <= 0) {
      throw DukaError.invalidQuantity('Quantity received must be greater than zero.');
    }
    if (tillCashOutCents != null && tillCashOutCents <= 0) {
      throw DukaError.invalidAmount('Amount paid from till must be greater than zero.');
    }
    return transaction(() async {
      final product = await (select(products)..where((t) => t.id.equals(productId)))
          .getSingleOrNull();
      if (product == null) {
        throw DukaError.notFound('Product not found.');
      }

      final companion = ProductsCompanion(
        quantity: Value(product.quantity + qty),
        updatedAt: Value(DateTime.now()),
        buyingPrice: newBuyingPriceCents != null
            ? Value(newBuyingPriceCents)
            : const Value.absent(),
      );
      await (update(products)..where((t) => t.id.equals(productId))).write(companion);

      await into(stockMovements).insert(
        StockMovementsCompanion.insert(
          productId: productId,
          movementType: MovementType.stockReceived,
          quantity: qty,
          note: Value(note),
          createdAt: DateTime.now(),
        ),
      );

      if (tillCashOutCents != null) {
        await attachedDatabase.expensesDao.recordExpense(
          amountCents: tillCashOutCents,
          category: ExpenseCategory.stockPurchase,
          description: 'Stock: ${product.name} ×$qty',
          method: PaymentMethod.cash,
          selectedDate: DateTime.now(),
        );
      }
    });
  }
}
