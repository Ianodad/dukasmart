WARGAME ORDER. You are not executing this mission, you are wargaming it. A cheaper
executor runs the brief below later. Your job is the route it will follow.

Recon first, read-only: the repo structure, the existing patterns for similar
features, and anything the new feature must integrate with or match.

Then fight the mission on paper, move by move, and write it to
wargames/03-notebook-import.md.

=== THE MISSION BRIEF (the executor's orders, not yours) ===

Here is my repo: /data/Documents/Flutter/dukasmart. I want to add **Notebook
import**: photograph pages of the owner's old paper daily book → the vision
extraction plumbing (mission 01) reads the handwritten product list (names,
units, prices — Swahili/Sheng/English mix) → a review list shows every
candidate product → the owner edits/deselects → one Confirm bulk-creates the
selected products through the EXISTING product-creation path. This kills the
"type 100 products by hand" onboarding wall.

Flow, concretely:
1. Entry points: (a) the products/catalog screen, and (b) the empty-catalog
   state — both visible only when aiAvailableProvider is true. Label like
   "Import from your notebook".
2. Capture loop: photograph page → extraction runs → "Add another page?" →
   repeat. Each page is ONE extraction call; results accumulate. Hard cap of
   ~10 pages per session (cost sanity); show page count.
3. Review list — one row per candidate product across all pages:
   - name (editable), unit (picker, prefilled when extracted), selling price
     and buying price (editable, may be empty — empty is allowed, not zero)
   - duplicate handling: candidates matching an EXISTING catalog product
     (normalized name) are shown greyed-out as "already in catalog", default
     deselected; near-duplicates WITHIN the import batch are merged, keeping
     the last-seen price
   - checkbox per row, "select all" default ON for clean rows
4. Confirm: bulk-create selected rows through the existing product repository
   create method, one by one, inside a progress indicator; report "N products
   added, M skipped". The AI layer never touches the DB — only this
   owner-confirmed screen does, via the same code path manual add-product uses.
5. Partial failure: if a page's extraction fails, keep the pages that worked;
   the failed page can be retried or skipped. Nothing already reviewed is lost.

It needs to integrate with: mission-01 extraction plumbing, the product
catalog model + creation repository + validation rules (units, duplicate
names), the onboarding/empty state, and aiAvailableProvider gating. Follow
the existing patterns in lib/features/ for state management, list UIs, and
forms — do not introduce a new pattern where one already exists.

Constraints:
- Owner-confirmed writes ONLY, through existing creation methods — respect
  their validation (whatever recon finds about name uniqueness, required
  fields, unit enums). No new write primitives.
- Money integer cents; empty price ≠ 0 — products may be created priceless if
  the existing model allows it; otherwise the row requires a price before it
  can be selected (follow what the manual form enforces).
- Android + web safe (no dart:io in shared paths).
- Keep analyze clean and tests green; add tests: page-accumulation state,
  dedupe/merge logic, bulk-create with a faked repository, partial-failure
  retry.

Do the simplest thing that works well. No speculative abstractions, no
configuration options nobody asked for.

When you believe you are done, verify before reporting: run `flutter analyze`
and `flutter test`, and manually exercise the golden path (2 fixture pages →
review → confirm creates N products) plus edge cases: all-duplicates page,
extraction failure on page 2 of 3, empty page (zero candidates), dedupe
within batch. Audit each claim in your final summary against something you
actually ran or read in this session.

=== ASSUMPTIONS MADE WHILE DRAFTING (flagged, not asked) ===
- Past daily TOTALS in the notebook are OUT of scope — v2 imports the product
  catalog only (historical sales backfill would corrupt "trust the numbers").
- 10-page cap per session is a product guess — cheap to change later.
- Depends on mission 01; independent of mission 02 (parallel-safe if
  worktree-isolated, subject to recon confirming no shared files beyond
  mission-01 outputs).
