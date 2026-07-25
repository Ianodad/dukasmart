# DukaSmart MVP Implementation Plan

> **For agentic workers:** Execute your assigned task ONLY. Specs: `docs/specs/2026-07-25-requirements.md` (product) + `docs/specs/2026-07-25-design.md` (v1.3, Codex-approved — BINDING). Steps use checkbox (`- [ ]`) syntax. If your task conflicts with the design doc, the design doc wins; escalate, don't improvise.

**Goal:** Working Flutter Android MVP for a Kenyan kiosk: products, stock, cash/M-PESA sales, expenses, low-stock, close-day, daily report — all on local Drift/SQLite.

**Architecture:** Foundation-first: the entire data layer (schema, DAOs, DTOs, routes, theme, shared widgets) is built serially and frozen (design D9), then four worktree-isolated tracks implement screens only, touching nothing outside their own `lib/features/<x>/` directory (design D6). Serial integration wires, reviews, and ships the APK.

**Tech Stack:** Flutter 3.38 / Dart, flutter_riverpod, go_router (StatefulShellRoute), drift + drift_flutter (native Android; WASM on web per design D7 — verify package set against current drift docs at setup time), mobile_scanner, image_picker, intl, path_provider.

---

## Phase F — Foundation (serial, ONE executor, branch `phase/foundation`)

### Task F0: Scaffold

**Files:** project root (already contains `docs/` + git).

- [ ] `git checkout -b phase/foundation`
- [ ] `flutter create . --project-name dukasmart --platforms android,web --org com.dukasmart`
- [ ] Replace `pubspec.yaml` deps: `flutter_riverpod`, `go_router`, `drift`, `drift_flutter`, `sqlite3`, `mobile_scanner`, `image_picker`, `intl`, `path_provider`, `path`; dev: `drift_dev`, `build_runner`, `flutter_lints`. Resolve current compatible versions via `flutter pub add` (design D7: verify drift web/native setup against current docs — context7/pub.dev — do NOT assume `sqlite3_flutter_libs`).
- [ ] Web assets per current drift docs: `sqlite3.wasm` (from the pinned `sqlite3` package release) + `drift_worker.dart.js` (from the pinned drift release) into `web/`.
- [ ] `flutter analyze` clean → commit `chore: scaffold DukaSmart`.

### Task F1: Core enums + money

**Files:** Create `lib/core/formatting/money.dart`, `lib/core/database/enums.dart`, `test/core/money_test.dart`.

- [ ] `enums.dart`:

```dart
enum ProductUnit { piece, packet, bottle, kilogram, litre, crate, carton, tray, other }
enum PaymentMethod { cash, mpesa }
enum ExpenseCategory { stockTransport, electricity, airtime, food, rent, repairs, personalWithdrawal, other }
enum MovementType { openingStock, stockReceived, sale, manualCorrection }
```

Each enum gets a `label` getter with the display strings from the requirements (e.g. `stockTransport` → "Stock transport").

- [ ] `money.dart` — int cents only, `double * 100` banned (design D2):

```dart
/// Parses "55", "55.5", "55.50" → cents. Returns null on invalid input.
int? parseKesToCents(String input) {
  final t = input.trim();
  if (t.isEmpty) return null;
  final m = RegExp(r'^(\d+)(?:\.(\d{1,2}))?$').firstMatch(t);
  if (m == null) return null;
  final shillings = int.parse(m.group(1)!);
  final frac = m.group(2);
  final cents = frac == null ? 0 : int.parse(frac.padRight(2, '0'));
  return shillings * 100 + cents;
}

/// 1245000 → "KES 12,450"; 1245050 → "KES 12,450.50"
String formatCents(int cents) { /* intl NumberFormat('#,##0'), append .xx only when cents % 100 != 0 */ }
```

- [ ] Failing tests first (`money_test.dart`): `parseKesToCents('55') == 5500`, `'55.5' == 5550`, `'55.50' == 5550`, `'' == null`, `'-5' == null`, `'1.234' == null`; `formatCents(1245000) == 'KES 12,450'`, `formatCents(5550) == 'KES 55.50'`, `formatCents(0) == 'KES 0'`. Run → fail → implement → pass → commit `feat: money core`.

