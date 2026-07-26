import 'package:dukasmart/core/database/database.dart';
import 'package:dukasmart/core/database/enums.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forExecutor(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Future<int> insertProduct({int? buyingPrice = 100, int? sellingPrice = 200}) async {
    final now = DateTime.now();
    return db.into(db.products).insert(
          ProductsCompanion.insert(
            name: 'Item',
            buyingPrice: Value(buyingPrice),
            sellingPrice: Value(sellingPrice),
            quantity: const Value(50),
            unit: ProductUnit.piece,
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  group('closeDay', () {
    test('computes D4 aggregates from source tables', () async {
      final productId = await insertProduct(buyingPrice: 100, sellingPrice: 200);
      final today = DateTime.now();

      await db.salesDao.completeSale(
        lines: [(productId: productId, quantity: 2)],
        method: PaymentMethod.cash,
        amountReceivedCents: 400,
      );
      await db.salesDao.completeSale(
        lines: [(productId: productId, quantity: 1)],
        method: PaymentMethod.mpesa,
        amountReceivedCents: 200,
      );
      await db.expensesDao.recordExpense(
        amountCents: 150,
        category: ExpenseCategory.airtime,
        method: PaymentMethod.cash,
        selectedDate: today,
      );

      await db.dailyCloseDao.closeDay(date: today, actualCashCents: 250, note: 'first close');

      final close = await db.dailyCloseDao.getClose(today);
      expect(close, isNotNull);
      expect(close!.totalSales, 600);
      expect(close.cashSales, 400);
      expect(close.mpesaSales, 200);
      expect(close.expenses, 150);
      expect(close.costOfGoods, 300); // (2+1) * buyingPrice 100
      expect(close.grossProfit, 300); // 600 - 300
      expect(close.netResult, 150); // 300 - 150
      expect(close.expectedCash, 250); // cashSales 400 - cashExpenses 150
      expect(close.actualCash, 250);
      expect(close.cashDifference, 0);
      expect(close.note, 'first close');
    });

    test('closing twice on the same date upserts — one row, refreshed figures', () async {
      final productId = await insertProduct(sellingPrice: 200);
      final today = DateTime.now();

      await db.dailyCloseDao.closeDay(date: today, actualCashCents: 0);
      expect(await db.select(db.dailyCloses).get(), hasLength(1));

      await db.salesDao.completeSale(
        lines: [(productId: productId, quantity: 1)],
        method: PaymentMethod.cash,
        amountReceivedCents: 200,
      );

      await db.dailyCloseDao.closeDay(date: today, actualCashCents: 200, note: 'second close');

      final rows = await db.select(db.dailyCloses).get();
      expect(rows, hasLength(1));
      expect(rows.single.totalSales, 200);
      expect(rows.single.note, 'second close');
    });

    test('Amendment A1: a cash stockPurchase expense reduces expectedCash '
        'only, not expenses/netResult', () async {
      final productId = await insertProduct(buyingPrice: 100, sellingPrice: 200);
      final today = DateTime.now();

      await db.salesDao.completeSale(
        lines: [(productId: productId, quantity: 2)],
        method: PaymentMethod.cash,
        amountReceivedCents: 400,
      );
      await db.expensesDao.recordExpense(
        amountCents: 150,
        category: ExpenseCategory.airtime,
        method: PaymentMethod.cash,
        selectedDate: today,
      );
      await db.expensesDao.recordExpense(
        amountCents: 1000,
        category: ExpenseCategory.stockPurchase,
        method: PaymentMethod.cash,
        selectedDate: today,
      );

      await db.dailyCloseDao.closeDay(date: today, actualCashCents: 0, note: 'a1 close');

      final close = await db.dailyCloseDao.getClose(today);
      expect(close, isNotNull);
      // expenses/netResult exclude the stockPurchase row.
      expect(close!.expenses, 150);
      expect(close.netResult, 50); // grossProfit 200 (400 - cogs 200) - expenses 150
      // expectedCash includes it: cashSales 400 - cashExpenses (150 + 1000)
      expect(close.expectedCash, -750);
    });
  });

  group('latestClose', () {
    test('returns null when no day has ever been closed', () async {
      expect(await db.dailyCloseDao.latestClose(), isNull);
    });

    test('returns the most recently closed day by date', () async {
      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));

      await db.dailyCloseDao.closeDay(date: yesterday, actualCashCents: 0, note: 'yesterday');
      await db.dailyCloseDao.closeDay(date: today, actualCashCents: 0, note: 'today');

      final latest = await db.dailyCloseDao.latestClose();
      expect(latest, isNotNull);
      expect(latest!.note, 'today');
    });
  });
}
