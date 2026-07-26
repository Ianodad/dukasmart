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

    // The whole snapshot must be jsonEncode-able (no DateTime leaks).
    expect(() => snapshot.toJsonString(), returnsNormally);
    expect(jsonDecode(snapshot.toJsonString()), isA<Map<String, Object?>>());
  });

  test('stock projections are capped at 8 entries', () async {
    final snapshot = await builder.build(DateTime.now());
    expect((snapshot.json['stock_projections'] as List).length, lessThanOrEqualTo(8));
  });
}
