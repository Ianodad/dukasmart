# DukaSmart

DukaSmart is an Android inventory and sales app built for a single Kenyan kiosk
owner — one owner, one kiosk, one phone, local-first data ("Know your stock.
Grow your business."). Nothing leaves the device unless the optional AI
features below are built in. It covers the full daily workflow of a small duka: add
products and opening stock, record sales (cash or M-PESA), watch stock
auto-reduce, log expenses, keep an eye on low-stock items, and close the day
with a plain-language summary of what happened and why.

## Demo

[![DukaSmart demo](docs/dukasmart-promo.gif)](docs/dukasmart-promo.mp4)

*Click the preview for the full-quality MP4 ([`docs/dukasmart-promo.mp4`](docs/dukasmart-promo.mp4)).*

## Screenshots

| Dashboard | New Sale | Payment | Sale Complete |
|---|---|---|---|
| ![Dashboard](docs/screenshots/13-dashboard-live.png) | ![POS](docs/screenshots/10-pos-cart.png) | ![Payment](docs/screenshots/11-payment.png) | ![Success](docs/screenshots/12-sale-success.png) |

More in [`docs/screenshots/`](docs/screenshots/) — products, expenses, add
stock, low stock, and close day.

## Prerequisites

- **Flutter 3.38.3**, installed at `~/flutter` (add to `PATH` before running
  any command below: `export PATH="$HOME/flutter/bin:$PATH"`).
- **Android SDK** at `~/Android/Sdk` (for building/running on a device).
- **Linux native test/build deps** — Drift's `sqlite3` native-asset hook needs
  a working C toolchain: install `clang`, `cmake`, and `ninja` (via Homebrew on
  Linux, or your distro's equivalents) before running `flutter test` or
  building natively.

Run `flutter pub get` once after cloning.

## Run on Chrome (fastest dev loop)

```
flutter run -d chrome --web-port=8770
```

Chrome is a time-boxed dev aid only — Drift on web loads `sqlite3.wasm` /
`drift_worker.js` from `web/`. It is not the release target.

## Run on Android

Connect a physical device via `adb` (preferred over an emulator for this
project) and confirm it's visible:

```
adb devices
flutter run -d <device-id>
```

## AI features (optional, online)

DukaSmart's AI features — "Ask your duka" natural-language Q&A and the AI
daily-report insight — activate only when an Anthropic API key is compiled
into the build. This is a decision made by whoever builds the app, not a
setting the shop owner can toggle at runtime; there is no in-app switch:

```
flutter run -d <device-id> --dart-define=ANTHROPIC_API_KEY=sk-ant-...
```

Without the define, the app is the unchanged offline app: no AI surfaces
render and no network calls are made. The key is baked into that build
only — do not distribute an APK built with a real key. All AI tools are
read-only; the AI never writes to the database. Money figures are computed
locally by the app and passed to the model, which is instructed to quote
them verbatim — the app does not re-validate the wording it gets back, so
treat AI prose as a summary and the app's own screens as authoritative. The daily
report also keeps its original rule-based, deterministic insight
generator — it is not gone, it is the offline fallback used whenever no
key is provided or the device has no connectivity.

**Privacy:** when AI features are active, these are sent to Anthropic's
API — the user's question, the conversation thread, the results of the
read-only tools, and the daily-close snapshot.

"Tool results" is not only aggregates, so be specific. The five tools send:

| Tool | What goes over the wire |
|---|---|
| `salesSummary` | period totals — sales, cash/M-PESA split, counts |
| `topProducts` | per-product rows: name, quantity sold, revenue |
| `expensesSummary` | totals grouped by category and by free-text reason |
| `stockLevels` | a product count, plus one row per product: name, quantity, unit, low-stock threshold, is-low flag |
| `dailyCloses` | the stored close rows in full — date, sales, expenses, COGS, gross profit, net result, expected/actual cash, difference |

So individual product names and stock positions do leave the device;
individual sale and expense transactions do not. DukaSmart holds no customer
data, so none is sent. `lib/core/ai/ai_query_service.dart` is the definitive
list — check it there rather than trusting this table if the two disagree.

Nothing is transmitted at all when no key is compiled in. Use a scoped /
expiring demo key for any live demo and revoke it afterward.

**In progress, no UI yet:** receipt / notebook-page photo extraction —
photographing a supplier receipt to restock, or a handwritten catalog
page to create products — is planned but not built. The extraction
schemas, the image capture/decode pipeline, and vision support in the
Anthropic gateway are merged, but there is no screen for either feature —
no camera flow for receipt or notebook extraction exists. (The barcode
scanner on Add Product and New Sale is unrelated and does ship.) Once
built, the photo
would be sent to Anthropic for extraction; DukaSmart would not retain
the photo or store it in the database, though the system photo picker
may keep a temporary copy in the OS cache.

**Known gap:** the Android release/profile manifest carries the
`INTERNET` permission needed to reach the API from a real device build,
but this has only been verified by static inspection of the manifest —
it has not been exercised end-to-end on an Android profile/release build
in this environment (no device was available). Verify on-device before a
real demo. The Chrome dev target does not exercise Android permissions at
all.

## Release build

```
flutter build apk --release
```

The APK is written to `build/app/outputs/flutter-apk/app-release.apk`.

## Tests

```
flutter test
```

269 tests, all passing. `flutter analyze` reports no issues. This includes
widget tests (dashboard, ask, add_stock, close_day, record_expense, and
daily_report screens) alongside the unit tests.

Quirk: the Drift code generator needs the JIT VM, not AOT-snapshot mode —
if `dart run build_runner build` fails or hangs on this machine, re-run it
with `--force-jit`:

```
dart run build_runner build --delete-conflicting-outputs --force-jit
```

## Seed data (first launch)

On first run (fresh database file), five demo products are seeded along with
an `openingStock` movement for each:

| Product | Buy | Sell | Stock | Unit | Threshold |
|---|---|---|---|---|---|
| Coca-Cola 500ml | 55 | 70 | 24 | Bottle | 6 |
| Brookside Milk 500ml | 55 | 65 | 12 | Packet | 5 |
| Jogoo Maize Flour 2kg | 180 | 210 | 10 | Packet | 4 |
| Sugar 1kg | 145 | 170 | 8 | Packet | 4 |
| Bread 400g | 55 | 65 | 5 | Piece | 3 |

(Prices are KES shillings for readability here; they're stored as integer
cents internally.)

## What's explicitly out of scope (MVP)

DukaSmart is a deliberately small, one-day MVP. This list describes that
original one-day baseline; the optional AI layer described above was added
afterward and is documented there, not here. The following are **not**
included by design:

- Auth/login, employee roles
- Customer accounts or credit
- Multi-branch support, cloud sync, or any backend
- KRA eTIMS integration
- Daraja / M-PESA API integration (M-PESA payments are recorded manually —
  amount + optional transaction code — with no live API call)
- Receipt printing (including Bluetooth printing)
- Push notifications
- Data export
- Refunds or discounts
- Mixed payments (a sale is cash *or* M-PESA, not split)
- Expiry tracking
- Barcode product lookup against an external catalog
- Suppliers / purchase orders

## Project structure

```
lib/
  app/                App shell, router (GoRouter), theme
  core/
    ai/                Anthropic gateway, tool definitions, extraction
                       schemas, snapshot builder
    capture/           Image decode / resize / re-encode for vision calls
    database/         Drift schema, DAOs, enums, errors (frozen data layer)
      daos/
    formatting/        Money parsing/formatting (int-cents everywhere)
    models/            Shared DTOs (e.g. DailyMetrics, ClosedDayReport)
    widgets/           Shared widgets (SummaryCard, MoneyText, etc.)
  features/
    assistant/         Ask your duka screen + controller
    dashboard/         Home dashboard
    products/          Product list, Add Product, common-products catalog
    inventory/         Add Stock, Low Stock
    sales/             New Sale (POS), cart, Payment, Sale Success
    expenses/          Expense list, Record Expense
    daily_close/       Close Day, Daily Report, rule-based insight generator
  main.dart
docs/
  specs/               Requirements + design decisions (binding contracts)
  plans/               Build plan + handoff notes
test/                  Unit and widget tests (money math, DAO invariants,
                       close-day math, insight generator, dashboard, ask,
                       add_stock, close_day, record_expense, daily_report)
```


