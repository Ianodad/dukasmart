# Handoff — Fable 5 (orchestrator) — DukaSmart / MVP SHIPPED to main

## Current State
**MVP COMPLETE AND SHIPPED.** On Ian's explicit go (2026-07-26 ~04:20):
`phase/foundation` + `phase/integration` merged --no-ff into `main`
(`77f86bc`, `8f386f1`), verified on main (analyze 0, **125/125 tests**,
zero content diff vs integration tip), pushed to the public repo
`Ianodad/dukasmart` (default branch now `main`). All phase/track/worktree
branches deleted locally and on origin; all worktrees removed — repo is
single-branch `main`. UAT #1 and #2 PASSED. Codex verdict fully folded.
UI restyle (PRODUCT.md/DESIGN.md contract) shipped.

## Still open (post-ship tail)
1. Android ON-DEVICE acceptance only: no adb device was attached; ~1GB
   emulator download stays gated on Ian. (APK itself is BUILT and RELEASED.)
2. Ian's `feature/ai-capabilities` branch (his commit `33427c1`, unpushed,
   checked out in main tree): design spec for v1 AI features — next
   milestone, plan on his go. Deck/promo commits went to main, not his branch.

## Shipped extras (2026-07-26 early morning)
- MIT LICENSE (`a9062f5`). 14 screenshots + README gallery (`2a5b3f2`).
- Remotion promo video (36s 1080p) + GIF preview embedded in README
  (`8cb2710`); project source in `remotion/`.
- 10-slide pptx deck `docs/dukasmart-deck.pptx` (`857d2ab`).
- **GitHub Release `v0.1.0-mvp` LIVE** with `dukasmart-v0.1.0.apk` (75MB,
  debug-signed) + promo mp4: github.com/Ianodad/dukasmart/releases.
  NDK 28.2.13676358 installed manually (gradle download hung; direct curl).
- pkill LESSON (extended): never combine pkill with a relaunch or ANY
  command whose line contains the plain pattern — bracket-escape always.

## Decisions Made
- Execution lane (Ian): PRIMARY account, Agent-tool/Workflow subagents;
  per-stage testable UAT gates; reviews deferred to end.
- Codex PLAN review verdict (REVISE 2H/5M/1L) was folded pre-tracks (`95aecb8`).
- Phase T ran as resumable Workflow `wf_c6e13174-3b3` (4 build + 4 verify agents,
  all done/verified, worktree-isolated). Orchestrator merged all 4 tracks into
  `phase/integration` — zero conflicts.
- UAT-feedback features implemented directly on `phase/integration` by small
  Sonnet executors (Ian's live-iteration loop), each verified by orchestrator
  re-running analyze + full suite.
- Common-products catalog prices are ORCHESTRATOR ESTIMATES (KES, kiosk-typical),
  flagged to Ian; he may re-price — each is one line in
  `lib/features/products/common_products.dart`.

## Completed
- Phase F (F0–F5): `phase/foundation`, tag `foundation-frozen` = `975408e`;
  43 foundation tests. (Toolchain notes: riverpod 2.x + drift_dev 2.34.0 pins;
  sqlite3 3.5.0 native-asset hook needs Homebrew clang/cmake/ninja — installed;
  build_runner needs `--force-jit`.)
- Phase T: 4 track branches built + independently verified, merged:
  `4323a55`/`fe66f36`/`a56b6d2` (+products/sales/expenses+dashboard/close).
  61 tests at merge.
- UAT #2 feedback (both on `phase/integration`):
  - `0d9028b` duplicate-aware Add Product (amber "Already in inventory" banner on
    barcode/name match → "Add Stock instead" preselected) + quick-restock icon on
    every Product List row. 67 tests.
  - `27b7d09` common-products catalog: "Choose common product" bottom sheet in Add
    Product, 15 staples with default KES prices; tap → prefills name/unit/prices/
    threshold (opening stock left to user); already-stocked items show "In stock: N"
    and route to Add Stock instead. 78 tests.
  - `f724761` till cash-out for stock (design Amendment A1, appended to design doc):
    new `ExpenseCategory.stockPurchase` — EXCLUDED from expensesTotal/netResult
    (COGS covers cost at sale time), INCLUDED in cashExpenses → reduces
    expectedCash. `receiveStock(tillCashOutCents:)` records it atomically via
    ExpensesDao inside the same transaction; Add Stock gets "Paid from till
    (cash)" toggle + editable prefill (`computeTillPrefillCents`); Record Expense
    shows helper text for the category. 88 tests.
- Handoff committed on `phase/integration` (this file).
- **Codex consolidated review (gpt-5.6-sol xhigh, 2026-07-26 ~03:00): REVISE —
  5H/8M/1L** (full text: session task bnusqrgrq output; findings also
  reflected in fix commits). ALL code H/M folded and verified:
  - `bbd54e3` Fix-A: negative formatCents sign, createProduct/receiveStock
    invariant validation, integer M-PESA share, delivery README, design-doc
    header v1.3. (+13 tests)
  - `a250d94` Fix-B: dailyMetricsProvider rebuilt as single transactional
    snapshot (drift tableUpdates + self-rescheduling midnight timer, bounds
    recomputed per emission), closedDayReportProvider → autoDispose,
    AppDatabase.ready() + databaseReadyProvider, splash raw SQL removed.
    (+6 tests)
  - Merged: `b2f7440` on `phase/integration`; verified 107/107, analyze 0.
  - Parked adjudications: (a) dialog format LOW → UI-2A spec; (b) dashboard
    test gap LOW → noted; (c) doc header LOW → fixed in Fix-A.
  - Remaining Codex MEDs live in UI-2 specs: payment `_mpesaPrefilled`
    (UI-2B), barcode manual submit + dashboard Daily Report action (UI-1).
- **"Slate + Emerald Pro" UI restyle COMPLETE (Ian-approved direction,
  2026-07-26 ~03:00–04:00), merged `8f6467b` on `phase/integration`,
  verified 125/125 + analyze 0.** PRODUCT.md + DESIGN.md at repo root are the
  BINDING design contract for all future UI work. Structure: UI-1 core
  (bundled Lexend fonts as offline assets, theme.dart rewritten to
  AppTokens/AppTextStyles + full ThemeData, all core/widgets restyled
  API-compatible, dark-band app bar, dashboard showpiece + Daily Report quick
  action + DailyCloseDao.latestClose(), barcode manual-submit fix) then
  UI-2A/B/C parallel screen sweeps (products/inventory/splash, sales incl.
  M-PESA prefill fix, expenses/close/report ledger treatment). All six work
  branches merged and deleted; worktrees removed.
- Test map extension: 88 → 107 (codex fixes) → 114 (UI-1) → 125 (UI-2A/B/C).

## Remaining
1. **Finish UAT #2** incl. FULL new-UI visual pass (slate+emerald restyle landed,
   see Completed) + catalog price check.
   Dev server: `cd ~/Documents/Flutter/dukasmart && export PATH="$HOME/flutter/bin:$PATH" && flutter run -d chrome --web-port=8770`
   (pkill gotcha EXTENDED: never put the pkill and the relaunch in ONE command
   line — the relaunch half's literal "web-port=8770" makes pkill kill the
   compound shell itself. Kill and launch in separate commands.)