### Task F2: Drift schema + database

**Files:** Create `lib/core/database/tables.dart`, `lib/core/database/database.dart`; generated `database.g.dart` via build_runner.

- [ ] `tables.dart` — exactly six tables (requirements §DB; prices nullable per design D3):

```dart
class Products extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1)();
  TextColumn get barcode => text().nullable()();
  TextColumn get imagePath => text().nullable()();
  IntColumn get buyingPrice => integer().nullable()();   // cents
  IntColumn get sellingPrice => integer().nullable()();  // cents
  IntColumn get quantity => integer().withDefault(const Constant(0))();
  TextColumn get unit => textEnum<ProductUnit>()();
  IntColumn get lowStockThreshold => integer().withDefault(const Constant(5))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}
class Sales extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get subtotal => integer()();          // cents
  IntColumn get total => integer()();             // cents
  TextColumn get paymentMethod => textEnum<PaymentMethod>()();
  IntColumn get amountReceived => integer()();    // cents
  IntColumn get changeAmount => integer()();      // cents
  TextColumn get mpesaCode => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
}
class SaleItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get saleId => integer().references(Sales, #id)();
  IntColumn get productId => integer().references(Products, #id)();
  TextColumn get productName => text()();
  IntColumn get quantity => integer()();
  IntColumn get buyingPriceSnapshot => integer()();   // cents; product.buyingPrice ?? 0
  IntColumn get sellingPriceSnapshot => integer()();  // cents
  IntColumn get total => integer()();                 // cents
}
class Expenses extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get amount => integer()();            // cents
  TextColumn get category => textEnum<ExpenseCategory>()();
  TextColumn get description => text().nullable()();
  TextColumn get paymentMethod => textEnum<PaymentMethod>()();
  DateTimeColumn get createdAt => dateTime()();   // see design D3 expense semantics
}
class StockMovements extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get productId => integer().references(Products, #id)();
  TextColumn get movementType => textEnum<MovementType>()();
  IntColumn get quantity => integer()();          // signed: +in / −sale (design D3)
  TextColumn get note => text().nullable()();
  IntColumn get referenceId => integer().nullable()();
  DateTimeColumn get createdAt => dateTime()();
}
class DailyCloses extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime().unique()(); // normalized to local midnight
  IntColumn get totalSales => integer()();
  IntColumn get cashSales => integer()();
  IntColumn get mpesaSales => integer()();
  IntColumn get expenses => integer()();
  IntColumn get costOfGoods => integer()();
  IntColumn get grossProfit => integer()();
  IntColumn get netResult => integer()();
  IntColumn get expectedCash => integer()();
  IntColumn get actualCash => integer()();
  IntColumn get cashDifference => integer()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
}
```

- [ ] `database.dart`: `@DriftDatabase(tables: [...], daos: [...])`; connection via `driftDatabase(name: 'dukasmart')` (drift_flutter) with the web options required by current docs. `MigrationStrategy.onCreate` = create all + **seed** (design D3): the 5 demo products (requirements table, prices ×100 to cents) each with an `openingStock` movement of its quantity.
- [ ] `dart run build_runner build` → analyze clean → commit `feat: drift schema + first-run seed`.

### Task F3: DAOs (the frozen atomic surface — design D3, verbatim contracts)

**Files:** Create `lib/core/database/daos/products_dao.dart`, `stock_dao.dart`, `sales_dao.dart`, `expenses_dao.dart`, `daily_close_dao.dart`; tests in `test/core/daos/`.

Signatures (FROZEN):

