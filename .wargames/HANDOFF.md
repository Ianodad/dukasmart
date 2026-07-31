# Handoff — Opus 5 — DukaSmart / AI v2 / SHIPPED TO MAIN, gate open (2026-07-28)

## Current State
- **AI v1 + v2 mission-01 plumbing are now ON `main`.** Ian gave the explicit
  go on 2026-07-28; merged via PR #1. `main` is no longer the AI-free MVP.
  `development` was brought up to match — the two are **content-identical**.
- **Mission 01 is built, reviewed, merged, and proven against the real
  Anthropic API.** Mission 03 is now rev 10 and **fully Codex-APPROVED** — it
  carries no review debt at all.
- **Missions 02 and 03 remain blocked** — correctly. They gate their own M0 on
  `.wargames/GATE-01-extraction-spike.md`, which still holds the unfilled
  placeholder.
- **Everything on the critical path needs Ian personally:** photographing real
  samples for the M10 spike, and a live API key for the two AI screenshots +
  the Swahili check. **No code work is pending or in flight.**
- Working tree clean (no modified tracked files). Nothing mid-edit.

### Update 2026-07-31 — README AI pass, two of four AI screenshots captured
- **The key-gated set is smaller than this handoff assumed.** Rendering an AI
  surface needs only a *non-empty* key (`AiConfig.isConfigured` is
  `apiKey.isNotEmpty`); only the *content* needs a valid one. So the ask bar
  and the Ask screen were captured with a dummy key and are now on the branch:
  `15-dashboard-ai.png`, `16-ask-suggestions.png`. **The key-gated captures
  renumber to `17-ask-answer` / `18-daily-report-ai`** — CAPTURE.md is updated,
  this file's checklist below still says 15/16.
- `13-dashboard-live.png` — the README's headline shot — turned out to be from
  a **no-key build**: no ask bar. It is left in place (the promo's `BEATS`
  references it) and the AI pair was added as a separate README row.
- **New tooling makes the key run one command:** `tool/capture_ai_screens.sh`
  (prompts for the key with echo off). It builds, serves, seeds a day via
  `tool/drive_ui.mjs` + `tool/seed_demo_day.json`, closes the day, asks, and
  captures. Dry-run against a dummy key caught two silent failures now fixed:
  Complete Day opens a confirmation dialog, and the report's insight sits
  below the fold.
- **The promo `BEATS` edit was deliberately NOT done.** The only Ask capture
  that exists is the empty suggestion-chip state, and CAPTURE.md says not to
  use it. That edit stays part of the key run.
- Not verified this session: `flutter test`. This box lacks `clang++`, the
  Drift native-asset prereq, so the 269-test gate below was not re-run.
  `flutter analyze` → No issues found, and no Dart changed.

| Mission | File | Rev | Status |
|---|---|---|---|
| 01 vision + extraction plumbing | `.wargames/wargames/01-ai-vision-extraction.md` | 6 | **SHIPPED** — Codex APPROVED, merged, real-API verified |
| 02 snap-to-restock | `.wargames/wargames/02-snap-to-restock.md` | 5 | Plan APPROVED — BLOCKED on the gate |
| 03 notebook import | `.wargames/wargames/03-notebook-import.md` | 10 | **Plan APPROVED** (Codex delta round 2) — BLOCKED on the gate, nothing else |

Full planning + execution record: `.wargames/LEDGER.md`.

## Verified gates (orchestrator-run, never taken from an executor's claim)
- `flutter analyze` → **No issues found**
- `flutter test` → **269 passed** (baseline was 217)
- `grep -rn "dart:io" lib/core/ai/ lib/core/capture/` → 2 hits, both
  **pre-existing prose in comments**; zero imports
- `flutter build web` → **✓ Built build/web**
- Codex (gpt-5.6-sol xhigh): round 1 REVISE (2 Medium, 2 Low) → all 4 folded
  → **round 2 APPROVED**

