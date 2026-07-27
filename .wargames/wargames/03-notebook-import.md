# Wargame 03 — Notebook Import (rev 9)

Rev 9 closes the round-7 review: the save() in-flight refusal now runs before
`saving` is set (a refusal could otherwise strand the flag and block every
later save), and the three leftover text sites that still said `normalizeName`
for catalog behaviour now say `catalogKey`.

Rev 8 closes the round-6 review: a scheduler-idle gate on Review/Confirm
(concurrent extraction could let a page finish AFTER save() snapshotted rows,
silently dropping it), and a dedicated `catalogKey` (trim+lowercase) for
catalog collisions — `normalizeName` also strips punctuation, so the claimed
equivalence with the app's `findExactNameMatch` was false and would have
greyed out genuinely distinct products.

Rev 7 closes Codex round-5: three blocking findings, all accepted — the
pre-save "fresh" catalog read was not actually fresh (replaced with a new
`getAllProducts()` DAO one-shot query), the TextEdit/MoneyEdit migration was
left half-applied outside the model block (stale `FieldEdit` references
swept and fixed), and save-time duplicate counting is reordered so
`skippedDuplicates` is captured before the selected-filter erases the
evidence.

Rev 6 closes Codex round-4: split TextEdit/MoneyEdit (one int?-valued FieldEdit
could not serve both name and prices), CandidateRow now carries raw text +
parse state so the invalid-input write-block has something to inspect, and the
pre-save catalog read is a fresh watchProducts().first rather than a possibly
cached provider emission.

Rev 4 closes round-3 findings. Rev 5 tightens the M0 gate check to Ian's
2026-07-27 model decision (see below) — no other content changed.

Branch: `feature/ai-capabilities`. Repo: `/data/Documents/Flutter/dukasmart`.
Brief: `.wargames/tasks/03-notebook-import.md`.
**Depends on mission 01 (rev 6) AND its exit gate,
`.wargames/GATE-01-extraction-spike.md` (F8 — see M0/A0).** Independent of
mission 02 except one GoRoute block in `lib/app/router.dart` (Fork F4).
Rev 2 incorporated Codex plan-lock round-1 findings 03.1–03.10 (2026-07-27).
Rev 3 incorporates Codex plan-lock round-2 findings F1–F8 (2026-07-27) —
labels `F1`–`F8` below always refer to these round-2 review findings, not
the pre-existing Fork IDs in the Forks section. Rev 4 incorporates Codex
plan-lock round-3 findings on rev 3, all accepted (2026-07-27). Rev 5 applies
Ian's 2026-07-27 decision: extraction runs on Haiku
(`claude-haiku-4-5-20251001`) via mission 01 rev 5's
`AiConfig.extractionModel` / `AnthropicGateway.extractionModel`, while
Ask-your-duka and the daily-close insight stay on Opus — this mission never
shares the Ask model.

**Settled facts (read from source this session):**
- `ProductsDao.createProduct(ProductsCompanion p, {required int openingQty})`
  (`products_dao.dart:25`): one transaction; throws BEFORE any write on
  empty/whitespace name, negative buying/selling price, negative openingQty,
  negative threshold, duplicate non-empty barcode. **Null prices are
  allowed.** Forces `quantity = openingQty`; writes an `openingStock`
  movement only when `openingQty > 0`. Returns the new id.
- Exact companion shape to copy (`add_product_screen.dart:270`):
  `ProductsCompanion.insert(name: name, barcode: Value(...), imagePath:
  Value(...), buyingPrice: Value(...), sellingPrice: Value(...), unit: unit,
  lowStockThreshold: Value(threshold), createdAt: now, updatedAt: now)` with
  ONE `final now = DateTime.now();` shared by both timestamps.
- **No product name uniqueness anywhere** (only `DailyCloses.date` is UNIQUE).
- Every fresh install is seeded with 5 products (`database.dart:108`:
  Coca-Cola 500ml, Brookside Milk 500ml, Jogoo Maize Flour 2kg, Sugar 1kg,
  Bread 400g) and there is **no product-deletion path** — a genuinely empty
  catalog is unreachable.
- `ProductListScreen`'s `products.isEmpty` (`product_list_screen.dart:119`)
  is the **filtered** list — it is also empty after a search miss or a
  low-stock filter with no hits.
- `aiGatewayProvider` throws `StateError` when unconfigured
  (`ai_providers.dart:29`). `AskController`'s `_disposed` guard:
  `ask_controller.dart:41-106`.
- `findExactNameMatch(String, List<Product>)` is a public top-level function
  in `add_product_screen.dart:47` (case-insensitive, trimmed, exact).
- `productsProvider` (`lib/core/providers.dart:34`) is
  `StreamProvider<List<Product>>`; `ref.read(productsProvider.future)`
  resolves to its first emitted value (used by F4).

**Design decisions (do not re-decide):**
- **D-03a** Imported products are created with `openingQty: 0`. The notebook
  is a CATALOG source, not a stock count; inventing quantities would break
  "trust the numbers". Stock arrives later via Add Stock / mission 02.
- **D-03b** Historical daily totals are OUT of scope.
- **D-03c** 10 pages per session, one extraction call per page.
- **D-03d** Empty price ⇒ `null`, never `0`.
- **D-03e (revised per Codex 03.1)** **Single entry point: the Products tab
  AppBar action** ("Import from your notebook", gated on
  `aiAvailableProvider`). The brief's empty-catalog entry is DROPPED: a true
  empty catalog cannot occur (seeded, no deletes), and
  `product_list_screen.dart:119`'s `isEmpty` is the filtered list, so
  attaching a CTA there would surface it after an unrelated search miss.
- **D-03f** Updating EXISTING products' prices from the notebook is a
  deliberate v2.1 deferral (see Red-team). This mission only creates.

---

## Moves