```dart
// ProductsDao
Future<int> createProduct(ProductsCompanion p, {required int openingQty});      // tx: insert + openingStock movement if qty>0; duplicate non-empty barcode → throw DukaError.duplicateBarcode
Stream<List<Product>> watchProducts({String? query, bool lowStockOnly = false});
Future<Product?> getByBarcode(String barcode);
Future<void> updateProduct(Product p);                                          // sets updatedAt
// StockDao
Future<void> receiveStock({required int productId, required int qty, int? newBuyingPriceCents, String? note}); // tx: qty>0, +quantity, optional price update, stockReceived movement
// SalesDao
Future<int> completeSale({required List<CartLine> lines, required PaymentMethod method, required int amountReceivedCents, String? mpesaCode}); // enforces design D3 invariants (a)–(f) inside tx
Future<SaleWithItems> getSale(int saleId);
// ExpensesDao
Future<void> recordExpense({required int amountCents, required ExpenseCategory category, String? description, required PaymentMethod method, required DateTime selectedDate}); // design D3 createdAt semantics; amount>0; future date → throw
Stream<List<Expense>> watchExpensesForDay(DateTime day);
// DailyCloseDao
Future<void> closeDay({required DateTime date, required int actualCashCents, String? note}); // tx: recompute D4 aggregates from tables, upsert by date
Future<DailyClose?> getClose(DateTime date);
```

`CartLine = ({int productId, int quantity})`. Day filters use half-open local bounds helper `dayBounds(DateTime d)` in `lib/core/database/day_bounds.dart`.

- [ ] TDD each DAO against an in-memory `NativeDatabase.memory()`. Mandatory test cases (design D10): `completeSale` reduces stock and writes movements with `referenceId = saleId`; aborts entirely when one line exceeds stock (no partial writes); rejects empty cart, null-selling-price product, cash `amountReceived < total`, mpesa `amountReceived != total`; totals recomputed from DB prices, not caller input. `receiveStock` rejects `qty <= 0`. `recordExpense` backdated → local midnight; today → now; future → error. `closeDay` twice on one date leaves one row with refreshed figures. Day-bounds: expense at 23:59 in, 00:00 next day out.
- [ ] Commit `feat: atomic DAOs + tests`.

### Task F4: Read models + providers (frozen)

**Files:** Create `lib/core/models/daily_metrics.dart`, `lib/core/models/closed_day_report.dart`, `lib/core/providers.dart`.

```dart
class DailyMetrics {           // design D4 formulas, all int cents
  final int totalSales, cashSales, mpesaSales, expensesTotal, cashExpenses,
      cogs, grossProfit, netResult, txCount, lowStockCount;
  final List<Product> lowStock, outOfStock, missingBuyingPrice, missingSellingPrice;
  final BestSeller? bestSeller; // (productId, name, qtySold, revenue) — D4 tie-breaks
}
class ClosedDayReport {        // design D4: Daily Report contract
  final DailyClose close;      // stored financials ("as at close")
  final BestSeller? bestSeller;// derived from that date's sale_items ("for the day")
  final List<Product> lowStockNow; // current levels ("current")
}
```

- [ ] `providers.dart` (FROZEN registrations): `databaseProvider`, per-DAO providers, `dailyMetricsProvider = StreamProvider<DailyMetrics>` (today, live-recomputed via drift watch on sales/sale_items/expenses/products), `closedDayReportProvider = FutureProvider.family<ClosedDayReport?, DateTime>`, `productsProvider`, `expensesTodayProvider`.
- [ ] Unit-test DailyMetrics math (design D10): known fixture → every D4 number, best-seller tie → higher revenue → alphabetical; no sales → null bestSeller. Commit `feat: DailyMetrics + ClosedDayReport read models`.

### Task F5: Theme, shared widgets, router, splash, stubs

**Files:** Create `lib/app/theme.dart`, `lib/app/router.dart`, `lib/app/app.dart`, `lib/main.dart`, `lib/core/widgets/` (SummaryCard, ProductListTile, StockStatusChip, MoneyText, PrimaryButton, EmptyState, NumericInputField, PaymentMethodSelector, CartItemTile, SectionHeader, ConfirmationDialog, BarcodeField), `lib/features/dashboard/splash_screen.dart`, plus ONE stub screen file per feature screen.

