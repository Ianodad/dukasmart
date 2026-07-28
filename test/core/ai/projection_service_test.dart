import 'package:dukasmart/core/ai/projection_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('projectStockRunOut', () {
    test('steady seller: 14 sold over 14 days, 8 in stock -> 8 days left', () {
      final result = projectStockRunOut(const [
        ProductVelocity(
          productId: 1,
          name: 'Sugar 1kg',
          unitLabel: 'Packet',
          currentQty: 8,
          soldInWindow: 14,
          windowDays: 14,
        ),
      ]);
      expect(result, hasLength(1));
      expect(result.single.avgDailyQty, closeTo(1.0, 0.001));
      expect(result.single.daysRemaining, 8);
    });

    test('no sales in window -> no estimate (null daysRemaining)', () {
      final result = projectStockRunOut(const [
        ProductVelocity(
          productId: 2,
          name: 'Bread 400g',
          unitLabel: 'Piece',
          currentQty: 5,
          soldInWindow: 0,
          windowDays: 14,
        ),
      ]);
      expect(result.single.daysRemaining, isNull);
      expect(result.single.avgDailyQty, 0);
    });

    test('zero stock with sales -> 0 days remaining', () {
      final result = projectStockRunOut(const [
        ProductVelocity(
          productId: 3,
          name: 'Milk 500ml',
          unitLabel: 'Packet',
          currentQty: 0,
          soldInWindow: 7,
          windowDays: 14,
        ),
      ]);
      expect(result.single.daysRemaining, 0);
    });

    test('sorts soonest run-out first, no-estimate rows last', () {
      final result = projectStockRunOut(const [
        ProductVelocity(
            productId: 1, name: 'A', unitLabel: 'Piece', currentQty: 20, soldInWindow: 2, windowDays: 14),
        ProductVelocity(
            productId: 2, name: 'B', unitLabel: 'Piece', currentQty: 5, soldInWindow: 0, windowDays: 14),
        ProductVelocity(
            productId: 3, name: 'C', unitLabel: 'Piece', currentQty: 2, soldInWindow: 14, windowDays: 14),
      ]);
      expect(result.map((p) => p.name).toList(), ['C', 'A', 'B']);
    });

    test('toJson carries name, days_remaining, and current qty', () {
      final json = projectStockRunOut(const [
        ProductVelocity(
            productId: 1,
            name: 'Sugar 1kg',
            unitLabel: 'Packet',
            currentQty: 8,
            soldInWindow: 14,
            windowDays: 14),
      ]).single.toJson();
      expect(json['name'], 'Sugar 1kg');
      expect(json['days_remaining'], 8);
      expect(json['current_quantity'], 8);
      expect(json['unit'], 'Packet');
    });
  });

  group('projectCashFlow', () {
    test('30 days of KES 300 net/day -> KES 2,100 projected over 7 days', () {
      final result = projectCashFlow(netCentsInWindow: 900000, daysOfData: 30);
      expect(result.avgDailyNetCents, 30000);
      expect(result.projectedNet7dCents, 210000);
      expect(result.daysOfData, 30);
    });

    test('negative net projects negative', () {
      final result = projectCashFlow(netCentsInWindow: -300000, daysOfData: 30);
      expect(result.avgDailyNetCents, -10000);
      expect(result.projectedNet7dCents, -70000);
    });

    test('zero days of data -> zeros, no division error', () {
      final result = projectCashFlow(netCentsInWindow: 0, daysOfData: 0);
      expect(result.avgDailyNetCents, 0);
      expect(result.projectedNet7dCents, 0);
      expect(result.daysOfData, 0);
    });

    test('toJson includes KES display strings from formatCents', () {
      final json = projectCashFlow(netCentsInWindow: 900000, daysOfData: 30).toJson();
      expect(json['avg_daily_net_display'], 'KES 300');
      expect(json['projected_net_7d_display'], 'KES 2,100');
    });
  });
}
