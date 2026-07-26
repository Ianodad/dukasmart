import 'dart:convert';

import 'package:dukasmart/core/ai/ai_query_service.dart';
import 'package:dukasmart/core/ai/duka_tools.dart';
import 'package:dukasmart/core/database/database.dart';
import 'package:dukasmart/core/database/enums.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late DukaToolDispatcher dispatcher;

  setUp(() {
    db = AppDatabase.forExecutor(NativeDatabase.memory());
    dispatcher = DukaToolDispatcher(AiQueryService(db));
  });

  tearDown(() async {
    await db.close();
  });

  String today() => DateTime.now().toIso8601String().substring(0, 10);

  test('exposes exactly the 6 read-only tools from the spec', () {
    final names = DukaToolDispatcher.toolDefinitions
        .map((t) => t['name'])
        .toSet();
    expect(names, {
      'get_sales_summary',
      'get_top_products',
      'get_expenses',
      'get_stock_levels',
      'get_daily_closes',
      'get_projections',
    });
    // Every definition is a valid Anthropic tool shape.
    for (final def in DukaToolDispatcher.toolDefinitions) {
      expect(def['description'], isA<String>());
      expect((def['input_schema'] as Map)['type'], 'object');
    }
  });

  test('get_sales_summary returns totals for today', () async {
    await db.salesDao.completeSale(
      lines: [(productId: 1, quantity: 1)], // Coca-Cola 7000c
      method: PaymentMethod.cash,
      amountReceivedCents: 7000,
    );
    final out = await dispatcher
        .execute('get_sales_summary', {'from': today(), 'to': today()});
    final json = jsonDecode(out) as Map<String, dynamic>;
    expect(json['total_sales_cents'], 7000);
    expect(json['total_sales_display'], 'KES 70');
  });

  test('get_stock_levels with low_only filters', () async {
    // Bread (id 5): qty 5, threshold 3 -> sell 2 makes it low.
    await db.salesDao.completeSale(
      lines: [(productId: 5, quantity: 2)],
      method: PaymentMethod.cash,
      amountReceivedCents: 13000,
    );
    final out = await dispatcher.execute('get_stock_levels', {'low_only': true});
    final json = jsonDecode(out) as Map<String, dynamic>;
    expect(json['product_count'], 1);
    expect((json['products'] as List).single['name'], 'Bread 400g');
  });

  test('get_projections returns stock projections and cash flow', () async {
    // Established shop: real activity well before the 30-day cash-flow
    // window, so days_of_data clamps up to the full 30.
    await db.expensesDao.recordExpense(
      amountCents: 500,
      category: ExpenseCategory.other,
      method: PaymentMethod.cash,
      selectedDate: DateTime.now().subtract(const Duration(days: 45)),
    );

    final out = await dispatcher.execute('get_projections', {});
    final json = jsonDecode(out) as Map<String, dynamic>;
    expect(json['stock_projections'], isA<List>());
    expect((json['cash_flow'] as Map)['days_of_data'], 30);
  });

  test(
      'get_projections clamps days_of_data to actual shop history, not a '
      'fixed 30', () async {
    // Brand-new shop: only 2 days of history. avg_daily_net_cents must be
    // net over 2 days, not net divided by a fixed 30 (which would silently
    // under-estimate the figure narrated back to the shopkeeper).
    final now = DateTime.now();
    await db.expensesDao.recordExpense(
      amountCents: 1000,
      category: ExpenseCategory.other,
      method: PaymentMethod.cash,
      selectedDate: now.subtract(const Duration(days: 1)),
    );

    final out = await dispatcher.execute('get_projections', {});
    final json = jsonDecode(out) as Map<String, dynamic>;
    final cashFlow = json['cash_flow'] as Map<String, dynamic>;
    expect(cashFlow['days_of_data'], 2);
    expect(cashFlow['avg_daily_net_cents'], -1000 ~/ 2);
  });

  test('bad date input -> error JSON, never a throw', () async {
    final out = await dispatcher
        .execute('get_sales_summary', {'from': 'yesterday', 'to': today()});
    final json = jsonDecode(out) as Map<String, dynamic>;
    expect(json['error'], contains('from'));
  });

  test('missing date input -> error JSON', () async {
    final out = await dispatcher.execute('get_expenses', {});
    final json = jsonDecode(out) as Map<String, dynamic>;
    expect(json['error'], isA<String>());
  });

  test('unknown tool -> error JSON', () async {
    final out = await dispatcher.execute('get_weather', {});
    final json = jsonDecode(out) as Map<String, dynamic>;
    expect(json['error'], 'Unknown tool: get_weather');
  });
}
