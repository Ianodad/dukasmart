import 'package:dukasmart/core/database/database.dart';
import 'package:dukasmart/core/database/enums.dart';
import 'package:dukasmart/core/models/closed_day_report.dart';
import 'package:dukasmart/core/models/daily_metrics.dart';
import 'package:dukasmart/core/providers.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Polls [condition] until it is true, or fails after [timeout]. Used to
/// await async stream/future emissions driven by drift's table-update
/// notifications without hard-coding a fixed delay.
Future<void> _waitFor(bool Function() condition, {Duration timeout = const Duration(seconds: 5)}) async {
  final sw = Stopwatch()..start();
  while (!condition()) {
    if (sw.elapsed > timeout) {
      fail('Condition not satisfied within $timeout');
    }
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

Future<int> _insertProduct(
  AppDatabase db, {
  int? buyingPrice = 100,
  int? sellingPrice = 200,
  int quantity = 50,
}) {
  final now = DateTime.now();
  return db.into(db.products).insert(
        ProductsCompanion.insert(
          name: 'Item',
          buyingPrice: Value(buyingPrice),
          sellingPrice: Value(sellingPrice),
          quantity: Value(quantity),
          unit: ProductUnit.piece,
          createdAt: now,
          updatedAt: now,
        ),
      );
}

void main() {
  group('untilNextLocalMidnight', () {
    test('mid-day returns the remaining time until the next midnight', () {
      final now = DateTime(2026, 7, 25, 14, 30);
      expect(untilNextLocalMidnight(now), const Duration(hours: 9, minutes: 30));
    });

    test('23:59:59 returns exactly one second', () {
      final now = DateTime(2026, 7, 25, 23, 59, 59);
      expect(untilNextLocalMidnight(now), const Duration(seconds: 1));
    });

    test('exactly midnight returns a full day — the *next* midnight, not now', () {
      final now = DateTime(2026, 7, 25);
      expect(untilNextLocalMidnight(now), const Duration(days: 1));
    });
  });

  group('dailyMetricsProvider (single transactional snapshot)', () {
    late AppDatabase db;
    late ProviderContainer container;

    setUp(() {
      db = AppDatabase.forExecutor(NativeDatabase.memory());
      container = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(db)],
      );
    });

    tearDown(() async {
      container.dispose();
      await db.close();
    });

    test(
        'a write to sales after the first emission produces a new emission '
        'whose values reflect the committed state', () async {
      final productId = await _insertProduct(db, sellingPrice: 200, buyingPrice: 100);

      final emissions = <DailyMetrics>[];
      final errors = <Object>[];
      final sub = container.listen<AsyncValue<DailyMetrics>>(
        dailyMetricsProvider,
        (previous, next) {
          next.whenOrNull(
            data: emissions.add,
            error: (error, _) => errors.add(error),
          );
        },
        fireImmediately: true,
      );

      await _waitFor(() => emissions.isNotEmpty);
      expect(emissions.last.totalSales, 0);
      expect(emissions.last.txCount, 0);

      await db.salesDao.completeSale(
        lines: [(productId: productId, quantity: 2)],
        method: PaymentMethod.cash,
        amountReceivedCents: 400,
      );

      await _waitFor(() => emissions.last.totalSales == 400);
      expect(emissions.last.totalSales, 400);
      expect(emissions.last.cashSales, 400);
      expect(emissions.last.txCount, 1);
      expect(emissions.last.cogs, 200); // 2 * buyingPrice 100
      expect(errors, isEmpty);

      sub.close();
    });
  });

  group('closedDayReportProvider (autoDispose freshness)', () {
    late AppDatabase db;
    late ProviderContainer container;

    setUp(() {
      db = AppDatabase.forExecutor(NativeDatabase.memory());
      container = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(db)],
      );
    });

    tearDown(() async {
      container.dispose();
      await db.close();
    });

    test(
        'read -> dispose listeners -> write new close for same date -> '
        'fresh read returns updated figures', () async {
      final productId = await _insertProduct(db, sellingPrice: 200, buyingPrice: 100);
      final today = DateTime.now();

      await db.salesDao.completeSale(
        lines: [(productId: productId, quantity: 1)],
        method: PaymentMethod.cash,
        amountReceivedCents: 200,
      );
      await db.dailyCloseDao.closeDay(date: today, actualCashCents: 200);

      ClosedDayReport? firstReport;
      final firstSub = container.listen<AsyncValue<ClosedDayReport?>>(
        closedDayReportProvider(today),
        (previous, next) => next.whenData((report) => firstReport = report),
        fireImmediately: true,
      );
      await _waitFor(() => firstReport != null);
      expect(firstReport!.close.totalSales, 200);

      // Dispose every listener — with `autoDispose`, this tears the cached
      // family instance down instead of leaving a stale value cached
      // forever. Riverpod schedules that teardown via `Future(task)` (a
      // macrotask), so a real event-loop turn must elapse before it runs.
      firstSub.close();
      await Future<void>.delayed(Duration.zero);

      // Another sale, then re-closing the SAME date changes the stored
      // figures for that date.
      await db.salesDao.completeSale(
        lines: [(productId: productId, quantity: 1)],
        method: PaymentMethod.cash,
        amountReceivedCents: 200,
      );
      await db.dailyCloseDao.closeDay(date: today, actualCashCents: 400);

      ClosedDayReport? secondReport;
      final secondSub = container.listen<AsyncValue<ClosedDayReport?>>(
        closedDayReportProvider(today),
        (previous, next) => next.whenData((report) => secondReport = report),
        fireImmediately: true,
      );
      await _waitFor(() => secondReport != null);
      expect(secondReport!.close.totalSales, 400);

      secondSub.close();
    });
  });
}
