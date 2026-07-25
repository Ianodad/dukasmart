import '../database/database.dart';
import '../database/enums.dart';
import 'best_seller.dart';

/// Today's authoritative dashboard/close-day numbers (design D3/D4).
///
/// This is the single source of truth consumed by both the Home Dashboard
/// and Close Day screens — no screen recomputes its own aggregates.
class DailyMetrics {
  const DailyMetrics({
    required this.totalSales,
    required this.cashSales,
    required this.mpesaSales,
    required this.expensesTotal,
    required this.cashExpenses,
    required this.cogs,
    required this.grossProfit,
    required this.netResult,
    required this.txCount,
    required this.lowStockCount,
    required this.lowStock,
    required this.outOfStock,
    required this.missingBuyingPrice,
    required this.missingSellingPrice,
    required this.bestSeller,
  });

  // All amounts are int cents (design D2).
  final int totalSales;
  final int cashSales;
  final int mpesaSales;
  final int expensesTotal;
  final int cashExpenses;
  final int cogs;
  final int grossProfit;
  final int netResult;
  final int txCount;
  final int lowStockCount;

  final List<Product> lowStock;
  final List<Product> outOfStock;
  final List<Product> missingBuyingPrice;
  final List<Product> missingSellingPrice;

  final BestSeller? bestSeller;
}

/// Pure computation of [DailyMetrics] from already-fetched rows (design
/// D4 formulas). Kept side-effect-free and DB-free so it is directly unit
/// testable (design D10).
DailyMetrics computeDailyMetrics({
  required List<Product> products,
  required List<Sale> sales,
  required List<SaleItem> saleItems,
  required List<Expense> expenses,
}) {
  final totalSales = sales.fold<int>(0, (sum, s) => sum + s.total);
  final cashSales = sales
      .where((s) => s.paymentMethod == PaymentMethod.cash)
      .fold<int>(0, (sum, s) => sum + s.total);
  final mpesaSales = sales
      .where((s) => s.paymentMethod == PaymentMethod.mpesa)
      .fold<int>(0, (sum, s) => sum + s.total);

  final cogs = saleItems.fold<int>(0, (sum, i) => sum + i.buyingPriceSnapshot * i.quantity);
  final grossProfit = totalSales - cogs;

  final expensesTotal = expenses.fold<int>(0, (sum, e) => sum + e.amount);
  final cashExpenses = expenses
      .where((e) => e.paymentMethod == PaymentMethod.cash)
      .fold<int>(0, (sum, e) => sum + e.amount);
  final netResult = grossProfit - expensesTotal;

  final lowStock = products.where((p) => p.quantity > 0 && p.quantity <= p.lowStockThreshold).toList();
  final outOfStock = products.where((p) => p.quantity == 0).toList();
  final missingBuyingPrice = products.where((p) => p.buyingPrice == null).toList();
  final missingSellingPrice = products.where((p) => p.sellingPrice == null).toList();

  return DailyMetrics(
    totalSales: totalSales,
    cashSales: cashSales,
    mpesaSales: mpesaSales,
    expensesTotal: expensesTotal,
    cashExpenses: cashExpenses,
    cogs: cogs,
    grossProfit: grossProfit,
    netResult: netResult,
    txCount: sales.length,
    lowStockCount: lowStock.length + outOfStock.length,
    lowStock: lowStock,
    outOfStock: outOfStock,
    missingBuyingPrice: missingBuyingPrice,
    missingSellingPrice: missingSellingPrice,
    bestSeller: computeBestSeller(saleItems),
  );
}

/// Design D4 best-seller rule: highest total quantity sold; tie -> higher
/// revenue; still tied -> alphabetically-first product name. No sale
/// items -> `null`.
BestSeller? computeBestSeller(List<SaleItem> saleItems) {
  if (saleItems.isEmpty) return null;

  final byProduct = <int, ({String name, int qty, int revenue})>{};
  for (final item in saleItems) {
    final existing = byProduct[item.productId];
    if (existing == null) {
      byProduct[item.productId] = (
        name: item.productName,
        qty: item.quantity,
        revenue: item.total,
      );
    } else {
      byProduct[item.productId] = (
        name: existing.name,
        qty: existing.qty + item.quantity,
        revenue: existing.revenue + item.total,
      );
    }
  }

  final entries = byProduct.entries.toList();
  entries.sort((a, b) {
    final byQty = b.value.qty.compareTo(a.value.qty);
    if (byQty != 0) return byQty;
    final byRevenue = b.value.revenue.compareTo(a.value.revenue);
    if (byRevenue != 0) return byRevenue;
    return a.value.name.compareTo(b.value.name);
  });

  final winner = entries.first;
  return BestSeller(
    productId: winner.key,
    name: winner.value.name,
    qtySold: winner.value.qty,
    revenue: winner.value.revenue,
  );
}