**M0 — Baseline + dependency gate.**
Run `git status --porcelain`; `grep -n "extractStructured"
lib/core/ai/ai_gateway.dart`; `export PATH="$HOME/flutter/bin:$PATH" &&
flutter analyze && flutter test`; `git log --oneline -3 --name-only --
lib/app/router.dart`; and (F8 — new, rev 5 tightened) `test -f
.wargames/GATE-01-extraction-spike.md && grep -nE "^GATE: GO.*notebook=YES"
.wargames/GATE-01-extraction-spike.md` — then confirm the gate's `model=`
value equals the effective `AiConfig.extractionModel` (normally
`claude-haiku-4-5-20251001`, per Ian's 2026-07-27 decision above).
- Expect: no modified-TRACKED files (the known untracked set is fine); grep
  prints the abstract `extractStructured<T>`; analyze clean; suite green —
  RECORD the count; the router log tells you whether mission 02's route
  already landed (relevant to Fork F4); the gate file exists, its `GATE:
  GO` line names `notebook=YES`, AND its `model=` matches
  `AiConfig.extractionModel`.
- Failure 1: grep for `extractStructured` comes back empty. Cause: mission
  01 not merged onto this branch. Counter-move: ABORT A1.
- Failure 2: `flutter analyze`/`flutter test` red, or modified tracked files
  present. Cause: uncommitted or broken work already in the tree. Counter-
  move: ABORT A1 — do not attempt to fix pre-existing breakage as part of
  this mission.
- Failure 3 (F8, rev 5 tightened): `.wargames/GATE-01-extraction-spike.md`
  is missing, present without a `GATE: GO` line naming `notebook=YES`, OR
  its `model=` names a different model than the effective
  `AiConfig.extractionModel`. Cause: mission 01's spike never validated
  handwritten-notebook extraction specifically (it may have only proven
  typed/receipt text, or nothing at all), OR it validated a model the build
  will not actually run extraction on — a gate that passed on the wrong
  model proves nothing about the model this mission ships with. Handwritten
  Swahili/Sheng notebook pages are the HARDEST extraction input in v2 —
  meaningfully harder than mission 02's printed receipts — so if Haiku
  misses the bar anywhere, this mission is the likely casualty. Counter-
  move: ABORT A0 — do not proceed on the assumption that mission 01 being
  merged is sufficient; the gate is a separate, model-specific,
  mission-03-specific green light. Per mission 01 rev 5, do NOT silently
  fall back to Opus on a `notebook=NO` (or wrong-model) gate — stop and
  return the decision to Ian, who may choose to spend Opus money on this
  feature specifically or defer it.

**M1 — Pure merge/dedupe core (TDD, no Flutter imports).**
All pure types live together in `import_model.dart` (F2) — no type this
mission needs is declared anywhere else, and the controller file (M2) may
depend on this file but this file never depends on the controller.
```dart
String normalizeName(String s);   // lowercase, strip . , - / ( ), collapse ws, trim
String mergeKey(String s);        // normalizeName with ALL whitespace removed

class ExtractedRow {              // immutable, page-local, never mutated after extraction
  final int pageId; final int indexInPage;
  final String rawName;
  final ProductUnit? extractedUnit;
  final int? sellingPriceCents; final int? buyingPriceCents;
  const ExtractedRow({required this.pageId, required this.indexInPage,
                       required this.rawName, this.extractedUnit,
                       this.sellingPriceCents, this.buyingPriceCents});
}

// Codex round-4 fix: ONE FieldEdit carrying an `int? value` could not serve
// both the name (a String) and the prices (ints) — implemented literally it
// would not compile. Two distinct types instead.
enum FieldParse { blank, valid, invalid }   // blank = owner cleared it

class TextEdit {                  // for `name`; absent (null) = untouched
  final String rawText;
  final FieldParse parse;         // blank | valid ONLY — a name is never "invalid"
  const TextEdit(this.rawText, this.parse);
  /// Trimmed text when parse == valid; empty string when blank.
  String get value => parse == FieldParse.valid ? rawText.trim() : '';
}

class MoneyEdit {                 // for prices; absent (null) = untouched
  final String rawText;
  final FieldParse parse;         // blank | valid | invalid
  final int? cents;               // non-null ONLY when parse == valid
  const MoneyEdit(this.rawText, this.parse, this.cents);
}

class RowOverride {               // durable owner intent; every field null = "owner did not touch this"
  final bool? selected;
  final TextEdit? name;
  final ProductUnit? unit; final bool unitTouched;
  final MoneyEdit? sellingPrice;
  final MoneyEdit? buyingPrice;
  const RowOverride({this.selected, this.name, this.unit,
                      this.unitTouched = false,
                      this.sellingPrice, this.buyingPrice});
  RowOverride copyWith({...});    // standard nullable-field copyWith
}

class CandidateRow {              // display row — output of applyOverrides, never stored
  final String identityKey;       // stable across re-aggregation; see below
  final String name;              // '' only when the owner cleared it → blocks save
  final ProductUnit unit;
  final int? sellingPriceCents; final int? buyingPriceCents;
  final bool selected;
  final bool mergedDuplicate; final bool alreadyInCatalog;
  final List<String> absorbedNames;   // other raw names folded into this survivor (F5b)
  // Codex round-4 fix: the row must carry the owner's raw text and parse
  // state forward, or the "malformed input blocks all writes" gate has
  // nothing to inspect and the field cannot re-render what was typed.
  final String? sellingPriceText;     // non-null when the owner edited it
  final FieldParse? sellingPriceParse;
  final String? buyingPriceText;
  final FieldParse? buyingPriceParse;
  /// True when any edited field is `FieldParse.invalid`, or the name is
  /// blank. `preparePlan`/`save()` must refuse to write while ANY selected
  /// row has this set, and the UI shows the per-field error inline.
  bool get hasBlockingError => name.trim().isEmpty
      || sellingPriceParse == FieldParse.invalid
      || buyingPriceParse == FieldParse.invalid;
}

enum PageStatus { capturing, waiting, extracting, done, failed }
// `capturing` is defined for type completeness (F2's exact list) but this
// mission never assigns it to a real ImportPage: a page is only created
// once bytes are in hand (M2), entering `waiting` directly, preserving
// rev 2's "no page until capture succeeds" rule unchanged. It exists so a
// future multi-shot capture UI can reuse this enum without a model change.

class ImportPage {
  final int pageId; PageStatus status;
  List<ExtractedRow> rows;
  String? errorMessage;
  int skippedRows; bool truncated;   // parser stats (F2), surfaced by Fork F3
}

List<CandidateRow> aggregate(List<ImportPage> pages, List<Product> catalog,
                              Set<String> unmergedGroupKeys);
List<CandidateRow> applyOverrides(List<CandidateRow> baseRows,
                                   Map<String, RowOverride> overrides,
                                   List<Product> catalog);   // rev 4 FIX 4
```

**Two-layer model (F1 — the most serious round-2 finding).** Rev 2's
`aggregate` mutated `selected` on every recomputation, which silently
RE-SELECTED rows the owner had deliberately deselected and either lost or
overwrote owner edits on merge survivors — the exact "recompute from
scratch" pattern the plan relied on everywhere was quietly destructive to
owner intent. Rev 3 splits state into what the extractor produced
(immutable) and what the owner decided (durable, identity-keyed), and never
lets the second collapse back into the first:
- `aggregate` builds ONLY from `ExtractedRow`s + the catalog + the current
  unmerge set. It is still pure and deterministic — recomputed from scratch
  after every add/retry/remove/edit/unmerge, so arrival order can never
  matter — and its `selected` default is still `!alreadyInCatalog`, computed
  from each row's EXTRACTED (pre-edit) name.
- `applyOverrides` then overlays `overrides[row.identityKey]` on top
  (rev 4 FIX 1 + FIX 4): `selected` and `unit` (when `unitTouched`) replace
  the base value when set. For `name`, the override is a `TextEdit?`:
  absent (`null`) leaves the base value untouched; `parse: blank` sets the
  name to the EMPTY STRING `''` — NOT `null` — since `CandidateRow.name` is
  a non-nullable `String`; that `''` (the owner deliberately cleared it)
  MUST survive re-aggregation, and `hasBlockingError` already treats `''`
  as a save-blocking error, so a cleared name still blocks the save rather
  than silently vanishing; `parse: valid` replaces the name with
  `TextEdit.value` (the trimmed text). For `sellingPrice`/`buyingPrice`,
  the override is a `MoneyEdit?`: absent (`null`) leaves the base value
  untouched; `parse: blank` sets the field to `null` (the owner
  deliberately cleared it) and that null MUST survive re-aggregation;
  `parse: valid` replaces the field with `MoneyEdit.cents`; `parse:
  invalid` (price fields only — `name` never parses invalid) leaves the
  row carrying its malformed `rawText` for display and flags the row with
  an inline error that blocks the ENTIRE save — zero writes — until fixed.
  `applyOverrides` projects the name edit FIRST, then recomputes
  `alreadyInCatalog` from the CURRENT (post-edit)
  name against the `catalog` argument it now takes, and forces `selected =
  false` on any row that newly matches — this is what makes editing a name
  into an existing product immediately grey and uncheck it, since
  `aggregate`'s own catalog check only ever sees the extracted name.
- The UI and the pre-save snapshot BOTH read
  `applyOverrides(aggregate(pages, catalog, unmergedGroupKeys), overrides,
  catalog)` — there is no other place either is allowed to read rows from.
- **Identity**: for an unmerged/never-merged row, `identityKey =
  mergeKey(row.rawName)`. For a merge survivor, `identityKey =
  mergeKey(survivor.rawName)` too (the FIRST occurrence's raw name — stable
  because `ExtractedRow` is immutable, and page removal/retry can change
  which rows exist but never their `rawName`). For a row split back out by
  Unmerge (F5b), `identityKey =
  "${mergeKey(row.rawName)}#${row.pageId}:${row.indexInPage}"` — this keeps
  the split siblings distinct even though they share a `mergeKey`.
- **Unmerge migration (rev 4 FIX 2)**: when the owner runs Unmerge on a
  group, the survivor's existing `overrides[mergeKey(survivor.rawName)]`
  entry, if any, is moved — not copied — to the split row with the lowest
  `pageId` (ties broken by lowest `indexInPage`): that row inherits the full
  `RowOverride`, the old key is removed from `overrides`, and every other
  split row starts untouched (no entry). This migration runs once,
  synchronously, at the same time the group's key is added to
  `unmergedGroupKeys`.
- The controller upserts an override with
  `overrides[key] = (overrides[key] ?? const RowOverride()).copyWith(...)`
  — never a bare replace, so an edit doesn't clobber an earlier deselect on
  the same row.

Merge (within-batch, still aggressive — F5a keeps this key here on purpose):
1. Walk pages in ascending `pageId`, rows in `indexInPage` order.
2. Group by `mergeKey(rawName)`, UNLESS the group's key is in
   `unmergedGroupKeys` (owner ran Unmerge on it — F5b), in which case every
   row in that group becomes its own singleton `CandidateRow` instead.
3. Within a merge group: fold later rows into the FIRST occurrence; for each
   of `extractedUnit`, `sellingPriceCents`, `buyingPriceCents` the **last
   non-null value wins**; set `mergedDuplicate = true`; `absorbedNames` =
   every OTHER row's `rawName` in the group, in arrival order (Codex 03.3's
   unit-fill behavior is unchanged).
