import 'dart:convert';

import 'package:dukasmart/core/ai/ai_query_service.dart';
import 'package:dukasmart/core/ai/snapshot_builder.dart';
import 'package:dukasmart/core/database/database.dart';
import 'package:dukasmart/core/database/enums.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late SnapshotBuilder builder;

  setUp(() {
    db = AppDatabase.forExecutor(NativeDatabase.memory());
    builder = SnapshotBuilder(AiQueryService(db));
  });

  tearDown(() async {
    await db.close();
  });

  test('snapshot carries today, comparisons, expenses, close, projections', () async {
    // One cash sale of seeded product 1 (Coca-Cola, 7000c) + one expense.
    await db.salesDao.completeSale(
      lines: [(productId: 1, quantity: 2)],
      method: PaymentMethod.cash,
      amountReceivedCents: 14000,
    );
    await db.expensesDao.recordExpense(
      amountCents: 3000,
      category: ExpenseCategory.stockTransport,
      method: PaymentMethod.cash,
      selectedDate: DateTime.now(),
    );
    await db.dailyCloseDao.closeDay(date: DateTime.now(), actualCashCents: 11000);

    final snapshot = await builder.build(DateTime.now());
    final json = snapshot.json;

    expect(json['date'], isA<String>());
    expect((json['today'] as Map)['total_sales_cents'], 14000);
    expect((json['top_products_today'] as Map)['products'], isNotEmpty);
    expect(json['previous_7_days'], isA<Map>());
    expect(json['same_weekday_last_week'], isA<Map>());
    expect((json['expenses_today'] as Map)['total_expenses_cents'], 3000);
    expect(json['expenses_last_7_days'], isA<Map>());
    expect((json['close_today'] as Map)['closes'], hasLength(1));
    expect(json['stock_projections'], isA<List>());
    expect((json['cash_flow'] as Map)['projected_net_7d_cents'], isA<int>());

    // R5: 30-day expense aggregate by category, and locally computed
    // 7d/30d sales averages -- integer division, exact values. Only
    // today's 14000c sale exists in this fixture.
    expect((json['expenses_last_30_days'] as Map)['total_expenses_cents'], 3000);
    expect(json['sales_avg_7d_cents'], 14000 ~/ 7);
    expect(json['sales_avg_30d_cents'], 14000 ~/ 30);
    expect(json['sales_avg_7d_display'], isA<String>());
    expect(json['sales_avg_30d_display'], isA<String>());

    // R6: close_today carries the full stored DailyClose row. Coca-Cola:
    // buying 5500c x2 = 11000 COGS; gross profit = 14000 - 11000 = 3000;
    // net result = 3000 - 3000 expenses = 0; expected cash = 14000 cash
    // sales - 3000 cash expenses = 11000, matching the 11000 actual cash.
    final close = ((json['close_today'] as Map)['closes'] as List).single as Map;
    expect(close['cash_sales_cents'], 14000);
    expect(close['mpesa_sales_cents'], 0);
    expect(close['cost_of_goods_cents'], 11000);
    expect(close['gross_profit_cents'], 3000);
    expect(close['net_result_cents'], 0);
    expect(close['expected_cash_cents'], 11000);
    expect(close['actual_cash_cents'], 11000);
    expect(close['cash_difference_cents'], 0);

    // The whole snapshot must be jsonEncode-able (no DateTime leaks).
    expect(() => snapshot.toJsonString(), returnsNormally);
    expect(jsonDecode(snapshot.toJsonString()), isA<Map<String, Object?>>());
  });

  test(
      'R6: close_today stays the stored close row after a sale/expense is '
      'recorded post-close; live "today" context does see them', () async {
    await db.salesDao.completeSale(
      lines: [(productId: 1, quantity: 1)], // Coca-Cola 7000c
      method: PaymentMethod.cash,
      amountReceivedCents: 7000,
    );
    await db.dailyCloseDao.closeDay(date: DateTime.now(), actualCashCents: 7000);

    final before = await builder.build(DateTime.now());
    final closeBefore =
        ((before.json['close_today'] as Map)['closes'] as List).single as Map;

    // Record more activity AFTER the close -- must not leak into
    // close_today unless the day is explicitly re-closed.
    await db.salesDao.completeSale(
      lines: [(productId: 2, quantity: 1)], // Milk 6500c
      method: PaymentMethod.cash,
      amountReceivedCents: 6500,
    );
    await db.expensesDao.recordExpense(
      amountCents: 200,
      category: ExpenseCategory.airtime,
      method: PaymentMethod.cash,
      selectedDate: DateTime.now(),
    );

    final after = await builder.build(DateTime.now());
    final closeAfter =
        ((after.json['close_today'] as Map)['closes'] as List).single as Map;

    expect(closeAfter, equals(closeBefore));
    // Live "today" context, by contrast, does see the post-close activity.
    expect((after.json['today'] as Map)['total_sales_cents'], 13500);
  });

  test('stock projections are capped at 8 entries', () async {
    final snapshot = await builder.build(DateTime.now());
    expect((snapshot.json['stock_projections'] as List).length, lessThanOrEqualTo(8));
  });

  test(
      'days_of_data stays at 30 for an established shop even with a quiet '
      "day at the cash-flow window's leading edge", () async {
    final now = DateTime.now();
    // Real activity well before the 30-day cash-flow window — this shop
    // has been trading for 45+ days.
    await db.expensesDao.recordExpense(
      amountCents: 500,
      category: ExpenseCategory.other,
      method: PaymentMethod.cash,
      selectedDate: now.subtract(const Duration(days: 45)),
    );
    // Quiet on the first two days of the window itself (closed for a
    // trip, restocking, a holiday) — trading resumes after that.
    await db.expensesDao.recordExpense(
      amountCents: 1000,
      category: ExpenseCategory.other,
      method: PaymentMethod.cash,
      selectedDate: now.subtract(const Duration(days: 27)),
    );

    final snapshot = await builder.build(now);
    final cashFlow = snapshot.json['cash_flow'] as Map;

    // The shop genuinely traded the full 30-day window; a quiet day or
    // two right at the window's edge must not shrink days_of_data below
    // 30 for a shop with real history further back.
    expect(cashFlow['days_of_data'], 30);
  });
}
