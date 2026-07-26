import 'package:drift/drift.dart';

import '../database.dart';
import '../enums.dart';
import '../errors.dart';
import '../tables.dart';

part 'products_dao.g.dart';

/// Frozen atomic surface (design D3/D9). Every method here is a single
/// Drift transaction with all validation inside it.
@DriftAccessor(tables: [Products, StockMovements])
class ProductsDao extends DatabaseAccessor<AppDatabase> with _$ProductsDaoMixin {
  ProductsDao(super.db);

  /// Inserts [p] with its starting stock set to [openingQty] (the only
  /// column on [p] the DAO overrides — quantity is always DAO-controlled,
  /// never caller-supplied). If [openingQty] > 0, also inserts an
  /// `openingStock` movement for the new product. Throws
  /// [DukaError.duplicateBarcode] when [p]'s barcode is non-empty and
  /// already used by another product.
  Future<int> createProduct(ProductsCompanion p, {required int openingQty}) {
    return transaction(() async {
      final barcode = p.barcode.present ? p.barcode.value : null;
      if (barcode != null && barcode.isNotEmpty) {
        final existing = await (select(products)
              ..where((t) => t.barcode.equals(barcode)))
            .getSingleOrNull();
        if (existing != null) {
          throw DukaError.duplicateBarcode(barcode);
        }
      }

      final productId = await into(products).insert(p.copyWith(quantity: Value(openingQty)));

      if (openingQty > 0) {
        await into(stockMovements).insert(
          StockMovementsCompanion.insert(
            productId: productId,
            movementType: MovementType.openingStock,
            quantity: openingQty,
            createdAt: DateTime.now(),
          ),
        );
      }

      return productId;
    });
  }

  /// Watches products, optionally filtered by [query] (case-insensitive
  /// name contains) and/or [lowStockOnly] (qty <= threshold).
  Stream<List<Product>> watchProducts({String? query, bool lowStockOnly = false}) {
    final q = select(products);
    final trimmed = query?.trim();
    if (trimmed != null && trimmed.isNotEmpty) {
      q.where((t) => t.name.like('%$trimmed%'));
    }
    if (lowStockOnly) {
      q.where((t) => t.quantity.isSmallerOrEqual(t.lowStockThreshold));
    }
    q.orderBy([(t) => OrderingTerm.asc(t.name)]);
    return q.watch();
  }

  Future<Product?> getByBarcode(String barcode) {
    return (select(products)..where((t) => t.barcode.equals(barcode)))
        .getSingleOrNull();
  }

  /// Updates [p]'s editable fields. NEVER writes the `quantity` column —
  /// stock only changes via [StockDao.receiveStock] or
  /// `SalesDao.completeSale` (design D3/plan amendment).
  Future<void> updateProduct(Product p) {
    final companion = ProductsCompanion(
      id: Value(p.id),
      name: Value(p.name),
      barcode: Value(p.barcode),
      imagePath: Value(p.imagePath),
      buyingPrice: Value(p.buyingPrice),
      sellingPrice: Value(p.sellingPrice),
      unit: Value(p.unit),
      lowStockThreshold: Value(p.lowStockThreshold),
      updatedAt: Value(DateTime.now()),
      // quantity intentionally omitted — never written by this method.
    );
    return (update(products)..where((t) => t.id.equals(p.id))).write(companion);
  }
}