4. Catalog flag (F5a — CONSERVATIVE, changed from `mergeKey`; this is the
   BASE/pre-edit value only — `applyOverrides` recomputes it from the
   post-edit name and has final say, rev 4 FIX 4).
   **Use a THIRD, dedicated matcher — not `normalizeName` (round-6 fix).**
   ```dart
   String catalogKey(String s) => s.trim().toLowerCase();
   ```
   `alreadyInCatalog = catalog.any((p) => catalogKey(p.name) ==
   catalogKey(row.name))`.
   Rationale: an earlier revision claimed `normalizeName` "matches
   `findExactNameMatch`'s convention exactly" — that was FALSE.
   `findExactNameMatch` (`add_product_screen.dart:47`) only trims and
   lowercases, while `normalizeName` ALSO strips `. , - / ( )` and collapses
   internal whitespace. Using it here would treat `ACME/Plus` and `ACMEPlus`
   as the same product and grey out a genuinely distinct row as
   unselectable. So this mission now has three deliberately distinct keys,
   each with one job: `catalogKey` (trim+lowercase — matches the app's real
   duplicate convention, used for catalog collisions), `normalizeName`
   (punctuation-stripping — used for save-time within-batch dedupe of edited
   names), and `mergeKey` (whitespace-stripped — used for within-batch
   merging of near-duplicate extractions). State this three-key split
   explicitly wherever each is used; do not collapse them.
   Being conservative on the CATALOG key is deliberate: a false catalog
   match greys out real owner data as unselectable, which is worse than an
   occasional undetected duplicate the owner can still see on the review
   list and skip by hand.
   - Required test: catalog contains `ACME/Plus`, an extracted row reads
     `ACMEPlus` → the row is NOT flagged `alreadyInCatalog` (proves
     `catalogKey`, not `normalizeName`, is in use).
