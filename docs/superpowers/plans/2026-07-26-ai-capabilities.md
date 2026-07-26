# DukaSmart AI Capabilities Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add online-only AI features (natural-language Q&A over shop data, AI daily-close insight, projections) per the approved spec at `docs/superpowers/specs/2026-07-26-ai-capabilities-design.md`, without weakening the offline core.

**Architecture:** A provider-agnostic `AiGateway` in `lib/core/ai/` talks to the Anthropic Messages API over raw HTTPS (no Dart SDK exists). Free-form Q&A uses a manual tool-use loop over 6 read-only tools backed by a new `AiQueryService`; the daily-close insight uses a one-shot prompt built from a locally computed `ShopSnapshot`. Projections are pure Dart math (`ProjectionService`) that the AI only narrates. All AI surfaces are gated on a build-time API key (`--dart-define=ANTHROPIC_API_KEY`); without it the app is unchanged.

**Tech Stack:** Flutter 3.38.3, Riverpod 2.6 (`Notifier` pattern), Drift/SQLite, go_router, `http` package (new dependency; its `MockClient` from `package:http/testing.dart` covers tests — no mocking library needed).

**Conventions that bind every task:**
- Money is integer cents everywhere; display strings come ONLY from `formatCents()` in `lib/core/formatting/money.dart`. Tool/snapshot JSON carries both `*_cents` ints and `*_display` strings.
- Day filtering uses the half-open helpers in `lib/core/database/day_bounds.dart` (`dayBounds`, `localMidnight`).
- Run tests with `flutter test <path>` (needs `export PATH="$HOME/flutter/bin:$PATH"` first). Expect the Drift native prerequisites from README (clang/cmake/ninja) to already be installed.
- The AI never writes to the database. All 6 tools are read-only.
- Commit after every task (each task ends with a commit step).

---

## File Structure

```
lib/core/ai/
  ai_config.dart            # NEW — build-time key, model const, endpoint
  projection_service.dart   # NEW — pure math: stock run-out, cash-flow
  ai_query_service.dart     # NEW — read-only aggregates over AppDatabase
  snapshot_builder.dart     # NEW — ShopSnapshot JSON for one-shot insight
  duka_tools.dart           # NEW — 6 tool definitions + dispatcher
  ai_gateway.dart           # NEW — AiMessage/AiGateway/AiUnavailableError
  anthropic_gateway.dart    # NEW — Messages API impl + tool loop
  ai_providers.dart         # NEW — Riverpod wiring incl. aiInsightProvider
lib/features/assistant/
  ask_controller.dart       # NEW — AskState + AutoDisposeNotifier
  ask_screen.dart           # NEW — Q&A thread UI
lib/app/router.dart         # MODIFY — add /home/ask route
lib/features/dashboard/dashboard_screen.dart      # MODIFY — gated ask bar
lib/features/daily_close/daily_report_screen.dart # MODIFY — AI insight card
pubspec.yaml                # MODIFY — add http

test/core/ai/
  projection_service_test.dart   # NEW
  ai_query_service_test.dart     # NEW
  snapshot_builder_test.dart     # NEW
  duka_tools_test.dart           # NEW
  anthropic_gateway_test.dart    # NEW
test/features/assistant/
  ask_controller_test.dart       # NEW
  ask_screen_test.dart           # NEW
test/features/dashboard/dashboard_screen_test.dart      # MODIFY — ask bar cases
test/features/daily_close/daily_report_screen_test.dart # MODIFY — AI card cases
```

---

### Task 1: `http` dependency + AiConfig

**Files:**
- Modify: `pubspec.yaml` (dependencies block, after `path: ^1.9.1`)
- Create: `lib/core/ai/ai_config.dart`

- [ ] **Step 1: Add the dependency**

In `pubspec.yaml`, add `http: ^1.2.0` at the end of the `dependencies:` block (after the `path: ^1.9.1` line):

```yaml
  path_provider: ^2.1.6
  path: ^1.9.1
  http: ^1.2.0
```

- [ ] **Step 2: Fetch packages**

Run: `flutter pub get`
Expected: `Got dependencies!` with `http` resolved at 1.2.x or newer.

- [ ] **Step 3: Create AiConfig**

Create `lib/core/ai/ai_config.dart`:

```dart
/// Build-time AI configuration (spec: demo/portfolio deployment).
///
/// The Anthropic API key is injected at build time:
///   flutter run --dart-define=ANTHROPIC_API_KEY=sk-ant-...
///
/// When the define is absent, [isConfigured] is false, every AI surface
/// stays hidden, and no AI network code path is reachable — the app is
/// byte-for-byte today's offline app. The key is never committed.
class AiConfig {
  AiConfig._();

  static const String apiKey = String.fromEnvironment('ANTHROPIC_API_KEY');

  /// Single const so switching models later is a one-line change.
  static const String model = 'claude-opus-5';

  static const String endpoint = 'https://api.anthropic.com/v1/messages';
  static const String anthropicVersion = '2023-06-01';

  static bool get isConfigured => apiKey.isNotEmpty;
}
```

- [ ] **Step 4: Verify it analyzes**

Run: `flutter analyze lib/core/ai/ai_config.dart`
Expected: `No issues found!`

- [ ] **Step 5: Commit**

```bash
git add pubspec.yaml pubspec.lock lib/core/ai/ai_config.dart
git commit -m "feat(ai): add http dependency and build-time AiConfig"
```

---

### Task 2: ProjectionService (pure math)

Pure Dart, no database imports. Stock run-out = `currentQty / avgDailyQty` where `avgDailyQty = soldInWindow / windowDays`; products with no sales in the window get `daysRemaining = null` ("no estimate"). Cash-flow = average daily net (sales − expenses, integer division) over a window, projected 7 days.

**Files:**
- Create: `lib/core/ai/projection_service.dart`
- Test: `test/core/ai/projection_service_test.dart`

- [ ] **Step 1: Write the failing tests**

Create `test/core/ai/projection_service_test.dart`:

```dart
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
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/core/ai/projection_service_test.dart`
Expected: FAIL — `Error: Couldn't resolve the package 'dukasmart/core/ai/projection_service.dart'` (file does not exist yet).

- [ ] **Step 3: Implement**

Create `lib/core/ai/projection_service.dart`:

```dart
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
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/core/ai/projection_service_test.dart`
Expected: `All tests passed!` (9 tests)

- [ ] **Step 5: Commit**

```bash
git add lib/core/ai/projection_service.dart test/core/ai/projection_service_test.dart
git commit -m "feat(ai): pure-Dart projection service (stock run-out, cash-flow)"
```

---

### Task 3: AiQueryService (read-only aggregates)

One class composing `AppDatabase` directly (existing DAOs are NOT modified — spec). Every public method returns a `jsonEncode`-ready `Map<String, Object?>` carrying both `*_cents` ints and `*_display` strings. Remember: the in-memory test database seeds 5 demo products on create (Coca-Cola 500ml qty 24/thr 6, Brookside Milk 500ml 12/5, Jogoo Maize Flour 2kg 10/4, Sugar 1kg 8/4, Bread 400g 5/3 — see `database.dart`).

**Files:**
- Create: `lib/core/ai/ai_query_service.dart`
- Test: `test/core/ai/ai_query_service_test.dart`

- [ ] **Step 1: Write the failing tests**

Create `test/core/ai/ai_query_service_test.dart`:

