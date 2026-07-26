import 'package:dukasmart/core/ai/ai_query_service.dart';
import 'package:dukasmart/core/database/database.dart';
import 'package:dukasmart/core/database/enums.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late AiQueryService service;

  setUp(() {
    db = AppDatabase.forExecutor(NativeDatabase.memory());
    service = AiQueryService(db);
  });

  tearDown(() async {
    await db.close();
  });

  /// Seeded product ids are insertion-ordered: 1 Coca-Cola (7000c sell),
  /// 2 Milk (6500c), 3 Jogoo (21000c), 4 Sugar (17000c), 5 Bread (6500c).
  Future<void> sellToday(int productId, int qty, PaymentMethod method) async {
    final product = await (db.select(db.products)
          ..where((t) => t.id.equals(productId)))
        .getSingle();
    final total = product.sellingPrice! * qty;
    await db.salesDao.completeSale(
      lines: [(productId: productId, quantity: qty)],
      method: method,
      amountReceivedCents: total,
    );
  }

  group('salesSummary', () {
    test('totals and cash/mpesa split for today', () async {
      await sellToday(1, 1, PaymentMethod.cash); // 7000
      await sellToday(2, 1, PaymentMethod.mpesa); // 6500
      final now = DateTime.now();

      final json = await service.salesSummary(now, now);
      expect(json['sale_count'], 2);
      expect(json['total_sales_cents'], 13500);
      expect(json['cash_sales_cents'], 7000);
      expect(json['mpesa_sales_cents'], 6500);
      expect(json['total_sales_display'], 'KES 135');
    });

    test('empty range -> zeros', () async {
      final lastWeek = DateTime.now().subtract(const Duration(days: 7));
      final json = await service.salesSummary(lastWeek, lastWeek);
      expect(json['sale_count'], 0);
      expect(json['total_sales_cents'], 0);
    });
  });

  test('topProducts aggregates by product, best first', () async {
    await sellToday(1, 2, PaymentMethod.cash);
    await sellToday(2, 1, PaymentMethod.cash);
    final now = DateTime.now();

    final json = await service.topProducts(now, now, limit: 5);
    final products = json['products'] as List;
    expect(products, hasLength(2));
    final first = products.first as Map;
    expect(first['name'], 'Coca-Cola 500ml');
    expect(first['quantity_sold'], 2);
    expect(first['revenue_cents'], 14000);
  });

  test('expensesSummary groups by category label', () async {
    await db.expensesDao.recordExpense(
      amountCents: 20000,
      category: ExpenseCategory.stockTransport,
      method: PaymentMethod.cash,
      selectedDate: DateTime.now(),
    );
    await db.expensesDao.recordExpense(
      amountCents: 5000,
      category: ExpenseCategory.airtime,
      method: PaymentMethod.mpesa,
      selectedDate: DateTime.now(),
    );
    final now = DateTime.now();

    final json = await service.expensesSummary(now, now);
    expect(json['total_expenses_cents'], 25000);
    final byCategory = json['by_category'] as List;
    expect(byCategory, hasLength(2));
    final transport =
        byCategory.cast<Map>().singleWhere((c) => c['category'] == 'Stock transport');
    expect(transport['total_cents'], 20000);
  });

  group('stockLevels', () {
    test('all products with low flags', () async {
      final json = await service.stockLevels();
      final products = (json['products'] as List).cast<Map>();
      expect(products, hasLength(5));
      expect(products.every((p) => p['is_low'] == false), isTrue);
    });

    test('lowOnly filters to low/out-of-stock products', () async {
      // Bread: qty 5, threshold 3 -> selling 2 leaves 3 <= 3 (low).
      await sellToday(5, 2, PaymentMethod.cash);
      final json = await service.stockLevels(lowOnly: true);
      final products = (json['products'] as List).cast<Map>();
      expect(products, hasLength(1));
      expect(products.single['name'], 'Bread 400g');
      expect(products.single['is_low'], true);
    });
  });

  test('dailyCloses returns closed days in range, newest first', () async {
    await sellToday(1, 1, PaymentMethod.cash);
    await db.dailyCloseDao.closeDay(date: DateTime.now(), actualCashCents: 7000);
    final now = DateTime.now();

    final json = await service.dailyCloses(now.subtract(const Duration(days: 6)), now);
    final closes = (json['closes'] as List).cast<Map>();
    expect(closes, hasLength(1));
    expect(closes.single['total_sales_cents'], 7000);
    expect(closes.single['cash_difference_cents'], 0);
  });

  test('productVelocities: first sale today -> 1-day effective window', () async {
    await sellToday(1, 2, PaymentMethod.cash);
    final velocities = await service.productVelocities();
    final coke = velocities.singleWhere((v) => v.name == 'Coca-Cola 500ml');
    expect(coke.soldInWindow, 2);
    expect(coke.windowDays, 1);
    expect(coke.currentQty, 22);
    final bread = velocities.singleWhere((v) => v.name == 'Bread 400g');
    expect(bread.soldInWindow, 0);
  });

  test('netCentsBetween = sales minus expenses', () async {
    await sellToday(1, 1, PaymentMethod.cash); // +7000
    await db.expensesDao.recordExpense(
      amountCents: 500,
      category: ExpenseCategory.airtime,
      method: PaymentMethod.cash,
      selectedDate: DateTime.now(),
    ); // -500
    final now = DateTime.now();
    expect(await service.netCentsBetween(now, now), 6500);
  });
}