## Decisions Made (2026-07-28 session)
1. **Ran the mission-03 rev-9 delta review EARLY, overriding the previous
   session's explicit "wait for the gate" deferral.** Reasoning: the deferral
   optimised cost, not correctness, and the unreviewed delta was a
   **concurrency guard** — cheapest to catch with slack time, most expensive to
   hit on the critical path. **The override was right.** Codex found a real
   Medium: rev 9's guard reorder fixed only the REFUSAL path, so after
   `saving = true` an F6 validation block or a thrown DAO error still wedged
   the controller permanently. Folded into rev 10; round 2 APPROVED.
2. **Merged to `main` via PR, then synced `development` to match.** Ian chose
   this over the repo's own precedent of routing through `development` first.
   Both branches now carry identical trees. `feature/ai-capabilities` is fully
   merged and 0 commits ahead — **safe to delete, left alone deliberately**
   because the wargame docs still reference it by name.
3. **Deleted `docs/dukasmart-deck.pptx` from `main` (PR #2).** See Open Flag 7 —
   it was a pre-AI binary the correction pass never reached.
4. **Refused to fabricate the AI screenshots.** A placeholder key renders an
   error state, and stubbing a fake answer would put an invented screenshot of
   a non-working feature on a public README. Built the capture rig instead and
   stopped at the key boundary.

## Decisions Made (2026-07-27 session)
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
      deck now 10 slides); `presentation/` is now tracked (was entirely
      untracked); real READMEs replaced Remotion boilerplate;
      a roadmap slide for the camera/OCR work (S9Ocr) went on at Ian's request —
      labelled **in build, not shipped**, since neither screen exists and the
      M10 gate has not run; `docs/screenshots/CAPTURE.md` pins the 860×1864 geometry the promo's
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

## Completed 2026-07-28
- [x] **Mission 03 rev 10** — `saving` flag made unstrandable on every exit
      path (`try/finally`, disposed-safe reset, one finally not scattered
      assignments); required test split in two so neither can pass vacuously.
      Codex delta round 1 REVISE → round 2 **APPROVED**. Commit `61c2d06`.
- [x] **Merged to `main`** — PR #1, `f4dc8ee`. Gates re-run by the orchestrator
      on the merge head first: analyze clean, **269 passed**. Merge dry-run
      with `git merge-tree` before touching the branch; merged tree inspected
      to confirm main's own files survived.
- [x] **Synced `development`** to match main. Verified content-identical.
- [x] **Removed the stale pptx deck** — PR #2, `bc78cf9`. Also fixed
      `presentation/README.md` saying "9-slide" when the source has 10.
- [x] **Scripted screenshot capture** — PR #3, `62ecc8a`.
      `tool/capture_screens.mjs` drives headless Chrome over CDP, no
      dependencies (Node 22+ global `WebSocket`). Verified end to end against a
      keyless build: dashboard + daily report at **exactly 860 x 1864**, fully
      rendered. CAPTURE.md now leads with it, manual recipe kept as fallback.

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
- [ ] **Two AI screenshots + the Swahili check — needs a live API key.**
      Blocked on nothing else; the rig is built and proven. Both at
      **860 x 1864**, into BOTH `docs/screenshots/` and
      `remotion/public/screens/`:
      ```
      flutter build web --dart-define=ANTHROPIC_API_KEY=sk-ant-...
      python3 -m http.server 8771 --directory build/web &
      node tool/capture_screens.mjs http://localhost:8771 docs/screenshots \
        15-ask-answer:/home/ask 16-daily-report-ai:/home/report
      ```
      **Seed real sales + an expense through the UI first** — the rig
      photographs whatever the profile holds, and a fresh one shows `KES 0`
      plus the demo seed products (Open Flag 6), which reads as fake.
      Ask the Swahili question in the same session to close Open Flag 0.
      Then: README Screenshots row, the "More in…" line, and ~2 lines in
      `BEATS` in `remotion/src/DukaPromo.tsx`, then re-render the promo.
      Use a scoped/expiring key and revoke it — it is baked into that build.
- [ ] Then dispatch **03 before 02** when serial — notebook import builds the
      catalog that makes 02's matcher useful.
