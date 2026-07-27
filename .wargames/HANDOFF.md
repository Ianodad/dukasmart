# Handoff — Opus 5 — DukaSmart / AI v2 / Mission 01 BUILT + APPROVED (2026-07-27)

## Current State
- **Mission 01 is built, reviewed, and gate-green on `phase/01-ai-vision-extraction`.**
  Awaiting Ian's merge go. Not merged. Not pushed.
- Planning for all three missions is committed (`328d838` on `feature/ai-capabilities`).

| Mission | File | Rev | Status |
|---|---|---|---|
| 01 vision + extraction plumbing | `.wargames/wargames/01-ai-vision-extraction.md` | 6 | **BUILT — Codex APPROVED (execution round 2)** |
| 02 snap-to-restock | `.wargames/wargames/02-snap-to-restock.md` | 5 | Plan APPROVED — BLOCKED on the M10 gate |
| 03 notebook import | `.wargames/wargames/03-notebook-import.md` | 9 | Plan substance-verified — BLOCKED on the M10 gate; re-verify with Codex at dispatch |

- Full decision + review record: `.wargames/LEDGER.md` (now includes the
  execution arc, not just the planning arc).

## Verified gates on the phase branch (orchestrator-run, not executor-claimed)
- `flutter analyze` → **No issues found**
- `flutter test` → **269 passed** (baseline 217 → 264 after round 1 → 269 after fixes)
- `grep -rn "dart:io" lib/core/ai/ lib/core/capture/` → 2 hits, both
  **pre-existing prose in comments**; zero imports
- `flutter build web` → **✓ Built build/web**
- Codex (gpt-5.6-sol xhigh): round 1 REVISE (2 Medium, 2 Low) → all 4 folded →
  **round 2 APPROVED**

