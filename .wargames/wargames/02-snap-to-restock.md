# Wargame 02 — Snap-to-Restock (rev 5)

Branch: `feature/ai-capabilities`. Repo: `/data/Documents/Flutter/dukasmart`.
Brief: `.wargames/tasks/02-snap-to-restock.md`.
**Depends on mission 01 (rev 6) being merged first AND its M10 exit gate
passing with `receipts=YES` (checked in M0).**
Rev 2 incorporated Codex plan-lock round-1 findings 02.1–02.10 (2026-07-27).
Rev 3 incorporates Codex plan-lock round-2 findings F1–F7 (2026-07-27) — the
retry ledger, confirmation snapshot, discard race, catalog acquisition, price
parse-state, `nearMisses` spec, and batch-contract staleness fixed below.
Rev 4 closes Codex plan-lock round-3 findings (2026-07-27) — retry-ledger
reachability, phase-one commit safety, and cleared-quantity validation — all
ACCEPTED.
Rev 5 applies Ian's per-feature model split (2026-07-27): extraction runs on
Haiku, reversing D-02c; see D-02c below and the sharpened M0 gate check.

**Settled facts (read from source this session — cite, don't re-derive):**
- `StockDao.receiveStock({productId, qty, newBuyingPriceCents, note,
  tillCashOutCents})` (`stock_dao.dart:26`): validates `qty > 0`,
  `newBuyingPriceCents >= 0` when present, `tillCashOutCents > 0` when
  present — ALL BEFORE the transaction opens. Inside one `transaction()`:
  product lookup (null → `DukaError.notFound`), quantity bump +
  `updatedAt` + conditional buyingPrice via `ProductsCompanion`,
  `StockMovementsCompanion.insert(movementType: stockReceived, quantity: qty,
  note: Value(note), createdAt: DateTime.now())`, then when till is present
  `attachedDatabase.expensesDao.recordExpense(amountCents:, category:
  ExpenseCategory.stockPurchase, description: 'Stock: ${product.name} ×$qty',
  method: PaymentMethod.cash, selectedDate: DateTime.now())`.
- `ProductsDao.createProduct(ProductsCompanion p, {required int openingQty})`
  (`products_dao.dart:25`): one transaction; throws before any write on
  empty/whitespace name, negative buying/selling price, negative openingQty,
  negative threshold, duplicate non-empty barcode. **Null prices allowed.**
  Forces `quantity` to `openingQty`; writes an `openingStock` movement ONLY
  when `openingQty > 0`. Returns the new id.
- Companion shape to copy (`add_product_screen.dart:270`):
  `ProductsCompanion.insert(name:, barcode: Value(...), imagePath:
  Value(...), buyingPrice: Value(...), sellingPrice: Value(...), unit:,
  lowStockThreshold: Value(...), createdAt: now, updatedAt: now)`.
- `productsProvider` (`lib/core/providers.dart:34`) is a
  `StreamProvider<List<Product>>` wrapping `ProductsDao.watchProducts()`
  (`products_dao.dart:81`) — it must be **awaited** via `.future`, never
  read via `valueOrNull ?? []`, before matching (F4 — a not-yet-delivered
  stream looks identical to a genuinely empty catalog and would push every
  row toward a duplicate create).
- `aiGatewayProvider` THROWS `StateError` when read without a configured key
  (`ai_providers.dart:29`) — gating is mandatory before any read.
- `AskController` A8.1 guard: `bool _disposed`, set via
  `ref.onDispose(...)` in `build()`, checked after EVERY await, `finally`
  writes gated on `!_disposed` (`ask_controller.dart:41-106`).
- `SaleSubmitController` (`lib/features/sales/sale_submit_controller.dart`)
  is the app's precedent for double-submit guarding.

**Brief amendments recorded here (Codex 02.2 — resolved by amendment, not
silently):**
- **AM-1 Entry points.** The brief said "an action on the inventory/stock
  screen"; there is no single such screen. Entry points are the **Add Stock
  screen AppBar** (primary — it is the stock-receiving surface and the
  manual alternative the owner would otherwise type into; all three existing
  restock paths land there) and the **Low Stock screen AppBar** (secondary —
  where restock intent originates). Both `if (ref.watch(aiAvailableProvider))`.
  The Products tab is deliberately left to mission 03 (catalog surface) to
  avoid two AI actions competing on one AppBar.
- **AM-2 Cancellation (revised after Fable advisor pass).** At a counter,
  interruption is the NORMAL case — a customer walks up mid-extraction. So
  leaving the screen must NOT throw the work away. The controller takes a
  `KeepAliveLink` (`ref.keepAlive()`) for the duration of the extraction and
  holds it while a `review` state exists; the link is released on `done`, on
  `failed`, or when the owner explicitly discards. Returning to the screen
  restores the review in progress. There is still no HTTP abort
  (`package:http` offers none here), so an explicit **Discard** button says
  exactly that — it drops the result, it does not cancel a request.
- **AM-3 Supplier payment method (Fable advisor finding — money-trust).** The
  earlier plan pre-ticked "Paid from till (cash)" whenever the receipt
  carried a total, and `receiveStock` hardcodes `PaymentMethod.cash`. Duka
  suppliers are very often paid by M-PESA or on credit; a rubber-stamped
  pre-tick would book a cash out-flow that never happened and break drawer
  reconciliation at daily close. Replaced by an EXPLICIT three-way choice —
  **"Not paid yet" (default, records nothing) / "Cash from till" / "M-PESA"**
  — with the amount prefilled so the correct answer is one tap. Rationale for
  the default: omitting an expense leaves expected cash too high (visible,
  correctable); inventing a cash out-flow makes the drawer silently wrong.
  Never default to writing money.

**Design decisions (do not re-decide):**
- **D-02a** Add `StockDao.receiveStockBatch` — see M2 for the full contract.
  Logged amendment to the frozen D3/D9 surface.
- **D-02b (revised per Codex 02.1, ledger mechanics fixed per F1)** New
  products are created with **`openingQty: 0`**, and their generated ids are
  stored in the `SnapRestockSaving.createdIdsByRowId` ledger — updated after
  EVERY successful create, and merged back into the restored review's rows
  on any failure (see M3 `save(plan)`) — so a retry reuses the stored ids
  instead of re-deriving them from scratch. Then **every** confirmed line —
  newly created and pre-existing — goes through ONE `receiveStockBatch`
  call. Residual on batch failure: zero-quantity catalog rows exist
  (visible, harmless, no stock, no expense); retry reuses the ledger so **no
  duplicate products and no double stock**. Creating products inside the
  batch transaction was rejected: it would require duplicating
  `createProduct`'s validation inside StockDao.
- **D-02c (reversed per Ian, 2026-07-27 — cost decision)** Extraction runs on
  **Haiku**, not the Ask/insight model: `gateway.extractStructured` uses the
  gateway's injected **`extractionModel`** field, which resolves to
  `AiConfig.extractionModel` (mission 01 rev 5; dart-define
  `AI_EXTRACTION_MODEL`, default `claude-haiku-4-5-20251001`). Ask-your-duka
  and the daily-close insight are unaffected — they keep reading
  `AiConfig.model` (Opus) via the gateway's `model` field. This split is
  deliberate, not an oversight: receipts are the highest-volume AI call in
  the app, so it is where per-call model cost compounds fastest, and Haiku is
  cheap enough to make that call trivial. It does not open the door to a
  third model or a model-choice UI — this mission adds no per-feature knob
  beyond this one already-decided split.

---

## Moves

**M0 — Baseline + dependency gate.**
Run: `git status --porcelain`; `grep -n "extractStructured"
lib/core/ai/ai_gateway.dart`; `cat .wargames/GATE-01-extraction-spike.md`;
`export PATH="$HOME/flutter/bin:$PATH" && flutter analyze && flutter test`.
- Expect: no modified-TRACKED lines (untracked `.wargames/`, `.agents/`,
  `.claude/`, `presentation/`, `remotion/*`, `skills-lock.json`,
  `docs/superpowers/HANDOFF.md` are known and fine); the grep prints the
  abstract `extractStructured<T>` signature; `.wargames/GATE-01-extraction-spike.md`
  exists and contains a line starting `GATE: GO` with `receipts=YES` **and a
  `model=` value equal to the effective `AiConfig.extractionModel`
  (normally `claude-haiku-4-5-20251001`)**; analyze "No issues found"; suite
  green — RECORD the count.
- Failure (gate check, new this rev): the gate file is missing, or present
  but its `GATE:` line reads anything other than `GO`, or lacks
  `receipts=YES` → cause: mission 01's exit gate did not pass, or mission 01
  hasn't been run at all → ABORT A0. This check is independent of, and in
  ADDITION to, the `extractStructured` grep below — passing one does not
  excuse skipping the other.
- Failure (gate model mismatch, new this rev): the gate file's `model=`
  value does not equal the effective `AiConfig.extractionModel` this build
  will actually run → cause: the gate validated a different model than the
  one this mission ships, so it proves nothing about the model in use →
  ABORT A0 (same abort as a missing/failing gate — do not proceed on a
  technicality that the gate merely exists).
- Failure A: grep finds nothing → cause: mission 01 not merged → ABORT A1.
- Failure B: modified tracked files → cause: a concurrent session → ABORT A1.
- Failure C: suite red → cause: pre-existing breakage, not yours → ABORT A1.

**M1 — Matcher (pure Dart, TDD, zero judgment calls).**
`lib/features/inventory/snap_restock/receipt_matcher.dart`:
```dart
String normalizeName(String s);            // lowercase, strip . , - / ( ),
                                           // collapse whitespace, trim
List<String> nameTokens(String s);         // normalizeName split on ' '
SuggestedMatch? matchLine(String rawName, List<Product> catalog);
/// Below-threshold candidates, best first — shown as suggestions inside the
/// product picker so a conservative miss still points the owner at the
/// right product (Fable advisor finding on split stock; fully specified
/// below per Codex round-2 F6).
List<SuggestedMatch> nearMisses(String rawName, List<Product> catalog);
class SuggestedMatch { final Product product; final double score; }
```
Exact rules — implement these, nothing else:
1. If `normalizeName(raw) == normalizeName(p.name)` for some product →
   `SuggestedMatch(p, 1.0)`. (Ties impossible-ish; if several, lowest id.)
2. Else if `nameTokens(raw).length == 1` → **null** (single-token names match
   only exactly).
3. Else score each product: `shared = |tokens(raw) ∩ tokens(p.name)|`,
   `score = shared / max(tokens(raw).length, tokens(p.name).length)`.
   Suggest the best ONLY if `score >= 0.6 && shared >= 2`; else null.
4. Tie-break: highest score, then lowest product id (deterministic).
5. **`nearMisses` (F6 — fully specified; reuses `normalizeName`,
   `nameTokens`, and the SAME score formula from rule 3):** if
   `nameTokens(raw).length == 1`, return `[]` (consistent with rule 2 —
   single-token raw names never get suggestions either). Otherwise score
   every catalog product with the rule-3 formula and return every product
   with `0.35 <= score < 0.6 && shared >= 1`, sorted by score descending
   then product id ascending, capped at the first 5 results.
Required `matchLine` test vectors (exact expected results — no "may"):
| raw | catalog name | expect |
|---|---|---|
| `Bread 400g` | `Bread 400g` | match 1.0 |
| `sugar  1KG` | `Sugar 1kg` | match 1.0 (normalize) |
| `Brookside Milk 500ml` | `Milk 500ml` | match 0.666… |
| `Unga Jogoo 2kg` | `Jogoo Maize Flour 2kg` | **null** (0.5 < 0.6) |
| `Soda 500ml` | `Coca-Cola 500ml` | **null** (0.33) |
| `Sugar` | `Sugar 1kg` | **null** (single token, not exact) |
Required `nearMisses` test vectors (F6 — exact expected results, no "may"):
| raw | catalog | expect |
|---|---|---|
| `Unga Jogoo 2kg` | `Jogoo Maize Flour 2kg` | appears, score 0.5 — must NOT
  auto-match via `matchLine` (above), but MUST be suggested here |
| `Sugar` | `Sugar 1kg` | `[]` (single token) |
| `Soda 500ml` | `Coca-Cola 500ml` | `[]` (score 0.33 < 0.35) |
- Expect: all nine vectors (six `matchLine` + three `nearMisses`) pass first
  run after implementation.
- Failure: a vector disagrees → cause: tokenization (e.g. `500ml` vs `500
  ml`) → counter: fix `normalizeName`/`nameTokens` only; NEVER move the
  0.6/2-token or 0.35/1-token thresholds to make a vector pass — the
  thresholds are the contract.

**M2 — `StockDao.receiveStockBatch` (TDD: DAO tests before implementation).**
```dart
typedef ReceiveLine = ({int productId, int qty, int? newBuyingPriceCents});
Future<void> receiveStockBatch({
  required List<ReceiveLine> lines,
  int? supplierPaymentCents,
  PaymentMethod? supplierPaymentMethod,   // AM-3: cash or mpesa, never assumed
  String? note,
});
```
Contract (mirrors `receiveStock` exactly — read it at `stock_dao.dart:26`
and keep semantics identical):
- Pre-transaction validation, in this order: `lines` non-empty (else
  `DukaError.invalidQuantity('Nothing to receive.')`); every `qty > 0`; every
  non-null `newBuyingPriceCents >= 0`; `supplierPaymentCents == null ||
  supplierPaymentCents > 0`; and **`supplierPaymentCents` and
  `supplierPaymentMethod` must be JOINTLY null or JOINTLY non-null (F7) —
  either dangling half (an amount with no method, or a method with no
  amount) throws `DukaError.invalidPayment`** — the DAO must never pick a
  payment method on the caller's behalf, nor silently accept a stated
  method with nothing to pay (AM-3, F7). An empty `lines` with a payment is
  REFUSED by the same non-empty rule (a supplier payment with no stock
  belongs on the Expenses screen).
- Inside ONE `transaction()`: for each line in order — lookup (null →
  `DukaError.notFound`), quantity bump + `updatedAt` + conditional
  buyingPrice, insert a `stockReceived` movement with the shared `note`.
  Duplicate `productId` across lines is ALLOWED: each line yields its own
  movement, quantities accumulate, and when both carry
  `newBuyingPriceCents` the LAST line's price wins (documented + tested).
- Then, if `supplierPaymentCents != null`, exactly ONE
  `recordExpense(category: stockPurchase, method: supplierPaymentMethod!,
  selectedDate: DateTime.now())` whose `description` follows the single-line
  convention generalised: `'Stock: N items'` for `N = lines.length`
  (single-line `receiveStock` keeps its existing `'Stock: ${name} ×$qty'` and
  its hardcoded cash method — do NOT change it).
- **Reviewer note:** this method is the only new money-write primitive in all
  of v2. Route its diff through the HARD review lane (Codex xhigh) on its
  own, not blended into the UI diff.
- Refactor: extract the per-line body of `receiveStock` into a private
  `Future<void> _applyLine(ReceiveLine line)` used by BOTH methods so the
  semantics cannot drift.
- Expect: new DAO tests green AND every existing `stock_dao_test.dart` test
  still green untouched (`flutter test test/core/daos/stock_dao_test.dart`).
  **Required test list (F7 — replaces the stale one; `tillCashOutCents` is
  not a parameter of this method and must not appear anywhere in these
  tests):** multi-line happy path; per-line price update; ONE aggregate
  expense row; cash path; M-PESA path (asserts `PaymentMethod.mpesa` is
  stored, not cash); each dangling half rejected (`supplierPaymentCents`
  with no `supplierPaymentMethod`, AND `supplierPaymentMethod` with no
  `supplierPaymentCents`, as two separate cases); `supplierPaymentCents: 0`
  rejected; one invalid line rolls back EVERYTHING (assert zero movements,
  zero expenses, unchanged quantities); duplicate productId accumulates and
  last-price-wins; empty lines rejected; and an unchanged regression run of
  the existing `receiveStock` tests.
- Failure A: existing `receiveStock` tests break after the `_applyLine`
  refactor → cause: the extraction changed ordering or dropped `updatedAt` →
  counter: diff the two code paths statement by statement; if not resolved in
  2 attempts, leave `receiveStock` byte-identical and give the batch its own
  copy of the statements → ABORT A2 only if even that fails.
- Failure B: nested-transaction error when `recordExpense` runs inside the
  batch transaction → cause: misuse of the accessor → counter: `receiveStock`
  already does exactly this (line 69) — copy that call shape verbatim.
- Failure C: a dangling-half test passes for one direction and not the
  other → cause: the joint-null check only guarded "amount without method"
  and missed "method without amount" → counter: assert both directions as
  separate test cases, not one combined case (F7).

**M3 — Controller state + logic (TDD).**
`lib/features/inventory/snap_restock/snap_restock_controller.dart`,
`AutoDisposeNotifier<SnapRestockState>`.
States: `idle` | `extracting(Uint8List previewJpeg)` | `review(...)` |
`saving(ConfirmedPlan plan, SnapRestockReview originalReview,
Map<int,int> createdIdsByRowId)` | `done(SaveOutcome)` | `failed(String
message)`. (Preview bytes live in the state so M5's thumbnail is real —
Codex 02.3. `SnapRestockSaving` carries the plan, the pre-save review, and
the running id ledger — F1: this is the shape the retry-safety guarantee
actually needs; the rev-2 shape held neither rows nor an id ledger, so
"retry creates nothing new" had nothing to restore from.)
`ReviewRow` fields — all of these, none optional unless noted:
```dart
enum RowResolution { matched, unresolved, createNew, skipped }
enum ParseState { blank, valid, invalid }        // F5
int id;                       // stable row id (index at build time)
String rawName;               // as extracted
bool include;                 // checkbox
RowResolution resolution;     // AM-4: no silent default to createNew
int? matchedProductId;        // when resolution == matched
int? createdProductId;        // filled after a successful create (retry-safe)
String name;                  // editable; used when createNew
ProductUnit unit;             // editable; default ProductUnit.piece
String qtyText;                // F5: raw text as typed
int? qty;                       // F5/round-3 R3: parsed value; null when qtyParse != valid — clearing the field resets this to null, never leaves a stale positive value
ParseState qtyParse;             // F5
String buyingPriceText;         // F5: raw text as typed
int? buyingPriceCents;          // F5: null means blank OR unparsed — see buyingPriceParse
ParseState buyingPriceParse;    // F5
String sellingPriceText;        // F5, createNew only
int? sellingPriceCents;         // editable, createNew only, nullable
ParseState sellingPriceParse;   // F5, createNew only
List<SuggestedMatch> nearMisses;   // shown in the picker
String? error;                  // per-row message set by preparePlan() (F2/F5)
```
Plus `int? receiptTotalCents`, `SupplierPayment payment` (`enum
SupplierPaymentChoice { notPaid, cashFromTill, mpesa }`, `String
amountText`, `int? amountCents`, `ParseState amountParse` — F5 applies to
the payment amount field too), `int skippedRows`, `bool truncated`.

**F5 (Codex round 2 — blank vs malformed).** Every editable numeric field
(`qty`, `buyingPriceCents`, `sellingPriceCents`, the payment `amountCents`)
parses its raw text through the SAME `NumericInputField.parseValue` the
manual forms already use (`add_product_screen.dart:218`,
`add_stock_screen.dart:93`): blank text ⇒ `ParseState.blank`, a parseable
value ⇒ `ParseState.valid`, unparseable non-blank text ⇒
`ParseState.invalid`. Only `blank` is a legitimate null — `preparePlan()`
(below) blocks on ANY field left `invalid`, matching the manual forms'
rejection of malformed non-blank money text instead of silently saving it
as "no price". **Exception — `qty` (round-3 R3):** unlike the price fields,
a blank quantity is never legitimate on an INCLUDED row: clearing
`qtyText` sets `qtyParse = ParseState.blank` AND resets `qty` to `null` in
the same edit, so the field can never keep showing its old positive number
while silently no longer backing a write; `preparePlan()` blocks an
included row whose `qtyParse != valid` exactly as it blocks `invalid`.

**AM-4 (Fable advisor finding — split stock counts).** An unmatched line must
NOT default to "create new". The matcher is deliberately conservative (its own
test vector makes `Unga Jogoo 2kg` miss `Jogoo Maize Flour 2kg`), and since
there is no product-delete path, a rubber-stamped create-new turns a staple
into two catalog rows with the stock split between them — a worse inventory
lie than the typing it saved. Unmatched rows start `unresolved`, render an
amber "Choose product" prompt listing `nearMisses` first with an explicit
"Create as new product" option below, and are EXCLUDED from save (counted and
reported) until the owner resolves them.

`start(ImageSource src)`:
0. **Take an operation token and a `KeepAliveLink`** (AM-2, F3):
   `final localGen = ++_opGeneration;` captured as a LOCAL, then `final
   link = ref.keepAlive();` stored on the controller. After EVERY `await`
   below, check BOTH `if (_disposed) return;` (A8.1) AND `if (localGen !=
   _opGeneration) return;` (F3 — a stale completion from a superseded
   `start()` or a discard must never overwrite newer state). `_opGeneration`
   is incremented on EVERY new `start()` call and on explicit discard.
1. **Fail closed FIRST** (Codex 02.4): `if (!ref.read(aiAvailableProvider))
   { state = failed('AI features are not available in this build.'); return; }`
   — before any `aiGatewayProvider` read.
2. `capture(src)` → `CaptureCancelled` ⇒ release the `KeepAliveLink` (F3 —
   the picker-cancel path was the one gap in AM-2's release discipline) and
   go back to `idle`; `CaptureFailed(tooLarge)` ⇒ `failed('That photo is too
   large — try again from a bit further back.')`; `CaptureFailed(undecodable)`
   ⇒ `failed("That file isn't a photo DukaSmart can read.")`.
3. `state = extracting(image.bytes)`.
4. **Await the catalog** (F4): `await ref.read(productsProvider.future)`
   wrapped so THREE outcomes are distinguished, never conflated:
   loaded-with-products (match normally against it), loaded-empty
   (legitimate — every row becomes `createNew`, fork F3), or load-failure
   (the future throws) → `state = failed("Couldn't read your product list —
   try again.")` and STOP — never treated as an empty catalog.
5. `gateway.extractStructured(spec: ReceiptExtraction.spec, images: [image],
   instruction: <receipt instruction>)`.
6. Build rows against the catalog from step 4: `matchLine` per item →
   `resolution = match != null ? matched : unresolved` (AM-4 — never
   `createNew` automatically; when the catalog loaded empty, every row is
   `createNew` instead, per fork F3), `nearMisses` filled for unresolved
   rows via the M1 `nearMisses` function (F6); `unit` = mapped extracted
   unit string when it matches a `ProductUnit` name, else
   `ProductUnit.piece`; **buying-price derivation rule**: `unit_price_cents`
   when present; else if `line_total_cents != null && qty > 0 &&
   line_total_cents % qty == 0` → `line_total_cents ~/ qty`; else **leave
   null** (never floor-divide a non-divisible total). Each numeric field is
   seeded with both its raw text and `ParseState.valid` (F5 — values that
   came straight from the gateway's own numeric type are trusted, not
   re-parsed as if hand-typed). `payment = SupplierPaymentChoice.notPaid`
   with `amountText`/`amountCents` = `receiptTotalCents` prefilled
   (`ParseState.valid` when present) but INERT until the owner picks a
   method (AM-3).
7. `state = review(...)`.
Error mapping for the whole method (Codex 02.4): `on AiUnavailableError` →
`failed(e.userMessage)` **except** when `e.kind == offline`, where the
Ask-specific wording is wrong for this screen — use `'No internet — you can
still type this stock in manually.'`; `on FormatException` (defensive; the
gateway should have mapped it) and `catch (_)` → `failed("Couldn't read that
receipt — try a clearer photo, or type it in.")`. This mapping is separate
from the step-4 catalog-load-failure path, which always raises its own
`failed(...)` message rather than falling through here. Every `await` is
followed by the `_disposed` AND `_opGeneration` checks (F3, copied from the
A8.1 pattern and extended).

`preparePlan()` (F2 — the screen renders EXACTLY what this returns; `save()`
never rebuilds it):
- Validates the CURRENT rows against these deterministic rules; on ANY
  violation, sets that row's `error` (or the payment section's error for a
  payment violation), returns `null`, and leaves `state` as `review` — no
  writes at all on a `null` return: **`include ⇒ qtyParse == valid && qty
  != null && qty > 0`** (round-3 R3 — a blank or invalid quantity on an
  included row blocks with its own inline error; blank is only legitimate
  on the optional price fields, never on `qty`); `resolution ==
  createNew ⇒ name.trim().isNotEmpty`; `resolution == matched ⇒
  matchedProductId != null`; **`resolution == unresolved ⇒ excluded from
  the save set and counted`** (AM-4); **every numeric field's `ParseState`
  must be `blank` or `valid` — ANY `invalid` field blocks the whole plan,
  surfacing a per-field error, with zero creates and zero writes** (F5);
  `payment != notPaid ⇒ amountParse == valid && amountCents != null &&
  amountCents > 0`; at least one included resolved row.
- On success, returns an immutable `ConfirmedPlan` built from those rows —
  this object, and only this object, is what `ConfirmationDialog.show`
  renders and what `save(plan)` writes.

`save(ConfirmedPlan plan)` (F1, F2 — takes the confirmed plan as a
parameter; never re-reads rows):
- Reentrancy guard (round-3 R1 — this is the ONLY guard; there is no second
  route into an in-progress save): first synchronous statement `if (state is!
  SnapRestockReview) return;` — a call made while `state` is already
  `SnapRestockSaving` is rejected right here, full stop. Capture `final
  originalReview = state as SnapRestockReview;` and seed the ledger from what
  the restored review already carries: `final seededLedger = {for (final row
  in originalReview.rows) if (row.createdProductId != null) row.id:
  row.createdProductId!};` — these ids were merged back into
  `originalReview`'s rows when a PRIOR attempt failed (see below), so this is
  how a retry actually reaches its ledger, not by reusing an unreachable
  `saving` state. Then `state = SnapRestockSaving(plan, originalReview,
  seededLedger);`.
- Phase 1: for each `createNew` row in `plan` with no entry yet in
  `createdIdsByRowId`, call `createProduct(companion, openingQty: 0)`
  (companion per `add_product_screen.dart:270`, `barcode: const
  Value(null)`, `imagePath: const Value(null)`, `lowStockThreshold: const
  Value(5)`, `createdAt`/`updatedAt` = one `DateTime.now()`). Wrap EACH
  create in `try { ... } on DukaError catch (_) { ... } catch (_) { ... }`
  (F1 — an unexpected exception is treated exactly like a `DukaError` here,
  never left to crash mid-ledger). On success, IMMEDIATELY update the
  ledger — `createdIdsByRowId = {...createdIdsByRowId, row.id: newId}` —
  and re-emit `state = SnapRestockSaving(plan, originalReview,
  createdIdsByRowId)` before starting the next row (F1 — the ledger must be
  correct after EVERY single create, not just at the end of the phase, so
  a crash between two creates still leaves an accurate ledger to restore
  from). **On failure for a row (round-3 R2): mark that row's error and STOP
  phase 1 immediately — do not attempt any remaining unprocessed `createNew`
  rows — then go straight to the failure path below. `receiveStockBatch` is
  never called when any create has failed.**
- Phase 2 (reached ONLY when every Phase-1 create succeeded — round-3 R2):
  wrapped in the same `try`/`on DukaError`/`catch (_)` discipline (F1). ONE
  `receiveStockBatch(lines: <every included row with a resolved
  product id — matched rows use `matchedProductId`, createNew rows use
  `createdIdsByRowId[row.id]`>, supplierPaymentCents: plan.payment ==
  notPaid ? null : plan.payment.amountCents, supplierPaymentMethod:
  plan.payment == cashFromTill ? PaymentMethod.cash : plan.payment == mpesa
  ? PaymentMethod.mpesa : null, note: 'Snap receipt')`.
- **On a Phase-1 failure (round-3 R2): ABORT before `receiveStockBatch` is
  ever called.** Restore `state = originalReview` with `createdIdsByRowId`
  merged back into the matching rows' `createdProductId`, the failing row's
  `error` set, plus the failure message banner. The ledger is NEVER
  discarded on failure — the reentrancy guard above already seeds a retry's
  `save(plan)` from `originalReview.rows`, so every already-created id
  carries forward and no product or its stock is ever created twice.
  Rationale: a partially-applied receipt is worse for the owner than a
  cleanly refused one — "did my stock go in?" is exactly the doubt this
  product cannot afford — so nothing may commit until every row is safely
  creatable.
- **On a Phase-2 failure (round-3 R2, `receiveStockBatch` throws):** because
  it runs inside ONE transaction, nothing it touches commits — restore
  `state = originalReview` the same way as a Phase-1 failure, ledger merged
  in, zero stock and zero expense written.
- **Success (round-3 R2): terminal.** `state = done(SaveOutcome(restocked,
  created, skippedFailed, skippedUnresolved))`, then release the
  `KeepAliveLink`. A `receiveStockBatch` that commits ALWAYS lands in `done`
  — never back in `review` — so a completed batch can never be reached by a
  second `save(plan)` call.
- Expect (tests, in-memory DB + `FakeAiGateway`): golden path; zero items;
  all-unmatched; offline wording; parse failure; **double `save(plan)`
  applies stock exactly once**; **batch fails after 2 creates → retry →
  product count unchanged and stock applied exactly once** (F1, exact
  vector from the finding); **a create failure with a supplier payment
  configured → zero movements, zero expenses, zero products beyond those
  already created, and the review is retryable** (round-3 R2); **no
  committed batch can ever return to a retryable review** (round-3 R2);
  unavailable-AI `start()` never reads the
  gateway (assert via a gateway that throws if touched); **delayed catalog
  delivery — `start()` awaits it and matches correctly once it resolves**
  (F4); **catalog load failure never renders as an empty catalog** (F4);
  **a malformed non-blank qty/price/payment-amount blocks `preparePlan()`
  entirely — zero creates, zero writes, per-field error shown** (F5);
  **an included row with a blank quantity blocks `preparePlan()` with an
  inline per-row error — zero creates, zero writes** (round-3 R3);
  **editing a row after `preparePlan()` returns cannot change what
  `save(plan)` writes — dialog and DAO read the identical object** (F2);
  **discard mid-extraction leaves state `idle` and writes nothing** (F3);
  **picker cancel releases the `KeepAliveLink`** (F3); **a stale `start()`
  completion (superseded by a newer `start()` or a discard) never
  overwrites the newer state** (F3); `payment == notPaid` writes ZERO
  expense rows (AM-3); `payment == mpesa` writes one expense with
  `PaymentMethod.mpesa`, not cash (AM-3); unresolved rows are never created
  and never restocked, and are reported in the outcome (AM-4); state
  survives a simulated navigate-away (dispose the listener, re-read the
  provider, review intact — AM-2).
- Failure A: `ProviderContainer` disposal mid-test makes state assertions
  flaky → cause: autoDispose with no listener → counter: keep a
  `container.listen(provider, (_, __) {})` subscription in the test, the
  pattern already used in `test/core/ai/ai_providers_test.dart`.
- Failure B: the F1 retry test still shows duplicate products → cause:
  `SnapRestockSaving`'s ledger was seeded from `{}` (or from `plan`) instead
  of from `originalReview.rows`' persisted `createdProductId`, so ids merged
  back after the first failure never reached the retry → counter: seed
  `createdIdsByRowId` from `originalReview.rows` on every `review → saving`
  transition, per the reentrancy-guard rule above (round-3 R1).
- Failure C: the F4 delayed-catalog test is flaky or hangs → cause: the
  fake `productsProvider` stream never emits, so `.future` never completes
  → counter: seed the fake provider with at least one emission (even an
  empty list) before `start()` awaits it, matching how the real
  `productsDaoProvider` stream behaves against a live Drift query.

**M4 — Route + entry points (small, verifiable move).**
`lib/app/router.dart`: add ONE `GoRoute(path: 'snap-restock', name:
'snap-restock', parentNavigatorKey: rootNavigatorKey, builder: (_, __) =>
const SnapRestockScreen())` as a child of `/home` (the `/home/ask`
precedent). Add the two gated AppBar actions per AM-1.
- Expect: `flutter analyze` clean; a widget test pushes the named route and
  lands on the screen; a widget test with `aiAvailableProvider: false`
  asserts BOTH entry actions are absent.
- Failure: route name collision → cause: duplicate name in the table →
  counter: `grep -n "name: '" lib/app/router.dart`, pick a free name.

**M5 — Screens.** `snap_restock_screen.dart` renders by state:
- `idle`: two ≥48dp buttons — "Take photo" (emerald primary) / "From
  gallery"; one line: "Photo of a supplier receipt. You confirm every number
  before anything is saved."; plus the **data disclosure** line, quieter and
  below: "The photo is sent to Anthropic to read it. DukaSmart doesn't keep
  it." (Fable blind-spot 2 — the owner never reads the README.)
- `extracting`: thumbnail from the state's preview bytes
  (`Image.memory`), progress indicator, "Reading receipt… you can leave and
  come back", and a **Discard** button (AM-2: leaving preserves, Discard
  drops — and drives `_opGeneration` forward per F3, so a late completion
  after Discard is inert).
