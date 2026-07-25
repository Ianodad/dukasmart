import 'package:dukasmart/core/database/database.dart';
import 'package:dukasmart/core/database/enums.dart';
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

  test('onCreate seeds the 5 demo products with opening stock movements', () async {
    final products = await db.select(db.products).get();
    expect(products, hasLength(5));

    final names = products.map((p) => p.name).toSet();
    expect(names, {
      'Coca-Cola 500ml',
      'Brookside Milk 500ml',
      'Jogoo Maize Flour 2kg',
      'Sugar 1kg',
      'Bread 400g',
    });

    final coke = products.firstWhere((p) => p.name == 'Coca-Cola 500ml');
    expect(coke.buyingPrice, 5500);
    expect(coke.sellingPrice, 7000);
    expect(coke.quantity, 24);
    expect(coke.unit, ProductUnit.bottle);
    expect(coke.lowStockThreshold, 6);

    final movements = await db.select(db.stockMovements).get();
    expect(movements, hasLength(5));
    for (final m in movements) {
      expect(m.movementType, MovementType.openingStock);
      expect(m.quantity, greaterThan(0));
    }
  });

  test('ready() completes against an in-memory db', () async {
    await expectLater(db.ready(), completes);
  });
}
