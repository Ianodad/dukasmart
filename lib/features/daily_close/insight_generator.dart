import '../../core/formatting/money.dart';
import '../../core/models/closed_day_report.dart';

/// Feature-local, pure-Dart rule-based insight generator for the Daily
/// Report (design D4/D13 — "no external AI"). Deterministic templates:
/// - Always states total sales.
/// - Adds an M-PESA share sentence only when `totalSales > 0`.
/// - Adds a best-seller sentence only when one exists.
/// - Adds a low-stock sentence only when there are currently low/out of
///   stock products.
/// - Adds a cash short/over sentence only when `cashDifference != 0`.
String buildInsight(ClosedDayReport report) {
  final close = report.close;
  final sentences = <String>[];

  sentences.add('Total sales for the day: ${formatCents(close.totalSales)}.');

  if (close.totalSales > 0) {
    final mpesaShare =
        ((close.mpesaSales * 100) + (close.totalSales ~/ 2)) ~/ close.totalSales;
    sentences.add('M-PESA accounted for $mpesaShare% of sales.');
  }

  final bestSeller = report.bestSeller;
  if (bestSeller != null) {
    sentences.add(
      'Best seller: ${bestSeller.name} (${bestSeller.qtySold} sold, ${formatCents(bestSeller.revenue)}).',
    );
  }

  final lowStockCount = report.lowStockNow.length;
  if (lowStockCount > 0) {
    final noun = lowStockCount == 1 ? 'product is' : 'products are';
    sentences.add('$lowStockCount $noun running low on stock.');
  }

  final diff = close.cashDifference;
  if (diff != 0) {
    final sentence = diff > 0
        ? 'Cash was over by ${formatCents(diff)}.'
        : 'Cash was short by ${formatCents(-diff)}.';
    sentences.add(sentence);
  }

  return sentences.join(' ');
}
