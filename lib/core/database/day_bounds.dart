/// Half-open local-time day bounds helper (design D3 day boundary rule).
///
/// Every "today"/daily query uses:
/// `createdAt >= startOfLocalDay && createdAt < startOfNextLocalDay`.
class DayBounds {
  const DayBounds(this.start, this.end);

  final DateTime start;
  final DateTime end;
}

/// Returns the half-open local-time bounds `[start, end)` for the local
/// calendar day containing [d].
DayBounds dayBounds(DateTime d) {
  final local = d.isUtc ? d.toLocal() : d;
  final start = DateTime(local.year, local.month, local.day);
  final end = start.add(const Duration(days: 1));
  return DayBounds(start, end);
}

/// Normalizes [d] to local midnight (used for `DailyCloses.date` and the
/// backdated-expense `createdAt` rule in design D3).
DateTime localMidnight(DateTime d) {
  final local = d.isUtc ? d.toLocal() : d;
  return DateTime(local.year, local.month, local.day);
}
