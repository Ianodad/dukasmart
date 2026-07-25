# Handoff — Fable 5 (orchestrator) — DukaSmart / Phase T + UAT-feedback features / Mid-UAT #2

## Current State
Phases F and T are BUILT and merged into `phase/integration`. Ian PASSED UAT #1
(foundation). **UAT #2 (full-app walkthrough) is IN PROGRESS** — Ian has been
actively testing and filed two feedback items, BOTH already built, verified, and
committed (see Completed). Latest verified state: `flutter analyze` 0 issues,
**78/78 tests pass**, app boots in Chrome cleanly. UAT #2 has NOT been declared
passed yet. Reviews remain DEFERRED to one consolidated pass after all phases
(Ian, 2026-07-25). Nothing merged to `main`. No remote.

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
- Handoff committed on `phase/integration` (this file).

## Remaining
1. **Finish UAT #2** — Ian still walking: sales (cash w/ change + M-PESA), stock
   reduction, expenses (incl. backdated), dashboard totals/Attention Needed,
   close day, daily report + insight. Also confirm/adjust catalog prices.
   Dev server: `cd ~/Documents/Flutter/dukasmart && export PATH="$HOME/flutter/bin:$PATH" && flutter run -d chrome --web-port=8770`
   Fix-loop further feedback via small executor dispatches on `phase/integration`.
2. Consolidated review (deferred-to-end): Codex gpt-5.6-sol xhigh over
   `git diff main...phase/integration` + parked findings below; Sonnet 5 xhigh
   fallback if Codex unreachable. Fold H/M, note L.
3. Phase I tail: Android run via adb (physical device preferred; FLAG IAN before
   any ~1GB emulator download), `flutter build apk --release`, README.md,
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
- Test map: 43 foundation → 61 post-tracks → 67 (+dup/restock) → 78 (+catalog).
- Flutter 3.38.3 at `~/flutter`; Android SDK at `~/Android/Sdk`, NO emulator image
  (Ian chose SDK-only); C toolchain via Homebrew required for tests/run.

## Git State
- Repo `~/Documents/Flutter/dukasmart`, NO remote. `phase/integration` checked
  out; clean except untracked `.claude/` (workflow worktrees).
- `phase/integration` tip after this handoff commit; sequence: `733ee4a` handoff →
  `0d9028b` dup/restock → `27b7d09` catalog → this commit.
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
