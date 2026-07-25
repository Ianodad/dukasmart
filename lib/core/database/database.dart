import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'enums.dart';
import 'tables.dart';

part 'database.g.dart';

/// The 5 demo products seeded on first run (requirements §Seed data),
/// prices converted from shillings to integer cents (design D2).
class _SeedProduct {
  const _SeedProduct({
    required this.name,
    required this.buyingPriceCents,
    required this.sellingPriceCents,
    required this.quantity,
    required this.unit,
    required this.lowStockThreshold,
  });

  final String name;
  final int buyingPriceCents;
  final int sellingPriceCents;
  final int quantity;
  final ProductUnit unit;
  final int lowStockThreshold;
}

const List<_SeedProduct> _seedProducts = [
  _SeedProduct(
    name: 'Coca-Cola 500ml',
    buyingPriceCents: 5500,
    sellingPriceCents: 7000,
    quantity: 24,
    unit: ProductUnit.bottle,
    lowStockThreshold: 6,
  ),
  _SeedProduct(
    name: 'Brookside Milk 500ml',
    buyingPriceCents: 5500,
    sellingPriceCents: 6500,
    quantity: 12,
    unit: ProductUnit.packet,
    lowStockThreshold: 5,
  ),
  _SeedProduct(
    name: 'Jogoo Maize Flour 2kg',
    buyingPriceCents: 18000,
    sellingPriceCents: 21000,
    quantity: 10,
    unit: ProductUnit.packet,
    lowStockThreshold: 4,
  ),
  _SeedProduct(
    name: 'Sugar 1kg',
    buyingPriceCents: 14500,
    sellingPriceCents: 17000,
    quantity: 8,
    unit: ProductUnit.packet,
    lowStockThreshold: 4,
  ),
  _SeedProduct(
    name: 'Bread 400g',
    buyingPriceCents: 5500,
    sellingPriceCents: 6500,
    quantity: 5,
    unit: ProductUnit.piece,
    lowStockThreshold: 3,
  ),
];

// NOTE: `daos: [...]` is added in Task F3 once the DAO classes exist.
@DriftDatabase(
  tables: [Products, Sales, SaleItems, Expenses, StockMovements, DailyCloses],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Test-only constructor allowing an in-memory (or otherwise custom)
  /// [QueryExecutor] to be injected — see design D10 DAO tests.
  AppDatabase.forExecutor(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
          await _seedFirstRun();
        },
      );

  /// True first-run seeding (design D3): runs exactly once inside
  /// `onCreate`, when the database file is first created. Seeds the 5 demo
  /// products AND an `openingStock` movement for each.
  Future<void> _seedFirstRun() async {
    final now = DateTime.now();
    for (final seed in _seedProducts) {
      final productId = await into(products).insert(
        ProductsCompanion.insert(
          name: seed.name,
          buyingPrice: Value(seed.buyingPriceCents),
          sellingPrice: Value(seed.sellingPriceCents),
          quantity: Value(seed.quantity),
          unit: seed.unit,
          lowStockThreshold: Value(seed.lowStockThreshold),
          createdAt: now,
          updatedAt: now,
        ),
      );
      if (seed.quantity > 0) {
        await into(stockMovements).insert(
          StockMovementsCompanion.insert(
            productId: productId,
            movementType: MovementType.openingStock,
            quantity: seed.quantity,
            createdAt: now,
          ),
        );
      }
    }
  }
}

QueryExecutor _openConnection() {
  return driftDatabase(
    name: 'dukasmart',
    web: DriftWebOptions(
      sqlite3Wasm: Uri.parse('sqlite3.wasm'),
      driftWorker: Uri.parse('drift_worker.js'),
    ),
  );
}
