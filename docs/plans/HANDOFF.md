# Handoff — Fable 5 — DukaSmart / Planning Phase Complete / Pre-Execution

## Current State
Planning is 100% done and Codex-approved; ZERO app code written yet (docs only).
Execution has NOT started — Ian was mid-decision on the execution lane when the
session ended. One background Codex consistency review of the implementation plan
was still running (see Open Flags).

## Decisions Made
- **Approach A** (Ian-approved): Foundation first (serial) → 4 parallel worktree-isolated
  Sonnet tracks (screens only) → serial integration. Tracks rebalanced to 4 per Codex.
- **Design v1.3 APPROVED by Codex** (gpt-5.6-sol, xhigh) after 4 review rounds
  (R1: 9 required changes; R2: 5; R3: 2; R4: APPROVED). All accepted — divergence log empty.
- Key design rulings (binding, in `docs/specs/2026-07-25-design.md`): int-cents money
  (D2); atomic DAO contracts with in-transaction validation + double-submit guards (D3);
  half-open local-day bounds; expense backdating = midnight + list shows date not fake
  time (D3); first-run seeding via Drift `onCreate` with opening movements; exact close-day
  formulas + best-seller tie-breaks (D4); `ClosedDayReport` DTO = Daily Report contract
  (stored financials "as at close", derived best-seller, current low stock); bottom sheets
  for View Sale / View Product — 13 screens fixed (D5); tracks may modify/add files ONLY in
  their own `lib/features/<x>/` (D6/D9); Drift web assets explicit, Foundation must verify
  package set vs current docs — do NOT assume sqlite3_flutter_libs (D7); scanner fallback
  at every entry point via MobileScanner error API (D7).
- Fable planning pass logged to `~/.claude/fable-ledger.md` (2026-07-25 23:10).

## Completed
- `docs/specs/2026-07-25-requirements.md` — Ian's full MVP spec, condensed.
- `docs/specs/2026-07-25-design.md` — v1.3, Codex-APPROVED.
- `docs/plans/2026-07-25-dukasmart-mvp-plan.md` — full implementation plan:
  Phase F (F0–F5 Foundation incl. schema/DAO/DTO code + frozen route table),
  Phase T (T1 Products/Inventory, T2 Sales/POS, T3 Expenses+Dashboard, T4 Close+Report),
  Phase I (reviews, merges, acceptance, Android run, APK, README, synthesis).
- **Android SDK reinstalled** to `~/Android/Sdk` (platforms 35+36, build-tools 35/36,
  platform-tools; licenses accepted). `flutter doctor`: Android toolchain ✓, Chrome ✓.
  Flutter 3.38.3 at `~/flutter`.

## Remaining
1. Read the pending Codex PLAN review verdict (Open Flag #1); apply any REVISE items.
2. Ian picks execution lane (he interrupted the question to ask for this handoff):
   (a) second-account headless — Foundation via `~/.claude/scripts/dispatch-second.sh`,
   then tracks via `fanout-second.sh` (recommended default per routing rules);
   (b) primary-account Agent-tool Sonnet subagents.
3. Execute Phase F → tag `foundation-frozen` → fan out T1–T4 in worktrees →
   per-track Sonnet xhigh reviews → Phase I integration → acceptance in Chrome →
   Android device run → `flutter build apk --release` → README → synthesis.

## Open Flags
1. **Codex plan-consistency review was IN FLIGHT** at session end. Output file:
   `/tmp/claude-1000/-home-adera-Documents/18bffd15-d52f-461c-8fde-1898de9a312e/tasks/bou8q9qwt.output`
   If missing/empty next session, re-run: `codex exec --sandbox read-only -C ~/Documents/Flutter/dukasmart -c model_reasoning_effort=xhigh "<plan-vs-design consistency review, see plan header>"`.
   Do NOT start Phase F before a plan verdict exists.
2. **Android acceptance run** (design D7, mandatory pre-APK): physical device via adb
   preferred; NO emulator system image installed (Ian chose SDK-only). If no device at
   integration time, FLAG IAN before downloading an emulator image (~1GB).
3. Foundation executor must VERIFY current drift web/native package set against live
   docs (context7 / pub.dev) — Codex flagged that sqlite3_flutter_libs guidance may be stale.

## Critical Context
- Design doc v1.3 is BINDING on all executors; plan header says design wins on conflict.
- Track write rule is the parallel-safety linchpin: tracks touch ONLY their feature dir;
  router/core/generated files are Foundation-frozen (tag `foundation-frozen`).
- Codex = reviewer ONLY (never executes). Track reviews are routine tier → Sonnet 5 xhigh.
- Second-account dispatches log to `~/.claude/second-dispatch-ledger.md`; specs must be
  self-contained (the plan's task sections were written for exactly this).
- No `.planning/advisor-notes.md` exists yet (no recurring-critique lessons this task).

## Git State
- Repo: `~/Documents/Flutter/dukasmart`, branch `main`, clean working tree.
- HEAD `76757ec` "docs: implementation plan — foundation + 4 parallel tracks + integration".
- History: 76757ec → 5b3d544 (design v1.3) → 000e377 (v1.2) → 0e4338a (v1.1) → 6c73a87 (initial specs).
- No remote configured. Docs only — no Flutter scaffold yet (F0 not run).

## Resume instruction
Next session (Opus orchestrator per routing rules): (1) read this file +
`docs/plans/2026-07-25-dukasmart-mvp-plan.md`; (2) resolve Open Flag #1 (plan verdict;
apply revisions if any); (3) ask Ian which execution lane, or default to second-account
headless if he already answered; (4) dispatch Task F0–F5 as ONE Foundation executor run
(`dispatch-second.sh -o docs/plans/foundation-report.md -f docs/plans/2026-07-25-dukasmart-mvp-plan.md -C ~/Documents/Flutter/dukasmart "Execute Phase F only"`);
verify `foundation-frozen` tag + green tests before fanning out T1–T4.
