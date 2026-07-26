import 'package:dukasmart/core/ai/ai_query_service.dart';
import 'package:dukasmart/core/database/database.dart';
import 'package:dukasmart/core/database/enums.dart';
import 'package:drift/drift.dart' show Value;
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

  /// Inserts a sale directly (bypassing [SalesDao.completeSale], which
  /// always stamps `DateTime.now()`) so tests can backdate a sale to
  /// exercise R2's "first-EVER sale, unbounded" lookup.
  Future<void> sellOnDate(int productId, int qty, DateTime date) async {
    final product = await (db.select(db.products)
          ..where((t) => t.id.equals(productId)))
        .getSingle();
    final total = product.sellingPrice! * qty;
    final saleId = await db.into(db.sales).insert(
          SalesCompanion.insert(
            subtotal: total,
            total: total,
            paymentMethod: PaymentMethod.cash,
            amountReceived: total,
            changeAmount: 0,
            createdAt: date,
          ),
        );
    await db.into(db.saleItems).insert(
          SaleItemsCompanion.insert(
            saleId: saleId,
            productId: productId,
            productName: product.name,
            quantity: qty,
            buyingPriceSnapshot: product.buyingPrice ?? 0,
            sellingPriceSnapshot: product.sellingPrice!,
            total: total,
          ),
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

  test(
      'R3: topProducts aggregates by productId, so two distinct products '
      'sharing one name stay separate rows', () async {
    final duplicateId = await db.productsDao.createProduct(
      ProductsCompanion.insert(
        name: 'Coca-Cola 500ml', // same display name as seeded product 1
        unit: ProductUnit.bottle,
        sellingPrice: const Value(7000),
        buyingPrice: const Value(5500),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      openingQty: 10,
    );
    await sellToday(1, 1, PaymentMethod.cash); // seeded Coca-Cola (id 1)
    await sellToday(duplicateId, 1, PaymentMethod.cash); // distinct product
    final now = DateTime.now();

    final json = await service.topProducts(now, now, limit: 10);
    final products = (json['products'] as List).cast<Map>();
    final cokeRows =
        products.where((p) => p['name'] == 'Coca-Cola 500ml').toList();
    expect(cokeRows, hasLength(2));
    expect(cokeRows.every((p) => p['quantity_sold'] == 1), isTrue);
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

  test('R4: expensesSummary groups by reason (description) as well, and '
      'never leaks raw expense rows', () async {
    await db.expensesDao.recordExpense(
      amountCents: 20000,
      category: ExpenseCategory.stockTransport,
      description: 'Boda fare to town',
      method: PaymentMethod.cash,
      selectedDate: DateTime.now(),
    );
    await db.expensesDao.recordExpense(
      amountCents: 5000,
      category: ExpenseCategory.stockTransport,
      description: 'Boda fare to town',
      method: PaymentMethod.mpesa,
      selectedDate: DateTime.now(),
    );
    await db.expensesDao.recordExpense(
      amountCents: 1000,
      category: ExpenseCategory.other,
      method: PaymentMethod.cash,
      selectedDate: DateTime.now(),
    ); // no description -> "Unspecified"
    final now = DateTime.now();

    final json = await service.expensesSummary(now, now);
    expect(json.containsKey('by_reason'), isTrue);
    expect(json.containsKey('description'), isFalse); // no raw rows
    final byReason = (json['by_reason'] as List).cast<Map>();
    expect(byReason, hasLength(2));
    final boda =
        byReason.singleWhere((r) => r['reason'] == 'Boda fare to town');
    expect(boda['total_cents'], 25000);
    expect(boda['count'], 2);
    final unspecified = byReason.singleWhere((r) => r['reason'] == 'Unspecified');
    expect(unspecified['total_cents'], 1000);
    expect(unspecified['count'], 1);
  });

  test(
      'expensesSummary caps by_reason at reasonLimit distinct entries and '
      'folds the remainder into an "Other" bucket', () async {
    final now = DateTime.now();
    // 3 distinct free-text reasons, each 1000c, well under a limit of 2.
    for (final reason in ['Boda', 'Diesel', 'Airtime top-up']) {
      await db.expensesDao.recordExpense(
        amountCents: 1000,
        category: ExpenseCategory.other,
        description: reason,
        method: PaymentMethod.cash,
        selectedDate: now,
      );
    }

    final json = await service.expensesSummary(now, now, reasonLimit: 2);
    expect(json['total_expenses_cents'], 3000);
    final byReason = (json['by_reason'] as List).cast<Map>();
    // Capped to reasonLimit (2) + one "Other" overflow bucket.
    expect(byReason, hasLength(3));
    final other = byReason.singleWhere((r) => r['reason'] == 'Other');
    expect(other['total_cents'], 1000);
    expect(other['count'], 1);
    // Totals across all buckets still reconcile with the grand total.
    final sum = byReason.fold<int>(0, (s, r) => s + (r['total_cents'] as int));
    expect(sum, 3000);
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

  test(
      'R6: dailyCloses serializes the full stored close row (cash/mpesa '
      'split, COGS, gross profit, expected/actual cash)', () async {
    // Coca-Cola: buying 5500c, selling 7000c -> COGS 5500, gross profit 1500.
    await sellToday(1, 1, PaymentMethod.cash);
    await db.expensesDao.recordExpense(
      amountCents: 500,
      category: ExpenseCategory.airtime,
      method: PaymentMethod.cash,
      selectedDate: DateTime.now(),
    );
    await db.dailyCloseDao.closeDay(date: DateTime.now(), actualCashCents: 6500);
    final now = DateTime.now();

    final json = await service.dailyCloses(now, now);
    final close = (json['closes'] as List).cast<Map>().single;
    expect(close['cash_sales_cents'], 7000);
    expect(close['mpesa_sales_cents'], 0);
    expect(close['cost_of_goods_cents'], 5500);
    expect(close['gross_profit_cents'], 1500);
    expect(close['net_result_cents'], 1000); // 1500 gross profit - 500 expenses
    expect(close['expected_cash_cents'], 6500); // 7000 cash sales - 500 cash expenses
    expect(close['actual_cash_cents'], 6500);
    expect(close['cash_difference_cents'], 0);
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

  test(
      'R2: an established product whose only recent sale is today keeps a '
      'full-window average, not a 1-day one', () async {
    // Coca-Cola's first-ever sale was 100 days ago (well outside the
    // default 14-day window) -- it must not be treated as a brand-new
    // product just because that's its only sale visible inside the
    // window.
    await sellOnDate(1, 1, DateTime.now().subtract(const Duration(days: 100)));
    await sellToday(1, 2, PaymentMethod.cash);

    final velocities = await service.productVelocities();
    final coke = velocities.singleWhere((v) => v.name == 'Coca-Cola 500ml');
    expect(coke.soldInWindow, 2); // the 100-day-old sale is outside the window
    expect(coke.windowDays, 14); // full window -- established product
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
