# Handoff — Opus 5 — DukaSmart / AI v2 / Mission 01 SHIPPED, gate open (2026-07-27)

## Current State
- **Mission 01 (vision + structured extraction plumbing) is built, reviewed,
  merged, pushed, and proven against the real Anthropic API.**
- **Missions 02 and 03 are blocked** — correctly. They gate their own M0 on
  `.wargames/GATE-01-extraction-spike.md`, which still holds the unfilled
  placeholder.
- **The only thing on the critical path is Ian photographing real samples and
  running the M10 spike.** No code work is pending or in flight.
- Working tree clean (no modified tracked files). Nothing mid-edit.

| Mission | File | Rev | Status |
|---|---|---|---|
| 01 vision + extraction plumbing | `.wargames/wargames/01-ai-vision-extraction.md` | 6 | **SHIPPED** — Codex APPROVED, merged, real-API verified |
| 02 snap-to-restock | `.wargames/wargames/02-snap-to-restock.md` | 5 | Plan APPROVED — BLOCKED on the gate |
| 03 notebook import | `.wargames/wargames/03-notebook-import.md` | 9 | Plan substance-verified — BLOCKED on the gate; **re-verify with Codex at dispatch** |

Full planning + execution record: `.wargames/LEDGER.md`.

## Verified gates (orchestrator-run, never taken from an executor's claim)
- `flutter analyze` → **No issues found**
- `flutter test` → **269 passed** (baseline was 217)
- `grep -rn "dart:io" lib/core/ai/ lib/core/capture/` → 2 hits, both
  **pre-existing prose in comments**; zero imports
- `flutter build web` → **✓ Built build/web**
- Codex (gpt-5.6-sol xhigh): round 1 REVISE (2 Medium, 2 Low) → all 4 folded
  → **round 2 APPROVED**

## Decisions Made (this session)
1. **Mission 01 ran on its own phase branch** (`phase/01-ai-vision-extraction`),
   not directly on the feature branch as the mission header said. Merged
   `--no-ff`, phase branch deleted, merged tree verified byte-identical to the
   phase tip.
2. **Logged divergence — picker failures map to `CaptureFailure.undecodable`.**
   `undecodable` is a poor label for "camera permission denied", but the
   two-value `CaptureFailure { tooLarge, undecodable }` enum is the surface
   missions 02 and 03 were **already written and approved against**. Widening
   it would silently invalidate two reviewed plans. Rationale is commented at
   the catch site. **v2.1 item: a dedicated `unavailable` case.**
3. **All four Codex findings folded, including the two Lows** — they were
   tests the plan explicitly required, guarding the exact boundary an earlier
   review round had already caught once.
4. **Spike diagnostics added (`c8a808c`)** after the first real-API run failed
   opaquely. Debug-only, no content logged. See Critical Context.

## Completed
- [x] `.wargames/` committed — planning is no longer untracked.
- [x] Baseline re-verified from scratch (217 tests) rather than trusted.
- [x] Mission 01 M0–M9 built by a second-account Sonnet executor, blind from
      the plan file.
- [x] M10 artifacts: `tool/extraction_spike.dart` (two-button harness),
      `tool/spike_samples/README.md`, `.wargames/GATE-01-extraction-spike.md`
      (**template, deliberately unfilled**).
- [x] 2 Codex review rounds; all findings folded; delta APPROVED.
- [x] Empirical probe confirming the async `expect(...throwsA)` assertion in
      the timeout test is substantive, not vacuous. Probe deleted after.
- [x] Merged to `feature/ai-capabilities`, post-merge gates re-run.
- [x] **Spike root-caused and fixed** — first real-API run failed on both
      buttons; cause was configuration, not the model. Now working.
- [x] **Branch pushed** to `origin/feature/ai-capabilities` @ `dc16323`.
- [x] 5 synthetic test images generated (gpt-image-2) with ground-truth tables
      for smoke-testing — `tool/spike_samples/synthetic/`.
- [x] **Public-facing docs corrected (`4de9b9d`, `c55769a`, `1e6202a`, 2026-07-27).**
      README contradicted itself — it documented the AI features and also listed
      "An AI assistant … no external AI" as out of scope. Deck had the same bug
      plus a stale test count (107 vs 269). Fixed both; added an AI slide (S8Ai,
      deck now 9 slides); `presentation/` is now tracked (was entirely
      untracked); real READMEs replaced Remotion boilerplate;
      `docs/screenshots/CAPTURE.md` pins the 860×1864 geometry the promo's
      phone frame depends on. **Three Codex rounds** (REVISE → REVISE → one Low
      folded); every finding was an overclaim — "only aggregated JSON leaves the
      device", "money quoted verbatim", "the owner decides", and a slide saying
      the close-day report is "recomputed fresh, never cached stale" when the
      stored row is deliberately authoritative. Verified by orchestrator: tsc
      clean, slides 5/7/8/9 rendered and inspected, analyze clean.
