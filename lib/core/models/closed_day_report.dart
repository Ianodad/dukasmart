import '../database/database.dart';
import 'best_seller.dart';

/// The frozen Daily Report contract (design D4).
///
/// - [close] financials are STORED figures for the date, labeled
///   "as at close" in the UI.
/// - [bestSeller] is derived fresh from that date's `sale_items`
///   (design D4 tie-break rules), labeled "for the day".
/// - [lowStockNow] reflects CURRENT stock levels, labeled "current".
class ClosedDayReport {
  const ClosedDayReport({
    required this.close,
    required this.bestSeller,
    required this.lowStockNow,
  });

  final DailyClose close;
  final BestSeller? bestSeller;
  final List<Product> lowStockNow;
}
