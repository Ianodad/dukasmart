# LEDGER

One entry per mission. Draft location, point-by-point self-grade against
`SUCCESS.md`, and every patch the refinement loop makes.

## Review arc

- **Round 1 (Codex gpt-5.6-sol xhigh, 2026-07-27):** VERDICT REVISE on all
  three — 30 findings. Output:
  `/tmp/claude-1000/-data-Documents-Flutter-dukasmart/b10f5760-.../scratchpad/codex-plan-lock.md`
- **Rev 2 authored (Opus orchestrator):** all 30 findings addressed; three
  brief amendments recorded in-plan (AM-1 entry points, AM-2 cancellation
  semantics, D-03e dropped empty-catalog entry).
- **Fable advisor plan-lock pass (second account, `claude-fable-5`,
  2026-07-27 08:54):** VERDICT **PROCEED WITH CHANGES**. Advice is non-binding
  (Rule 17); orchestrator accepted all five recommendations, with two
  refinements of its own. Output: scratchpad `fable-advisor.md`.
  - **AM-3** (highest consequence, missed by both Codex rounds): the
    pre-ticked "Paid from till (cash)" default + hardcoded `PaymentMethod.cash`
    would book phantom cash out-flows for M-PESA/credit supplier payments and
    break daily-close reconciliation. → explicit three-way payment choice
    defaulting to "Not paid yet"; DAO refuses an amount without a method.
    *Orchestrator refinement:* default is "record nothing" rather than
    Fable's "default OFF" — an omission leaves expected cash visibly high and
    is correctable; an invented cash out-flow is silently wrong.
  - **AM-4**: unmatched receipt lines no longer default to "create new"
    (split stock counts on staples, no delete path to undo) → `unresolved`
    state + near-miss suggestions + excluded from save until resolved.
  - **AM-2 revised**: extraction survives leaving the screen via
    `KeepAliveLink` — interruption is the normal case at a counter.
  - **Mission 03**: `capturing` now gates only the OS picker, not the network
    call; up to 3 concurrent extractions, FIFO queue. *Orchestrator
    refinement:* Fable proposed uncapped concurrency; capped at 3 to avoid a
    10-request burst and rate-limit failures.
  - **Mission 01 M10**: new Ian-owned EXIT GATE — a real-sample extraction
    spike (≥5 genuine photos, Opus vs Haiku) that BLOCKS dispatch of 02/03,
    because every test in all three plans fakes extraction and nothing
    otherwise validates the core assumption before two features rest on it.
  - **Sequencing**: run 03 before 02 when serial (notebook import builds the
    catalog that makes 02's matcher useful).
  - **In-app disclosure** added to both capture screens (owners don't read
    READMEs).
  - Recorded, not built: v2.1 flag for buying-price-drift highlighting; the
    5 undeletable seed products remain a pre-real-user issue.
- **Round 2 (Codex gpt-5.6-sol xhigh):** VERDICT REVISE ×3, 20 findings —
  narrower than round 1, and Codex explicitly listed what round 1 had fixed
  (stop_reason, injected model/timeout, size math, implementor inventory,
  privacy wording, entry points, fail-closed access, empty-state handling,
  unit provenance, creation companion). Output: scratchpad
  `codex-plan-lock-r2.md`. Two findings were self-inflicted by the
  orchestrator's own fast application of Fable's advice (02: KeepAliveLink
  does not stop an in-flight completion writing state after Discard; 03:
  contradictory picker-guard text with no queue/active-count/FIFO rule) —
  **lesson: advisor amendments must be re-run through the same rigor as the
  original plan, not appended.**
  Most serious independent catches: 02's retry-safety guarantee was
  unimplementable (the `saving` state carried neither rows nor the created-id
  ledger it claimed to restore); 03's mandatory pre-save re-aggregation would
  silently re-select rows the owner had deselected.
- **Rev 3 (dispatched to three parallel second-account Sonnet executors,
  one document each, disjoint files):** all 20 findings applied against
  orchestrator design decisions, including a **logged divergence** — Codex
  asked for int-only parsing; we keep integral-double coercion (`1200.0` →
  `1200`) because models genuinely emit it, the coercion is lossless, and
  dropping the row costs the owner a manual re-type for no safety gain.
  Non-integral values are still rejected.
- **Round 3 (Codex):** VERDICT REVISE ×3, 10 findings — convergence is clear
  (30 → 20 → 10), and Codex marked most round-2 items FIXED. Output:
  scratchpad `codex-plan-lock-r3.md`. Two were data-safety blockers:
  02 could double-apply stock (a failed create excluded the row and let the
  batch commit, yet returned to a review screen whose Save could re-apply it)
  → resolved by aborting before the batch if ANY create fails, making a
  committed batch always terminal; 03's `RowOverride` could not distinguish
  "owner cleared this price" from "owner never touched it", which also left
  the promised invalid-input write-block unimplementable → resolved with an
  explicit per-field edit type (raw text + parse state), matching the shape
  mission 02 already uses.
- **Rev 4 (three parallel second-account Sonnet executors):** all 10 round-3
  findings applied.
- **Ian's decision, 2026-07-27: extraction runs on Haiku**
  (`claude-haiku-4-5-20251001`); Ask-your-duka and the daily insight stay on
  Opus. This REVERSES D-02c ("no per-feature model knob"). Rationale:
  extraction is the highest-volume AI call in the app (every receipt, every
  notebook page) and is structured output against a forced tool schema —
  the place cost compounds and the tier Haiku suits. Implemented as a
  separate `AiConfig.extractionModel` (dart-define `AI_EXTRACTION_MODEL`)
  plus an injectable `extractionModel` field on `AnthropicGateway` used only
  by `extractStructured`. The M10 spike is reframed from "choose a model" to
  "validate Haiku, measure the Opus gap"; a `notebook=NO` or `receipts=NO`
  result returns the decision to Ian — **the executor must never silently
  fall back to Opus**.
- **Rev 5:** the Haiku decision applied across all three plans.
- **Round 4 (Codex):** **VERDICT 02: APPROVED** — plan-locked. 01 REVISE
  (1 finding), 03 REVISE (2). Output: `codex-plan-lock-r4.md`.
- **Rev 6 (orchestrator, direct):** 01's M10 spike could not run at all —
  it selected receipt-vs-notebook via a command-line arg, but Flutter
  entrypoint args are desktop-only and the web picker needs a user gesture →
  replaced with a two-button harness. 03's edit model would not have
  compiled (one `FieldEdit` with an `int? value` served both the String name
  and the int prices) → split into `TextEdit`/`MoneyEdit` with parse state
  carried on `CandidateRow`.
- **Round 5 (Codex, 01 + 03 only):** **VERDICT 01: APPROVED.** 03 REVISE
  (3 findings). Output: `codex-plan-lock-r5.md`. Notable: Codex read Drift's
  own source (`stream_queries.dart:95`) to show that the orchestrator's
  `watchProducts().first` fix was WRONG — Drift reuses identical active query
  streams and hands new listeners cached `_lastData`, so with the product
  list screen already subscribed, the "fresh" pre-save read could replay a
  stale catalog and create a real duplicate.
- **Rev 7 (dispatched, 03 only):** one-shot `ProductsDao.getAllProducts()`
  (logged read-only DAO amendment) replacing the stream read; the
  `FieldEdit` → `TextEdit`/`MoneyEdit` migration completed across the whole
  file; and `skippedDuplicates` counted BEFORE the selected-filter, which
  had made the promised "detected, skipped, reported" test unpassable.
- **Round 6 (Codex, 03 only):** REVISE, 2 findings. (a) The concurrency
  amendment let the owner reach Review while pages were still extracting;
  `save()` snapshots rows once, so a page finishing after that snapshot was
  silently dropped from the import — no error, no count. (b) The plan
  claimed `normalizeName` "matches `findExactNameMatch` exactly" — FALSE:
  `normalizeName` also strips punctuation, so `ACME/Plus` and `ACMEPlus`
  would collide and a genuinely distinct product would be greyed out as
  already-in-catalog.
- **Rev 8 (orchestrator, direct):** scheduler-idle gate on Review/Confirm
  with a defensive re-check in `save()`; and a THIRD dedicated key —
  `catalogKey` (trim+lowercase, matching the app's real convention) for
  catalog collisions, leaving `normalizeName` for save-time dedupe of edited
  names and `mergeKey` for within-batch merging. The three-key split is now
  stated explicitly at every use site.
- **Round 7 (Codex, 03 only, narrow):** REVISE, 2 minor findings — BUT both
  rev-8 substantive changes were explicitly CONFIRMED correct ("the
  scheduler-idle gate closes the late-page hole… `failed` pages do not block,
  so permanent extraction failure cannot deadlock Review"; "`catalogKey`
  genuinely matches `findExactNameMatch`"). Remaining: the `save()` in-flight
  refusal ran after `saving = true` (a refusal could strand the flag and
  block every later save), and three explanatory text sites still said
  `normalizeName` where they meant `catalogKey`.
- **Rev 9 (orchestrator, direct):** guard order made explicit — reentrancy
  check, then in-flight refusal, THEN `saving = true`, with a test that a
  later save succeeds after extraction finishes; the three text sites
  corrected; an `ACME/Plus` vs `ACMEPlus` test added.
- **Findings by round: 30 → 20 → 10 → 3 → 3 → 2 → 2 (both minor).**

## Status
- **01-ai-vision-extraction — rev 6, APPROVED (Codex round 5).**
- **02-snap-to-restock — rev 5, APPROVED (Codex round 4).**
- **03-notebook-import — rev 9. Substance verified by Codex round 7; the two
  minor fixes above were applied AFTER that review and are not themselves
  re-verified.** Deliberately not re-reviewed: mission 03 cannot be
  dispatched until the M10 spike returns `notebook=YES`, so its final stamp
  is not on the critical path, and a poor handwriting result may change the
  mission anyway. **Re-verify at dispatch time, after the spike.**

## Execution arc

### 01-ai-vision-extraction — BUILT 2026-07-27, branch `phase/01-ai-vision-extraction`
- Planning artifacts committed first (`328d838`), then the phase branch cut from
  `feature/ai-capabilities`.
- **Orchestrator-verified baseline before dispatch:** analyze clean, **217 tests**.
  Not taken from the handoff — re-run.
- **Round 1 (second-account Sonnet executor, blind from the mission file):**
  M0–M9 executed, M10 artifacts built (harness + samples README + unfilled gate
  template). Result: analyze clean, **264 tests** (+47), `build web` OK, zero
  `dart:io` imports. All four gates re-run and confirmed by the orchestrator,
  not accepted from the executor's report.
- **Codex review (gpt-5.6-sol xhigh) — VERDICT REVISE, 4 findings:**
  - **M1** the photo picker sat OUTSIDE the error boundary — a denied camera
    permission threw `PlatformException` out of `capture()` instead of
    returning a `CaptureResult`, leaving the spike harness's buttons
    permanently dead.
  - **M2** "strict `YYYY-MM-DD`" was not strict: Dart's `DateTime.parse`
    accepts 4–6 digit years and the round-trip check preserves them, so
    `12345-01-01` passed as a valid date.
  - **L3** two M8 proofs the plan REQUIRED were incomplete — the
    "independent timeouts" test never called `ask()` (proving only half its
    own claim), and the malformed-`extractInput` test on `FakeAiGateway`
    (the round-2 F1 boundary) did not exist at all.
  - **L4** `_ThrowingAiGateway.extractStructured` threw `UnimplementedError`
    instead of mirroring its `ask()`'s `StateError('boom')`.
- **All 4 folded** (Lows included — they guarded the exact boundary an earlier
  review round had already caught once).
- **Logged orchestrator divergence (M1's fix):** picker failures fold into
  `CaptureFailure.undecodable` rather than gaining a new `unavailable` enum
  case. `undecodable` is a poor label for "permission denied", but the
  two-value `CaptureFailure` enum is the surface missions **02 and 03 were
  already written and APPROVED against** — widening it would silently
  invalidate two reviewed plans. Rationale is commented at the catch site.
  **v2.1 item: dedicated `unavailable` case + proper message.**
- **Round 2 (Codex delta) — VERDICT APPROVED.** Confirmed each fix at source
  plus a mutation-sensitivity pass. Noted honestly that L4's fix is not
  covered by any test (nothing calls that helper) — correct, but unproven.
- **Orchestrator empirical check:** ran a throwaway probe proving
  `expect(() => asyncFn(), throwsA(...))` genuinely FAILS when the async
  function does not throw ("returned a Future that emitted `<null>`"), so
  L3a's new assertion is substantive rather than vacuous. Probe deleted.
- **Final verified state: analyze clean, 269 tests green, `build web` OK.**
- **Still unproven, by design:** every one of those 269 tests fakes the
  extraction result. Nothing here shows a model can read a real receipt or
  real handwriting. That is exactly what M10 exists for.

## Lesson recorded (for future planning loops)
Three separate defects traced back to ONE source: the concurrency change
adopted from the Fable advisor pass and applied quickly on top of a reviewed
plan (contradictory picker-guard text → no queue/FIFO definition → the
late-page drop above). **Advisor amendments must be re-run through the same
rigor as the original plan, not appended to it.** A second lesson: two of the
orchestrator's own "obvious" fixes were wrong in ways only source-reading
caught — `watchProducts().first` (Drift replays cached `_lastData`) and the
`normalizeName`/`findExactNameMatch` equivalence claim. Verify against the
dependency's source, not against what the API name suggests.

## 01-ai-vision-extraction — 2026-07-27 (rev 2)
- Draft: wargames/01-ai-vision-extraction.md
- Round-1 findings folded in: typed `ExtractionSpec<T>` with parsing INSIDE
  the gateway boundary (01.1); A6.1-exhaustive stop_reason switch + defensive
  input shape checks (01.2); injected `model` + injectable `extractionTimeout`
  (01.3); deterministic decode→resize→encodeJpg pipeline via `package:image`
  because `image_picker_for_web` 3.1.1 silently returns the original on resize
  failure (01.4); base64-derived cap 3_375_000 enforced at construction AND
  the gateway (01.5); `date` + item-level required + qty>0 (01.6); ALL FIVE
  implementors listed incl. three private test gateways (01.7); real generated
  image fixtures + golden capture→gateway→typed test (01.8); factually safe
  privacy wording re: OS picker cache + known-untracked baseline (01.9);
  full expected/failure/counter blocks on every move (01.10).
- Self-grade vs SUCCESS.md: all 8 hold. One live `RECON NEEDED`-class fork
  remains by design (F1, package:image web performance) with its exact check.
- Status: rev 2 awaiting Codex round 2.

## 02-snap-to-restock — 2026-07-27 (rev 2)
- Draft: wargames/02-snap-to-restock.md
- Round-1 findings folded in: **D-02b reversed** — create new products at
  `openingQty: 0`, retain ids in state, ALL lines through one
  `receiveStockBatch`; failure-then-retry test (02.1, the serious one);
  entry points recorded as brief amendment AM-1 (02.2); `ReviewRow` gains
  `unit`/`createdProductId`, `extracting` carries preview bytes (02.3);
  `start()` fails closed before any gateway read + full error mapping with
  receipt-appropriate wording (02.4); `ConfirmedPlan` snapshot shared by
  dialog and DAO with enumerated validation rules (02.5); AM-2 honest
  cancellation semantics (02.6); matcher thresholds fixed with six exact
  test vectors incl. the Jogoo case → null (02.7); full batch contract incl.
  till>0, `'Stock: N items'` description, duplicate-id last-price-wins,
  shared note (02.8); high-risk sequence tests (02.9); complete move blocks
  (02.10).
- Self-grade vs SUCCESS.md: all 8 hold.
- Status: rev 2 awaiting Codex round 2. Depends on 01.

## 03-notebook-import — 2026-07-27 (rev 2)
- Draft: wargames/03-notebook-import.md
- Round-1 findings folded in: empty-catalog entry DROPPED (unreachable +
  filtered-isEmpty bug) → single Products-tab entry, D-03e (03.1);
  `mergeKey` (whitespace-stripped) gives a real, tested near-duplicate rule
  (03.2); nullable `extractedUnit` provenance + last-non-null-wins +
  independent flags (03.3); no page until capture succeeds, `capturing`
  guard, stable page ids, pure `aggregate()` recomputed on every mutation
  (03.4); fail-closed before gateway read (03.5); duplicate flags recomputed
  on edit AND immediately before save (03.6); exact companion fields +
  feature-local `centsToInputString` (03.7); normalization kept local so the
  dependency graph stays 01-only (03.8); the missing test list (03.9);
  complete move blocks and the SETTLED/RECON contradiction removed (03.10).
- Self-grade vs SUCCESS.md: all 8 hold.
- Status: rev 2 awaiting Codex round 2. Depends on 01; router.dart one-block
  overlap with 02 is the known accepted conflict (F4).

<!-- Example entry, delete once you have real ones:

## 01-feature-user-export — 2026-07-06

- Draft: wargames/01-feature-user-export.md
- Self-grade vs SUCCESS.md: 1 hold, 2 hold, 3 hold, 4 hold, 5 hold, 6 hold, 7 hold
  (attack: "what if the export table has 10M rows" — patched with a streaming
  export move), 8 hold
- Status: PASS, ready for executor
- Patches: added streaming-export fork after red-team pass

-->