- [x] ~~Re-verify mission 03 with Codex at dispatch time~~ — **DONE EARLY
      (2026-07-28), overriding the previous session's deferral.** Round 1
      REVISE: rev 9's guard reorder fixed only the refusal path, leaving
      `saving` strandable on F6-validation and thrown-error exits — a
      permanent wedge. Folded into rev 10 (`try/finally`, disposed-safe reset,
      required test split in two). Round 2 **APPROVED, no findings.** Mission
      03 now carries no review debt; the gate is its only blocker. Divergence
      and reasoning logged in `.wargames/LEDGER.md`.

## Open Flags
0. **UNVERIFIED CLAIM: Swahili Q&A.** The gateway instructs the model to reply
   in the user's language, a test covers UTF-8 handling against a mocked
   response, and the Ask screen offers "English au Kiswahili" — but nobody has
   asked a Swahili question with a real key. Codex flagged it Low; shipped
   deliberately. **Ian: test this during the screenshot trip.**

   *Corrected 2026-07-31 — this flag previously said the claim was "on `main`'s
   front page" via the README. It was not: the README never mentioned Swahili.
   The claim lives in deck slide 8 (`slides.tsx`, S8Ai), the promo
   (`DukaPromo.tsx`, `AiCard`) and the in-app hint (`ask_screen.dart`). The
   README now documents it explicitly as designed-for-not-verified, so if the
   check fails the README needs a wording tweak, not a retraction — the two
   asset fixes stand, then re-render the promo.*

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
   **Also a screenshot hazard** — a fresh profile photographs as an empty demo
   shop.
7. **Binary artifacts escape a text review pass. Proven, not theoretical.**
   `docs/dukasmart-deck.pptx` sat on `main` through the entire three-round
   documentation correction: 10 slides with **zero** AI content and a slide
   claiming "125 automated tests" against a real 269, linked prominently from
   the README. It survived because the correction pass fixed
   `presentation/src/slides.tsx` — a different artifact — and because
   `grep "no external AI"` returns nothing on a pptx (text is split across XML
   runs; you must unzip and strip tags). Removed 2026-07-28.
   **Rule going forward: anything not plain text — pptx, rendered video,
   images, PDFs — needs an explicit unpack-and-read check. Grep will not find
   it and reviewers will not open it.**
8. **`feature/ai-capabilities` is fully merged and 0 commits ahead of `main`.**
   Left undeleted on purpose — the wargame docs reference it by name — but it
   is dead weight and will drift. Delete it once the mission docs stop
   pointing at it.

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
- **The AI screens cannot be photographed without a key — verified in code,
  not inferred from docs.** `AiConfig.isConfigured` is `apiKey.isNotEmpty`
  (`lib/core/ai/ai_config.dart:27`) and `aiAvailableProvider`
  (`lib/core/ai/ai_providers.dart:18`) gates every AI surface. Without the
  dart-define the Ask bar and insight card are **not in the widget tree** —
  there is nothing on screen to capture. Confirmed visually: a keyless build
  photographs a dashboard with no "Ask about your duka" bar.
- **Screenshot rig trap, already paid for.** Do NOT use Chrome's plain
  `--screenshot` flag. It needs `--virtual-time-budget` to wait for the app,
  but virtual time freezes real timers while Drift's `sqlite3` worker runs
  off-thread — the app never leaves the splash screen. Budgets of 12s and 40s
  both photographed the logo. `tool/capture_screens.mjs` waits in real time
  over CDP instead. It needs no npm install (Node 22+ global `WebSocket`).
- Test env: `export PATH="$HOME/flutter/bin:$PATH"`. **No CI** — analyze and
  test are run manually, by the orchestrator, never accepted from an
  executor's report.
- No `dart:io` in any web-shared path; money is integer cents via `formatCents()`.
- **Process rule that keeps paying off:** verify against the dependency's
  source, not against what an API name suggests. This session it was Dart's
  `DateTime.parse` accepting 4–6 digit years, which made a "strict
  `YYYY-MM-DD`" check non-strict.

## Git State
**Tips move with every commit — run `git log -1` rather than trusting hashes
written here.** As of the 2026-07-28 handoff commit:

