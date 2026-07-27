# Handoff — Opus 5 (planning began on Fable 5) — DukaSmart / AI v2 / Planning COMPLETE (2026-07-27)

## Current State
- **Planning complete. No application code written. No tracked file modified.**
- Three wargame missions for AI v2 exist under `.wargames/`, fully reviewed:

| Mission | File | Rev | Status |
|---|---|---|---|
| 01 vision + extraction plumbing | `.wargames/wargames/01-ai-vision-extraction.md` | 6 | **Codex APPROVED** (round 5) |
| 02 snap-to-restock | `.wargames/wargames/02-snap-to-restock.md` | 5 | **Codex APPROVED** (round 4) |
| 03 notebook import | `.wargames/wargames/03-notebook-import.md` | 9 | Substance verified (round 7); 2 minor fixes applied after — re-verify at dispatch |

- Briefs: `.wargames/tasks/`. Grading bar: `.wargames/SUCCESS.md`.
  Full review arc + every design decision + lessons: `.wargames/LEDGER.md`.
- Review effort: **7 Codex (gpt-5.6-sol xhigh) rounds + 1 Fable advisor pass.**
  Findings per round: **30 → 20 → 10 → 3 → 3 → 2 → 2.**
- Session models: planning started on Fable 5; orchestration moved to Opus 5
  on Ian's `/model` switch. Fable used as ADVISOR only, via second-account
  dispatch. All plan rewrites executed by second-account Sonnet.

## Decisions Made
1. **v2 scope** = snap-to-restock + notebook import sharing one vision/
   extraction plumbing job. Voice quick-entry deferred to v2.1.
2. **AI never writes to the DB.** Extraction returns typed data only; every
   write goes through existing/amended DAOs behind owner confirmation.
3. **D-02a** new `StockDao.receiveStockBatch` — logged amendment to the frozen
   D3/D9 DAO surface; `_applyLine` shared with `receiveStock`.
4. **D-02b** new products created at `openingQty: 0` with an id ledger; **if
   ANY create fails, abort before the batch.** Nothing commits, retry is safe,
   and a committed batch is always terminal — stock can never double-apply.
5. **D-03a** notebook imports create at quantity 0 (catalog, not stock count).
   **D-03b** no historical-totals backfill. **D-03e** single Products-tab entry.
6. **AM-3** supplier payment is an explicit three-way choice defaulting to
   "Not paid yet" — never default to writing money.
7. **AM-4** unmatched receipt lines start `unresolved`; they never auto-create.
8. **Extraction runs on Haiku** (`claude-haiku-4-5-20251001`) via
   `AiConfig.extractionModel` / `AI_EXTRACTION_MODEL`; Ask-your-duka and the
   daily insight stay on Opus (Ian, 2026-07-27). Reverses the earlier
   single-model decision.
