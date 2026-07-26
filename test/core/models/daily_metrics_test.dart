import 'package:dukasmart/core/database/database.dart';
import 'package:dukasmart/core/database/enums.dart';
import 'package:dukasmart/core/models/daily_metrics.dart';
import 'package:flutter_test/flutter_test.dart';

Product _product({
  required int id,
  required String name,
  int quantity = 10,
  int threshold = 5,
  int? buyingPrice = 100,
  int? sellingPrice = 200,
}) {
  final now = DateTime.now();
  return Product(
    id: id,
    name: name,
    barcode: null,
    imagePath: null,
    buyingPrice: buyingPrice,
    sellingPrice: sellingPrice,
    quantity: quantity,
    unit: ProductUnit.piece,
    lowStockThreshold: threshold,
    createdAt: now,
    updatedAt: now,
  );
}

Sale _sale({
  required int id,
  required int total,
  required PaymentMethod method,
}) {
  final now = DateTime.now();
  return Sale(
    id: id,
    subtotal: total,
    total: total,
    paymentMethod: method,
    amountReceived: total,
    changeAmount: 0,
    mpesaCode: null,
    createdAt: now,
  );
}

SaleItem _saleItem({
  required int saleId,
  required int productId,
  required String productName,
  required int quantity,
  required int buyingPriceSnapshot,
  required int sellingPriceSnapshot,
}) {
  return SaleItem(
    id: saleId * 100 + productId,
    saleId: saleId,
    productId: productId,
    productName: productName,
    quantity: quantity,
    buyingPriceSnapshot: buyingPriceSnapshot,
    sellingPriceSnapshot: sellingPriceSnapshot,
    total: sellingPriceSnapshot * quantity,
  );
}

Expense _expense({
  required int id,
  required int amount,
  required PaymentMethod method,
  ExpenseCategory category = ExpenseCategory.other,
}) {
  return Expense(
    id: id,
    amount: amount,
    category: category,
    description: null,
    paymentMethod: method,
    createdAt: DateTime.now(),
  );
}

void main() {
  group('computeDailyMetrics', () {
    test('computes every D4 number from a known fixture', () {
      final products = [
        _product(id: 1, name: 'Coke', quantity: 3, threshold: 5), // low stock
        _product(id: 2, name: 'Milk', quantity: 0, threshold: 5), // out of stock
        _product(id: 3, name: 'Bread', quantity: 20, threshold: 5, buyingPrice: null), // missing buy price
        _product(id: 4, name: 'Sugar', quantity: 20, threshold: 5, sellingPrice: null), // missing sell price
      ];

      final sales = [
        _sale(id: 1, total: 1000, method: PaymentMethod.cash),
        _sale(id: 2, total: 500, method: PaymentMethod.mpesa),
      ];

      final saleItems = [
        _saleItem(
          saleId: 1,
          productId: 1,
          productName: 'Coke',
          quantity: 5,
          buyingPriceSnapshot: 100,
          sellingPriceSnapshot: 200,
        ),
        _saleItem(
          saleId: 2,
          productId: 3,
          productName: 'Bread',
          quantity: 5,
          buyingPriceSnapshot: 0,
          sellingPriceSnapshot: 100,
        ),
      ];

      final expenses = [
        _expense(id: 1, amount: 200, method: PaymentMethod.cash),
        _expense(id: 2, amount: 100, method: PaymentMethod.mpesa),
      ];

      final metrics = computeDailyMetrics(
        products: products,
        sales: sales,
        saleItems: saleItems,
        expenses: expenses,
      );

      expect(metrics.totalSales, 1500);
      expect(metrics.cashSales, 1000);
      expect(metrics.mpesaSales, 500);
      expect(metrics.cogs, 500); // (5*100) + (5*0)
      expect(metrics.grossProfit, 1000); // 1500 - 500
      expect(metrics.expensesTotal, 300);
      expect(metrics.cashExpenses, 200);
      expect(metrics.netResult, 700); // 1000 - 300
      expect(metrics.txCount, 2);
      expect(metrics.lowStockCount, 2); // Coke (low) + Milk (out)
      expect(metrics.lowStock.map((p) => p.name), ['Coke']);
      expect(metrics.outOfStock.map((p) => p.name), ['Milk']);
      expect(metrics.missingBuyingPrice.map((p) => p.name), ['Bread']);
      expect(metrics.missingSellingPrice.map((p) => p.name), ['Sugar']);
      expect(metrics.bestSeller, isNotNull);
      expect(metrics.bestSeller!.name, 'Coke');
      expect(metrics.bestSeller!.qtySold, 5);
    });

    test('no sales -> null bestSeller and zeroed sale-derived numbers', () {
      final metrics = computeDailyMetrics(
        products: const [],
        sales: const [],
        saleItems: const [],
        expenses: const [],
      );

      expect(metrics.bestSeller, isNull);
      expect(metrics.totalSales, 0);
      expect(metrics.cogs, 0);
      expect(metrics.grossProfit, 0);
      expect(metrics.txCount, 0);
    });

    test('best-seller tie on quantity -> higher revenue wins', () {
      final saleItems = [
        _saleItem(
          saleId: 1,
          productId: 1,
          productName: 'A',
          quantity: 5,
          buyingPriceSnapshot: 50,
          sellingPriceSnapshot: 100, // revenue 500
        ),
        _saleItem(
          saleId: 2,
          productId: 2,
          productName: 'B',
          quantity: 5,
          buyingPriceSnapshot: 50,
          sellingPriceSnapshot: 150, // revenue 750
        ),
      ];

      final metrics = computeDailyMetrics(
        products: const [],
        sales: const [],
        saleItems: saleItems,
        expenses: const [],
      );

      expect(metrics.bestSeller!.name, 'B');
      expect(metrics.bestSeller!.revenue, 750);
    });

    test('best-seller tie on quantity and revenue -> alphabetically-first name wins', () {
      final saleItems = [
        _saleItem(
          saleId: 1,
          productId: 2,
          productName: 'Zebra',
          quantity: 5,
          buyingPriceSnapshot: 50,
          sellingPriceSnapshot: 100,
        ),
        _saleItem(
          saleId: 2,
          productId: 1,
          productName: 'Apple',
          quantity: 5,
          buyingPriceSnapshot: 50,
          sellingPriceSnapshot: 100,
        ),
      ];

      final metrics = computeDailyMetrics(
        products: const [],
        sales: const [],
        saleItems: saleItems,
        expenses: const [],
      );

      expect(metrics.bestSeller!.name, 'Apple');
    });

    test('Amendment A1: a cash stockPurchase expense reduces expected cash '
        'only, not expensesTotal/netResult', () {
      final expenses = [
        _expense(id: 1, amount: 500, method: PaymentMethod.cash), // normal
        _expense(
          id: 2,
          amount: 2000,
          method: PaymentMethod.cash,
          category: ExpenseCategory.stockPurchase,
        ),
      ];

      final metrics = computeDailyMetrics(
        products: const [],
        sales: const [],
        saleItems: const [],
        expenses: expenses,
      );

      // expensesTotal/netResult exclude the stockPurchase row.
      expect(metrics.expensesTotal, 500);
      expect(metrics.netResult, -500); // grossProfit 0 - expensesTotal 500

      // cashExpenses (and therefore expectedCash = cashSales - cashExpenses)
      // include it.
      expect(metrics.cashExpenses, 2500);
      final expectedCash = metrics.cashSales - metrics.cashExpenses;
      expect(expectedCash, -2500);
    });
  });
}