2. Codex verdict fully folded — every code H/M/L from the REVISE list is now
   fixed and merged (see Completed). Remaining Codex items are process gates
   only (= items 3–4 here: Android acceptance, APK, synthesis, then merge).
3. Phase I tail: Android run via adb (physical device preferred; FLAG IAN before
   any ~1GB emulator download), `flutter build apk --release`, README (DONE),
   `docs/plans/SYNTHESIS.md`.
4. Merge `phase/foundation` + `phase/integration` → `main` ONLY on Ian's explicit
   go; push is a separate go (no remote yet).

## Open Flags
1. Parked for end review: (a) T1 local `centsToInputString()` used for dialog
   display text instead of frozen `formatCents()` (LOW, literal contract
   violation — note: the SAME helper pattern was reused in `27b7d09`'s prefill,
   acceptable there since it feeds TextEditingControllers, not display); (b) T3
   has no tests for dashboard UI logic (attentionCount etc.); (c) catalog prices
   unconfirmed by Ian.
2. T2 divergences (benign, recorded): design doc H1 says "v1.2" but content is
   v1.3; "Confirm Cash Payment" label chosen by symmetry; cart shared via
   feature-local Riverpod providers (consistent with D6).
3. Network was flaky (Anthropic 529/ECONNRESET ×2, OpenAI resets) — killed agents
   mid-run repeatedly; workflow + SendMessage resumes recovered everything.
4. Workflow worktrees at `.claude/worktrees/wf_c6e13174-3b3-{1..4}` (untracked) —
   branches fully merged; safe to `git worktree remove` anytime.
5. pkill gotcha: killing the dev server with `pkill -f "web-port=8770"` self-kills
   the invoking shell — use a bracket pattern (`web-port=877[0]`).

## Critical Context
- Design doc v1.3 + plan (incl. `95aecb8` amendments) BINDING for any executor.
- Frozen surface held all session: tracks + feature executors touched only
  lib/features/<x>/ + test/features/<x>/; verifiers confirmed no raw drift usage.
- Review-of-record happens ONCE (Remaining #2) before merge to main — do not
  re-litigate per-feature.
- Test map: 43 foundation → 61 post-tracks → 67 (+dup/restock) → 78 (+catalog) →
  88 (+till cash-out A1).
- Flutter 3.38.3 at `~/flutter`; Android SDK at `~/Android/Sdk`, NO emulator image
  (Ian chose SDK-only); C toolchain via Homebrew required for tests/run.

## Git State
- Repo `~/Documents/Flutter/dukasmart`, NO remote. `phase/integration` checked
  out; clean except untracked `.claude/` (workflow worktrees).
- `phase/integration` tip after this handoff commit; sequence: `733ee4a` handoff →
  `0d9028b` dup/restock → `27b7d09` catalog → `dd50741` handoff → `f724761`
  till cash-out → this commit.
- Branches: `main` (docs, `447ac0e`), `phase/foundation` (`975408e`, tag
  `foundation-frozen`), `phase/track-{products,sales,expenses,close}` (merged),
  `phase/integration` (HEAD).

## Resume instruction
Next session: (1) read this file; (2) restart dev server (Remaining #1 command),
ask Ian to continue/finish UAT #2 walkthrough incl. catalog price check;
(3) implement any further UAT feedback via small Sonnet executor dispatches on
`phase/integration` (orchestrator re-verifies analyze + full suite each time);
(4) on "UAT pass": consolidated Codex xhigh review over full diff, fold H/M;
(5) Android adb run (flag before emulator download) → `flutter build apk
--release` → README → SYNTHESIS.md; (6) request Ian's explicit go to merge to
`main` (--no-ff), delete phase branches; push only on separate go.
