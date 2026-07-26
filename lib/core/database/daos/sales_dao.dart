import 'package:drift/drift.dart';

import '../database.dart';
import '../enums.dart';
import '../errors.dart';
import '../tables.dart';

part 'sales_dao.g.dart';

/// A single POS cart line: a product and how many units of it.
typedef CartLine = ({int productId, int quantity});

/// A completed sale together with its line items (used by the Sale
/// Success "View Sale" bottom sheet, design D5).
class SaleWithItems {
  const SaleWithItems({required this.sale, required this.items});

  final Sale sale;
  final List<SaleItem> items;
}

/// Frozen atomic surface (design D3/D9). [completeSale] enforces every
/// invariant (a)-(f) from design D3 inside a single transaction; any
/// failure aborts the whole sale with no partial writes.
@DriftAccessor(tables: [Products, Sales, SaleItems, StockMovements])
class SalesDao extends DatabaseAccessor<AppDatabase> with _$SalesDaoMixin {
  SalesDao(super.db);

  Future<int> completeSale({
    required List<CartLine> lines,
    required PaymentMethod method,
    required int amountReceivedCents,
    String? mpesaCode,
  }) {
    if (lines.isEmpty) {
      throw DukaError.emptyCart();
    }
    for (final line in lines) {
      if (line.quantity <= 0) {
        throw DukaError.invalidQuantity('Line quantity must be greater than zero.');
      }
    }

    // (c) Aggregate lines by product before re-checking stock.
    final aggregated = <int, int>{};
    for (final line in lines) {
      aggregated[line.productId] = (aggregated[line.productId] ?? 0) + line.quantity;
    }

    return transaction(() async {
      final now = DateTime.now();

      // Pass 1: fetch + validate every product, compute the recomputed
      // (d) subtotal/total from DB prices — never from caller input.
      final resolved = <({int productId, int quantity, Product product, int lineTotal})>[];
      int subtotal = 0;
      for (final entry in aggregated.entries) {
        final productId = entry.key;
        final qty = entry.value;
        final product = await (select(products)..where((t) => t.id.equals(productId)))
            .getSingleOrNull();
        if (product == null) {
          throw DukaError.notFound('Product not found.');
        }
        if (product.sellingPrice == null) {
          throw DukaError.missingSellingPrice(product.name);
        }
        if (product.quantity < qty) {
          throw DukaError.insufficientStock(product.name);
        }
        final lineTotal = product.sellingPrice! * qty;
        subtotal += lineTotal;
        resolved.add((productId: productId, quantity: qty, product: product, lineTotal: lineTotal));
      }

      final total = subtotal;

      // (e) Payment validation.
      final int changeAmount;
      if (method == PaymentMethod.cash) {
        if (amountReceivedCents < total) {
          throw DukaError.invalidPayment('Amount received is less than the total.');
        }
        changeAmount = amountReceivedCents - total;
      } else {
        if (amountReceivedCents != total) {
          throw DukaError.invalidPayment('M-PESA amount must equal the total.');
        }
        changeAmount = 0;
      }

      // (f) Insert sale, then sale_items, decrement stock, insert
      // `sale` movements referencing the sale.
      final saleId = await into(sales).insert(
        SalesCompanion.insert(
          subtotal: subtotal,
          total: total,
          paymentMethod: method,
          amountReceived: amountReceivedCents,
          changeAmount: changeAmount,
          mpesaCode: Value(mpesaCode),
          createdAt: now,
        ),
      );

      for (final r in resolved) {
        await into(saleItems).insert(
          SaleItemsCompanion.insert(
            saleId: saleId,
            productId: r.productId,
            productName: r.product.name,
            quantity: r.quantity,
            buyingPriceSnapshot: r.product.buyingPrice ?? 0,
            sellingPriceSnapshot: r.product.sellingPrice!,
            total: r.lineTotal,
          ),
        );

        await (update(products)..where((t) => t.id.equals(r.productId))).write(
          ProductsCompanion(
            quantity: Value(r.product.quantity - r.quantity),
            updatedAt: Value(now),
          ),
        );

        await into(stockMovements).insert(
          StockMovementsCompanion.insert(
            productId: r.productId,
            movementType: MovementType.sale,
            quantity: -r.quantity,
            referenceId: Value(saleId),
            createdAt: now,
          ),
        );
      }

      return saleId;
    });
  }

  Future<SaleWithItems> getSale(int saleId) async {
    final sale = await (select(sales)..where((t) => t.id.equals(saleId))).getSingle();
    final items = await (select(saleItems)..where((t) => t.saleId.equals(saleId))).get();
    return SaleWithItems(sale: sale, items: items);
  }
}