9. **Three distinct name keys in mission 03**, each with one job: `catalogKey`
   (trim+lowercase — matches the app's real duplicate convention),
   `normalizeName` (punctuation-stripping — save-time dedupe of edited names),
   `mergeKey` (whitespace-stripped — within-batch merging).
10. **M10 spike is a blocking exit gate**, Ian-owned. Missions 02 and 03 abort
    at M0 without a matching `GATE: GO` line naming the shipping model.

## Completed
- [x] Recon of the whole AI seam + restock/catalog/daily-close/platform
      (ultracode workflow `wf_ddd7ecd3-c19`, 5 mappers, 0 errors).
- [x] 3 mission briefs + 3 wargames, red-teamed and self-graded vs SUCCESS.md.
- [x] 7 Codex review rounds; all findings resolved or logged as divergences.
- [x] 1 Fable advisor pass (second account) — 5 amendments accepted.
- [x] Fable ledger lines written (`~/.claude/fable-ledger.md`, 07:06 + 08:54).
- [x] Obsidian daily log updated.

## Remaining
- [ ] **Commit `.wargames/`** — ~2,000 lines of reviewed planning is untracked
      and the branch has never been pushed. Cheapest possible safety step.
- [ ] **Build mission 01** (recommended next action — see Resume). It is
      APPROVED and does NOT need the spike; it CREATES the spike harness.
- [ ] **Ian runs the M10 spike** — real key, ≥5 printed receipts + ≥5
      handwritten notebook pages, Haiku primary with Opus as comparison; fill
      `.wargames/GATE-01-extraction-spike.md`. This is the fork in the road:
      it decides whether 02 and 03 are worth building.
- [ ] Then dispatch **03 before 02** when serial (notebook import builds the
      catalog that makes 02's matcher useful).
- [ ] Re-verify mission 03 with Codex at dispatch time.

## Open Flags
1. **Nothing proves extraction works yet.** Every test in all three plans fakes
   the extraction result. The M10 spike is the only thing that will tell us
   whether Haiku can read a faded thermal receipt or Swahili/Sheng handwriting.
2. Handwriting is the harder half — if Haiku misses, mission 03 is the likely
   casualty. The gate records `notebook=NO` and the decision returns to Ian;
   **the executor must NOT silently fall back to Opus.**
3. `receiveStockBatch` is the only new money-write primitive in v2 → HARD-lane
   Codex review on its own diff, not blended into the UI diff.
4. Mission 01 F1: `package:image` decode/resize cost on the web target —
   empirical check written into the plan with a documented fallback.
5. Pre-real-user issue, out of v2 scope: every install carries 5 undeletable
   seed demo products, which notebook import will put right in front of the owner.
6. v2.1 deferrals: voice quick-entry; notebook import updating EXISTING product
   prices (D-03f); buying-price-drift highlighting.

## Critical Context
- **The binding appendix** in `docs/superpowers/plans/2026-07-26-ai-capabilities.md`
  (lines ~2910–2984, R1–R7 + A6.x) governs all gateway behavior and overrides
  inline plan code. It binds BEHAVIOR, not the `AiGateway` interface — adding
  methods is permitted.
- **Three defects worth remembering** (all in `.wargames/LEDGER.md`):
  (a) snap-to-restock could have double-applied stock via a retry after a
  partial commit; (b) the pre-ticked "Paid from till (cash)" default would
  have booked phantom cash out-flows for M-PESA supplier payments, breaking
  daily-close reconciliation — Fable caught this, two Codex rounds missed it
  because the code was technically correct; (c) `watchProducts().first` does
  NOT force a fresh query — Drift replays cached `_lastData` when an identical
  stream is already subscribed, as the product list screen always is.
- **Process lesson, recorded:** three separate defects traced to ONE Fable
  amendment applied quickly on top of an already-reviewed plan. Advisor
  feedback must be re-run through the same rigor as the original plan.
- Test env: `export PATH="$HOME/flutter/bin:$PATH"`. No CI exists — analyze and
  test are run manually. Baseline at last check: 217 tests green.
- No `dart:io` in any web-shared path; money is integer cents displayed via
  `formatCents()`.

## Git State
- Branch **`feature/ai-capabilities`** @ **`afd617c`** ("fix(ai): send
  anthropic-dangerous-direct-browser-access header").
- **No modified tracked files.** Working tree clean apart from untracked dirs.
- Untracked: `.wargames/` (this session's work), plus pre-existing `.agents/`,
  `.claude/`, `presentation/`, `remotion/*`, `skills-lock.json`,
  `docs/superpowers/HANDOFF.md`.
- `origin/development` @ `6fb2cd3` contains AI v1 (merged + pushed previously).
  0 commits ahead of it on this branch. `main` untouched.
- **`feature/ai-capabilities` has never been pushed.**

## Resume instruction
Read this file, then `.wargames/LEDGER.md` for the decision record. The
recommended next action is: **commit `.wargames/`, then execute mission 01**
(`.wargames/wargames/01-ai-vision-extraction.md`) via a second-account Sonnet
executor — it is APPROVED and runnable blind, and it ends by leaving
`tool/extraction_spike.dart` ready for Ian. Do NOT dispatch missions 02 or 03
until Ian has run the spike and `.wargames/GATE-01-extraction-spike.md` carries
a `GATE: GO` line naming `claude-haiku-4-5-20251001`. Execution requires Ian's
explicit go.
