# Handoff — Fable 5 (orchestrator) — DukaSmart / Phase T complete / Paused before UAT #2 sign-off

## Current State
Phases F and T are BUILT, merged into `phase/integration`, and verified by the
orchestrator: `flutter analyze` 0 issues, **61/61 tests pass**, app boots in Chrome
with zero exceptions. Ian PASSED UAT #1 (foundation shell). **UAT #2 (full app
walkthrough) was presented but NOT yet passed** — Ian paused the session instead.
Reviews are DEFERRED to a single consolidated pass after all phases (Ian,
2026-07-25 "skip code review until all phases are done"). Nothing merged to `main`.

## Decisions Made (this session)
- Execution lane (Ian): PRIMARY account, Agent-tool/Workflow subagents (not
  second-account dispatch). Per-stage testable UAT gates (Ian).
- Reviews deferred to end (Ian) — EXCEPT the pre-existing Codex PLAN review, whose
  verdict (REVISE: 2H/5M/1L) was folded into the plan BEFORE tracks ran, commit
  `95aecb8`: added frozen `/expenses/add` route + `name:` on every route,
  `NumericInputField.money`/`.quantity` split, `updateProduct` quantity ban,
  `ExpensesDao.watchRecentExpenses` + `recentExpensesProvider`, track
  `test/features/<x>/` write permission, submit-guard + snackbar rules.
- Phase T ran as a Workflow (`dukasmart-tracks`, run `wf_c6e13174-3b3`): 4 Sonnet
  build agents in isolated worktrees off `foundation-frozen`, each piped into an
  independent Sonnet verifier (boundary diff, frozen-surface abuse, contract
  spot-check, full test suite). All 4 done + verified, 0 errors.
- Orchestrator merged the 4 track branches into new `phase/integration` (--no-ff,
  zero conflicts — write isolation held). Merge to `main` awaits Ian's explicit go.

## Completed
- Phase F (F0–F5) on `phase/foundation`, tag `foundation-frozen` = `975408e`.
  Foundation executor divergences (all resolved): riverpod pinned to 2.x line +
  drift_dev 2.34.0 (SDK dep conflicts); sqlite3_flutter_libs confirmed obsolete —
  sqlite3 3.5.0 native-asset build hook used instead (needed user-space Homebrew
  clang/cmake/ninja + `ld` symlink in LLVM bin); build_runner needs `--force-jit`
  with native-asset hooks present; TDD caught real bug (createProduct not setting
  opening quantity — fixed + test-locked).
- Phase T: T1 Products/Inventory (`phase/track-products`), T2 Sales/POS
  (`phase/track-sales`), T3 Expenses+Dashboard (`phase/track-expenses`),
  T4 Close/Report (`phase/track-close`). All boundary-clean, all full-suite green.
- Integration merge commits on `phase/integration` up to `a56b6d2`.

## Remaining
1. **Ian's UAT #2** — full walkthrough on `phase/integration` (script in the last
   session message; short form: seeded products → add product w/ profit row →
   add stock → cash sale w/ change + M-PESA sale → stock reduced → expense incl.
   backdated → dashboard totals + Attention Needed → close day → report + insight).
   Run with: `cd ~/Documents/Flutter/dukasmart && export PATH="$HOME/flutter/bin:$PATH" && flutter run -d chrome --web-port=8770`
2. Consolidated review pass (task #1): Codex gpt-5.6-sol xhigh over the full diff
   (`git diff main...phase/integration`) + the parked findings below; fall back to
   Sonnet 5 xhigh if Codex unreachable. Fold H/M, note L.
3. Phase I tail: Android device run via adb (physical device preferred; FLAG IAN
   before downloading any ~1GB emulator image), `flutter build apk --release`,
   README.md, `docs/plans/SYNTHESIS.md`.
4. Merges to `main` (foundation + integration) — ONLY on Ian's explicit go;
   push (no remote exists yet) is a separate go.

## Open Flags
1. **Parked LOW findings for the end review:** (a) T1
   `add_stock_screen.dart` local `centsToInputString()` also used for dialog
   display text instead of frozen `formatCents()` — literal contract violation,
   not a correctness bug; (b) T3 added no tests for new dashboard/expense UI
   (attentionCount aggregation etc.) — coverage gap.
2. **T2 divergence notes (benign, recorded):** design doc H1 still titled "v1.2"
   though content is v1.3 (cosmetic); cash button label "Confirm Cash Payment"
   chosen by symmetry; cart shared via feature-local Riverpod providers
   (cartProvider et al.) rather than route params — consistent with D6.
3. Network was flaky all night (Anthropic 529/ECONNRESET, OpenAI resets killed one
   Codex run). Workflow runs are resumable: `resumeFromRunId: wf_c6e13174-3b3`.
4. Workflow worktrees live under `.claude/worktrees/wf_c6e13174-3b3-{1..4}`
   (untracked `.claude/` dir) — safe to `git worktree remove` after review; the
   track branches are fully merged so nothing is lost either way.

## Critical Context
- Reviews deferred = Ian's standing instruction for this build; the review-of-record
  happens ONCE, after Phase I build steps, before merge to main.
- Frozen surface (DAOs/providers/widgets/router) held: verifiers confirmed no track
  touched core files and no raw drift usage.
- Test count map: foundation 43 → +T1 8 +T2 4 +T4 6 = 61 combined (T3 added none).
- Flutter 3.38.3 at `~/flutter`; Android SDK at `~/Android/Sdk` (no emulator image
  — SDK only, per Ian). C toolchain via Homebrew is REQUIRED for tests/run
  (sqlite3 native-asset hook); already installed user-space.
- Plan file + design doc v1.3 remain BINDING for any remaining executor work.

## Git State
- Repo `~/Documents/Flutter/dukasmart`, NO remote. Working tree clean except
  untracked `.claude/` (workflow worktrees).
- `phase/integration` (checked out): `a56b6d2` = merge of all 4 tracks onto
  `foundation-frozen`; history: foundation F0–F5 (`975408e`, tagged
  `foundation-frozen`) ← docs commits ← track merges 4323a55/fe66f36/a56b6d2.
- Branches: `main` (docs only, `447ac0e`), `phase/foundation` (`975408e`),
  `phase/track-{products,sales,expenses,close}` (merged), `phase/integration`.
- This handoff committed on `phase/integration`.

## Resume instruction
Next session: (1) read this file; (2) restart the dev server (command in
Remaining #1) and get Ian's UAT #2 verdict — fix-loop any failures via small
executor dispatches on `phase/integration`; (3) on UAT pass, run the consolidated
review (Remaining #2), fold H/M via executor dispatches, re-verify 61+ tests;
(4) Phase I tail: adb Android run (flag before emulator download), release APK,
README, SYNTHESIS.md; (5) ask Ian's explicit go to merge `phase/foundation` +
`phase/integration` → `main` (--no-ff), delete merged phase branches; push only on
a separate explicit go if a remote is added.