5. `selected = !alreadyInCatalog` (base default only; `applyOverrides`
   overrides it, both from owner intent and from its own post-edit
   `alreadyInCatalog` recheck).

Required test vectors (exact), all still valid:
| A | B | same product? |
|---|---|---|
| `Blue Band 250g` | `Blueband 250 g` | YES (merge) |
| `OMO  500 G` | `omo 500g` | YES |
| `Sugar 1kg` | `Sugar 2kg` | NO |
| `Bread 400g` | seeded `Bread 400g` | alreadyInCatalog |
Plus: later row with `kilogram` fills an earlier null unit; a row that is
both merged and alreadyInCatalog carries both flags; `aggregate` called
twice on the same input returns identical output (determinism).

New required tests (F1 — owner intent survives re-aggregation):
- deselect a row, add another page → the row is still deselected.
- edit a row's name, retry an unrelated page → the edit is preserved.
- edit a row's name/unit/price, then run the pre-save recompute (M2 `save`)
  → the edit survives, unchanged.
- remove the page that contributed an absorbed duplicate → the merge
  survivor's row does NOT resurrect to `selected` if the owner had
  deselected it.

New required tests (rev 4 FIX 1 — cleared vs malformed price):
- clearing an extracted price (`MoneyEdit(rawText, FieldParse.blank, null)`)
  survives adding another page AND the pre-save recomputation — the field
  stays `null`, not the original extracted value.
- a malformed, non-blank price input (`MoneyEdit(rawText, FieldParse.invalid,
  null)`) blocks confirmation for the ENTIRE batch and creates ZERO
  products, even when every other row is valid.

New required tests (F5a — conservative catalog key vs aggressive merge key):
- a catalog product and an incoming row whose names differ only by internal
  whitespace (`mergeKey`-equal, e.g. catalog `Blue Band 250g` vs incoming
  `Blueband 250g`) must NOT be flagged `alreadyInCatalog` — `catalogKey`
  keeps that space, `mergeKey` doesn't.
- catalog `ACME/Plus` vs incoming `ACMEPlus` must NOT be flagged
  `alreadyInCatalog` — `catalogKey` only trims and lowercases, so the slash
  keeps them distinct (this is the test that proves `catalogKey`, not
  `normalizeName`, is wired to catalog collision).

New required tests (F5b — absorbed names + Unmerge):
- a merge survivor's `absorbedNames` lists every other raw name folded in,
  in arrival order.
- running Unmerge on a merge group produces one `CandidateRow` per original
  `ExtractedRow`, each independently selectable/editable, and re-running
  `aggregate` after ANY subsequent page add/retry/remove keeps that group
  split (its key stays in `unmergedGroupKeys` for the rest of the session).
- (rev 4 FIX 2) edit a survivor's name AND deselect it, then Unmerge → the
  split row with the lowest `pageId`/`indexInPage` carries BOTH the name
  edit and the deselection, every other split row is untouched, and a
  subsequent page add/recomputation preserves that split.

New required tests (rev 4 FIX 4 — catalog projection order + failed re-read):
- editing a row's name to match an existing catalog product immediately
  (before Save) greys it, unchecks it, and marks it `alreadyInCatalog`, via
  `applyOverrides`'s post-edit recheck — not just at save time.
- if the pre-save catalog re-read fails, `saving` resets to `false`, the
  Review screen shows an error, and zero writes occur.

- Failure: `mergeKey` over-merges within a batch (e.g. `Sugar 1kg`/`Sugar
  1 kg` are the same — intended — but `Soda 1`/`Soda1` collide with
  something real). Cause: the key is too aggressive for free-text OCR
  names. Counter-move: keep the aggressive key for within-batch merge ONLY
  (never for catalog matching, F5a), and give the owner Unmerge (F5b) as
  the correction path instead of chasing key-accuracy tuning.

**M2 — Controller (TDD).**
`notebook_import_controller.dart` holds STATE + IO ONLY (F2) — every type it
manipulates is imported from `import_model.dart`, never declared here.
`AutoDisposeNotifier<NotebookImportState>`.
State: `pages` (`List<ImportPage>`), `overrides` (`Map<String,
RowOverride>`), `unmergedGroupKeys` (`Set<String>`), a tri-state catalog
load (loading / error / ready — see Catalog freshness below), `saving`,
`result`, plus the F3 scheduler fields below. Rows shown = derived
`applyOverrides(aggregate(pages, catalog, unmergedGroupKeys), overrides,
catalog)` — **never** stored denormalised (Codex 03.4, unchanged).

**Concurrency scheduler (F3 — fully specified; rev 2's text was not
executable blind).**
- `bool _pickerBusy` — guards ONLY the OS picker call. Set `true`
  synchronously before `pick()`; cleared as soon as bytes are in hand OR the
  pick cancels/fails. NEVER held across the network call.