```dart
import 'package:dukasmart/core/ai/ai_query_service.dart';
import 'package:dukasmart/core/database/database.dart';
import 'package:dukasmart/core/database/enums.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late AiQueryService service;

  setUp(() {
    db = AppDatabase.forExecutor(NativeDatabase.memory());
    service = AiQueryService(db);
  });

  tearDown(() async {
    await db.close();
  });

  /// Seeded product ids are insertion-ordered: 1 Coca-Cola (7000c sell),
  /// 2 Milk (6500c), 3 Jogoo (21000c), 4 Sugar (17000c), 5 Bread (6500c).
  Future<void> sellToday(int productId, int qty, PaymentMethod method) async {
    final product = await (db.select(db.products)
          ..where((t) => t.id.equals(productId)))
        .getSingle();
    final total = product.sellingPrice! * qty;
    await db.salesDao.completeSale(
      lines: [(productId: productId, quantity: qty)],
      method: method,
      amountReceivedCents: total,
    );
  }

  group('salesSummary', () {
    test('totals and cash/mpesa split for today', () async {
      await sellToday(1, 1, PaymentMethod.cash); // 7000
      await sellToday(2, 1, PaymentMethod.mpesa); // 6500
      final now = DateTime.now();

      final json = await service.salesSummary(now, now);
      expect(json['sale_count'], 2);
      expect(json['total_sales_cents'], 13500);
      expect(json['cash_sales_cents'], 7000);
      expect(json['mpesa_sales_cents'], 6500);
      expect(json['total_sales_display'], 'KES 135');
    });

    test('empty range -> zeros', () async {
      final lastWeek = DateTime.now().subtract(const Duration(days: 7));
      final json = await service.salesSummary(lastWeek, lastWeek);
      expect(json['sale_count'], 0);
      expect(json['total_sales_cents'], 0);
    });
  });

  test('topProducts aggregates by product, best first', () async {
    await sellToday(1, 2, PaymentMethod.cash);
    await sellToday(2, 1, PaymentMethod.cash);
    final now = DateTime.now();

    final json = await service.topProducts(now, now, limit: 5);
    final products = json['products'] as List;
    expect(products, hasLength(2));
    final first = products.first as Map;
    expect(first['name'], 'Coca-Cola 500ml');
    expect(first['quantity_sold'], 2);
    expect(first['revenue_cents'], 14000);
  });

  test('expensesSummary groups by category label', () async {
    await db.expensesDao.recordExpense(
      amountCents: 20000,
      category: ExpenseCategory.stockTransport,
      method: PaymentMethod.cash,
      selectedDate: DateTime.now(),
    );
    await db.expensesDao.recordExpense(
      amountCents: 5000,
      category: ExpenseCategory.airtime,
      method: PaymentMethod.mpesa,
      selectedDate: DateTime.now(),
    );
    final now = DateTime.now();

    final json = await service.expensesSummary(now, now);
    expect(json['total_expenses_cents'], 25000);
    final byCategory = json['by_category'] as List;
    expect(byCategory, hasLength(2));
    final transport =
        byCategory.cast<Map>().singleWhere((c) => c['category'] == 'Stock transport');
    expect(transport['total_cents'], 20000);
  });

  group('stockLevels', () {
    test('all products with low flags', () async {
      final json = await service.stockLevels();
      final products = (json['products'] as List).cast<Map>();
      expect(products, hasLength(5));
      expect(products.every((p) => p['is_low'] == false), isTrue);
    });

    test('lowOnly filters to low/out-of-stock products', () async {
      // Bread: qty 5, threshold 3 -> selling 2 leaves 3 <= 3 (low).
      await sellToday(5, 2, PaymentMethod.cash);
      final json = await service.stockLevels(lowOnly: true);
      final products = (json['products'] as List).cast<Map>();
      expect(products, hasLength(1));
      expect(products.single['name'], 'Bread 400g');
      expect(products.single['is_low'], true);
    });
  });

  test('dailyCloses returns closed days in range, newest first', () async {
    await sellToday(1, 1, PaymentMethod.cash);
    await db.dailyCloseDao.closeDay(date: DateTime.now(), actualCashCents: 7000);
    final now = DateTime.now();

    final json = await service.dailyCloses(now.subtract(const Duration(days: 6)), now);
    final closes = (json['closes'] as List).cast<Map>();
    expect(closes, hasLength(1));
    expect(closes.single['total_sales_cents'], 7000);
    expect(closes.single['cash_difference_cents'], 0);
  });

  test('productVelocities: first sale today -> 1-day effective window', () async {
    await sellToday(1, 2, PaymentMethod.cash);
    final velocities = await service.productVelocities();
    final coke = velocities.singleWhere((v) => v.name == 'Coca-Cola 500ml');
    expect(coke.soldInWindow, 2);
    expect(coke.windowDays, 1);
    expect(coke.currentQty, 22);
    final bread = velocities.singleWhere((v) => v.name == 'Bread 400g');
    expect(bread.soldInWindow, 0);
  });

  test('netCentsBetween = sales minus expenses', () async {
    await sellToday(1, 1, PaymentMethod.cash); // +7000
    await db.expensesDao.recordExpense(
      amountCents: 500,
      category: ExpenseCategory.airtime,
      method: PaymentMethod.cash,
      selectedDate: DateTime.now(),
    ); // -500
    final now = DateTime.now();
    expect(await service.netCentsBetween(now, now), 6500);
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/core/ai/ai_query_service_test.dart`
Expected: FAIL — package resolve error for `ai_query_service.dart`.

- [ ] **Step 3: Implement**

Create `lib/core/ai/ai_query_service.dart`:

```dart
import 'package:drift/drift.dart';

import '../database/database.dart';
import '../database/day_bounds.dart';
import '../database/enums.dart';
import '../formatting/money.dart';
import 'projection_service.dart';

/// Read-only aggregate queries for the AI layer (spec: single service in
/// lib/core/ai/ composing the database; existing DAOs are not modified).
/// Every JSON map carries raw `*_cents` ints AND `*_display` strings from
/// [formatCents] — the model is instructed to quote display strings and
/// never do its own arithmetic on money.
class AiQueryService {
  AiQueryService(this._db);

  final AppDatabase _db;

  static String _dateString(DateTime d) =>
      localMidnight(d).toIso8601String().substring(0, 10);

  /// Half-open bounds covering local calendar days [from]..[to] inclusive.
  (DateTime, DateTime) _rangeBounds(DateTime from, DateTime to) =>
      (dayBounds(from).start, dayBounds(to).end);

  Future<List<Sale>> _salesBetween(DateTime from, DateTime to) {
    final (start, end) = _rangeBounds(from, to);
    return (_db.select(_db.sales)
          ..where((t) =>
              t.createdAt.isBiggerOrEqualValue(start) &
              t.createdAt.isSmallerThanValue(end)))
        .get();
  }

  Future<Map<String, Object?>> salesSummary(DateTime from, DateTime to) async {
    final sales = await _salesBetween(from, to);
    final total = sales.fold<int>(0, (sum, s) => sum + s.total);
    final cash = sales
        .where((s) => s.paymentMethod == PaymentMethod.cash)
        .fold<int>(0, (sum, s) => sum + s.total);
    final mpesa = total - cash;
    return {
      'from': _dateString(from),
      'to': _dateString(to),
      'sale_count': sales.length,
      'total_sales_cents': total,
      'total_sales_display': formatCents(total),
      'cash_sales_cents': cash,
      'cash_sales_display': formatCents(cash),
      'mpesa_sales_cents': mpesa,
      'mpesa_sales_display': formatCents(mpesa),
    };
  }

  Future<Map<String, Object?>> topProducts(
    DateTime from,
    DateTime to, {
    int limit = 5,
  }) async {
    final sales = await _salesBetween(from, to);
    if (sales.isEmpty) {
      return {'from': _dateString(from), 'to': _dateString(to), 'products': []};
    }
    final saleIds = sales.map((s) => s.id).toList();
    final items = await (_db.select(_db.saleItems)
          ..where((t) => t.saleId.isIn(saleIds)))
        .get();

    final byName = <String, ({int qty, int revenue})>{};
    for (final item in items) {
      final prev = byName[item.productName] ?? (qty: 0, revenue: 0);
      byName[item.productName] =
          (qty: prev.qty + item.quantity, revenue: prev.revenue + item.total);
    }
    final ranked = byName.entries.toList()
      ..sort((a, b) {
        final byQty = b.value.qty.compareTo(a.value.qty);
        return byQty != 0 ? byQty : b.value.revenue.compareTo(a.value.revenue);
      });

    return {
      'from': _dateString(from),
      'to': _dateString(to),
      'products': [
        for (final e in ranked.take(limit))
          {
            'name': e.key,
            'quantity_sold': e.value.qty,
            'revenue_cents': e.value.revenue,
            'revenue_display': formatCents(e.value.revenue),
          },
      ],
    };
  }

  Future<Map<String, Object?>> expensesSummary(DateTime from, DateTime to) async {
    final (start, end) = _rangeBounds(from, to);
    final rows = await (_db.select(_db.expenses)
          ..where((t) =>
              t.createdAt.isBiggerOrEqualValue(start) &
              t.createdAt.isSmallerThanValue(end)))
        .get();

    final total = rows.fold<int>(0, (sum, e) => sum + e.amount);
    final byCategory = <ExpenseCategory, ({int total, int count})>{};
    for (final e in rows) {
      final prev = byCategory[e.category] ?? (total: 0, count: 0);
      byCategory[e.category] =
          (total: prev.total + e.amount, count: prev.count + 1);
    }
    final ranked = byCategory.entries.toList()
      ..sort((a, b) => b.value.total.compareTo(a.value.total));

    return {
      'from': _dateString(from),
      'to': _dateString(to),
      'total_expenses_cents': total,
      'total_expenses_display': formatCents(total),
      'by_category': [
        for (final e in ranked)
          {
            'category': e.key.label,
            'total_cents': e.value.total,
            'total_display': formatCents(e.value.total),
            'count': e.value.count,
          },
      ],
    };
  }

  Future<Map<String, Object?>> stockLevels({bool lowOnly = false}) async {
    final products = await (_db.select(_db.products)
          ..orderBy([(t) => OrderingTerm.asc(t.quantity)]))
        .get();
    final rows = [
      for (final p in products)
        if (!lowOnly || p.quantity <= p.lowStockThreshold)
          {
            'name': p.name,
            'quantity': p.quantity,
            'unit': p.unit.label,
            'low_stock_threshold': p.lowStockThreshold,
            'is_low': p.quantity <= p.lowStockThreshold,
          },
    ];
    return {'product_count': rows.length, 'products': rows};
  }

  Future<Map<String, Object?>> dailyCloses(DateTime from, DateTime to) async {
    final start = localMidnight(from);
    final end = localMidnight(to);
    final closes = await (_db.select(_db.dailyCloses)
          ..where((t) =>
              t.date.isBiggerOrEqualValue(start) & t.date.isSmallerOrEqualValue(end))
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .get();
    return {
      'from': _dateString(from),
      'to': _dateString(to),
      'closes': [
        for (final c in closes)
          {
            'date': _dateString(c.date),
            'total_sales_cents': c.totalSales,
            'total_sales_display': formatCents(c.totalSales),
            'expenses_cents': c.expenses,
            'expenses_display': formatCents(c.expenses),
            'net_result_cents': c.netResult,
            'net_result_display': formatCents(c.netResult),
            'cash_difference_cents': c.cashDifference,
            'cash_difference_display': formatCents(c.cashDifference),
          },
      ],
    };
  }

  /// Per-product velocity inputs for [projectStockRunOut]. The effective
  /// window is `min(windowDays, days since that product's first sale in
  /// the window)`, so a product first sold 3 days ago is averaged over 3
  /// days, not 14 (spec: "only days since first sale of that product").
  Future<List<ProductVelocity>> productVelocities({
    DateTime? asOf,
    int windowDays = 14,
  }) async {
    final now = asOf ?? DateTime.now();
    final windowStart =
        localMidnight(now).subtract(Duration(days: windowDays - 1));
    final windowEnd = dayBounds(now).end;

    final sales = await (_db.select(_db.sales)
          ..where((t) =>
              t.createdAt.isBiggerOrEqualValue(windowStart) &
              t.createdAt.isSmallerThanValue(windowEnd)))
        .get();
    final saleById = {for (final s in sales) s.id: s};
    final items = sales.isEmpty
        ? <SaleItem>[]
        : await (_db.select(_db.saleItems)
              ..where((t) => t.saleId.isIn(saleById.keys.toList())))
            .get();

    final soldByProduct = <int, int>{};
    final firstSaleByProduct = <int, DateTime>{};
    for (final item in items) {
      soldByProduct[item.productId] =
          (soldByProduct[item.productId] ?? 0) + item.quantity;
      final saleAt = saleById[item.saleId]!.createdAt;
      final existing = firstSaleByProduct[item.productId];
      if (existing == null || saleAt.isBefore(existing)) {
        firstSaleByProduct[item.productId] = saleAt;
      }
    }

    final products = await _db.select(_db.products).get();
    return [
      for (final p in products)
        () {
          final sold = soldByProduct[p.id] ?? 0;
          var effectiveDays = windowDays;
          if (sold > 0) {
            final firstDay = localMidnight(firstSaleByProduct[p.id]!);
            final daysSinceFirst =
                localMidnight(now).difference(firstDay).inDays + 1;
            effectiveDays = daysSinceFirst.clamp(1, windowDays);
          }
          return ProductVelocity(
            productId: p.id,
            name: p.name,
            unitLabel: p.unit.label,
            currentQty: p.quantity,
            soldInWindow: sold,
            windowDays: effectiveDays,
          );
        }(),
    ];
  }

  /// Money in from sales minus money out on expenses (all categories) —
  /// the cash-flow input for [projectCashFlow]. Deliberately simpler than
  /// the Daily Close's accounting netResult.
  Future<int> netCentsBetween(DateTime from, DateTime to) async {
    final sales = await _salesBetween(from, to);
    final (start, end) = _rangeBounds(from, to);
    final expenses = await (_db.select(_db.expenses)
          ..where((t) =>
              t.createdAt.isBiggerOrEqualValue(start) &
              t.createdAt.isSmallerThanValue(end)))
        .get();
    final salesTotal = sales.fold<int>(0, (sum, s) => sum + s.total);
    final expensesTotal = expenses.fold<int>(0, (sum, e) => sum + e.amount);
    return salesTotal - expensesTotal;
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/core/ai/ai_query_service_test.dart`
Expected: `All tests passed!` (9 tests)

- [ ] **Step 5: Commit**

```bash
git add lib/core/ai/ai_query_service.dart test/core/ai/ai_query_service_test.dart
git commit -m "feat(ai): read-only AiQueryService aggregates over the local database"
```

---

### Task 4: ShopSnapshot + SnapshotBuilder

Assembles the one-shot insight payload from AiQueryService + ProjectionService. Pure assembly — no formatting logic of its own.

**Files:**
- Create: `lib/core/ai/snapshot_builder.dart`
- Test: `test/core/ai/snapshot_builder_test.dart`

- [ ] **Step 1: Write the failing tests**

Create `test/core/ai/snapshot_builder_test.dart`:

```dart
import 'dart:convert';

import 'package:dukasmart/core/ai/ai_query_service.dart';
import 'package:dukasmart/core/ai/snapshot_builder.dart';
import 'package:dukasmart/core/database/database.dart';
import 'package:dukasmart/core/database/enums.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late SnapshotBuilder builder;

  setUp(() {
    db = AppDatabase.forExecutor(NativeDatabase.memory());
    builder = SnapshotBuilder(AiQueryService(db));
  });

  tearDown(() async {
    await db.close();
  });

  test('snapshot carries today, comparisons, expenses, close, projections', () async {
    // One cash sale of seeded product 1 (Coca-Cola, 7000c) + one expense.
    await db.salesDao.completeSale(
      lines: [(productId: 1, quantity: 2)],
      method: PaymentMethod.cash,
      amountReceivedCents: 14000,
    );
    await db.expensesDao.recordExpense(
      amountCents: 3000,
      category: ExpenseCategory.stockTransport,
      method: PaymentMethod.cash,
      selectedDate: DateTime.now(),
    );
    await db.dailyCloseDao.closeDay(date: DateTime.now(), actualCashCents: 11000);

    final snapshot = await builder.build(DateTime.now());
    final json = snapshot.json;

    expect(json['date'], isA<String>());
    expect((json['today'] as Map)['total_sales_cents'], 14000);
    expect((json['top_products_today'] as Map)['products'], isNotEmpty);
    expect(json['previous_7_days'], isA<Map>());
    expect(json['same_weekday_last_week'], isA<Map>());
    expect((json['expenses_today'] as Map)['total_expenses_cents'], 3000);
    expect(json['expenses_last_7_days'], isA<Map>());
    expect((json['close_today'] as Map)['closes'], hasLength(1));
    expect(json['stock_projections'], isA<List>());
    expect((json['cash_flow'] as Map)['projected_net_7d_cents'], isA<int>());

    // The whole snapshot must be jsonEncode-able (no DateTime leaks).
    expect(() => snapshot.toJsonString(), returnsNormally);
    expect(jsonDecode(snapshot.toJsonString()), isA<Map<String, Object?>>());
  });

  test('stock projections are capped at 8 entries', () async {
    final snapshot = await builder.build(DateTime.now());
    expect((snapshot.json['stock_projections'] as List).length, lessThanOrEqualTo(8));
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/core/ai/snapshot_builder_test.dart`
Expected: FAIL — package resolve error for `snapshot_builder.dart`.

- [ ] **Step 3: Implement**

Create `lib/core/ai/snapshot_builder.dart`:

```dart
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
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/core/ai/snapshot_builder_test.dart`
Expected: `All tests passed!` (2 tests)

- [ ] **Step 5: Commit**

```bash
git add lib/core/ai/snapshot_builder.dart test/core/ai/snapshot_builder_test.dart
git commit -m "feat(ai): ShopSnapshot builder for one-shot insight calls"
```

---

### Task 5: AiGateway types + DukaToolDispatcher

Two files: `ai_gateway.dart` (the provider-agnostic seam — message/error types + abstract gateway) and `duka_tools.dart` (the 6 read-only Anthropic tool definitions + the dispatcher that maps tool calls to AiQueryService). The dispatcher never throws for bad model input — it returns `{"error": ...}` JSON so the model can self-correct.

**Files:**
- Create: `lib/core/ai/ai_gateway.dart`
- Create: `lib/core/ai/duka_tools.dart`
- Test: `test/core/ai/duka_tools_test.dart`

- [ ] **Step 1: Write the failing tests**

Create `test/core/ai/duka_tools_test.dart`:

```dart
import 'dart:convert';

import 'package:dukasmart/core/ai/ai_query_service.dart';
import 'package:dukasmart/core/ai/duka_tools.dart';
import 'package:dukasmart/core/database/database.dart';
import 'package:dukasmart/core/database/enums.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late DukaToolDispatcher dispatcher;

  setUp(() {
    db = AppDatabase.forExecutor(NativeDatabase.memory());
    dispatcher = DukaToolDispatcher(AiQueryService(db));
  });

  tearDown(() async {
    await db.close();
  });

  String today() => DateTime.now().toIso8601String().substring(0, 10);

  test('exposes exactly the 6 read-only tools from the spec', () {
    final names = DukaToolDispatcher.toolDefinitions
        .map((t) => t['name'])
        .toSet();
    expect(names, {
      'get_sales_summary',
      'get_top_products',
      'get_expenses',
      'get_stock_levels',
      'get_daily_closes',
      'get_projections',
    });
    // Every definition is a valid Anthropic tool shape.
    for (final def in DukaToolDispatcher.toolDefinitions) {
      expect(def['description'], isA<String>());
      expect((def['input_schema'] as Map)['type'], 'object');
    }
  });

  test('get_sales_summary returns totals for today', () async {
    await db.salesDao.completeSale(
      lines: [(productId: 1, quantity: 1)], // Coca-Cola 7000c
      method: PaymentMethod.cash,
      amountReceivedCents: 7000,
    );
    final out = await dispatcher
        .execute('get_sales_summary', {'from': today(), 'to': today()});
    final json = jsonDecode(out) as Map<String, dynamic>;
    expect(json['total_sales_cents'], 7000);
    expect(json['total_sales_display'], 'KES 70');
  });

  test('get_stock_levels with low_only filters', () async {
    // Bread (id 5): qty 5, threshold 3 -> sell 2 makes it low.
    await db.salesDao.completeSale(
      lines: [(productId: 5, quantity: 2)],
      method: PaymentMethod.cash,
      amountReceivedCents: 13000,
    );
    final out = await dispatcher.execute('get_stock_levels', {'low_only': true});
    final json = jsonDecode(out) as Map<String, dynamic>;
    expect(json['product_count'], 1);
    expect((json['products'] as List).single['name'], 'Bread 400g');
  });

  test('get_projections returns stock projections and cash flow', () async {
    final out = await dispatcher.execute('get_projections', {});
    final json = jsonDecode(out) as Map<String, dynamic>;
    expect(json['stock_projections'], isA<List>());
    expect((json['cash_flow'] as Map)['days_of_data'], 30);
  });

  test('bad date input -> error JSON, never a throw', () async {
    final out = await dispatcher
        .execute('get_sales_summary', {'from': 'yesterday', 'to': today()});
    final json = jsonDecode(out) as Map<String, dynamic>;
    expect(json['error'], contains('from'));
  });

  test('missing date input -> error JSON', () async {
    final out = await dispatcher.execute('get_expenses', {});
    final json = jsonDecode(out) as Map<String, dynamic>;
    expect(json['error'], isA<String>());
  });

  test('unknown tool -> error JSON', () async {
    final out = await dispatcher.execute('get_weather', {});
    final json = jsonDecode(out) as Map<String, dynamic>;
    expect(json['error'], 'Unknown tool: get_weather');
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/core/ai/duka_tools_test.dart`
Expected: FAIL — package resolve error for `duka_tools.dart`.

- [ ] **Step 3: Implement the gateway types**

Create `lib/core/ai/ai_gateway.dart`:

```dart
import 'duka_tools.dart';
import 'snapshot_builder.dart';

/// The provider-agnostic AI seam (spec: "the ONLY seam to the network").
/// Features depend on this interface via Riverpod — never on the
/// Anthropic implementation directly. Swapping to a backend proxy later
/// is one new implementation class.

enum AiRole { user, assistant }

/// One turn of an Ask thread, provider-neutral.
class AiMessage {
  const AiMessage(this.role, this.text);

  final AiRole role;
  final String text;
}

enum AiFailureKind { offline, busy, error }

/// Thrown by gateway implementations for every failure mode. Features
/// render [userMessage] — they never see raw exceptions or status codes.
class AiUnavailableError implements Exception {
  const AiUnavailableError(this.kind);

  final AiFailureKind kind;

  String get userMessage => switch (kind) {
        AiFailureKind.offline => "You're offline — asking needs internet.",
        AiFailureKind.busy => 'AI is busy — try again shortly.',
        AiFailureKind.error => 'Something went wrong — please try again.',
      };

  @override
  String toString() => 'AiUnavailableError($kind)';
}

abstract class AiGateway {
  /// Multi-turn Q&A with tool use. Returns the final assistant text.
  /// Throws [AiUnavailableError] on network/API failure.
  Future<String> ask(List<AiMessage> thread, DukaToolDispatcher tools);

  /// One-shot insight paragraph from a precomputed snapshot.
  /// Throws [AiUnavailableError] on network/API failure.
  Future<String> generateInsight(ShopSnapshot snapshot);
}
```

- [ ] **Step 4: Implement the dispatcher**

Create `lib/core/ai/duka_tools.dart`:

```dart
import 'dart:convert';

import 'ai_query_service.dart';
import 'projection_service.dart';

/// The 6 read-only tools the model may call (spec: "the AI can never
/// write to the database"). Definitions follow the Anthropic Messages
/// API tool shape: name, description, input_schema (JSON Schema).
///
/// Descriptions are prescriptive about WHEN to call each tool, and tool
/// results carry pre-formatted `*_display` KES strings the model is told
/// to quote verbatim.
class DukaToolDispatcher {
  DukaToolDispatcher(this._queries);

  final AiQueryService _queries;

  static const List<Map<String, Object?>> toolDefinitions = [
    {
      'name': 'get_sales_summary',
      'description':
          'Call this for questions about sales totals, revenue, or the cash '
              'vs M-PESA split over a date range. Returns totals in cents plus '
              'pre-formatted KES display strings.',
      'input_schema': {
        'type': 'object',
        'properties': {
          'from': {'type': 'string', 'description': 'Start date, local, YYYY-MM-DD'},
          'to': {'type': 'string', 'description': 'End date inclusive, local, YYYY-MM-DD'},
        },
        'required': ['from', 'to'],
      },
    },
    {
      'name': 'get_top_products',
      'description':
          'Call this for questions about best or worst selling products over '
              'a date range. Returns products ranked by quantity sold with '
              'revenue.',
      'input_schema': {
        'type': 'object',
        'properties': {
          'from': {'type': 'string', 'description': 'Start date, local, YYYY-MM-DD'},
          'to': {'type': 'string', 'description': 'End date inclusive, local, YYYY-MM-DD'},
          'limit': {'type': 'integer', 'description': 'Max products to return (default 5)'},
        },
        'required': ['from', 'to'],
      },
    },
    {
      'name': 'get_expenses',
      'description':
          'Call this for questions about spending or expenses over a date '
              'range. Returns the total plus a per-category breakdown '
              '(categories: Stock transport, Stock purchase, Electricity, '
              'Airtime, Food, Rent, Repairs, Personal withdrawal, Other).',
      'input_schema': {
        'type': 'object',
        'properties': {
          'from': {'type': 'string', 'description': 'Start date, local, YYYY-MM-DD'},
          'to': {'type': 'string', 'description': 'End date inclusive, local, YYYY-MM-DD'},
        },
        'required': ['from', 'to'],
      },
    },
    {
      'name': 'get_stock_levels',
      'description':
          'Call this for questions about current stock, what is running low, '
              'or what is out of stock. Set low_only=true to return only '
              'low/out-of-stock products.',
      'input_schema': {
        'type': 'object',
        'properties': {
          'low_only': {
            'type': 'boolean',
            'description': 'Return only low/out-of-stock products (default false)',
          },
        },
        'required': <String>[],
      },
    },
    {
      'name': 'get_daily_closes',
      'description':
          'Call this for questions about past closed days: daily totals, net '
              'results, or cash differences (drawer short/over).',
      'input_schema': {
        'type': 'object',
        'properties': {
          'from': {'type': 'string', 'description': 'Start date, local, YYYY-MM-DD'},
          'to': {'type': 'string', 'description': 'End date inclusive, local, YYYY-MM-DD'},
        },
        'required': ['from', 'to'],
      },
    },
    {
      'name': 'get_projections',
      'description':
          'Call this for questions about the future: when a product will run '
              'out of stock, or the projected cash flow for the next 7 days. '
              'Figures are computed locally by the app, not estimated by you.',
      'input_schema': {
        'type': 'object',
        'properties': <String, Object?>{},
        'required': <String>[],
      },
    },
  ];

  /// Executes [name] and returns a JSON string for the tool_result block.
  /// Never throws on bad model input — returns `{"error": ...}` instead
  /// so the model can correct itself on the next round.
  Future<String> execute(String name, Map<String, Object?> input) async {
    try {
      switch (name) {
        case 'get_sales_summary':
          return jsonEncode(
              await _queries.salesSummary(_date(input, 'from'), _date(input, 'to')));
        case 'get_top_products':
          final limit = ((input['limit'] as num?)?.toInt() ?? 5).clamp(1, 20);
          return jsonEncode(await _queries.topProducts(
              _date(input, 'from'), _date(input, 'to'),
              limit: limit));
        case 'get_expenses':
          return jsonEncode(await _queries.expensesSummary(
              _date(input, 'from'), _date(input, 'to')));
        case 'get_stock_levels':
          return jsonEncode(
              await _queries.stockLevels(lowOnly: input['low_only'] == true));
        case 'get_daily_closes':
          return jsonEncode(await _queries.dailyCloses(
              _date(input, 'from'), _date(input, 'to')));
        case 'get_projections':
          final now = DateTime.now();
          final velocities = await _queries.productVelocities(asOf: now);
          final net30 = await _queries.netCentsBetween(
              now.subtract(const Duration(days: 29)), now);
          return jsonEncode({
            'stock_projections': [
              for (final p in projectStockRunOut(velocities)) p.toJson(),
            ],
            'cash_flow':
                projectCashFlow(netCentsInWindow: net30, daysOfData: 30).toJson(),
          });
        default:
          return jsonEncode({'error': 'Unknown tool: $name'});
      }
    } on FormatException catch (e) {
      return jsonEncode({'error': e.message});
    }
  }

  static DateTime _date(Map<String, Object?> input, String key) {
    final raw = input[key];
    if (raw is! String) {
      throw FormatException('Missing or non-string "$key" (expected YYYY-MM-DD).');
    }
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) {
      throw FormatException('Invalid "$key" date "$raw" (expected YYYY-MM-DD).');
    }
    return parsed;
  }
}
```

- [ ] **Step 5: Run tests to verify they pass**

Run: `flutter test test/core/ai/duka_tools_test.dart`
Expected: `All tests passed!` (7 tests)

- [ ] **Step 6: Commit**

```bash
git add lib/core/ai/ai_gateway.dart lib/core/ai/duka_tools.dart test/core/ai/duka_tools_test.dart
git commit -m "feat(ai): AiGateway seam types and 6 read-only duka tools with dispatcher"
```

---

### Task 6: AnthropicGateway (Messages API + manual tool loop)

The only file that talks to the network. Manual tool-use loop per Anthropic docs: while `stop_reason == "tool_use"`, execute each `tool_use` block locally, append the FULL assistant `content` plus ONE user message containing all `tool_result` blocks (matching `tool_use_id`s), re-send. Cap 5 tool rounds. `stop_reason == "refusal"` is handled BEFORE reading content (required on `claude-opus-5`). Errors map to `AiUnavailableError` — catch `http.ClientException` + `TimeoutException` (NOT `dart:io SocketException` — `package:http` wraps socket failures in `ClientException` on all platforms, and importing `dart:io` would break the Chrome dev target).

**Files:**
- Create: `lib/core/ai/anthropic_gateway.dart`
- Test: `test/core/ai/anthropic_gateway_test.dart`

- [ ] **Step 1: Write the failing tests**

Create `test/core/ai/anthropic_gateway_test.dart`:

```dart
import 'dart:convert';

import 'package:dukasmart/core/ai/ai_gateway.dart';
import 'package:dukasmart/core/ai/ai_query_service.dart';
import 'package:dukasmart/core/ai/anthropic_gateway.dart';
import 'package:dukasmart/core/ai/duka_tools.dart';
import 'package:dukasmart/core/ai/snapshot_builder.dart';
import 'package:dukasmart/core/database/database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

http.Response _apiJson(Map<String, Object?> body) => http.Response(
      jsonEncode(body),
      200,
      headers: {'content-type': 'application/json'},
    );

Map<String, Object?> _endTurn(String text) => {
      'stop_reason': 'end_turn',
      'content': [
        {'type': 'text', 'text': text},
      ],
    };

void main() {
  late AppDatabase db;
  late DukaToolDispatcher dispatcher;

  setUp(() {
    db = AppDatabase.forExecutor(NativeDatabase.memory());
    dispatcher = DukaToolDispatcher(AiQueryService(db));
  });

  tearDown(() async {
    await db.close();
  });

  AnthropicGateway gateway(http.Client client) =>
      AnthropicGateway(client: client, apiKey: 'test-key');

  test('plain answer: sends key/version headers, model, system, tools', () async {
    final client = MockClient((request) async {
      expect(request.headers['x-api-key'], 'test-key');
      expect(request.headers['anthropic-version'], '2023-06-01');
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(body['model'], 'claude-opus-5');
      expect(body['max_tokens'], 1024);
      expect(body['system'], contains('DukaSmart'));
      expect((body['tools'] as List), hasLength(6));
      expect((body['messages'] as List), hasLength(1));
      return _apiJson(_endTurn('Habari! Uliuza KES 135 leo.'));
    });

    final reply = await gateway(client)
        .ask([const AiMessage(AiRole.user, 'nimeuza pesa ngapi leo?')], dispatcher);
    expect(reply, 'Habari! Uliuza KES 135 leo.');
  });

  test('tool round trip: executes tool, echoes tool_use_id, returns final text',
      () async {
    var calls = 0;
    final client = MockClient((request) async {
      calls++;
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      final messages = body['messages'] as List;
      if (calls == 1) {
        return _apiJson({
          'stop_reason': 'tool_use',
          'content': [
            {'type': 'text', 'text': 'Let me check.'},
            {
              'type': 'tool_use',
              'id': 'toolu_1',
              'name': 'get_stock_levels',
              'input': {'low_only': false},
            },
          ],
        });
      }
      // Round 2 must carry: original user msg + full assistant content +
      // a user message whose content is the tool_result list.
      expect(messages, hasLength(3));
      expect((messages[1] as Map)['role'], 'assistant');
      final results = ((messages[2] as Map)['content'] as List).cast<Map>();
      expect(results.single['type'], 'tool_result');
      expect(results.single['tool_use_id'], 'toolu_1');
      final toolJson =
          jsonDecode(results.single['content'] as String) as Map<String, dynamic>;
      expect(toolJson['product_count'], 5); // seeded products
      return _apiJson(_endTurn('You stock 5 products.'));
    });

    final reply = await gateway(client)
        .ask([const AiMessage(AiRole.user, 'how many products?')], dispatcher);
    expect(reply, 'You stock 5 products.');
    expect(calls, 2);
  });

  test('refusal stop_reason -> polite decline without reading content', () async {
    final client = MockClient((request) async =>
        _apiJson({'stop_reason': 'refusal', 'content': <Object?>[]}));
    final reply =
        await gateway(client).ask([const AiMessage(AiRole.user, 'hack it')], dispatcher);
    expect(reply, "I can't help with that question.");
  });

  test('endless tool_use is capped: 6 posts then graceful fallback', () async {
    var calls = 0;
    final client = MockClient((request) async {
      calls++;
      return _apiJson({
        'stop_reason': 'tool_use',
        'content': [
          {
            'type': 'tool_use',
            'id': 'toolu_$calls',
            'name': 'get_stock_levels',
            'input': <String, Object?>{},
          },
        ],
      });
    });

    final reply =
        await gateway(client).ask([const AiMessage(AiRole.user, 'loop')], dispatcher);
    expect(reply, contains('simpler question'));
    expect(calls, 6); // initial round + 5 capped tool rounds
  });

  test('HTTP 429 -> AiUnavailableError(busy)', () async {
    final client = MockClient((request) async => http.Response('rate limited', 429));
    expect(
      () => gateway(client).ask([const AiMessage(AiRole.user, 'hi')], dispatcher),
      throwsA(isA<AiUnavailableError>()
          .having((e) => e.kind, 'kind', AiFailureKind.busy)),
    );
  });

  test('network failure -> AiUnavailableError(offline)', () async {
    final client =
        MockClient((request) async => throw http.ClientException('no network'));
    expect(
      () => gateway(client).ask([const AiMessage(AiRole.user, 'hi')], dispatcher),
      throwsA(isA<AiUnavailableError>()
          .having((e) => e.kind, 'kind', AiFailureKind.offline)),
    );
  });

  test('HTTP 500 -> AiUnavailableError(error)', () async {
    final client = MockClient((request) async => http.Response('boom', 500));
    expect(
      () => gateway(client).ask([const AiMessage(AiRole.user, 'hi')], dispatcher),
      throwsA(isA<AiUnavailableError>()
          .having((e) => e.kind, 'kind', AiFailureKind.error)),
    );
  });

  group('generateInsight', () {
    test('sends snapshot JSON with no tools, returns paragraph', () async {
      final snapshot = await SnapshotBuilder(AiQueryService(db)).build(DateTime.now());
      final client = MockClient((request) async {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body.containsKey('tools'), isFalse);
        expect(body['max_tokens'], 512);
        final userText =
            ((body['messages'] as List).single as Map)['content'] as String;
        expect(userText, contains('"cash_flow"'));
        return _apiJson(_endTurn('A quiet day with steady cash flow.'));
      });

      final insight = await gateway(client).generateInsight(snapshot);
      expect(insight, 'A quiet day with steady cash flow.');
    });

    test('empty content -> AiUnavailableError(error)', () async {
      final snapshot = await SnapshotBuilder(AiQueryService(db)).build(DateTime.now());
      final client = MockClient((request) async =>
          _apiJson({'stop_reason': 'end_turn', 'content': <Object?>[]}));
      expect(
        () => gateway(client).generateInsight(snapshot),
        throwsA(isA<AiUnavailableError>()),
      );
    });
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/core/ai/anthropic_gateway_test.dart`
Expected: FAIL — package resolve error for `anthropic_gateway.dart`.

- [ ] **Step 3: Implement**

Create `lib/core/ai/anthropic_gateway.dart`:

```dart
import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'ai_config.dart';
import 'ai_gateway.dart';
import 'duka_tools.dart';
import 'snapshot_builder.dart';

/// Anthropic Messages API implementation of [AiGateway] over raw HTTPS
/// (no official Dart SDK). See the spec's error-handling section for the
/// failure-mode mapping.
class AnthropicGateway implements AiGateway {
  AnthropicGateway({
    required http.Client client,
    required this.apiKey,
    this.model = AiConfig.model,
    this.endpoint = AiConfig.endpoint,
  }) : _client = client;

  final http.Client _client;
  final String apiKey;
  final String model;
  final String endpoint;

  /// Max tool-use rounds per question (spec). One initial request plus up
  /// to this many tool rounds = at most `maxToolRounds + 1` API posts.
  static const int maxToolRounds = 5;

  static const Duration _timeout = Duration(seconds: 30);

  static const String _askSystemPrompt = '''
You are the DukaSmart assistant for a single Kenyan kiosk (duka) owner.
Answer questions about their shop using ONLY the provided tools — never
invent, estimate, or recompute numbers yourself.

Rules:
- Money: quote the pre-formatted "*_display" strings from tool results
  exactly (e.g. "KES 12,450"). Never do arithmetic on money values.
- Reply in the language the user wrote in (English or Swahili).
- Keep answers short and plain: 1-4 sentences for a phone screen. No
  markdown headings. A short list is fine when naming several products.
- If a tool returns {"error": ...}, fix your input and call it again.
- If the data does not exist (e.g. a day was never closed), say so
  plainly instead of guessing.''';

  static const String _insightSystemPrompt = '''
You are the DukaSmart assistant writing one short insight for a Kenyan
kiosk owner's daily report. You are given a JSON snapshot computed
locally by the app. Write ONE plain-language paragraph of 2-4 sentences,
no markdown. Quote money using the "*_display" strings exactly; never
recompute figures. Cover at most: how today compares with recent days,
one notable expense pattern, and the most urgent stock run-out if any.
Never mention numbers that are not in the snapshot.''';

  /// The model needs today's date to translate "today"/"this week" into
  /// tool date ranges.
  String _askSystem() {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    return "$_askSystemPrompt\nToday's local date is $today.";
  }

  @override
  Future<String> ask(List<AiMessage> thread, DukaToolDispatcher tools) async {
    final messages = <Map<String, Object?>>[
      for (final m in thread)
        {
          'role': m.role == AiRole.user ? 'user' : 'assistant',
          'content': m.text,
        },
    ];

    // <= so the loop body runs maxToolRounds + 1 times at most.
    for (var round = 0; round <= maxToolRounds; round++) {
      final response = await _post({
        'model': model,
        'max_tokens': 1024,
        'system': _askSystem(),
        'tools': DukaToolDispatcher.toolDefinitions,
        'messages': messages,
      });

      final stopReason = response['stop_reason'];
      if (stopReason == 'refusal') {
        return "I can't help with that question.";
      }

      final content =
          (response['content'] as List? ?? const []).cast<Map<String, dynamic>>();

      if (stopReason == 'tool_use') {
        // Echo the FULL assistant content back, then all tool results in
        // ONE user message — splitting them breaks the API contract.
        messages.add({'role': 'assistant', 'content': content});
        final results = <Map<String, Object?>>[];
        for (final block in content) {
          if (block['type'] != 'tool_use') continue;
          final output = await tools.execute(
            block['name'] as String,
            Map<String, Object?>.from(block['input'] as Map? ?? const {}),
          );
          results.add({
            'type': 'tool_result',
            'tool_use_id': block['id'],
            'content': output,
          });
        }
        messages.add({'role': 'user', 'content': results});
        continue;
      }

      final text = _joinText(content);
      if (text.isNotEmpty) return text;
      throw const AiUnavailableError(AiFailureKind.error);
    }

    return "I couldn't finish answering that — try asking a simpler question.";
  }

  @override
  Future<String> generateInsight(ShopSnapshot snapshot) async {
    final response = await _post({
      'model': model,
      'max_tokens': 512,
      'system': _insightSystemPrompt,
      'messages': [
        {
          'role': 'user',
          'content': 'Shop snapshot JSON:\n${snapshot.toJsonString()}',
        },
      ],
    });
    if (response['stop_reason'] == 'refusal') {
      throw const AiUnavailableError(AiFailureKind.error);
    }
    final text = _joinText(
        (response['content'] as List? ?? const []).cast<Map<String, dynamic>>());
    if (text.isEmpty) {
      throw const AiUnavailableError(AiFailureKind.error);
    }
    return text;
  }

  static String _joinText(List<Map<String, dynamic>> content) => content
      .where((b) => b['type'] == 'text')
      .map((b) => (b['text'] as String?) ?? '')
      .join()
      .trim();

  Future<Map<String, dynamic>> _post(Map<String, Object?> body) async {
    final http.Response response;
    try {
      response = await _client
          .post(
            Uri.parse(endpoint),
            headers: {
              'content-type': 'application/json',
              'x-api-key': apiKey,
              'anthropic-version': AiConfig.anthropicVersion,
            },
            body: jsonEncode(body),
          )
          .timeout(_timeout);
    } on http.ClientException {
      throw const AiUnavailableError(AiFailureKind.offline);
    } on TimeoutException {
      throw const AiUnavailableError(AiFailureKind.offline);
    }

    if (response.statusCode == 429 || response.statusCode == 529) {
      throw const AiUnavailableError(AiFailureKind.busy);
    }
    if (response.statusCode != 200) {
      throw const AiUnavailableError(AiFailureKind.error);
    }
    // Decode bytes as UTF-8 explicitly: without a charset in the response
    // content-type, `response.body` falls back to Latin-1 and garbles
    // Swahili replies.
    return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/core/ai/anthropic_gateway_test.dart`
Expected: `All tests passed!` (9 tests)

- [ ] **Step 5: Commit**

```bash
git add lib/core/ai/anthropic_gateway.dart test/core/ai/anthropic_gateway_test.dart
git commit -m "feat(ai): AnthropicGateway with manual tool-use loop and error mapping"
```

---

### Task 7: Riverpod wiring (`ai_providers.dart`) + shared test fake

Wires the AI layer into the existing provider graph (`databaseProvider` from `lib/core/providers.dart`). Also creates the one shared `FakeAiGateway` used by every later widget/controller test.

**Files:**
- Create: `lib/core/ai/ai_providers.dart`
- Create: `test/helpers/fake_ai_gateway.dart`
- Test: `test/core/ai/ai_providers_test.dart`

- [ ] **Step 1: Write the shared fake**

Create `test/helpers/fake_ai_gateway.dart`:

```dart
import 'package:dukasmart/core/ai/ai_gateway.dart';
import 'package:dukasmart/core/ai/duka_tools.dart';
import 'package:dukasmart/core/ai/snapshot_builder.dart';

/// Canned-response [AiGateway] for tests. Set [error] (mutable) to make
/// the next call throw; [askCalls] records every thread sent.
class FakeAiGateway implements AiGateway {
  FakeAiGateway({
    this.reply = 'Fake reply.',
    this.insight = 'Fake insight.',
    this.error,
  });

  final String reply;
  final String insight;
  AiUnavailableError? error;
  final List<List<AiMessage>> askCalls = [];

  @override
  Future<String> ask(List<AiMessage> thread, DukaToolDispatcher tools) async {
    askCalls.add(List.of(thread));
    final e = error;
    if (e != null) throw e;
    return reply;
  }

  @override
  Future<String> generateInsight(ShopSnapshot snapshot) async {
    final e = error;
    if (e != null) throw e;
    return insight;
  }
}
```

- [ ] **Step 2: Write the failing provider tests**

Create `test/core/ai/ai_providers_test.dart`:

```dart
import 'package:dukasmart/core/ai/ai_providers.dart';
import 'package:dukasmart/core/ai/ai_gateway.dart';
import 'package:dukasmart/core/database/database.dart';
import 'package:dukasmart/core/providers.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_ai_gateway.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forExecutor(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  ProviderContainer makeContainer({required bool aiAvailable, FakeAiGateway? gateway}) {
    final container = ProviderContainer(overrides: [
      databaseProvider.overrideWith((ref) {
        // Container owns db lifetime via tearDown, not ref.onDispose.
        return db;
      }),
      aiAvailableProvider.overrideWithValue(aiAvailable),
      if (gateway != null) aiGatewayProvider.overrideWithValue(gateway),
    ]);
    addTearDown(container.dispose);
    return container;
  }

  test('aiInsightProvider is null when AI is not configured', () async {
    final container = makeContainer(aiAvailable: false);
    final insight =
        await container.read(aiInsightProvider(DateTime.now()).future);
    expect(insight, isNull);
  });

  test('aiInsightProvider returns gateway insight when available', () async {
    final container = makeContainer(
        aiAvailable: true, gateway: FakeAiGateway(insight: 'Sales are up.'));
    final insight =
        await container.read(aiInsightProvider(DateTime.now()).future);
    expect(insight, 'Sales are up.');
  });

  test('aiInsightProvider swallows AiUnavailableError -> null (no error card)',
      () async {
    final container = makeContainer(
      aiAvailable: true,
      gateway: FakeAiGateway(
          error: const AiUnavailableError(AiFailureKind.offline)),
    );
    final insight =
        await container.read(aiInsightProvider(DateTime.now()).future);
    expect(insight, isNull);
  });
}
```

- [ ] **Step 3: Run tests to verify they fail**

Run: `flutter test test/core/ai/ai_providers_test.dart`
Expected: FAIL — package resolve error for `ai_providers.dart`.

- [ ] **Step 4: Implement the providers**

Create `lib/core/ai/ai_providers.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../providers.dart';
import 'ai_config.dart';
import 'ai_gateway.dart';
import 'ai_query_service.dart';
import 'anthropic_gateway.dart';
import 'duka_tools.dart';
import 'snapshot_builder.dart';

/// Riverpod wiring for the AI layer. Features read these providers —
/// never the Anthropic implementation directly (spec: gateway seam).

/// True when a build-time API key exists (spec: without it, AI surfaces
/// don't render and no AI network path is reachable). Widget tests
/// override this to exercise the AI surfaces.
final aiAvailableProvider = Provider<bool>((ref) => AiConfig.isConfigured);

final aiQueryServiceProvider = Provider<AiQueryService>(
    (ref) => AiQueryService(ref.watch(databaseProvider)));

final dukaToolDispatcherProvider = Provider<DukaToolDispatcher>(
    (ref) => DukaToolDispatcher(ref.watch(aiQueryServiceProvider)));

final snapshotBuilderProvider = Provider<SnapshotBuilder>(
    (ref) => SnapshotBuilder(ref.watch(aiQueryServiceProvider)));

final aiGatewayProvider = Provider<AiGateway>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return AnthropicGateway(client: client, apiKey: AiConfig.apiKey);
});

/// The daily report's AI insight for a given close date. Null means "no
/// card": AI not configured, or the call failed — the report screen never
/// shows an error state for this (spec: "on any failure the card simply
/// does not appear").
final aiInsightProvider =
    FutureProvider.autoDispose.family<String?, DateTime>((ref, date) async {
  if (!ref.watch(aiAvailableProvider)) return null;
  try {
    final snapshot = await ref.watch(snapshotBuilderProvider).build(date);
    return await ref.watch(aiGatewayProvider).generateInsight(snapshot);
  } on AiUnavailableError {
    return null;
  }
});
```

- [ ] **Step 5: Run tests to verify they pass**

Run: `flutter test test/core/ai/ai_providers_test.dart`
Expected: `All tests passed!` (3 tests)

- [ ] **Step 6: Commit**

```bash
git add lib/core/ai/ai_providers.dart test/helpers/fake_ai_gateway.dart test/core/ai/ai_providers_test.dart
git commit -m "feat(ai): Riverpod wiring for the AI layer and shared test fake"
```

---

### Task 8: AskController (thread state)

Session-only thread state using the codebase's `AutoDisposeNotifier` pattern (same as `SaleSubmitController`). Error bubbles render in the UI but are excluded from the thread sent to the model.

**Files:**
- Create: `lib/features/assistant/ask_controller.dart`
- Test: `test/features/assistant/ask_controller_test.dart`

- [ ] **Step 1: Write the failing tests**

Create `test/features/assistant/ask_controller_test.dart`:

```dart
import 'package:dukasmart/core/ai/ai_gateway.dart';
import 'package:dukasmart/core/ai/ai_providers.dart';
import 'package:dukasmart/core/ai/ai_query_service.dart';
import 'package:dukasmart/core/ai/duka_tools.dart';
import 'package:dukasmart/core/database/database.dart';
import 'package:dukasmart/features/assistant/ask_controller.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_ai_gateway.dart';

void main() {
  late AppDatabase db;
  late FakeAiGateway gateway;
  late ProviderContainer container;

  setUp(() {
    db = AppDatabase.forExecutor(NativeDatabase.memory());
    gateway = FakeAiGateway(reply: 'You sold KES 135 today.');
    container = ProviderContainer(overrides: [
      aiGatewayProvider.overrideWithValue(gateway),
      dukaToolDispatcherProvider
          .overrideWithValue(DukaToolDispatcher(AiQueryService(db))),
    ]);
    addTearDown(container.dispose);
    // Keep the autoDispose controller alive for the test body.
    final sub = container.listen(askControllerProvider, (_, __) {});
    addTearDown(sub.close);
  });

  tearDown(() async {
    await db.close();
  });

  test('send appends user message then assistant reply', () async {
    await container.read(askControllerProvider.notifier).send('what did I sell?');

    final state = container.read(askControllerProvider);
    expect(state.sending, isFalse);
    expect(state.messages, hasLength(2));
    expect(state.messages[0].fromUser, isTrue);
    expect(state.messages[0].text, 'what did I sell?');
    expect(state.messages[1].fromUser, isFalse);
    expect(state.messages[1].text, 'You sold KES 135 today.');
  });

  test('blank input is ignored', () async {
    await container.read(askControllerProvider.notifier).send('   ');
    expect(container.read(askControllerProvider).messages, isEmpty);
    expect(gateway.askCalls, isEmpty);
  });

  test('gateway failure appends an error bubble with the friendly message',
      () async {
    gateway.error = const AiUnavailableError(AiFailureKind.offline);
    await container.read(askControllerProvider.notifier).send('hello?');

    final state = container.read(askControllerProvider);
    expect(state.messages, hasLength(2));
    expect(state.messages[1].isError, isTrue);
    expect(state.messages[1].text, "You're offline — asking needs internet.");
    expect(state.sending, isFalse);
  });

  test('error bubbles are excluded from the thread sent to the model',
      () async {
    gateway.error = const AiUnavailableError(AiFailureKind.offline);
    await container.read(askControllerProvider.notifier).send('first');
    gateway.error = null;
    await container.read(askControllerProvider.notifier).send('second');

    // Second call's thread: both user messages, no error bubble.
    final thread = gateway.askCalls.last;
    expect(thread, hasLength(2));
    expect(thread.every((m) => m.role == AiRole.user), isTrue);
    expect(thread.map((m) => m.text).toList(), ['first', 'second']);
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/features/assistant/ask_controller_test.dart`
Expected: FAIL — package resolve error for `ask_controller.dart`.

- [ ] **Step 3: Implement**

Create `lib/features/assistant/ask_controller.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/ai/ai_gateway.dart';
import '../../core/ai/ai_providers.dart';

/// One rendered bubble in the Ask thread.
class AskMessage {
  const AskMessage({
    required this.fromUser,
    required this.text,
    this.isError = false,
  });

  final bool fromUser;
  final String text;
  final bool isError;
}

class AskState {
  const AskState({this.messages = const [], this.sending = false});

  final List<AskMessage> messages;
  final bool sending;

  AskState copyWith({List<AskMessage>? messages, bool? sending}) => AskState(
        messages: messages ?? this.messages,
        sending: sending ?? this.sending,
      );
}

/// Session-only Q&A thread (spec: in-memory, cleared on leaving the
/// screen — hence autoDispose). Error bubbles are rendered but excluded
/// from the thread sent to the model.
class AskController extends AutoDisposeNotifier<AskState> {
  @override
  AskState build() => const AskState();

  Future<void> send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || state.sending) return;

    state = state.copyWith(
      messages: [...state.messages, AskMessage(fromUser: true, text: trimmed)],
      sending: true,
    );

    final thread = [
      for (final m in state.messages)
        if (!m.isError)
          AiMessage(m.fromUser ? AiRole.user : AiRole.assistant, m.text),
    ];

    try {
      final reply = await ref
          .read(aiGatewayProvider)
          .ask(thread, ref.read(dukaToolDispatcherProvider));
      state = state.copyWith(
        messages: [...state.messages, AskMessage(fromUser: false, text: reply)],
        sending: false,
      );
    } on AiUnavailableError catch (e) {
      state = state.copyWith(
        messages: [
          ...state.messages,
          AskMessage(fromUser: false, text: e.userMessage, isError: true),
        ],
        sending: false,
      );
    }
  }
}

final askControllerProvider =
    AutoDisposeNotifierProvider<AskController, AskState>(AskController.new);
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/features/assistant/ask_controller_test.dart`
Expected: `All tests passed!` (4 tests)

- [ ] **Step 5: Commit**

```bash
git add lib/features/assistant/ask_controller.dart test/features/assistant/ask_controller_test.dart
git commit -m "feat(assistant): AskController session thread state"
```

---

### Task 9: AskScreen + `/home/ask` route

Thread UI with suggestion chips on empty state, typing indicator while sending, and error bubbles. Route is a root-navigator child of `/home` (same pattern as `close-day`). Bubble colors: user = `emeraldContainer`, assistant = `surfaceMuted`, error = `redContainer` (existing tokens only).

**Files:**
- Create: `lib/features/assistant/ask_screen.dart`
- Modify: `lib/app/router.dart` (add import + one GoRoute under `/home`)
- Test: `test/features/assistant/ask_screen_test.dart`

- [ ] **Step 1: Write the failing widget tests**

Create `test/features/assistant/ask_screen_test.dart`:

```dart
import 'package:dukasmart/core/ai/ai_gateway.dart';
import 'package:dukasmart/core/ai/ai_providers.dart';
import 'package:dukasmart/core/ai/ai_query_service.dart';
import 'package:dukasmart/core/ai/duka_tools.dart';
import 'package:dukasmart/core/database/database.dart';
import 'package:dukasmart/features/assistant/ask_screen.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_ai_gateway.dart';

void main() {
  late AppDatabase db;
  late FakeAiGateway gateway;

  setUp(() {
    db = AppDatabase.forExecutor(NativeDatabase.memory());
    gateway = FakeAiGateway(reply: 'You sold KES 135 today.');
  });

  tearDown(() async {
    await db.close();
  });

  Widget app() => ProviderScope(
        overrides: [
          aiGatewayProvider.overrideWithValue(gateway),
          dukaToolDispatcherProvider
              .overrideWithValue(DukaToolDispatcher(AiQueryService(db))),
        ],
        child: const MaterialApp(home: AskScreen()),
      );

  testWidgets('empty state shows the three suggestion chips', (tester) async {
    await tester.pumpWidget(app());

    expect(find.text('What did I sell today?'), findsOneWidget);
    expect(find.text('Nimetumia pesa ngapi kwa transport wiki hii?'), findsOneWidget);
    expect(find.text("What's running low?"), findsOneWidget);
  });

  testWidgets('tapping a chip sends it and renders both bubbles', (tester) async {
    await tester.pumpWidget(app());

    await tester.tap(find.text('What did I sell today?'));
    await tester.pumpAndSettle();

    expect(find.text('What did I sell today?'), findsOneWidget); // now a bubble
    expect(find.text('You sold KES 135 today.'), findsOneWidget);
    // Chips are gone once the thread has messages.
    expect(find.text("What's running low?"), findsNothing);
  });

  testWidgets('typing and sending via the send button works', (tester) async {
    await tester.pumpWidget(app());

    await tester.enterText(find.byType(TextField), 'how is stock?');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    expect(find.text('how is stock?'), findsOneWidget);
    expect(find.text('You sold KES 135 today.'), findsOneWidget);
    // Input cleared after send.
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, isEmpty);
  });

  testWidgets('offline failure renders the friendly error bubble', (tester) async {
    gateway.error = const AiUnavailableError(AiFailureKind.offline);
    await tester.pumpWidget(app());

    await tester.enterText(find.byType(TextField), 'hello');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    expect(find.text("You're offline — asking needs internet."), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/features/assistant/ask_screen_test.dart`
Expected: FAIL — package resolve error for `ask_screen.dart`.

- [ ] **Step 3: Implement the screen**

Create `lib/features/assistant/ask_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import 'ask_controller.dart';

/// Ask your duka (route `/home/ask`) — spec UX surface: a focused Q&A
/// thread with suggestion chips on the empty state. The thread is
/// session-only; leaving the screen disposes the autoDispose controller.
class AskScreen extends ConsumerStatefulWidget {
  const AskScreen({super.key});

  @override
  ConsumerState<AskScreen> createState() => _AskScreenState();
}

class _AskScreenState extends ConsumerState<AskScreen> {
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();

  static const List<String> _suggestions = [
    'What did I sell today?',
    'Nimetumia pesa ngapi kwa transport wiki hii?',
    "What's running low?",
  ];

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send(String text) {
    ref.read(askControllerProvider.notifier).send(text);
    _input.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(askControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Ask your duka')),
      body: Column(
        children: [
          Expanded(
            child: state.messages.isEmpty
                ? _EmptyThread(onSuggestion: _send)
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.all(16),
                    itemCount: state.messages.length + (state.sending ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == state.messages.length) {
                        return const _TypingBubble();
                      }
                      return _MessageBubble(message: state.messages[index]);
                    },
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      textInputAction: TextInputAction.send,
                      onSubmitted: state.sending ? null : _send,
                      decoration: const InputDecoration(
                        hintText: 'Ask about your duka…',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: state.sending ? null : () => _send(_input.text),
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyThread extends StatelessWidget {
  const _EmptyThread({required this.onSuggestion});

  final ValueChanged<String> onSuggestion;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.auto_awesome_outlined,
              size: 40, color: AppTokens.inkMuted),
          const SizedBox(height: 12),
          Text(
            'Ask about your sales, expenses, stock, or what to restock — in '
            'English au Kiswahili.',
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(color: AppTokens.inkSecondary),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              for (final suggestion in _AskScreenState._suggestions)
                ActionChip(
                  label: Text(suggestion),
                  onPressed: () => onSuggestion(suggestion),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final AskMessage message;

  @override
  Widget build(BuildContext context) {
    final Color background;
    final Color textColor;
    if (message.isError) {
      background = AppTokens.redContainer;
      textColor = AppTokens.red;
    } else if (message.fromUser) {
      background = AppTokens.emeraldContainer;
      textColor = AppTokens.ink;
    } else {
      background = AppTokens.surfaceMuted;
      textColor = AppTokens.ink;
    }

    return Align(
      alignment: message.fromUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.8,
        ),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          message.text,
          style: AppTextStyles.body.copyWith(color: textColor),
        ),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppTokens.surfaceMuted,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 10),
            Text(
              'Thinking…',
              style: AppTextStyles.caption.copyWith(color: AppTokens.inkMuted),
            ),
          ],
        ),
      ),
    );
  }
}
```

Note: `_EmptyThread` references `_AskScreenState._suggestions` — both classes live in this file, so the private access is legal Dart.

- [ ] **Step 4: Add the route**

In `lib/app/router.dart`:

1. Add the import (alphabetical, after the `dashboard` imports):

```dart
import '../features/assistant/ask_screen.dart';
```

2. Inside the `/home` GoRoute's `routes:` list, add this entry FIRST (before `add-stock`):

```dart
GoRoute(
  path: 'ask',
  name: 'ask',
  parentNavigatorKey: rootNavigatorKey,
  builder: (context, state) => const AskScreen(),
),
```

- [ ] **Step 5: Run tests to verify they pass**

Run: `flutter test test/features/assistant/ask_screen_test.dart`
Expected: `All tests passed!` (4 tests)

Run: `flutter analyze lib/app/router.dart lib/features/assistant/`
Expected: `No issues found!`

- [ ] **Step 6: Commit**

```bash
git add lib/features/assistant/ask_screen.dart lib/app/router.dart test/features/assistant/ask_screen_test.dart
git commit -m "feat(assistant): Ask your duka screen and /home/ask route"
```

---

### Task 10: Dashboard ask bar (gated)

A quiet slate bar under the payment dot-chips (spec: "slate, not emerald — not a money action"). Rendered ONLY when `aiAvailableProvider` is true; in a key-less build the dashboard is unchanged.

**Files:**
- Modify: `lib/features/dashboard/dashboard_screen.dart`
- Test: `test/features/dashboard/dashboard_screen_test.dart` (append two tests)

- [ ] **Step 1: Write the failing tests**

Append to `test/features/dashboard/dashboard_screen_test.dart` (inside `main()`, after the existing tests) — also add this import at the top of the file:

```dart
import 'package:dukasmart/core/ai/ai_providers.dart';
```

```dart
  testWidgets('ask bar is hidden when AI is not configured', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dailyMetricsProvider.overrideWith((ref) => Stream.value(_fixtureMetrics)),
        ],
        child: const MaterialApp(home: DashboardScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();

    // No --dart-define in tests -> AiConfig.isConfigured is false.
    expect(find.text('Ask about your duka…'), findsNothing);
  });

  testWidgets('ask bar renders when AI is configured', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dailyMetricsProvider.overrideWith((ref) => Stream.value(_fixtureMetrics)),
          aiAvailableProvider.overrideWithValue(true),
        ],
        child: const MaterialApp(home: DashboardScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Ask about your duka…'), findsOneWidget);
  });
```

- [ ] **Step 2: Run tests to verify the new ones fail**

Run: `flutter test test/features/dashboard/dashboard_screen_test.dart`
Expected: the first new test passes trivially, the second FAILS (`findsNothing` — bar not implemented yet). Existing tests still pass.

- [ ] **Step 3: Implement the bar**

In `lib/features/dashboard/dashboard_screen.dart`:

1. Add the import (with the other `core` imports):

```dart
import '../../core/ai/ai_providers.dart';
```

2. In `DashboardScreen.build`, read availability and pass it down — change the `data:` line of `metricsAsync.when`:

```dart
      body: metricsAsync.when(
        data: (metrics) => _DashboardBody(
          metrics: metrics,
          aiAvailable: ref.watch(aiAvailableProvider),
        ),
```

3. Extend `_DashboardBody`:

```dart
class _DashboardBody extends StatelessWidget {
  const _DashboardBody({required this.metrics, required this.aiAvailable});

  final DailyMetrics metrics;
  final bool aiAvailable;
```

4. In `_DashboardBody.build`, insert directly after the dot-chips `Wrap(...)` (before `const SectionHeader('Attention Needed')`):

```dart
        if (aiAvailable) ...[
          const SizedBox(height: 16),
          const _AskDukaBar(),
        ],
```

5. Add the widget at the end of the file:

```dart
/// Quiet ask-bar entry point for the AI assistant (spec UX decision:
/// discoverable without competing with the money numbers — slate
/// surface, never emerald).
class _AskDukaBar extends StatelessWidget {
  const _AskDukaBar();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTokens.surfaceMuted,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () => context.pushNamed('ask'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              const Icon(Icons.auto_awesome_outlined,
                  size: 18, color: AppTokens.inkSecondary),
              const SizedBox(width: 10),
              Text(
                'Ask about your duka…',
                style: AppTextStyles.body.copyWith(color: AppTokens.inkMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/features/dashboard/dashboard_screen_test.dart`
Expected: `All tests passed!` (existing tests + 2 new)

- [ ] **Step 5: Commit**

```bash
git add lib/features/dashboard/dashboard_screen.dart test/features/dashboard/dashboard_screen_test.dart
git commit -m "feat(dashboard): gated Ask-your-duka bar"
```

---

### Task 11: Daily report AI insight card

Async card below the existing rule-based insight block (which stays untouched — it is the offline fallback). Loading shows a subtle progress row; success shows the paragraph; null/failure renders nothing (spec: never an error state here). Styling matches the existing insight block: `surfaceMuted`, never emerald (design principle: emerald = money-action only).

**Files:**
- Modify: `lib/features/daily_close/daily_report_screen.dart`
- Test: `test/features/daily_close/daily_report_screen_test.dart` (append two tests)

- [ ] **Step 1: Write the failing tests**

Append to `test/features/daily_close/daily_report_screen_test.dart` (inside `main()`) — add these imports at the top of the file if not already present:

```dart
import 'package:dukasmart/core/ai/ai_providers.dart';
import 'package:dukasmart/core/models/closed_day_report.dart';
```

Add this fixture at top level of the test file (after existing top-level declarations). NOTE: if the file already defines a `ClosedDayReport`/`DailyClose` fixture, reuse it instead of adding this one — the tests below only need SOME report to render:

```dart
final _aiCardClose = DailyClose(
  id: 1,
  date: DateTime(2026, 7, 25),
  totalSales: 14000,
  cashSales: 14000,
  mpesaSales: 0,
  expenses: 3000,
  costOfGoods: 11000,
  grossProfit: 3000,
  netResult: 0,
  expectedCash: 11000,
  actualCash: 11000,
  cashDifference: 0,
  note: null,
  createdAt: DateTime(2026, 7, 25, 20),
);

final _aiCardReport = ClosedDayReport(
  close: _aiCardClose,
  bestSeller: null,
  lowStockNow: const [],
);
```

```dart
  testWidgets('AI insight card renders when AI is available', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          closedDayReportProvider.overrideWith((ref, date) async => _aiCardReport),
          aiAvailableProvider.overrideWithValue(true),
          aiInsightProvider.overrideWith((ref, date) async => 'Steady sales today.'),
        ],
        child: MaterialApp(home: DailyReportScreen(date: DateTime(2026, 7, 25))),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Steady sales today.'), 200);
    expect(find.text('Steady sales today.'), findsOneWidget);
  });

  testWidgets('no AI card when AI is not configured', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          closedDayReportProvider.overrideWith((ref, date) async => _aiCardReport),
        ],
        child: MaterialApp(home: DailyReportScreen(date: DateTime(2026, 7, 25))),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.auto_awesome_outlined), findsNothing);
  });
```

- [ ] **Step 2: Run tests to verify the new ones fail**

Run: `flutter test test/features/daily_close/daily_report_screen_test.dart`
Expected: first new test FAILS (`Steady sales today.` not found); existing tests still pass.

- [ ] **Step 3: Implement the card**

In `lib/features/daily_close/daily_report_screen.dart`:

1. Add the import (with the other `core` imports):

```dart
import '../../core/ai/ai_providers.dart';
```

2. In `_ReportBody.build`, add the card as the LAST child of the `Column` (directly after the existing Insight `Container(...)`):

```dart
          _AiInsightCard(date: close.date),
```

3. Add the widget at the end of the file:

```dart
/// AI insight card (spec): loads below the deterministic insight when AI
/// is configured and online. Loading -> subtle progress row; success ->
/// paragraph; null or failure -> renders nothing (this screen never
/// shows an AI error state). The rule-based insight above is the
/// permanent offline fallback.
class _AiInsightCard extends ConsumerWidget {
  const _AiInsightCard({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(aiAvailableProvider)) return const SizedBox.shrink();

    final insightAsync = ref.watch(aiInsightProvider(date));
    return insightAsync.when(
      loading: () => Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Row(
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 10),
            Text(
              'AI insight…',
              style: AppTextStyles.caption.copyWith(color: AppTokens.inkMuted),
            ),
          ],
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (insight) {
        if (insight == null) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTokens.surfaceMuted,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.auto_awesome_outlined,
                    color: AppTokens.inkSecondary, size: 20),
                const SizedBox(width: 12),
                Expanded(child: Text(insight, style: AppTextStyles.body)),
              ],
            ),
          ),
        );
      },
    );
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/features/daily_close/daily_report_screen_test.dart`
Expected: `All tests passed!` (existing tests + 2 new)

- [ ] **Step 5: Commit**

```bash
git add lib/features/daily_close/daily_report_screen.dart test/features/daily_close/daily_report_screen_test.dart
git commit -m "feat(daily-close): async AI insight card below the rule-based insight"
```

---

### Task 12: Full verification + README

**Files:**
- Modify: `README.md` (new section after "Run on Android")

- [ ] **Step 1: Full static analysis**

Run: `flutter analyze`
Expected: `No issues found!` — fix anything reported before proceeding.

- [ ] **Step 2: Full test suite**

Run: `flutter test`
Expected: `All tests passed!` (every pre-existing test plus all new AI tests).

- [ ] **Step 3: Document the AI build flag**

In `README.md`, add this section after the "Run on Android" section:

```markdown
## AI features (optional, online)

DukaSmart's AI features — "Ask your duka" natural-language Q&A and the AI
daily-report insight — are demo features that activate only when an
Anthropic API key is provided at build time:

```
flutter run -d <device-id> --dart-define=ANTHROPIC_API_KEY=sk-ant-...
```

Without the define, the app is the unchanged offline app: no AI surfaces
render and no network calls are made. The key is baked into that build
only — do not distribute an APK built with a real key. All AI tools are
read-only; money figures shown by the AI are computed locally by the app
and quoted verbatim.
```

- [ ] **Step 4: Manual smoke test (requires a real key + internet)**

Run: `flutter run -d chrome --web-port=8770 --dart-define=ANTHROPIC_API_KEY=<real key>`

Verify by hand:
1. Dashboard shows the "Ask about your duka…" bar; without the define it does not.
2. Asking "What did I sell today?" answers with the seeded/demo data figures.
3. Asking in Swahili gets a Swahili reply.
4. Close the day, open the Daily Report: rule-based insight appears instantly, AI card loads below it.
5. Toggle airplane mode / kill network: chat shows the offline bubble; report shows no AI card; rest of the app works.

- [ ] **Step 5: Commit**

```bash
git add README.md
git commit -m "docs: document optional AI build flag"
```

---

## Spec coverage check (for the executor)

| Spec section | Tasks |
|---|---|
| AiGateway seam + AnthropicGateway + key gating | 1, 5, 6, 7 |
| 6 read-only tools + dispatcher + AiQueryService | 3, 5 |
| Tool-use loop rules (full content echo, tool_use_id, 5-round cap, refusal) | 6 |
| ShopSnapshot one-shot insight | 4, 6, 7, 11 |
| ProjectionService pure math | 2 |
| Ask bar on dashboard -> /ask screen, chips, session-only thread | 8, 9, 10 |
| Daily report AI card, rule-based fallback untouched | 11 |
| Error handling (offline/busy/error mapping, friendly copy) | 6, 8, 9 |
| Testing strategy (unit + MockClient + widget) | every task |
| Dependency changes (`http` only) | 1 |
| Out of scope items | none implemented — correct |