- [x] **Sample-photo gitignore settled (`bd752ad`, 2026-07-27).** Every image
      under `tool/spike_samples/` is ignored; the synthetic README (ground-truth
      tables + the two traps) is now tracked. Settled *before* the real photos
      land, so the first `git add -A` after Ian's shoot cannot commit a live
      shop's supplier prices.

## Remaining
- [ ] **Ian runs the M10 spike on REAL samples.** Needs **≥5 printed receipts
      and ≥5 handwritten notebook pages**, each photo run **twice** — once on
      Haiku (primary), once on `claude-opus-5` (comparison only).
      ```
      flutter run -d chrome tool/extraction_spike.dart \
        --dart-define=ANTHROPIC_API_KEY=sk-ant-... \
        --dart-define=AI_EXTRACTION_MODEL=claude-haiku-4-5-20251001
      ```
      `--dart-define` is **compile-time** — switching models means a rebuild.
      Run it as two batches (all 10 on Haiku, rebuild, all 10 on Opus), not
      20 rebuilds.
- [ ] **Fill `.wargames/GATE-01-extraction-spike.md`.** Pass bar per photo:
      **≥80% of the lines visible on the paper extracted AND every money
      figure correct** — a partial line or one wrong money figure fails that
      photo, no partial credit. **≥4 of 5 photos = GO** for that feature.
      All four hit-rate cells required.
- [ ] Then dispatch **03 before 02** when serial — notebook import builds the
      catalog that makes 02's matcher useful.
- [ ] **Re-verify mission 03 with Codex at dispatch time** — rev 9's last two
      fixes landed after its final review. Deliberately NOT pre-run: if the
      gate returns `notebook=NO`, mission 03 is cancelled and the review is
      wasted. Wait for the gate.

## Open Flags
1. **Nothing proves Haiku can read a real receipt yet.** All 269 tests fake
   the extraction result — by design. The spike now proves the *plumbing*
   works end to end against the live API; it does not prove *model quality*.
   That is exactly and only what the gate answers.
2. **Handwriting is the harder half.** If Haiku misses there, mission 03 is
   the likely casualty. The gate records `notebook=NO`, reports Opus's rate on
   the same photos beside it, and the decision returns to Ian. **The executor
   must NEVER silently fall back to Opus, and must never mark a feature GO on
   Opus's number.**
3. **Watch the cents, not just the line count.** Money is integer cents: a
   receipt printing `180.00` must come back as `18000`. A `180` is 100× under
   and renders as `KES 1.80`. That failure is silent and plausible, which
   makes it more dangerous than a missed line.
4. `receiveStockBatch` (mission 02) is the only new money-write primitive in
   v2 → **HARD-lane Codex review on its own diff**, not blended into the UI
   diff.
5. v2.1 deferrals: `CaptureFailure.unavailable`; voice quick-entry; notebook
   import updating EXISTING product prices (D-03f); buying-price-drift
   highlighting.
6. Pre-real-user issue, out of v2 scope: every install carries 5 undeletable
   seed demo products, which notebook import will put in front of the owner.