- `int _activeExtractions` (max 3) and `List<int> _queue` (page ids, FIFO).
- `_pump()`: while `_activeExtractions < 3 && _queue.isNotEmpty`, dequeue
  the head, `_activeExtractions++`, start that page's extraction. On every
  completion (success, failure, or discarded-as-abandoned),
  `_activeExtractions--` then call `_pump()` again.
- A newly captured page is created with `status: waiting`, appended to
  `_queue`, then `_pump()` runs. (No `capturing`-status page is ever
  created — see M1.)
- `retryPage(pageId)`: re-captures (subject to `_pickerBusy` like any
  capture), then re-enters the SAME pageId at the tail of `_queue` the same
  way a new page would, and counts against `extractionAttempts` (F7).
- Removing a `waiting` page also removes its id from `_queue`. Removing an
  in-flight (`extracting`) page marks it abandoned (the existing
  generation/abandoned-id check): when its extraction later completes,
  `_activeExtractions` still decrements normally (the slot frees) but the
  resulting rows are discarded rather than attached to any page, and
  `_pump()` runs to fill the freed slot.

`addPage(ImageSource src)`:
1. **Fail closed first**: `if (!ref.read(aiAvailableProvider)) { … return; }`
   before any `aiGatewayProvider` read.
2. **Slot + attempt caps (F7 — two separate limits, not one)**: `if
   (_pickerBusy || pages.length >= pageSlots || extractionAttempts >=
   extractionAttemptsMax) return;` with `pageSlots = 10`,
   `extractionAttemptsMax = 12`. State which cap was hit distinctly in the
   UI (slot cap: "10 pages max"; attempt cap, rev 4 FIX 5 — the old counter-
   move text ("remove a page to make room") was FALSE, since attempts never
   decrease: "You've used all 12 page reads for this import. Save what you
   have, or start a new import." No other copy in this mission may imply
   that removing a page restores an attempt).
   `_pickerBusy = true` synchronously.
3. `capture(src)`: `CaptureCancelled` ⇒ **no page is created at all**, just
   `_pickerBusy = false` (Codex 03.4, unchanged — a cancelled pick can
   never leave a page stuck). `CaptureFailed(tooLarge/undecodable)` ⇒ no
   page, SnackBar-level message. Neither counts against
   `extractionAttempts` (no paid call was made).
4. Only after a successful capture: create the page (`pageId` from a
   monotonic counter that never reuses ids) with `status: waiting`, enqueue
   it, `extractionAttempts++`, `_pickerBusy = false`, `_pump()`.
5. Per-page extraction (run by `_pump`, up to 3 concurrently):
   `extractStructured(spec: NotebookPage.spec, images: [image], …)` → rows
   for that page → `status: done`. Zero rows ⇒ `status:
   failed('Nothing readable on this page')`. Parser `skippedRows`/
   `truncated` are stored on the page (F2, surfaced by Fork F3).
6. `on AiUnavailableError` → page `failed(e.userMessage)`, except
   `kind == offline` → `'No internet — try this page again later.'`;
   `on FormatException` / `catch (_)` → `failed("Couldn't read this page.")`.
   `_disposed` checked after every await (A8.1 pattern).

**Catalog acquisition and freshness (F4 — was unspecified in rev 2, and
product names are not unique in the DAO, so a stale or unloaded snapshot
creates real duplicates).**
- Before showing the Review screen: `final catalog = await
  ref.read(productsProvider.future);` (`productsProvider` is a
  `StreamProvider`, so `.future` resolves to its first emitted value).
  Distinguish a genuine load failure (provider errors — show a retry state,
  do not proceed to Review) from a real empty list (unreachable per Settled
  facts, but if it ever happens, treat it as zero catalog matches, not an
  error). This initial load only needs *a* catalog to render against, not a
  guaranteed-fresh one, so `productsProvider.future` is fine here.