| Branch | Tip | Note |
|---|---|---|
| `main` | `62ecc8a` | **Carries AI v1 + v2 plumbing.** No longer the AI-free MVP |
| `development` | `5375811` | **Content-identical to `main`** — `git diff` between them is empty |
| `feature/ai-capabilities` | `61c2d06` | Fully merged, **0 commits ahead**. See Open Flag 8 |

- **PRs merged 2026-07-28:** #1 (`f4dc8ee`, AI to main), #2 (`bc78cf9`, stale
  pptx removed), #3 (`62ecc8a`, capture rig). All merged with `gh pr merge
  --merge`; branches for #2 and #3 deleted on merge.
- **Both merges were dry-run with `git merge-tree` before either branch was
  touched**, and the resulting tree inspected to confirm main's own files
  (notably `docs/dukasmart-deck.pptx`, which existed only on main) survived.
  Gates re-run by the orchestrator on the merge head before PR #1: analyze
  clean, **269 passed**.
- **Push policy in effect:** Ian's explicit go on 2026-07-27 covered making the
  branch public; routine commits to an already-public branch have been pushed
  without re-asking. Merges to `main`/`development` were done only on his
  explicit 2026-07-28 instruction, per Hard Rule 14.
- Fixed `~/.claude-second-account/settings.json`: it had `Write(~/SecondBrain/**)`,
  which is not a valid rule form (only `Edit(path)` matches file-writing tools),
  so the account refused to boot and **every** dispatch failed. Now `Edit(...)`.
  Its default model is still `claude-fable-5[1m]` — harmless because the scripts
  pass `--model claude-sonnet-5`, but a bare `claude` call there spends Fable.
- Gates re-verified from scratch on resume (2026-07-27, orchestrator-run, not
  taken from the previous session's word): `flutter analyze` → No issues found;
  `flutter test` → **269 passed**.
- **Working tree clean** — no modified tracked files.
- Untracked and intentionally so: `tool/spike_samples/synthetic/` (12MB of
  generated images), plus pre-existing `.agents/`, `.claude/`,
  `skills-lock.json`, `docs/superpowers/HANDOFF.md`. (`presentation/` and
  `remotion/` are now TRACKED — that changed on 2026-07-27.)
- Phase branch `phase/01-ai-vision-extraction` merged and deleted.
- Earlier arc, for context: `328d838` mission plans → `ec6ff2f` mission 01 →
  `17e07ff` phase merge → `c8a808c` spike diagnostics → the 2026-07-27
  documentation correction pass → `61c2d06` mission 03 rev 10. Sits on top of
  `afd617c` (the CORS header fix).

## Resume instruction
Read this file, then `.wargames/LEDGER.md` for the decision record.

**No code work is pending, and nothing here can be unblocked by working
harder.** Both open threads need Ian personally — a camera and an API key.
Do NOT invent adjacent work to look busy; the previous session's queue was
genuinely empty and the right move was to say so. (The one exception found on
2026-07-28 — the deferred mission-03 review — has now been taken, and it paid
off. There is no second one hiding.)

**Two things can arrive, in either order:**

**(a) A live API key** → build with the dart-define, seed real sales + an
expense through the UI, run `tool/capture_screens.mjs` (see Remaining for the
exact chain), ask one Swahili question to close Open Flag 0, copy both PNGs
into `docs/screenshots/` AND `remotion/public/screens/`, then do the README
Screenshots row and the `BEATS` entries in `remotion/src/DukaPromo.tsx` and
re-render the promo. **Never fabricate these screenshots** — see Decision 4.

**(b) M10 spike results** from real photos. When that happens: score each photo
against the pass bar
(≥80% of visible lines AND every money figure correct; ≥4 of 5 per feature),
fill in `.wargames/GATE-01-extraction-spike.md` including all four hit-rate
cells, and write the final `GATE:` line naming the validated model.

Do NOT dispatch mission 02 or 03 until that file carries a real
`GATE: GO ... model=claude-haiku-4-5-20251001` line — it currently holds the
unfilled placeholder on purpose. When the gate opens, dispatch **03 before
02**. Both plans are now fully Codex-APPROVED (03 at rev 10, 2026-07-28), so
the gate result is the only thing standing between the spike and dispatch —
no review step remains.