## Critical Context
- **Why the spike failed the first time, and why it was hard to see.**
  `AiConfig.apiKey` is `String.fromEnvironment('ANTHROPIC_API_KEY')`, which
  yields `''` — not an error — when the dart-define is missing or attached to
  the wrong entrypoint. The resulting 401 was collapsed by the A6.3 error
  boundary into the same opaque message as every other failure. `c8a808c`
  fixed the visibility: the spike now shows key presence + length and refuses
  to call the API without one, and each of the 7 `extractStructured` failure
  branches logs its name in debug builds. **Branch names and shapes only** —
  no key, no request/response bodies, no base64, no extracted prices (a real
  shop's numbers). Parse failures log `runtimeType`, not the message.
- **The binding appendix** in `docs/superpowers/plans/2026-07-26-ai-capabilities.md`
  (~lines 2910–2984, R1–R7 + A6.x) governs gateway BEHAVIOR and overrides
  inline plan code. It does NOT freeze the `AiGateway` interface. A6.4's
  4xx-logging rule covers `_post` — untouched by `c8a808c`.
- **Model split:** `AiConfig.model` (Opus) drives `ask()`/`generateInsight()`;
  `AiConfig.extractionModel` (Haiku) drives `extractStructured` only. Two
  independent dart-defines, proven by a test asserting each wire body.
- **Synthetic samples are NOT gate evidence.** `tool/spike_samples/synthetic/`
  holds 5 AI-generated images with ground-truth tables. They prove the pipe is
  connected; they are cleaner than real paper and must not be scored into the
  gate. Its README says so. Two deliberate traps live in there: `receipt-02`'s
  printed total does not equal the sum of its lines (correct behavior is to
  transcribe what the paper says, not reconcile it), and `notebook-02` has two
  struck-through price corrections.
- Test env: `export PATH="$HOME/flutter/bin:$PATH"`. **No CI** — analyze and
  test are run manually, by the orchestrator, never accepted from an
  executor's report.
- No `dart:io` in any web-shared path; money is integer cents via `formatCents()`.
- **Process rule that keeps paying off:** verify against the dependency's
  source, not against what an API name suggests. This session it was Dart's
  `DateTime.parse` accepting 4–6 digit years, which made a "strict
  `YYYY-MM-DD`" check non-strict.

## Git State
- Branch **`feature/ai-capabilities`** @ **`1e6202a`**, tracking
  `origin/feature/ai-capabilities`. **5 ahead of origin — NOT pushed**
  (`bd752ad`, `3bd5ad3`, `4de9b9d`, `c55769a`, `1e6202a`). Everything through
  `039d85a` is pushed and byte-matches the remote. Push is a separate explicit go.
- **Ian owes 2 screenshots** before the promo can gain an AI beat: the Ask
  screen mid-answer and the daily-report AI card, both at **860×1864**
  (430×932 @ DPR 2 — the promo's phone frame is `phoneW = 430`). Recipe in
  `docs/screenshots/CAPTURE.md`. Copy into BOTH `docs/screenshots/` and
  `remotion/public/screens/` — they are byte-identical duplicates. Adding the
  beats is then ~2 lines in `BEATS` in `remotion/src/DukaPromo.tsx`.
- Fixed `~/.claude-second-account/settings.json`: it had `Write(~/SecondBrain/**)`,
  which is not a valid rule form (only `Edit(path)` matches file-writing tools),
  so the account refused to boot and **every** dispatch failed. Now `Edit(...)`.
  Its default model is still `claude-fable-5[1m]` — harmless because the scripts
  pass `--model claude-sonnet-5`, but a bare `claude` call there spends Fable.
- Gates re-verified from scratch on resume (2026-07-27, orchestrator-run, not
  taken from the previous session's word): `flutter analyze` → No issues found;
  `flutter test` → **269 passed**.
- Commits this session, oldest first:
  - `328d838` docs(wargames): AI v2 mission plans
  - `ec6ff2f` feat(ai): vision + structured extraction plumbing (mission 01)
  - `17e07ff` Merge phase/01-ai-vision-extraction
  - `c8a808c` fix(spike): make extraction failures diagnosable
  - `dc16323` docs(wargames): record spike root cause and current state
- Sits on top of `afd617c` (the CORS header fix from the prior session).
- **Working tree clean** — no modified tracked files.
- Untracked and intentionally so: `tool/spike_samples/synthetic/` (12MB of
  generated images), plus pre-existing `.agents/`, `.claude/`, `presentation/`,
  `remotion/*`, `skills-lock.json`, `docs/superpowers/HANDOFF.md`.
- `main` and `development` untouched. `origin/development` still holds AI v1.
- Phase branch `phase/01-ai-vision-extraction` merged and deleted.

## Resume instruction
Read this file, then `.wargames/LEDGER.md` for the decision record.

**No code work is pending.** The next event is Ian pasting M10 spike results
from real photos. When that happens: score each photo against the pass bar
(≥80% of visible lines AND every money figure correct; ≥4 of 5 per feature),
fill in `.wargames/GATE-01-extraction-spike.md` including all four hit-rate
cells, and write the final `GATE:` line naming the validated model.

Do NOT dispatch mission 02 or 03 until that file carries a real
`GATE: GO ... model=claude-haiku-4-5-20251001` line — it currently holds the
unfilled placeholder on purpose. When the gate opens, dispatch **03 before
02**, and re-verify 03 with Codex first.