- [ ] Theme per requirements §Design direction: seed `Color(0xFF1B5E20)` dark green, Material 3, light; amber warn, red error, blue M-PESA accent const; large text styles for totals.
- [ ] `BarcodeField` (design D7): manual barcode `TextField` + scan `IconButton` → full-screen `MobileScanner` with `errorBuilder` fallback returning to manual entry — the ONLY scanner wrapper any track may use.
- [ ] Shared widget contracts: `MoneyText(int cents, {TextStyle? style})` (sole money renderer); `NumericInputField` returns validated cents/int qty via `parseKesToCents`; `PaymentMethodSelector(PaymentMethod, onChanged)`; others take plain data + callbacks.
- [ ] Router (FROZEN route table, design D6): `StatefulShellRoute.indexedStack` tabs `/home /sell /products /expenses`; pushed: `/home/add-stock`, `/home/low-stock`, `/home/close-day`, `/home/report`, `/products/add`, `/sell/payment`, `/sell/success/:saleId`; `/` = Splash (Foundation-owned) → waits for DB open → `context.go('/home')`.
- [ ] Stub screens: every route's screen file exists in its feature folder rendering `EmptyState(title: '<Screen> — under construction')`. Tracks replace stub bodies (design D6 write rule).
- [ ] `flutter analyze` clean; `flutter test` green; app boots in Chrome to Home stub. Commit `feat: app shell — theme, router, widgets, splash, stubs`. **Tag `foundation-frozen`.**

---

## Phase T — Tracks (4 parallel Sonnet executors, worktrees off `foundation-frozen`)

Common rules for every track: modify/add files ONLY inside your `lib/features/<feature>/` dir; consume frozen DAOs/providers/widgets — never raw drift; `MoneyText` for every amount; every list gets `EmptyState`; submit buttons disabled while an async submit is in flight (design D3); `flutter analyze` clean + `flutter test` green before done; report done/diverged/blocked + file list.

### Task T1: Products & Inventory (`phase/track-products`) — `lib/features/products/` + `lib/features/inventory/`

- [ ] **Product List** (`/products`): watchProducts stream; ProductListTile rows (name, MoneyText selling price or "No price", qty + unit label, StockStatusChip: qty==0 red Out of Stock / qty<=threshold amber Low Stock / green In Stock); search field (name contains, case-insensitive); low-stock filter chip; `BarcodeField` scan → filter to match else "Product not found" snackbar; FAB → `/products/add`.
- [ ] **Add Product** (`/products/add`): fields name*, BarcodeField, image (image_picker → copy file to `getApplicationDocumentsDirectory()`, store durable path; hide option on web — design D7), buying price, selling price (nullable — empty = null, `NumericInputField`), opening qty (int ≥0, default 0), unit dropdown (ProductUnit labels), threshold (default 5). Live "Profit per unit" row when both prices set. Save → `createProduct(companion, openingQty)`; duplicateBarcode error → inline field error. Cancel/save → back to list.
- [ ] **Add Stock** (`/home/add-stock`): product dropdown (or preselected via `extra`), qty received* (>0), latest buying price (prefilled current, optional change), note → ConfirmationDialog summary → `receiveStock` → snackbar + pop.
- [ ] **Low Stock** (`/home/low-stock`): products where qty<=threshold; rows show name, qty, threshold, price; actions: Add Stock (→ `/home/add-stock` with product preselected), View Product → **bottom sheet** (design D5) with details + Add Stock button. EmptyState: "No low-stock products. Well stocked!"

### Task T2: Sales/POS (`phase/track-sales`) — `lib/features/sales/`

- [ ] **Cart notifier** (feature-local, in-memory): `Map<int productId, int qty>`; add/increment/decrement/remove; guard: qty never exceeds product stock (advisory — DAO re-checks); expose lines + `totalCents` computed from product selling prices.
- [ ] **New Sale** (`/sell`): search field + `BarcodeField` (scan match → add to cart, else snackbar); product grid/list tiles (name, MoneyText price, stock left); null-selling-price tiles disabled with explanatory snackbar on tap (design D5); cart section with CartItemTile (+/−/remove, line total); sticky bottom bar: MoneyText total + PrimaryButton "Proceed to Payment" (disabled when cart empty) → `/sell/payment`.
- [ ] **Payment** (`/sell/payment`): big total; `PaymentMethodSelector`. Cash: amount received (NumericInputField, must be ≥ total — validator) with live "Change due" MoneyText. M-PESA: amount must equal total (prefilled, validation error if edited to differ), optional transaction code, button "Confirm M-PESA Payment". Submit → `completeSale(...)` (double-tap guarded) → clear cart AFTER success → `/sell/success/:saleId`. DAO errors (stock changed) → snackbar, stay.
- [ ] **Sale Success** (`/sell/success/:saleId`): check icon, MoneyText total, method, change (cash only), timestamp (`intl` date+time). Buttons: New Sale (`go('/sell')`), Return Home, View Sale → **bottom sheet** (design D5) listing items via `getSale(saleId)`.

