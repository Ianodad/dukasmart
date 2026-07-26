import 'package:dukasmart/core/database/day_bounds.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('dayBounds returns half-open local bounds for the calendar day', () {
    final d = DateTime(2026, 7, 25, 14, 30);
    final bounds = dayBounds(d);
    expect(bounds.start, DateTime(2026, 7, 25));
    expect(bounds.end, DateTime(2026, 7, 26));
  });

  test('localMidnight normalizes any time to that day\'s midnight', () {
    final d = DateTime(2026, 7, 25, 23, 59, 59);
    expect(localMidnight(d), DateTime(2026, 7, 25));
  });
}
