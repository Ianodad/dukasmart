import 'package:drift/drift.dart';

import '../database/database.dart';
import '../database/day_bounds.dart';
import '../database/enums.dart';
import '../formatting/money.dart';
import 'projection_service.dart';

/// Read-only aggregate queries for the AI layer (spec: single service in
/// lib/core/ai/ composing the database; existing DAOs are not modified).
/// Every JSON map carries raw `*_cents` ints AND `*_display` strings from
/// [formatCents] — the model is instructed to quote display strings and
/// never do its own arithmetic on money.
class AiQueryService {
  AiQueryService(this._db);

  final AppDatabase _db;

  static String _dateString(DateTime d) =>
      localMidnight(d).toIso8601String().substring(0, 10);

  /// Half-open bounds covering local calendar days [from]..[to] inclusive.
  (DateTime, DateTime) _rangeBounds(DateTime from, DateTime to) =>
      (dayBounds(from).start, dayBounds(to).end);

  Future<List<Sale>> _salesBetween(DateTime from, DateTime to) {
    final (start, end) = _rangeBounds(from, to);
    return (_db.select(_db.sales)
          ..where((t) =>
              t.createdAt.isBiggerOrEqualValue(start) &
              t.createdAt.isSmallerThanValue(end)))
        .get();
  }

  Future<Map<String, Object?>> salesSummary(DateTime from, DateTime to) async {
    final sales = await _salesBetween(from, to);
    final total = sales.fold<int>(0, (sum, s) => sum + s.total);
    final cash = sales
        .where((s) => s.paymentMethod == PaymentMethod.cash)
        .fold<int>(0, (sum, s) => sum + s.total);
    final mpesa = total - cash;
    return {
      'from': _dateString(from),
      'to': _dateString(to),
      'sale_count': sales.length,
      'total_sales_cents': total,
      'total_sales_display': formatCents(total),
      'cash_sales_cents': cash,
      'cash_sales_display': formatCents(cash),
      'mpesa_sales_cents': mpesa,
      'mpesa_sales_display': formatCents(mpesa),
    };
  }

  Future<Map<String, Object?>> topProducts(
    DateTime from,
    DateTime to, {
    int limit = 5,
  }) async {
    final sales = await _salesBetween(from, to);
    if (sales.isEmpty) {
      return {'from': _dateString(from), 'to': _dateString(to), 'products': []};
    }
    final saleIds = sales.map((s) => s.id).toList();
    final items = await (_db.select(_db.saleItems)
          ..where((t) => t.saleId.isIn(saleIds)))
        .get();

    final byProduct = <int, ({String name, int qty, int revenue})>{};
    for (final item in items) {
      final prev = byProduct[item.productId];
      byProduct[item.productId] = (
        name: prev?.name ?? item.productName,
        qty: (prev?.qty ?? 0) + item.quantity,
        revenue: (prev?.revenue ?? 0) + item.total,
      );
    }
    final ranked = byProduct.entries.toList()
      ..sort((a, b) {
        final byQty = b.value.qty.compareTo(a.value.qty);
        return byQty != 0 ? byQty : b.value.revenue.compareTo(a.value.revenue);
      });

    return {
      'from': _dateString(from),
      'to': _dateString(to),
      'products': [
        for (final e in ranked.take(limit))
          {
            'name': e.value.name,
            'quantity_sold': e.value.qty,
            'revenue_cents': e.value.revenue,
            'revenue_display': formatCents(e.value.revenue),
          },
      ],
    };
  }

  Future<Map<String, Object?>> expensesSummary(DateTime from, DateTime to) async {
    final (start, end) = _rangeBounds(from, to);
    final rows = await (_db.select(_db.expenses)
          ..where((t) =>
              t.createdAt.isBiggerOrEqualValue(start) &
              t.createdAt.isSmallerThanValue(end)))
        .get();

    final total = rows.fold<int>(0, (sum, e) => sum + e.amount);
    final byCategory = <ExpenseCategory, ({int total, int count})>{};
    // R4: also group by the expense's free-text "reason" (the `description`
    // column) — the schema has no dedicated reason enum, so `description`
    // is the closest thing to it. Rows with no/blank description are
    // bucketed under "Unspecified" rather than dropped.
    final byReason = <String, ({int total, int count})>{};
    for (final e in rows) {
      final prevCategory = byCategory[e.category] ?? (total: 0, count: 0);
      byCategory[e.category] =
          (total: prevCategory.total + e.amount, count: prevCategory.count + 1);

      final trimmed = e.description?.trim();
      final reasonKey = (trimmed == null || trimmed.isEmpty) ? 'Unspecified' : trimmed;
      final prevReason = byReason[reasonKey] ?? (total: 0, count: 0);
      byReason[reasonKey] =
          (total: prevReason.total + e.amount, count: prevReason.count + 1);
    }
    final rankedCategory = byCategory.entries.toList()
      ..sort((a, b) => b.value.total.compareTo(a.value.total));
    final rankedReason = byReason.entries.toList()
      ..sort((a, b) => b.value.total.compareTo(a.value.total));

    return {
      'from': _dateString(from),
      'to': _dateString(to),
      'total_expenses_cents': total,
      'total_expenses_display': formatCents(total),
      // R4: aggregated totals + counts only, grouped BOTH ways — never raw
      // expense rows.
      'by_category': [
        for (final e in rankedCategory)
          {
            'category': e.key.label,
            'total_cents': e.value.total,
            'total_display': formatCents(e.value.total),
            'count': e.value.count,
          },
      ],
      'by_reason': [
        for (final e in rankedReason)
          {
            'reason': e.key,
            'total_cents': e.value.total,
            'total_display': formatCents(e.value.total),
            'count': e.value.count,
          },
      ],
    };
  }