### Task T3: Expenses & Dashboard UI (`phase/track-expenses`) — `lib/features/expenses/` + `lib/features/dashboard/` (dashboard_screen.dart only; splash is frozen)

- [ ] **Expense List** (`/expenses`): today's total (from `dailyMetricsProvider.expensesTotal`); `watchExpensesForDay(today)` list — category label, MoneyText amount, method, time (same-day entries show time; backdated show date — design D3); Record Expense button.
- [ ] **Record Expense** (`/expenses` push or inline route): amount* (>0), category dropdown*, description, method*, date picker (default today; future dates blocked) → `recordExpense` → pop + snackbar.
- [ ] **Home Dashboard** (`/home`): renders `dailyMetricsProvider` ONLY (no new aggregates — design D1): SummaryCards for today's sales, cash, M-PESA, expenses, gross profit, low-stock count; quick actions New Sale / Add Product / Add Stock / Record Expense / Close Day (navigate to frozen routes); **Attention Needed** SectionHeader + list: low-stock (amber), out-of-stock (red), missing buying price, missing selling price — each row tappable to the relevant screen; EmptyState "All good!" when empty; loading/error states for the stream.

### Task T4: Daily Close & Report (`phase/track-close`) — `lib/features/daily_close/`

- [ ] **Close Day** (`/home/close-day`): live preview from `dailyMetricsProvider`: total/cash/M-PESA sales, expenses, COGS, gross profit, net result, txCount, low-stock count (all MoneyText/labels); inputs: actual cash counted* (NumericInputField), note; live `Expected cash` (= cashSales − cashExpenses) and `Difference` (= actual − expected, green ≥0 / red <0); PrimaryButton "Complete Day" → ConfirmationDialog (warns "replaces today's earlier close" when `getClose(today) != null` — design D4 upsert) → `closeDay` → `/home/report`.
- [ ] **Daily Report** (`/home/report`, optional `?date=`): `closedDayReportProvider(date)`. Null → EmptyState "Day not closed yet" + Close Day button (design D4). Else: date header; stored financials labeled "as at close"; cash difference colored; best-seller "for the day"; low-stock list "current"; **Insight card** — feature-local pure-Dart generator (design D4 template rules; testable function `String buildInsight(ClosedDayReport r)` + unit test covering: sales sentence always; M-PESA % only when sales>0; best-seller/low-stock/cash-diff sentences conditional).

---

## Phase I — Integration (serial, orchestrator-supervised, branch `phase/integration`)

- [ ] Merge foundation → main; merge each reviewed track (no-ff) — file-disjoint by construction; resolve any residuals manually.
- [ ] Per-track independent **Sonnet xhigh reviews** (routine tier) before merge; fixes applied by the track's executor.
- [ ] Full acceptance flow in Chrome (requirements §Acceptance): add product → add stock → sale (cash AND M-PESA) → stock reduced → expense → dashboard totals → close day → report.
- [ ] **Mandatory Android run** (design D7): `adb devices` — physical device if present; else STOP and flag Ian before downloading emulator image.
- [ ] `flutter build apk --release` → note APK path + size.
- [ ] README.md: what it is, run instructions (Chrome + Android), build instructions, seed-data note, MVP exclusions link to specs.
- [ ] Final commit + orchestrator synthesis to `docs/plans/SYNTHESIS.md` (built / diverged / open flags).

## Self-review notes
- Spec coverage: 13 screens → F5 stubs + T1(4) T2(3+cart) T3(3) T4(2) + splash(F5) = 13 ✓; 6 tables F2 ✓; all business rules land in F3 DAO contracts + track validators ✓; seed F2 ✓; APK + README Phase I ✓.
- Type consistency: `CartLine`, `DailyMetrics`, `ClosedDayReport`, DAO names used identically in F3/F4/T2/T3/T4 ✓.
- No placeholders: track UI steps intentionally spec behavior against frozen contracts rather than paste widget code — executors are competent; contracts are what prevent drift.