- `review`: `ListView.builder` of rows. Matched row: product name + "matched"
  chip + change-product sheet (search over `productsProvider`) +
  `NumericInputField.quantity` + `NumericInputField.money` (buying price),
  prefilled via a feature-local `centsToInputString` copy, one-shot per row
  id (the `_priceInitializedForProductId` guard pattern). **Unresolved row
  (AM-4):** amber "Choose product" button opening a sheet that lists
  `nearMisses` first ("Did you mean…?"), then full search, then "Create as
  new product" — the row stays excluded until resolved. New row: "New
  product" badge + name field + `ProductUnit` dropdown + optional selling
  price + Skip toggle. Any row's `error` (F5) renders inline beneath its
  field the moment `preparePlan()` sets it. Footer: "Receipt says KES X —
  your rows total KES Y" (amber when different, never blocking; hidden when
  no receipt total); the **supplier payment segmented control (AM-3)** —
  "Not paid yet" (default) / "Cash from till" / "M-PESA" — with the amount
  field enabled only for the latter two; emerald "Save all" → calls
  `preparePlan()` (F2); if it returns `null`, no dialog opens and the
  per-row/per-field errors it set are shown inline instead; otherwise
  `ConfirmationDialog.show` renders EXACTLY that `ConfirmedPlan` object
  (F2 — never a freshly rebuilt snapshot), which MUST state the payment
  outcome in words ("No expense recorded" / "KES X cash from till" / "KES X
  by M-PESA") and the count of unresolved rows being skipped → on confirm,
  `save(plan)` is called with that SAME object (F2). Button shows a spinner
  and is disabled in `saving`.
  When `skippedRows > 0` or `truncated`: one quiet line "N lines couldn't be
  read".
- `failed`: message + "Try again" + "Type it manually" →
  `context.pushNamed('add-stock')`.
- `done`: SnackBar "Stock updated — N restocked, M new products" then pop.
- Expect: widget tests drive fixture → review → edit qty → confirm → assert
  DB effects (quantities, ONE expense row, movement count).
- Failure A: money rendered from a raw int anywhere → cause: bypassed
  `formatCents` → counter: `grep -rn "KES" lib/features/inventory/snap_restock/`
  and route every display through `formatCents`.
- Failure B: a row edited between `preparePlan()` returning and the confirm
  tap ends up in what gets written → cause: the dialog or the confirm
  handler rebuilt the plan instead of reusing the object `preparePlan()`
  returned → counter: pass the exact `ConfirmedPlan` reference through, and
  assert via `identical()` in a widget test that `save(plan)` receives the
  same object `preparePlan()` produced (F2).

**M6 — Final battery.** In order, each with its bar:
1. `flutter analyze` → "No issues found". A lint you cannot fix without
   editing frozen surfaces → ABORT A2.
2. `flutter test` → all green, count > M0 baseline. A red test you did NOT
   write → you broke v1: diagnose from the assertion before any other move.
3. `grep -rn "dart:io" lib/features/inventory/snap_restock/` → zero hits.
4. `flutter build web` → completes.
Manual runs with a real key are Ian's smoke step — do NOT attempt them; say
so in the final report.

## Forks
- **F1 zero items.** Trigger: parsed `items` empty → `failed("Couldn't read
  this receipt — try a closer photo")`. Never render an empty review.
- **F2 no receipt total.** Trigger: `receiptTotalCents == null` → the payment
  amount prefills from the sum of included lines' `qty × buyingPrice`
  (skipping null prices) and the mismatch line is hidden. The payment choice
  still defaults to "Not paid yet" — identical to the with-total case, so
  there is no inconsistency for an owner to learn (AM-3).
- **F3 empty catalog.** Trigger: `productsProvider.future` resolves to an
  EMPTY list — NOT a load failure, see M3 step 4 (Codex round-2 F4) — →
  every row `createNew`; matcher not called. A load FAILURE is a different
  path entirely: `failed("Couldn't read your product list — try again.")`,
  never routed through this fork.
- **F4 all rows skipped by the owner.** Trigger: no `include` rows at confirm
  → "Save all" disabled with "Nothing selected".

## Abort conditions
- A0: mission 01's exit gate file `.wargames/GATE-01-extraction-spike.md` is
  missing, or present without a line starting `GATE: GO` carrying
  `receipts=YES`, or present with a `model=` value that does not equal the
  effective `AiConfig.extractionModel` this build will run.
- A1: mission 01 absent, baseline red, or modified tracked files at M0.
- A2: the `_applyLine` refactor cannot preserve existing `receiveStock`
  behavior, or a fix demands editing frozen surfaces beyond the planned
  additions.
- A3: anything requiring the receipt image to be persisted to disk/DB.

## Verification
M0 baseline (including the A0 gate check); M2 DAO suite in isolation; M3
controller suite; M6 final battery. The final summary must quote
baseline/final test counts, the dart:io grep result, the A0 gate-check
result, and "build web: OK".

## Red-team record
**Attack 1 (Phase B, held):** double-submit doubles stock and the expense —
patched with the synchronous review→saving reentrancy guard mirroring
`SaleSubmitController`, plus a double-`save()` test.
**Attack 2 (Codex 02.1, upheld — the serious one):** creating new products
with their stock (`openingQty: qty`) BEFORE the batch meant a batch failure
left stock committed for new products while the review screen still offered
"retry", and since product names are not unique the retry silently created
duplicate products and added their stock twice. Patched: create at
`openingQty: 0`, retain generated ids in state, put every line through the
single batch transaction, and test the failure-then-retry sequence
explicitly.
**Attack 3 (Codex 02.4, upheld):** a hidden entry button is not gating — the
route is directly reachable and `aiGatewayProvider` throws `StateError` when
unconfigured. Patched: `start()` checks `aiAvailableProvider` before any
gateway read, with a test using a gateway that throws if touched.
**Attack 4 (Fable advisor, upheld — the money-trust one both Codex rounds
missed):** the plan pre-ticked "Paid from till (cash)" whenever the receipt
carried a total, and the expense method was hardcoded cash. Duka suppliers
are commonly paid by M-PESA or on credit, so a rubber-stamped confirmation
would book a cash drawer out-flow that never happened — surfacing as an
unexplained shortage at daily close, on the exact screen the product stakes
its trust on. Patched by AM-3: explicit three-way payment choice defaulting
to "Not paid yet" (never default to writing money), DAO refuses an amount
without a method, and tests assert the notPaid and mpesa paths.
**Attack 5 (Fable advisor, upheld):** unmatched lines defaulting to "create
new" splits a staple's stock across two catalog rows, with no delete path to
undo it — a worse inventory lie than the typing it saved. Patched by AM-4:
`unresolved` resolution state, near-miss suggestions in the picker, excluded
from save and reported until the owner resolves them.
**Attack 6 (Codex plan-lock round 2, upheld — four findings):** the rev 2
retry-safety guarantee could not actually be built from the stated state
model — `SnapRestockSaving` held no rows and no id ledger, so "retry creates
nothing new" was an aspiration with nothing to restore from (F1). The
confirmation dialog and `save()` could diverge, because `save()` rebuilt its
snapshot from live rows instead of the object the owner actually confirmed
(F2). `KeepAliveLink` release stopped Discard from losing in-progress work,
but did nothing to stop a still-in-flight extraction from completing and
silently overwriting `idle` with a stale `review` after the owner had
already discarded — and the picker-cancel path leaked its link entirely
(F3). And `productsProvider` is a `StreamProvider`; treating an unresolved
stream as an empty catalog would have made every existing product look
unmatched, pushing the owner toward duplicate creates on the very first use
(F4). Patched respectively by: a `{plan, originalReview,
createdIdsByRowId}` saving state updated after every create; a
`preparePlan()`/`save(plan)` split where the dialog and the DAO read the
identical object; an `_opGeneration` token checked after every await,
incremented on discard and on every new `start()`, with the link released on
both discard and picker-cancel; and an awaited `.future` read with
load-failure kept as its own outcome, never confused with a legitimately
empty catalog.
**Held (no patch):** unit-price/line-total column swaps on odd receipt
layouts — structurally mitigated (owner sees every prefilled figure, the
total cross-check flags disagreement, non-divisible totals refuse to guess).
Fable's related suggestion — flagging rows whose new buying price differs
sharply from the stored one — is recorded as a v2.1 polish, not built now.