  Future<Map<String, Object?>> stockLevels({bool lowOnly = false}) async {
    final products = await (_db.select(_db.products)
          ..orderBy([(t) => OrderingTerm.asc(t.quantity)]))
        .get();
    final rows = [
      for (final p in products)
        if (!lowOnly || p.quantity <= p.lowStockThreshold)
          {
            'name': p.name,
            'quantity': p.quantity,
            'unit': p.unit.label,
            'low_stock_threshold': p.lowStockThreshold,
            'is_low': p.quantity <= p.lowStockThreshold,
          },
    ];
    return {'product_count': rows.length, 'products': rows};
  }

  /// R6: serializes the STORED [DailyClose] row in full — this is the
  /// authoritative record for report narration (cash sales, M-PESA sales,
  /// expenses total, COGS, gross profit, net result, expected/actual cash,
  /// and the cash difference), never recomputed from live sales/expenses.
  /// Recording a sale or expense after a day is closed does not change
  /// these figures unless the day is explicitly re-closed.
  Future<Map<String, Object?>> dailyCloses(DateTime from, DateTime to) async {
    final start = localMidnight(from);
    final end = localMidnight(to);
    final closes = await (_db.select(_db.dailyCloses)
          ..where((t) =>
              t.date.isBiggerOrEqualValue(start) & t.date.isSmallerOrEqualValue(end))
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .get();
    return {
      'from': _dateString(from),
      'to': _dateString(to),
      'closes': [
        for (final c in closes)
          {
            'date': _dateString(c.date),
            'total_sales_cents': c.totalSales,
            'total_sales_display': formatCents(c.totalSales),
            'cash_sales_cents': c.cashSales,
            'cash_sales_display': formatCents(c.cashSales),
            'mpesa_sales_cents': c.mpesaSales,
            'mpesa_sales_display': formatCents(c.mpesaSales),
            'expenses_cents': c.expenses,
            'expenses_display': formatCents(c.expenses),
            'cost_of_goods_cents': c.costOfGoods,
            'cost_of_goods_display': formatCents(c.costOfGoods),
            'gross_profit_cents': c.grossProfit,
            'gross_profit_display': formatCents(c.grossProfit),
            'net_result_cents': c.netResult,
            'net_result_display': formatCents(c.netResult),
            'expected_cash_cents': c.expectedCash,
            'expected_cash_display': formatCents(c.expectedCash),
            'actual_cash_cents': c.actualCash,
            'actual_cash_display': formatCents(c.actualCash),
            'cash_difference_cents': c.cashDifference,
            'cash_difference_display': formatCents(c.cashDifference),
          },
      ],
    };
  }

  /// Per-product velocity inputs for [projectStockRunOut]. The effective
  /// averaging window starts at `max(windowStart, that product's
  /// first-EVER sale day)` (R2) — the first-ever sale is looked up across
  /// *all* history, not just inside the window, so an established product
  /// that simply didn't sell early in the window is still averaged over
  /// the full [windowDays] instead of being mistaken for brand new (which
  /// would inflate its velocity and shorten its projected run-out). Only a
  /// product whose first-ever sale falls inside the window gets a
  /// shortened, "days since first sale" window.
  Future<List<ProductVelocity>> productVelocities({
    DateTime? asOf,
    int windowDays = 14,
  }) async {
    final now = asOf ?? DateTime.now();
    final windowStart =
        localMidnight(now).subtract(Duration(days: windowDays - 1));
    final windowEnd = dayBounds(now).end;

    final sales = await (_db.select(_db.sales)
          ..where((t) =>
              t.createdAt.isBiggerOrEqualValue(windowStart) &
              t.createdAt.isSmallerThanValue(windowEnd)))
        .get();
    final saleById = {for (final s in sales) s.id: s};
    final items = sales.isEmpty
        ? <SaleItem>[]
        : await (_db.select(_db.saleItems)
              ..where((t) => t.saleId.isIn(saleById.keys.toList())))
            .get();

    final soldByProduct = <int, int>{};
    for (final item in items) {
      soldByProduct[item.productId] =
          (soldByProduct[item.productId] ?? 0) + item.quantity;
    }

    final firstEverSaleByProduct = await _firstSaleDateByProduct();

    final products = await _db.select(_db.products).get();
    return [
      for (final p in products)
        () {
          final sold = soldByProduct[p.id] ?? 0;
          var effectiveDays = windowDays;
          final firstEver = firstEverSaleByProduct[p.id];
          if (firstEver != null) {
            final firstEverDay = localMidnight(firstEver);
            final effectiveWindowStart =
                firstEverDay.isAfter(windowStart) ? firstEverDay : windowStart;
            effectiveDays = (localMidnight(now)
                        .difference(effectiveWindowStart)
                        .inDays +
                    1)
                .clamp(1, windowDays);
          }
          return ProductVelocity(
            productId: p.id,
            name: p.name,
            unitLabel: p.unit.label,
            currentQty: p.quantity,
            soldInWindow: sold,
            windowDays: effectiveDays,
          );
        }(),
    ];
  }

  /// Earliest sale timestamp per product, across the shop's *entire*
  /// history (unbounded) — used by [productVelocities] (R2) to tell an
  /// established product apart from a genuinely new one, independent of
  /// which sales happen to fall inside the averaging window.
  Future<Map<int, DateTime>> _firstSaleDateByProduct() async {
    final allSales = await _db.select(_db.sales).get();
    if (allSales.isEmpty) return {};
    final saleById = {for (final s in allSales) s.id: s};
    final allItems = await (_db.select(_db.saleItems)
          ..where((t) => t.saleId.isIn(saleById.keys.toList())))
        .get();

    final firstSale = <int, DateTime>{};
    for (final item in allItems) {
      final saleAt = saleById[item.saleId]!.createdAt;
      final existing = firstSale[item.productId];
      if (existing == null || saleAt.isBefore(existing)) {
        firstSale[item.productId] = saleAt;
      }
    }
    return firstSale;
  }

  /// Money in from sales minus money out on expenses (all categories) —
  /// the cash-flow input for [projectCashFlow]. Deliberately simpler than
  /// the Daily Close's accounting netResult.
  Future<int> netCentsBetween(DateTime from, DateTime to) async {
    final sales = await _salesBetween(from, to);
    final (start, end) = _rangeBounds(from, to);
    final expenses = await (_db.select(_db.expenses)
          ..where((t) =>
              t.createdAt.isBiggerOrEqualValue(start) &
              t.createdAt.isSmallerThanValue(end)))
        .get();
    final salesTotal = sales.fold<int>(0, (sum, s) => sum + s.total);
    final expensesTotal = expenses.fold<int>(0, (sum, e) => sum + e.amount);
    return salesTotal - expensesTotal;
  }

  /// Earliest sale or expense timestamp at or before [to], or null when
  /// there is no activity at all. [from] is an optional lower bound; when
  /// omitted the lookup is unbounded (searches the shop's whole history),
  /// which is what callers need to tell "genuinely less than N days of
  /// history" apart from "N days of history with a quiet day near the
  /// start of the averaging window". Used to clamp the cash-flow window
  /// to actual history the same way [productVelocities] clamps its
  /// averaging window to days since first sale.
  Future<DateTime?> earliestActivityBetween(DateTime? from, DateTime to) async {
    final end = dayBounds(to).end;
    final start = from == null ? null : dayBounds(from).start;
    Expression<bool> inRange(Expression<DateTime> createdAt) => start == null
        ? createdAt.isSmallerThanValue(end)
        : createdAt.isBiggerOrEqualValue(start) & createdAt.isSmallerThanValue(end);

    final sales =
        await (_db.select(_db.sales)..where((t) => inRange(t.createdAt))).get();
    final expenses = await (_db.select(_db.expenses)
          ..where((t) => inRange(t.createdAt)))
        .get();

    DateTime? earliest;
    for (final s in sales) {
      if (earliest == null || s.createdAt.isBefore(earliest)) {
        earliest = s.createdAt;
      }
    }
    for (final e in expenses) {
      if (earliest == null || e.createdAt.isBefore(earliest)) {
        earliest = e.createdAt;
      }
    }
    return earliest;
  }
}