- **DAO amendment (round-5 review, FIX 1 — read-only, logged the same way
  as mission 02's `receiveStockBatch` amendment):** add a genuine one-shot
  list getter to `ProductsDao` (`lib/core/database/daos/products_dao.dart`),
  alongside the existing `watchProducts()` (stream), `getByBarcode()`,
  `createProduct()`, `updateProduct()`:
  ```dart
  Future<List<Product>> getAllProducts() =>
      (select(products)..orderBy([(t) => OrderingTerm.asc(t.name)])).get();
  ```
  Read-only, no transaction needed — it cannot affect any existing caller.
- Immediately before `save()` writes anything, take a GENUINELY FRESH read:
  ```dart
  final freshCatalog = await ref.read(productsDaoProvider).getAllProducts();
  ```
  **Not** `watchProducts().first` (round-5 review fix — rev 6's fix for
  Codex round-4 replaced `productsProvider.future` with
  `watchProducts().first`, but that still does not guarantee a fresh
  `SELECT`): Drift keys and reuses identical ACTIVE query streams and hands
  a new listener the cached `_lastData`
  (`drift-2.34.2/lib/src/runtime/executor/stream_queries.dart:95`).
  `ProductListScreen` already holds an identical `watchProducts()`
  subscription open, so the pre-save read can replay THAT subscription's
  stale cached value instead of re-querying — and `createProduct` does not
  enforce name uniqueness, so a product inserted moments before Confirm
  could be missed and duplicated. `getAllProducts()` is a genuine one-shot
  query with no stream and nothing to replay, so it always issues a fresh
  `SELECT`. Do not reuse the snapshot Review opened with. If this read
  fails, `save()` resets `saving = false`, returns to the Review screen with
  an error message, and performs ZERO writes — it never falls back to the
  stale Review-time snapshot.
  Required test: open a `watchProducts()` subscription FIRST (mimicking
  `ProductListScreen`'s own open subscription — Drift only hands back
  cached `_lastData` when an identical active stream already exists, so the
  bug cannot reproduce, and the test cannot be meaningful, without that
  subscription open), THEN insert a product directly via the DAO after
  Review opens but before Confirm, then Confirm → zero products created for
  that row AND `skippedDuplicates == 1` in the reported result (FIX 3
  below). This test must FAIL if the implementation reverts to a
  stream-based read.
- Editing a row's name on the Review screen re-checks that row for a live
  catalog collision using the SAME current-name/`catalogKey` logic as save
  (Codex 03.6; key corrected in rev 8) — the grey/uncheck treatment updates
  immediately, it does not wait for Save.

`save()`:
- **Guards, in this order, ALL synchronous and BEFORE any await or row
  snapshot (round-6 review):**
  1. `if (saving) return;` — reentrancy.
  2. **In-flight refusal:** `if (pages.any((p) => p.status ==
     PageStatus.waiting || p.status == PageStatus.extracting)) { /* surface
     "Still reading N pages…" */ return; }` — this runs BEFORE `saving` is
     set, so a refusal cannot strand the controller. (If an implementation
     ever sets `saving = true` first, it MUST reset it to `false` on every
     refusal path — a stranded `saving` flag would permanently block every
     later save.)
  3. Only then `saving = true;`.
- Required test: `save()` called while a page is still extracting performs
  ZERO writes, leaves the screen on Review, AND a subsequent `save()` after
  that page completes succeeds normally (proving the refusal did not strand
  the flag).
- **Exact save-time order (round-5 review, FIX 3 — otherwise
  `skippedDuplicates` can never be counted):**
  1. Re-read the fresh catalog: `final freshCatalog =
     await ref.read(productsDaoProvider).getAllProducts();` (FIX 1 above).
  2. Recompute current rows: `final rows =
     applyOverrides(aggregate(pages, freshCatalog, unmergedGroupKeys),
     overrides, freshCatalog);` — this is the fresh projection.
     `applyOverrides` has already forced `selected = false` on any row that
     newly collides with `freshCatalog` (see Two-layer model above), which
     is exactly why the counting in step 4 must run BEFORE any
     selected-filter, not after.
  3. **Full-snapshot validation (F6 — was per-row in rev 2, now
     blocking)**: filter `rows` to `selected` and validate EVERY one:
     non-blank trimmed name (a `name` override with `parse: blank`, or an
     untouched row whose extracted name is already blank, both fail here —
     a blank-name override yields the empty string `''`, since
     `CandidateRow.name` is non-nullable, and `hasBlockingError` already
     treats `''` as a save-blocking error); and (rev 4 FIX 1) any selected
     row whose `RowOverride.sellingPrice` or `.buyingPrice` carries `parse:
     invalid` fails, since that `rawText` cannot be represented as a price.
     ANY violation ⇒ show per-row errors on the Review screen and **block
     confirmation entirely — zero writes happen**. Only once this snapshot
     is clean does the next step run.
  4. **Count `skippedDuplicates` from owner intent, before the
     selected-filter erases the evidence (FIX 3)**: for every row in
     `rows` where `overrides[row.identityKey]?.selected != false` (the
     owner had NOT deliberately deselected it — their intent to save it)
     AND the fresh projection now flags it `alreadyInCatalog`, count it
     into `skippedDuplicates`. This is the only point this count can be
     taken: since `applyOverrides` already forced `selected = false` on
     these rows in step 2, filtering to `selected` first would always find
     zero of them, and the promised "detected, skipped, and reported"
     duplicate count would be zero even when a real collision occurred.
     This catches both a product added externally between Review and
     Confirm (F4) and an owner edit that now collides with an existing
     product (Codex 03.6, unchanged).
  5. Filter to genuinely selected, non-blocking rows from the validated
     snapshot. (Rev 4 FIX 3) Within THIS surviving set, dedupe by
     `normalizeName(row.name)` — computed AFTER owner edits are applied —
     keeping the first occurrence in deterministic page order and adding
     the rest into `skippedDuplicates` (same counter as step 4); suffixed
     `identityKey`s alone cannot catch this, since two rows split by
     Unmerge get distinct `identityKey`s even when the owner edits them to
     the same name, and `createProduct` enforces uniqueness only on
     barcode, never on name (`products_dao.dart:52`).
  6. Loop the survivors: `createProduct(companion, openingQty: 0)` with the
     companion exactly per `add_product_screen.dart:270` — `name:
     row.name.trim()`, `barcode: const Value(null)`, `imagePath: const
     Value(null)`, `buyingPrice: Value(row.buyingPriceCents)` (null stays
     null), `sellingPrice: Value(row.sellingPriceCents)`, `unit: row.unit`,
     `lowStockThreshold: const Value(5)`, `createdAt: now`, `updatedAt:
     now` (one shared `now`). A per-row failure here is now a DAO-level
     anomaly, not a validation gap (F6 already blocked bad input) — count
     it into `skippedFailed`, continue the loop (per-row atomicity: 98
     created must not roll back for 2 anomalies).
  7. Result: `{added, skippedDuplicates, skippedFailed}`.

- Expect (tests, in-memory DB + `FakeAiGateway` with per-page fixtures):
  two-page accumulation; page-2 failure preserves page 1; retry; cancel
  creates no page and spends no attempt; **two `addPage` calls while the
  picker is open ⇒ exactly one page** (picker serialisation); slot cap at
  10 (F7); attempt cap at 12 counting retries, independent of slot removals
  (F7); remove-a-merged-page recomputes correctly without resurrecting a
  deselected survivor (F1); **created rows have `quantity == 0` and NO
  `openingStock` movement**; null prices persist as null; an owner-edited
  name colliding with the fresh catalog is dropped at save and counted into
  `skippedDuplicates` (Codex 03.6); owner selects a row, a matching product
  is inserted externally (via the DAO, with a `watchProducts()` subscription
  already open elsewhere), then Confirm → zero products created for that
  row AND `skippedDuplicates == 1` in the reported result (F4, round-5
  review FIX 1 + FIX 3); an invalid name and an invalid optional money value
  each block confirmation with ZERO products created (F6); double `save()`
  writes once; unavailable-AI `addPage` never touches the gateway; **three
  concurrent extractions run at once, a fourth waits then runs when a slot
  frees, FIFO order is respected, and out-of-order completion yields an
  identical aggregate** (F3); retrying while at max concurrency queues
  correctly (F3); removing a `waiting` page dequeues it, removing an
  in-flight page discards its rows without corrupting `_activeExtractions`
  (F3); all four F1 override-survival tests (listed in M1) exercised
  through the controller's public API, not just the pure functions; two
  unmerged rows edited to the same normalized name save as exactly ONE
  product, with the skip counted into `skippedDuplicates` (rev 4 FIX 3); a
  cleared price survives a page add and the pre-save recompute, and a
  malformed price blocks the whole save with zero products created (rev 4
  FIX 1); a failed pre-save catalog re-read resets `saving`, shows an error,
  and writes nothing (rev 4 FIX 4).
- Failure: `FakeAiGateway` returns the same fixture for every page, making
  merge tests vacuous. Cause: mission 01 M4 made `extractInput` a mutable
  field, easy to forget to vary. Counter-move: set it explicitly between
  calls in every multi-page test.

**M3 — Screens + route.**
`lib/app/router.dart`: ONE `GoRoute(path: 'import', name: 'notebook-import',
parentNavigatorKey: rootNavigatorKey, builder: (_, __) => const
NotebookImportScreen())` under the products branch. Entry: Products tab
AppBar action, gated (D-03e).
Screens:
- **Capture**: list of pages (n°, status chip — waiting / extracting / done
  / failed — row count; failed pages show the message + Retry / Remove),
  "Add page" (emerald, ≥48dp, disabled while the picker is open, at the
  10-page slot cap, or at the 12-attempt cap — NOT while pages extract —
  showing the specific cap-hit message per F7), a small session counter
  ("N/10 pages, M/12 extraction attempts used"), and "Review N products →".
  **Scheduler-idle gate (round-6 fix).** Because rev 4 let capture run
  concurrently with extraction, an owner could reach Review while pages were
  still `waiting`/`extracting`, and `save()` snapshots rows ONCE — so any
  page finishing after that snapshot would be silently dropped from the
  import with no error and no count. Therefore: "Review N products →" is
  enabled only when ≥1 candidate exists AND the scheduler is idle (no page
  in `waiting` or `extracting`). While any page is still in flight the
  button is disabled and reads "Still reading N pages…". The same rule
  applies at Confirm: `save()` MUST refuse to run if any page is
  `waiting`/`extracting` — a defensive re-check, since the owner may have
  been on the Review screen when a retry was queued.
  - Required tests: with one page `done` and one `extracting`, the Review
    button is disabled and shows the waiting label; when the second page
    completes, it enables; and a `save()` invoked while a page is still
    extracting performs ZERO writes and stays on Review.
  Below the buttons, the **data disclosure**
  line: "Pages are sent to Anthropic to read them. DukaSmart doesn't keep
  the photos." (Fable blind-spot 2.)
- **Review**: gated on the catalog load (F4) — a loading state while
  `productsProvider.future` resolves, a retry state on load failure, then
  the list. Header "Select all (N)"; and when any `alreadyInCatalog` rows
  exist, the explicit line — *"M items are already in your catalog — their
  prices were NOT changed. Edit them in Products."* (Red-team patch). Rows:
  checkbox + name field + `ProductUnit` dropdown (`.label`) + optional
  selling/buying `NumericInputField.money`, prefilled via a **feature-local
  `centsToInputString` copy** (the app's existing convention — both
  `add_product_screen.dart` and `add_stock_screen.dart` carry their own
  copy; do NOT import a screen), EMPTY when the value is null (never "0").
  Every edit/toggle writes into `overrides[row.identityKey]` (F1) — it does
  NOT mutate a `CandidateRow` in place, since that type is a disposable
  read-only projection now. `alreadyInCatalog` rows: greyed, unchecked, not
  selectable, chip "In catalog", values still visible.
  Merged rows show "also read as: {absorbedNames.join(', ')}" and an
  **Unmerge** action (F5b) that splits the group back into independent,
  individually selectable/editable rows. Per-row validation errors (F6)
  render inline and block the Save button until every selected row is
  clean.
- **Save**: `ConfirmationDialog.show("Add N products to your catalog? Stock
  starts at 0 — receive stock when it arrives.")` → linear progress; back
  disabled while saving. If F6 validation fails, the dialog is never
  reached — the Review screen blocks first.
- **Result**: "N products added" (+ "M already in catalog", "K couldn't be
  added" when non-zero) → pop to the product list (its stream updates live).
- Leaving with unsaved candidates ⇒ confirm-discard dialog.
- Expect: widget tests — gated entry present/absent; fixture page → review
  shows rows; deselect one → save creates N−1; empty-price row saves with
  null prices; duplicate row greyed and uncounted; the header count line
  appears when seeds collide; absorbed names render on a merged row;
  Unmerge splits a merged row into two independently selectable rows;
  invalid name/price shows inline errors and disables Save; catalog-load
  retry state renders on a forced provider error.
- Failure: 600-row list janks. Cause: unbounded `ListView` rebuild cost.
  Counter-move: `ListView.builder` (already the plan), no images in rows,
  `const` where possible.

**M4 — Final battery.** In order, each with its bar:
1. `flutter analyze` → Expect "No issues found". Failure: an unfixable lint
   that would require editing frozen surfaces. Cause: the fix crosses into
   code outside this mission's ownership. Counter-move: ABORT A2.
2. `flutter test` → Expect all green, count > M0 baseline. Failure: a red
   test you did not write. Cause: you broke v1 behavior. Counter-move:
   diagnose from the failing assertion first — do not silence or skip it.
3. `grep -rn "dart:io" lib/features/products/notebook_import/` → Expect
   zero hits. Failure: a hit. Cause: a photo or file path leaked into the
   pure model/controller layer. Counter-move: move that code behind the
   existing IO boundary (image picker / AI gateway) instead of adding a
   new one.
4. `flutter build web` → Expect completes. Failure: build error. Cause:
   almost always a platform-conditional import (`dart:io` again, or a
   picker plugin) reached from a shared widget. Counter-move: guard it or
   move it behind the same IO boundary as #3.
Real-key multi-page runs are Ian's smoke step — do not attempt; say so.

## Forks
- **F1 zero candidates on a page.** Page → `failed('Nothing readable on this
  page')` + Retry/Remove; other pages unaffected.
- **F2 every row already in catalog.** "Add N" disabled + "Everything on
  these pages is already in your catalog."
- **F3 parser `skippedRows`/`truncated` > 0.** One quiet line above the list:
  "Some lines couldn't be read".
- **F4 router conflict with mission 02.** Trigger: M0's router log shows
  mission 02's `snap-restock` route already added, or a merge conflict
  appears in `router.dart` → both routes are disjoint: KEEP BOTH blocks. This
  is the known accepted overlap.

## Abort conditions
- A0 (F8, rev 5 tightened): `.wargames/GATE-01-extraction-spike.md` missing,
  present without a `GATE: GO` line naming `notebook=YES`, or its `model=`
  does not match the effective `AiConfig.extractionModel`, at M0. No silent
  fallback to Opus — return to Ian per mission 01 rev 5.
- A1: mission 01 absent, baseline red, or modified tracked files at M0.
- A2: `createProduct` rejects a field this plan supplies (contradiction with
  the settled signature above) or a fix demands editing frozen surfaces.
- A3: anything requiring notebook photos to be persisted to disk/DB.

## Verification
M0 baseline; M1 pure-core suite; M2 controller suite; M4 final battery. The
final summary must quote baseline/final test counts, the dart:io grep, state
explicitly that a test asserts `quantity == 0` with no `openingStock`
movement for imported products, and confirm (by test name) that: an invalid
selected row blocks the entire save with zero writes (F6), the pre-save
catalog re-read catches an externally-added duplicate (F4), a deselected or
edited row survives a full page-add/retry/remove cycle (F1), and three
concurrent extractions plus a fourth queued page behave per the F3
scheduler.

## Red-team record
**Attack 1 (Phase B, upheld):** every install ships 5 seed products that are
exactly the staples a real notebook lists (bread, milk, sugar, maize flour,
soda). On the owner's first import those rows are flagged
`alreadyInCatalog` and silently deselected — so the owner's REAL prices for
their five most important products are quietly discarded in favour of demo
prices, on the feature whose entire purpose is "get MY shop into the app".
Patched: the explicit header line naming the count and stating prices were
not changed, plus the same count on the result screen. Importing price
UPDATES for existing products is recorded as the v2.1 follow-up (D-03f) —
owner-safe in principle, but it doubles this mission's surface.
**Attack 2 (Codex 03.1, upheld):** the planned empty-catalog entry point was
both unreachable (seeded catalog, no delete path) and buggy (the screen's
`isEmpty` is the FILTERED list, so the onboarding CTA would appear after any
search miss). Patched: entry dropped to a single Products-tab AppBar action.
**Attack 3 (Codex 03.4, upheld):** cancelled picks left pages stuck in
`extracting`, concurrent Add Page taps made merge order nondeterministic, and
removing a page whose row had absorbed a merge left stale aggregate data.
Patched: no page until capture succeeds, a `capturing` serialisation guard,
stable never-reused page ids, page-local rows, and a pure `aggregate()`
recomputed from scratch on every mutation (with a determinism test).
**Attack 4 (Fable advisor, upheld):** the round-1 fix over-corrected — holding
`capturing` across the whole network call forced the owner through
"snap, wait 15–30s, snap, wait…" ten times, a five-minute session of enforced
staring for a one-time onboarding task. Patched: `capturing` now covers only
the OS picker; extraction runs concurrently (max 3 in flight, FIFO queue),
which the pure-`aggregate` design already makes order-independent — with a
test resolving extractions out of order to prove it.
**Attack 5 (Codex round-2 plan review, upheld — F1/F3/F5/F7):** four
independent failures in the rev-2 design, each serious enough alone:
(1) `aggregate`'s unconditional `selected = !alreadyInCatalog` silently
UN-DID the owner's deliberate deselections and lost or overwrote edits on
merge survivors every time the plan invoked the "recompute from scratch"
pattern it depends on everywhere else — the exact mechanism sold as safe in
Attack 3/4 was quietly destructive to owner intent. (2) the rev-2
concurrency text (`capturing` cleared "before the network call" but also in
`finally`, no queue, no scheduler defined) was not something an executor
could build blind. (3) catalog matching reused the aggressive within-batch
`mergeKey`, so a false near-match could grey out and hide the owner's real
data with no recovery path — the opposite of the "visible and correctable"
claim rev 2 made for merged rows, which were in fact folded away
permanently with no way back. (4) the `pages.length >= 10` check was sold
as a cost cap but was actually a concurrent-entry cap — remove-then-retry
permitted unbounded paid extraction calls. Patched: a two-layer
`ExtractedRow`/`RowOverride`/`applyOverrides` model that never lets
recomputation erase owner intent (F1); an exact FIFO scheduler with a
picker-only busy flag, a 3-slot active-extraction limit, and specified
retry/removal semantics (F3); conservative `catalogKey` catalog matching
kept separate from the aggressive within-batch `mergeKey`, plus a visible
"also read as" + Unmerge escape hatch for over-merges (F5); and a
`pageSlots`/`extractionAttempts` split that actually bounds paid calls per
session regardless of removals (F7). A fifth finding (F2) relocated all
pure types into `import_model.dart` so the controller file is state+IO
only, and a sixth (F8) ties this mission's dependency gate to mission 01's
new blocking exit gate, since handwriting is the harder extraction case and
this mission needs that proof more than mission 02 does.
**Sequencing note (Fable):** when the two feature missions run serially, run
**03 before 02** — notebook import builds the catalog that makes mission 02's
matcher useful; against the 5 seed products almost every receipt line would
land unresolved and the feature would show at its worst.
