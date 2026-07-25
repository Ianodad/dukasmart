import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'database/daos/daily_close_dao.dart';
import 'database/daos/expenses_dao.dart';
import 'database/daos/products_dao.dart';
import 'database/daos/sales_dao.dart';
import 'database/daos/stock_dao.dart';
import 'database/database.dart';
import 'database/day_bounds.dart';
import 'models/closed_day_report.dart';
import 'models/daily_metrics.dart';

/// Frozen provider registrations (design D9). Every screen reads through
/// these — never through raw Drift queries of its own.

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final productsDaoProvider = Provider<ProductsDao>((ref) => ref.watch(databaseProvider).productsDao);
final stockDaoProvider = Provider<StockDao>((ref) => ref.watch(databaseProvider).stockDao);
final salesDaoProvider = Provider<SalesDao>((ref) => ref.watch(databaseProvider).salesDao);
final expensesDaoProvider =
    Provider<ExpensesDao>((ref) => ref.watch(databaseProvider).expensesDao);
final dailyCloseDaoProvider =
    Provider<DailyCloseDao>((ref) => ref.watch(databaseProvider).dailyCloseDao);

/// All products, name-sorted (design D3 UI reads via Drift watch queries).
final productsProvider = StreamProvider<List<Product>>((ref) {
  return ref.watch(productsDaoProvider).watchProducts();
});

/// Today's expenses.
final expensesTodayProvider = StreamProvider<List<Expense>>((ref) {
  return ref.watch(expensesDaoProvider).watchExpensesForDay(DateTime.now());
});

/// Most recent expenses across all days, newest first — the Expense
/// List screen's source (design D3 amendment: shows time for same-day
/// entries, date for backdated/older ones).
final recentExpensesProvider = StreamProvider<List<Expense>>((ref) {
  return ref.watch(expensesDaoProvider).watchRecentExpenses();
});

/// Today's live-recomputed [DailyMetrics] — the single authoritative
/// aggregate consumed by the Home Dashboard and Close Day screens
/// (design D1/D3: no screen computes its own aggregates).
final dailyMetricsProvider = StreamProvider<DailyMetrics>((ref) {
  final db = ref.watch(databaseProvider);
  return _watchDailyMetrics(db);
});

/// The frozen Daily Report contract for a given [date] (design D4). Null
/// when that day has not been closed yet.
final closedDayReportProvider =
    FutureProvider.family<ClosedDayReport?, DateTime>((ref, date) async {
  final db = ref.watch(databaseProvider);
  final close = await ref.watch(dailyCloseDaoProvider).getClose(date);
  if (close == null) return null;

  final bounds = dayBounds(date);
  final daySales = await (db.select(db.sales)
        ..where((t) =>
            t.createdAt.isBiggerOrEqualValue(bounds.start) &
            t.createdAt.isSmallerThanValue(bounds.end)))
      .get();
  final saleIds = daySales.map((s) => s.id).toList();
  final saleItems = saleIds.isEmpty
      ? <SaleItem>[]
      : await (db.select(db.saleItems)..where((t) => t.saleId.isIn(saleIds))).get();

  final lowStockNow = await (db.select(db.products)
        ..where((t) => t.quantity.isSmallerOrEqual(t.lowStockThreshold)))
      .get();

  return ClosedDayReport(
    close: close,
    bestSeller: computeBestSeller(saleItems),
    lowStockNow: lowStockNow,
  );
});

/// Combines live watches of products, today's sales (+ their sale_items)
/// and today's expenses into a single [DailyMetrics] stream. Kept out of
/// any single DAO because it composes reads across every table (design
/// D3: `DailyMetrics` lives in Foundation, not in any one DAO).
Stream<DailyMetrics> _watchDailyMetrics(AppDatabase db) {
  final bounds = dayBounds(DateTime.now());
  final controller = StreamController<DailyMetrics>.broadcast();

  List<Product>? products;
  List<Sale>? sales;
  List<SaleItem>? saleItems;
  List<Expense>? expenses;

  void recompute() {
    if (products == null || sales == null || saleItems == null || expenses == null) return;
    controller.add(
      computeDailyMetrics(
        products: products!,
        sales: sales!,
        saleItems: saleItems!,
        expenses: expenses!,
      ),
    );
  }

  final subscriptions = <StreamSubscription<void>>[];

  subscriptions.add(
    db.select(db.products).watch().listen((rows) {
      products = rows;
      recompute();
    }, onError: controller.addError),
  );

  final salesQuery = db.select(db.sales)
    ..where((t) =>
        t.createdAt.isBiggerOrEqualValue(bounds.start) & t.createdAt.isSmallerThanValue(bounds.end));
  subscriptions.add(
    salesQuery.watch().listen((rows) async {
      sales = rows;
      final ids = rows.map((s) => s.id).toList();
      saleItems =
          ids.isEmpty ? <SaleItem>[] : await (db.select(db.saleItems)..where((t) => t.saleId.isIn(ids))).get();
      recompute();
    }, onError: controller.addError),
  );

  final expensesQuery = db.select(db.expenses)
    ..where((t) =>
        t.createdAt.isBiggerOrEqualValue(bounds.start) & t.createdAt.isSmallerThanValue(bounds.end));
  subscriptions.add(
    expensesQuery.watch().listen((rows) {
      expenses = rows;
      recompute();
    }, onError: controller.addError),
  );

  controller.onCancel = () async {
    for (final s in subscriptions) {
      await s.cancel();
    }
  };

  return controller.stream;
}
