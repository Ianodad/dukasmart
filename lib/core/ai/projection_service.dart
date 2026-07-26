import '../formatting/money.dart';

/// Pure-Dart projection math (spec: "the forecasting itself is plain
/// statistics; the AI only narrates"). No database imports here — inputs
/// are computed by AiQueryService and passed in.

/// Per-product sales velocity input for [projectStockRunOut].
class ProductVelocity {
  const ProductVelocity({
    required this.productId,
    required this.name,
    required this.unitLabel,
    required this.currentQty,
    required this.soldInWindow,
    required this.windowDays,
  });

  final int productId;
  final String name;
  final String unitLabel;
  final int currentQty;

  /// Units sold in the velocity window (>= 0).
  final int soldInWindow;

  /// Effective window length in days (>= 1 when the product has sales).
  final int windowDays;
}

/// One product's run-out estimate. [daysRemaining] is null when there is
/// no sales history to estimate from ("no estimate").
class StockProjection {
  const StockProjection({
    required this.productId,
    required this.name,
    required this.unitLabel,
    required this.currentQty,
    required this.avgDailyQty,
    required this.daysRemaining,
  });

  final int productId;
  final String name;
  final String unitLabel;
  final int currentQty;
  final double avgDailyQty;
  final int? daysRemaining;

  Map<String, Object?> toJson() => {
        'name': name,
        'unit': unitLabel,
        'current_quantity': currentQty,
        'avg_sold_per_day': double.parse(avgDailyQty.toStringAsFixed(2)),
        'days_remaining': daysRemaining,
      };
}

/// 7-day cash-flow projection from a trailing window's net figure.
class CashFlowProjection {
  const CashFlowProjection({
    required this.avgDailyNetCents,
    required this.projectedNet7dCents,
    required this.daysOfData,
  });

  final int avgDailyNetCents;
  final int projectedNet7dCents;
  final int daysOfData;

  Map<String, Object?> toJson() => {
        'avg_daily_net_cents': avgDailyNetCents,
        'avg_daily_net_display': formatCents(avgDailyNetCents),
        'projected_net_7d_cents': projectedNet7dCents,
        'projected_net_7d_display': formatCents(projectedNet7dCents),
        'days_of_data': daysOfData,
      };
}

/// Estimates run-out for each product. Sorted soonest-first; products
/// with no estimate (no sales in window) sort last, keeping their input
/// order.
List<StockProjection> projectStockRunOut(List<ProductVelocity> velocities) {
  final projections = velocities.map((v) {
    if (v.soldInWindow <= 0 || v.windowDays <= 0) {
      return StockProjection(
        productId: v.productId,
        name: v.name,
        unitLabel: v.unitLabel,
        currentQty: v.currentQty,
        avgDailyQty: 0,
        daysRemaining: null,
      );
    }
    final avg = v.soldInWindow / v.windowDays;
    return StockProjection(
      productId: v.productId,
      name: v.name,
      unitLabel: v.unitLabel,
      currentQty: v.currentQty,
      avgDailyQty: avg,
      daysRemaining: (v.currentQty / avg).floor(),
    );
  }).toList();

  projections.sort((a, b) {
    if (a.daysRemaining == null && b.daysRemaining == null) return 0;
    if (a.daysRemaining == null) return 1;
    if (b.daysRemaining == null) return -1;
    return a.daysRemaining!.compareTo(b.daysRemaining!);
  });
  return projections;
}

/// Average daily net (integer division, truncates toward zero) over the
/// window, projected 7 days forward. "Net" here is money in from sales
/// minus money out on expenses — a cash-flow view, deliberately simpler
/// than the Daily Close's accounting netResult.
CashFlowProjection projectCashFlow({
  required int netCentsInWindow,
  required int daysOfData,
}) {
  if (daysOfData <= 0) {
    return const CashFlowProjection(
      avgDailyNetCents: 0,
      projectedNet7dCents: 0,
      daysOfData: 0,
    );
  }
  final avg = netCentsInWindow ~/ daysOfData;
  return CashFlowProjection(
    avgDailyNetCents: avg,
    projectedNet7dCents: avg * 7,
    daysOfData: daysOfData,
  );
}
