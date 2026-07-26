import 'package:dukasmart/core/database/database.dart';
import 'package:dukasmart/core/database/enums.dart';
import 'package:dukasmart/core/models/best_seller.dart';
import 'package:dukasmart/core/models/closed_day_report.dart';
import 'package:dukasmart/features/daily_close/insight_generator.dart';
import 'package:flutter_test/flutter_test.dart';

DailyClose _close({
  int totalSales = 0,
  int cashSales = 0,
  int mpesaSales = 0,
  int cashDifference = 0,
}) {
  final now = DateTime.now();
  return DailyClose(
    id: 1,
    date: DateTime(now.year, now.month, now.day),
    totalSales: totalSales,
    cashSales: cashSales,
    mpesaSales: mpesaSales,
    expenses: 0,
    costOfGoods: 0,
    grossProfit: totalSales,
    netResult: totalSales,
    expectedCash: cashSales,
    actualCash: cashSales + cashDifference,
    cashDifference: cashDifference,
    note: null,
    createdAt: now,
  );
}

Product _product({required int id, required String name, int quantity = 2, int threshold = 5}) {
  final now = DateTime.now();
  return Product(
    id: id,
    name: name,
    barcode: null,
    imagePath: null,
    buyingPrice: 100,
    sellingPrice: 200,
    quantity: quantity,
    unit: ProductUnit.piece,
    lowStockThreshold: threshold,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('buildInsight', () {
    test('always states total sales, even when zero', () {
      final report = ClosedDayReport(close: _close(), bestSeller: null, lowStockNow: const []);
      final insight = buildInsight(report);
      expect(insight, contains('Total sales for the day: KES 0.'));
      expect(insight, isNot(contains('M-PESA accounted for')));
    });

    test('adds M-PESA share sentence only when totalSales > 0', () {
      final report = ClosedDayReport(
        close: _close(totalSales: 1000, cashSales: 750, mpesaSales: 250),
        bestSeller: null,
        lowStockNow: const [],
      );
      final insight = buildInsight(report);
      expect(insight, contains('M-PESA accounted for 25% of sales.'));
    });

    test('computes the M-PESA share with rounded integer arithmetic (1/3 -> 33%)', () {
      final report = ClosedDayReport(
        close: _close(totalSales: 3, cashSales: 2, mpesaSales: 1),
        bestSeller: null,
        lowStockNow: const [],
      );
      final insight = buildInsight(report);
      expect(insight, contains('M-PESA accounted for 33% of sales.'));
    });

    test('adds best-seller sentence only when one exists', () {
      const bestSeller = BestSeller(productId: 1, name: 'Coke', qtySold: 5, revenue: 1000);
      final withBestSeller = ClosedDayReport(
        close: _close(totalSales: 1000),
        bestSeller: bestSeller,
        lowStockNow: const [],
      );
      final withoutBestSeller = ClosedDayReport(
        close: _close(totalSales: 1000),
        bestSeller: null,
        lowStockNow: const [],
      );

      expect(buildInsight(withBestSeller), contains('Best seller: Coke (5 sold, KES 10).'));
      expect(buildInsight(withoutBestSeller), isNot(contains('Best seller:')));
    });

    test('adds low-stock sentence only when there are low-stock products', () {
      final withLowStock = ClosedDayReport(
        close: _close(),
        bestSeller: null,
        lowStockNow: [_product(id: 1, name: 'Bread')],
      );
      final withoutLowStock = ClosedDayReport(close: _close(), bestSeller: null, lowStockNow: const []);

      expect(buildInsight(withLowStock), contains('1 product is running low on stock.'));
      expect(buildInsight(withoutLowStock), isNot(contains('running low on stock')));
    });

    test('pluralizes the low-stock sentence for more than one product', () {
      final report = ClosedDayReport(
        close: _close(),
        bestSeller: null,
        lowStockNow: [_product(id: 1, name: 'Bread'), _product(id: 2, name: 'Milk')],
      );
      expect(buildInsight(report), contains('2 products are running low on stock.'));
    });

    test('adds cash short/over sentence only when cashDifference != 0', () {
      final short = ClosedDayReport(close: _close(cashDifference: -150), bestSeller: null, lowStockNow: const []);
      final over = ClosedDayReport(close: _close(cashDifference: 150), bestSeller: null, lowStockNow: const []);
      final exact = ClosedDayReport(close: _close(cashDifference: 0), bestSeller: null, lowStockNow: const []);

      expect(buildInsight(short), contains('Cash was short by KES 1.50.'));
      expect(buildInsight(over), contains('Cash was over by KES 1.50.'));
      expect(buildInsight(exact), isNot(contains('Cash was')));
    });
  });
}
