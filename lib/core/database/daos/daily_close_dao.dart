import 'package:drift/drift.dart';

import '../database.dart';
import '../day_bounds.dart';
import '../enums.dart';
import '../tables.dart';

part 'daily_close_dao.g.dart';

/// Frozen atomic surface (design D3/D9/D4).
@DriftAccessor(tables: [Sales, SaleItems, Expenses, DailyCloses])
class DailyCloseDao extends DatabaseAccessor<AppDatabase> with _$DailyCloseDaoMixin {
  DailyCloseDao(super.db);

  /// Recomputes every D4 aggregate for [date] from the source tables and
  /// upserts by date: re-closing a day replaces that day's record with
  /// fresh figures. Single Drift transaction.
  Future<void> closeDay({
    required DateTime date,
    required int actualCashCents,
    String? note,
  }) {
    return transaction(() async {
      final normalizedDate = localMidnight(date);
      final bounds = dayBounds(normalizedDate);

      final daySales = await (select(sales)
            ..where((t) =>
                t.createdAt.isBiggerOrEqualValue(bounds.start) &
                t.createdAt.isSmallerThanValue(bounds.end)))
          .get();
      final dayExpenses = await (select(expenses)
            ..where((t) =>
                t.createdAt.isBiggerOrEqualValue(bounds.start) &
                t.createdAt.isSmallerThanValue(bounds.end)))
          .get();

      final totalSales = daySales.fold<int>(0, (sum, s) => sum + s.total);
      final cashSales = daySales
          .where((s) => s.paymentMethod == PaymentMethod.cash)
          .fold<int>(0, (sum, s) => sum + s.total);
      final mpesaSales = daySales
          .where((s) => s.paymentMethod == PaymentMethod.mpesa)
          .fold<int>(0, (sum, s) => sum + s.total);

      int cogs = 0;
      final saleIds = daySales.map((s) => s.id).toList();
      if (saleIds.isNotEmpty) {
        final items = await (select(saleItems)..where((t) => t.saleId.isIn(saleIds))).get();
        cogs = items.fold<int>(0, (sum, i) => sum + i.buyingPriceSnapshot * i.quantity);
      }

      // Amendment A1 (D4): stockPurchase rows reduce expected cash only —
      // their cost reaches profit via COGS at sale time, so they're
      // excluded here.
      final expensesTotal = dayExpenses
          .where((e) => e.category != ExpenseCategory.stockPurchase)
          .fold<int>(0, (sum, e) => sum + e.amount);
      final cashExpenses = dayExpenses
          .where((e) => e.paymentMethod == PaymentMethod.cash)
          .fold<int>(0, (sum, e) => sum + e.amount);

      final grossProfit = totalSales - cogs;
      final netResult = grossProfit - expensesTotal;
      final expectedCash = cashSales - cashExpenses;
      final cashDifference = actualCashCents - expectedCash;

      final existing = await (select(dailyCloses)..where((t) => t.date.equals(normalizedDate)))
          .getSingleOrNull();

      final companion = DailyClosesCompanion(
        date: Value(normalizedDate),
        totalSales: Value(totalSales),
        cashSales: Value(cashSales),
        mpesaSales: Value(mpesaSales),
        expenses: Value(expensesTotal),
        costOfGoods: Value(cogs),
        grossProfit: Value(grossProfit),
        netResult: Value(netResult),
        expectedCash: Value(expectedCash),
        actualCash: Value(actualCashCents),
        cashDifference: Value(cashDifference),
        note: Value(note),
        createdAt: Value(DateTime.now()),
      );

      if (existing != null) {
        await (update(dailyCloses)..where((t) => t.id.equals(existing.id))).write(companion);
      } else {
        await into(dailyCloses).insert(companion);
      }
    });
  }

  Future<DailyClose?> getClose(DateTime date) {
    final normalizedDate = localMidnight(date);
    return (select(dailyCloses)..where((t) => t.date.equals(normalizedDate))).getSingleOrNull();
  }

  /// The most recently closed day (by [DailyCloses.date]), or `null` if no
  /// day has ever been closed. Backs the dashboard's "Daily Report" quick
  /// action, which jumps straight to the latest report.
  Future<DailyClose?> latestClose() {
    return (select(dailyCloses)
          ..orderBy([(t) => OrderingTerm.desc(t.date)])
          ..limit(1))
        .getSingleOrNull();
  }
}
