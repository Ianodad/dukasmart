import 'dart:convert';

import '../database/day_bounds.dart';
import 'ai_query_service.dart';
import 'projection_service.dart';

/// The one-shot insight payload (spec: "computed locally in Dart,
/// deterministic, unit-tested"). Serialized compactly and sent in a
/// single Messages API call with no tools.
class ShopSnapshot {
  const ShopSnapshot(this.json);

  final Map<String, Object?> json;

  String toJsonString() => jsonEncode(json);
}

class SnapshotBuilder {
  SnapshotBuilder(this._queries);

  final AiQueryService _queries;

  static const int _maxStockProjections = 8;

  Future<ShopSnapshot> build(DateTime date) async {
    final day = localMidnight(date);
    final weekAgo = day.subtract(const Duration(days: 7));

    final today = await _queries.salesSummary(day, day);
    final topToday = await _queries.topProducts(day, day, limit: 3);
    // The 7 full days before [day].
    final previous7 =
        await _queries.salesSummary(weekAgo, day.subtract(const Duration(days: 1)));
    final sameWeekdayLastWeek = await _queries.salesSummary(weekAgo, weekAgo);
    final expensesToday = await _queries.expensesSummary(day, day);
    final expenses7 = await _queries.expensesSummary(
        day.subtract(const Duration(days: 6)), day);
    final closeToday = await _queries.dailyCloses(day, day);

    final velocities = await _queries.productVelocities(asOf: day);
    final stockProjections = projectStockRunOut(velocities);
    final net30 = await _queries.netCentsBetween(
        day.subtract(const Duration(days: 29)), day);
    final cashFlow = projectCashFlow(netCentsInWindow: net30, daysOfData: 30);

    return ShopSnapshot({
      'date': day.toIso8601String().substring(0, 10),
      'today': today,
      'top_products_today': topToday,
      'previous_7_days': previous7,
      'same_weekday_last_week': sameWeekdayLastWeek,
      'expenses_today': expensesToday,
      'expenses_last_7_days': expenses7,
      'close_today': closeToday,
      'stock_projections': [
        for (final p in stockProjections.take(_maxStockProjections)) p.toJson(),
      ],
      'cash_flow': cashFlow.toJson(),
    });
  }
}
