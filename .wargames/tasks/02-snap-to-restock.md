WARGAME ORDER. You are not executing this mission, you are wargaming it. A cheaper
executor runs the brief below later. Your job is the route it will follow.

Recon first, read-only: the repo structure, the existing patterns for similar
features, and anything the new feature must integrate with or match.

Then fight the mission on paper, move by move, and write it to
wargames/02-snap-to-restock.md.

=== THE MISSION BRIEF (the executor's orders, not yours) ===

Here is my repo: /data/Documents/Flutter/dukasmart. I want to add
**Snap-to-restock**: photograph a supplier receipt → the vision extraction
plumbing (mission 01) pulls out line items → a review screen shows each line
matched against the existing product catalog → the owner edits/confirms → on
Save, stock quantities are updated through the EXISTING restock/save path and
(optionally, via a pre-ticked checkbox) the receipt total is recorded as a
supplier expense / till cash-out through the EXISTING expense path.

Flow, concretely:
1. Entry point: an action on the inventory/stock screen (visible only when
   aiAvailableProvider is true), e.g. "Snap receipt" with a camera icon.
2. Capture: camera or gallery via the mission-01 capture utility. Show the
   photo + a processing state while extraction runs (async, cancellable by
   leaving the screen).
3. Review screen — the heart of the feature: one row per extracted line item:
   - matched product (fuzzy name match against catalog; confidence shown by
     pre-selecting the match vs. leaving "choose product" open)
   - unmatched lines offer "create new product" (name + unit prefilled from
     the receipt, price fields prefilled) or "skip"
   - editable qty and buying price per row (prefilled from extraction)
   - running total vs. receipt_total_cents; mismatch shown, not blocking
4. Confirm: a single Save applies each confirmed row through the existing
   repository methods the manual restock form uses. The AI layer itself never
   touches the DB — only this owner-confirmed screen does, through the same
   code path a manual restock takes.
5. Failure honesty: if extraction fails (offline / bad photo / over-size),
   show the existing AI error states and a "type it manually" escape hatch
   that lands on the normal Add Stock form.

It needs to integrate with: the mission-01 extraction plumbing, the existing
restock/add-stock flow and its repositories, the product catalog (search +
create), the expense recording flow, and aiAvailableProvider gating. Follow
the existing patterns in lib/features/ (state management, controllers,
navigation, form validation, design system per DESIGN.md) — do not introduce
a new pattern where one already exists.

Constraints:
- Owner-confirmed writes ONLY; every DB mutation goes through the DAO layer
  the manual forms use. ONE deliberate exception (recon-driven): the existing
  StockDao.receiveStock is single-product, so this mission adds
  StockDao.receiveStockBatch — same validation and semantics, N lines + one
  optional till cash-out expense in ONE Drift transaction, factored to share
  code with receiveStock. No other new write paths; this is a logged amendment
  to the frozen D3/D9 DAO surface.
- Money is integer cents end-to-end; display via formatCents(). Design
  principles hold: money is the hierarchy, emerald = money-action, 48dp+
  targets, one-handed use.
- Works on Android and web (no dart:io in shared paths).
- Offline-first unharmed: the feature degrades to the manual form; nothing
  else in the app depends on it.
- Keep flutter analyze clean and the full test suite green; add controller +
  widget tests with a faked extraction result (no live API).

Do the simplest thing that works well. No speculative abstractions, no
configuration options nobody asked for.

When you believe you are done, verify before reporting: run `flutter analyze`
and `flutter test`, and manually exercise the golden path (fixture extraction
→ review → save updates stock + expense) plus key edge cases: zero matched
products, all-unmatched receipt, extraction failure, cancel mid-processing.
Audit each claim in your final summary against something you actually ran or
read in this session.

=== ASSUMPTIONS MADE WHILE DRAFTING (flagged, not asked) ===
- Fuzzy matching is local and simple (normalized token overlap / contains),
  no new dependency.
- Expense cash-out checkbox defaults ON when receipt_total_cents present.
- Depends on mission 01 landing first; runs after it, same branch.