## Decisions Made (this session, on top of the planning decisions)
1. Mission 01 executes on its own **phase branch** (Hard Rule #13), not directly
   on `feature/ai-capabilities` as the mission header said. Orchestrator call.
2. **Logged divergence:** picker-level failures (permission denied, no camera,
   plugin errors) map to `CaptureFailure.undecodable` rather than a new
   `unavailable` enum case — because the two-value `CaptureFailure` enum is the
   surface missions 02/03 were **already approved against**. Widening it would
   invalidate two reviewed plans. **v2.1 item: dedicated `unavailable` case.**
3. All 4 Codex findings folded including the two Lows — they were missing tests
   the plan explicitly required, guarding a boundary an earlier round already
   caught once.

## Completed
- [x] `.wargames/` committed (`328d838`) — planning no longer untracked.
- [x] Baseline re-verified from scratch (217 tests), not taken on trust.
- [x] Mission 01 M0–M9 built by a second-account Sonnet executor, blind from the plan.
- [x] M10 artifacts built: `tool/extraction_spike.dart` (two-button harness),
      `tool/spike_samples/README.md`, `.wargames/GATE-01-extraction-spike.md`
      (**template, deliberately unfilled**).
- [x] 2 Codex review rounds; all findings folded; delta APPROVED.
- [x] Empirical probe confirming L3a's async assertion is substantive.
- [x] All four gates re-run by the orchestrator after the fix round.

## Spike status (2026-07-27)
- **Mission 01 MERGED** into `feature/ai-capabilities` (`17e07ff`), phase
  branch deleted.
- **First real-API run of the spike FAILED on both buttons.** Root cause was
  configuration, not the model or the plumbing — `AiConfig.apiKey` is
  `String.fromEnvironment`, which yields `''` (not an error) when the
  dart-define is missing or lands on the wrong entrypoint, and A6.3 collapsed
  the resulting 401 into the same opaque message as every other failure.
- **Fixed in `c8a808c`:** the spike now shows key presence + length and
  refuses to call the API without one; the 7 silent `extractStructured`
  failure branches each log their name in debug builds (no key, no bodies,
  no extracted prices). Behavior unchanged; 269 tests still green.
- **Ian confirmed the spike now works.** The plumbing is proven end to end
  against the real API. The gate itself is still unfilled.

## Remaining
- [ ] **Push `feature/ai-capabilities`** — still never pushed, now 4 commits
      deep (`328d838`, `ec6ff2f`, `17e07ff`, `c8a808c`). Needs Ian's go.
- [ ] **Ian runs the M10 spike.** Needs a real key + **≥5 printed receipts and
      ≥5 handwritten notebook pages**. This is the fork in the road: it decides
      whether 02 and 03 are worth building at all.
      Run: `flutter run -d chrome tool/extraction_spike.dart --dart-define=ANTHROPIC_API_KEY=sk-ant-... --dart-define=AI_EXTRACTION_MODEL=claude-haiku-4-5-20251001`
      Every photo twice — once on Haiku (primary), once on `claude-opus-5`
      (comparison only). Fill `.wargames/GATE-01-extraction-spike.md`.
      Pass bar: ≥80% of visible lines extracted AND every money figure correct;
      **≥4 of 5 photos** passing = GO for that feature.
- [ ] Then dispatch **03 before 02** when serial (notebook import builds the
      catalog that makes 02's matcher useful).
- [ ] Re-verify mission 03 with Codex at dispatch time (rev 9's last two fixes
      were applied after its last review).

## Open Flags
1. **Nothing proves extraction works yet.** All 269 tests fake the extraction
   result. The spike is the only thing that will tell us whether Haiku can read
   a faded thermal receipt or Swahili/Sheng handwriting.
2. Handwriting is the harder half. If Haiku misses, mission 03 is the likely
   casualty — the gate records `notebook=NO` and the decision returns to Ian.
   **The executor must NEVER silently fall back to Opus.**
3. Missions 02/03 gate their own M0 on this file carrying a real
   `GATE: GO ... model=claude-haiku-4-5-20251001` line. It currently holds the
   literal unfilled placeholder — that is correct and intentional.
4. `receiveStockBatch` (mission 02) is the only new money-write primitive in
   v2 → HARD-lane Codex review on its own diff, not blended into the UI diff.
5. v2.1 deferrals: `CaptureFailure.unavailable`; voice quick-entry; notebook
   import updating EXISTING product prices (D-03f); buying-price-drift
   highlighting.
6. Pre-real-user issue, out of v2 scope: every install carries 5 undeletable
   seed demo products, which notebook import will put in front of the owner.

## Critical Context
- **The binding appendix** in `docs/superpowers/plans/2026-07-26-ai-capabilities.md`
  (lines ~2910–2984, R1–R7 + A6.x) governs gateway BEHAVIOR and overrides inline
  plan code. It does NOT freeze the `AiGateway` interface.
- **Model split:** `AiConfig.model` (Opus) drives `ask()`/`generateInsight()`;
  `AiConfig.extractionModel` (Haiku) drives `extractStructured` only. Two
  independent dart-defines — proven by a test asserting each wire body.
- Test env: `export PATH="$HOME/flutter/bin:$PATH"`. No CI — analyze and test
  are run manually, by the orchestrator, never accepted from an executor claim.
- No `dart:io` in any web-shared path; money is integer cents via `formatCents()`.
- **Process rule that keeps paying off:** verify against the dependency's
  source, not against what an API name suggests. This round it was Dart's
  `DateTime.parse` accepting 4–6 digit years.

## Git State
- Branch **`phase/01-ai-vision-extraction`**, cut from `feature/ai-capabilities`
  @ `328d838` ("docs(wargames): AI v2 mission plans").
- `feature/ai-capabilities` @ `328d838`, which sits on top of `afd617c`.
- Pre-existing untracked dirs (not ours, left alone): `.agents/`, `.claude/`,
  `presentation/`, `remotion/*`, `skills-lock.json`, `docs/superpowers/HANDOFF.md`.
- `origin/development` @ `6fb2cd3` holds AI v1. `main` untouched.
- **`feature/ai-capabilities` has never been pushed.**

## Resume instruction
Read this file, then `.wargames/LEDGER.md`. Mission 01 is done and approved;
the next move is Ian's merge go, then Ian running the M10 spike. Do NOT
dispatch mission 02 or 03 until `.wargames/GATE-01-extraction-spike.md` carries
a real `GATE: GO` line naming `claude-haiku-4-5-20251001` — it currently holds
the unfilled placeholder on purpose.
