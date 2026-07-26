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

/// Resolves once the database has finished opening — and, on first run,
/// finished `onCreate` seeding — via the core [AppDatabase.ready] API
/// (design F5). The splash screen awaits this instead of running its own
/// raw SQL against `databaseProvider` (Codex R1 #3).
final databaseReadyProvider = FutureProvider<void>((ref) async {
  final db = ref.watch(databaseProvider);
  await db.ready();
});

/// The frozen Daily Report contract for a given [date] (design D4). Null
/// when that day has not been closed yet.
///
/// `autoDispose` (Codex R1 #2): an always-alive family would cache a
/// report forever, so re-closing a day or later stock changes could show
/// a stale report. Disposing when the last screen stops watching forces a
/// fresh read on every visit.
final closedDayReportProvider =
    FutureProvider.autoDispose.family<ClosedDayReport?, DateTime>((ref, date) async {
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

/// Pure helper (Codex R1 #1 — midnight rollover): the [Duration] from
/// [now] until the next local-midnight boundary strictly after [now].
/// Side-effect-free so the boundary math is directly unit-testable
/// without touching a timer or a database.
Duration untilNextLocalMidnight(DateTime now) {
  final startOfToday = localMidnight(now);
  final nextMidnight = startOfToday.add(const Duration(days: 1));
  return nextMidnight.difference(now);
}

/// One authoritative, transactionally-consistent [DailyMetrics] stream
/// (Codex R1 #1). Every emission is triggered by one of three sources —
/// an immediate initial tick, a drift table-update notification for any
/// of the source tables, or a self-rescheduling local-midnight timer —
/// and, on every trigger, day bounds are recomputed fresh from
/// `DateTime.now()` and ALL source tables are read inside ONE
/// `db.transaction(...)` before a single result is emitted. There is no
/// cross-stream combining left to produce a mixed intermediate snapshot,
/// and an app left open past midnight rolls over to the new day on its
/// own via the timer.
Stream<DailyMetrics> _watchDailyMetrics(AppDatabase db) {
  StreamSubscription<Set<TableUpdate>>? tableSub;
  Timer? midnightTimer;
  var closed = false;
  var emitting = false;
  var pending = false;
  late final StreamController<DailyMetrics> controller;

  Future<void> emitSnapshot() async {
    final bounds = dayBounds(DateTime.now());
    await db.transaction(() async {
      final products = await db.select(db.products).get();
      final sales = await (db.select(db.sales)
            ..where((t) =>
                t.createdAt.isBiggerOrEqualValue(bounds.start) &
                t.createdAt.isSmallerThanValue(bounds.end)))
          .get();
      final saleIds = sales.map((s) => s.id).toList();
      final saleItems = saleIds.isEmpty
          ? <SaleItem>[]
          : await (db.select(db.saleItems)..where((t) => t.saleId.isIn(saleIds))).get();
      final expenses = await (db.select(db.expenses)
            ..where((t) =>
                t.createdAt.isBiggerOrEqualValue(bounds.start) &
                t.createdAt.isSmallerThanValue(bounds.end)))
          .get();

      if (!closed) {
        controller.add(
          computeDailyMetrics(
            products: products,
            sales: sales,
            saleItems: saleItems,
            expenses: expenses,
          ),
        );
      }
    });
  }

  // Coalesces bursts of triggers arriving while a snapshot read is still
  // in flight into a single trailing re-read, instead of stacking one
  // transaction per trigger.
  Future<void> trigger() async {
    if (closed) return;
    if (emitting) {
      pending = true;
      return;
    }
    emitting = true;
    try {
      await emitSnapshot();
    } catch (error, stackTrace) {
      if (!closed) controller.addError(error, stackTrace);
    } finally {
      emitting = false;
      if (pending && !closed) {
        pending = false;
        unawaited(trigger());
      }
    }
  }

  void scheduleMidnightTimer() {
    midnightTimer?.cancel();
    midnightTimer = Timer(untilNextLocalMidnight(DateTime.now()), () {
      scheduleMidnightTimer();
      unawaited(trigger());
    });
  }

  controller = StreamController<DailyMetrics>(
    onListen: () {
      closed = false;
      scheduleMidnightTimer();
      tableSub = db
          .tableUpdates(TableUpdateQuery.onAllTables(
            [db.products, db.sales, db.saleItems, db.expenses],
          ))
          .listen((_) => unawaited(trigger()));
      unawaited(trigger()); // immediate initial tick
    },
    onCancel: () async {
      closed = true;
      midnightTimer?.cancel();
      midnightTimer = null;
      await tableSub?.cancel();
      tableSub = null;
    },
  );

  return controller.stream;
}
