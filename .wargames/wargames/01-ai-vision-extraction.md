# Wargame 01 — AI Vision + Structured Extraction Plumbing (rev 6)

Rev 6 closes Codex round-4: the M10 spike selects its schema via a two-button
UI (entrypoint args are desktop-only, and the web picker needs a gesture).

Branch: `feature/ai-capabilities`. Repo: `/data/Documents/Flutter/dukasmart`.
Brief: `.wargames/tasks/01-ai-vision-extraction.md`.
Rev 2 incorporated Codex plan-lock round-1 findings 01.1–01.10 (2026-07-27).
Rev 3 incorporates Codex plan-review round-2 findings F1–F5 (2026-07-27):
an error-boundary leak in the fake gateway (F1), an accepted divergence plus
a parser-completeness gap (F2), silent multi-tool-block data loss (F3), an
untestable `tooLarge` branch (F4), and a non-deterministic M10 exit gate
(F5).
Rev 4 closes Codex plan-review round-3 findings (2/2 ACCEPTED):
non-deterministic model selection at the M10 exit gate, and a
self-contradictory optional-numeric-field parser rule in M6.
Rev 5 applies Ian's per-feature model decision (2026-07-27): **extraction
runs on Haiku; Ask-your-duka and the daily-close insight stay on Opus.**
This REVERSES rev 4's "one global model, pick the cheapest that clears
every feature" premise — see the decision note in Settled facts, and the
rewritten M2, M5, and M10 below.

**Settled facts (orchestrator + Codex verified against source):**
- `AnthropicGateway` is text-only; `_post(Map<String, Object?> body)` — caller
  builds the whole body; instance fields `model`, `endpoint`, `timeout`
  (default 15s) are constructor-injected (`anthropic_gateway.dart:17`).
- Binding appendix (plan lines 2910–2984) = R1–R7 + A6.x; it binds BEHAVIOR
  (A6.1 exhaustive stop_reason switch, A6.3 no raw TypeError/FormatException
  ever escapes, A6.4 429/5xx→busy + injectable timeout, debug-only 4xx logs)
  and does NOT freeze the `AiGateway` interface.
- `AiGateway` has FIVE implementors: `AnthropicGateway`,
  `test/helpers/fake_ai_gateway.dart` (FakeAiGateway), and three private test
  gateways in `test/features/assistant/ask_controller_test.dart` (e.g.
  `_ThrowingAiGateway`, line ~156) and `test/features/assistant/ask_screen_test.dart`.
- `image_picker_for_web` 3.1.1 (locked): applies `imageQuality` only to
  JPEG/WebP and on any resize failure SILENTLY returns the original file
  (`image_resizer.dart:31`) — picker resize params are best-effort ONLY, on
  every platform treat them as an optimization, never a guarantee.
- Workspace has KNOWN untracked artifacts (`.wargames/`, `.agents/`,
  `.claude/`, `presentation/`, `remotion/*`, `skills-lock.json`,
  `docs/superpowers/HANDOFF.md`); "clean" for this mission means NO modified
  TRACKED files.
- **Per-feature model split (Ian, 2026-07-27 — REVERSES rev 4's single
  global-model premise).** Extraction is a structured-output call against a
  forced tool schema with a photo attached, and it is also the
  highest-volume AI call in the app — it fires on every receipt and every
  notebook page — so it's the one place cost compounds, and that's exactly
  the shape of task Haiku is well suited to. Ask-your-duka and the
  daily-close insight are low-volume reasoning calls where Opus earns its
  price. So `AiConfig.model` (Opus, drives `ask()`/`generateInsight()` only)
  and `AiConfig.extractionModel` (Haiku, drives `extractStructured` only)
  are two INDEPENDENT dart-defines — changing one never changes the other,
  and nothing about Ask/insight behavior changes in this revision.

---

## Moves

**M0 — Baseline.** `git status --porcelain` then
`export PATH="$HOME/flutter/bin:$PATH" && flutter analyze && flutter test`.
- Expect: no ` M `/`M  ` (modified-tracked) lines — untracked lines matching
  the known list above are fine; analyze "No issues found"; full suite green
  (217 at last handoff — record the exact count).
- Failure: modified tracked files present → cause: another session's work in
  flight → ABORT A1. Suite red → pre-existing breakage → ABORT A1.

**M1 — Confirm the A6 rules you must obey.** Read
`docs/superpowers/plans/2026-07-26-ai-capabilities.md` lines 2956–2984 (A6.1–
A6.5) and `lib/core/ai/anthropic_gateway.dart` in full.
- Expect: you can state, before writing code, the three rules the new method
  inherits: exhaustive stop_reason switch, no raw decode/type error escapes,
  429/5xx→busy mapping with injectable timeout.
- Failure: the file's A6 comments contradict the appendix lines → cause: you
  misread or the plan file moved → counter: re-grep `grep -n "A6.1"
  lib/core/ai/anthropic_gateway.dart docs/superpowers/plans/*.md`; if a real
  contradiction remains → ABORT A2.

**M2 — Add `package:image` + `AiImage` type.**
`pubspec.yaml`: add `image: ^4.3.0` (pure Dart — decode/resize/JPEG-encode on
Android AND web; picker resize is unreliable per settled facts, so WE own the
pipeline). Run `flutter pub get`.
New `lib/core/ai/ai_image.dart` (imports `dart:typed_data` only):
```dart
class AiImage {
  AiImage.jpeg({required Uint8List bytes, required int width, required int height})
    : /* asserts + throws ArgumentError if bytes.length > maxRawBytes */
  final Uint8List bytes; final int width; final int height;
  String get mediaType => 'image/jpeg';
  /// 4.5MB base64 ceiling → raw = 4_500_000 * 3 / 4.
  static const int maxRawBytes = 3_375_000;
}
```
Single constructor, always JPEG (the capture pipeline in M7 guarantees it) —
no sniffing, no bypass path: constructing an over-cap AiImage THROWS.
- Expect: `flutter pub get` solves; analyze clean; a 3-line unit test:
  3_375_000 bytes constructs, 3_375_001 throws ArgumentError.
- Failure: `image ^4.x` version-solve conflict → cause: transitive pin →
  counter: `flutter pub deps | grep " image "` and pick the highest solvable
  4.x; if none solves → ABORT A3.

**M2 also fixes the M10 gate's model-selection gap at its root (Codex
round-3, ACCEPTED), and adds the per-feature model split (Ian, rev 5).**
`lib/core/ai/ai_config.dart:15` currently hardcodes
`static const String model = 'claude-opus-5';` — so M10's
`--dart-define=AI_MODEL=<model-id>` run command is a no-op today: nothing in
the app reads that define, and every spike run silently executes Opus
regardless of the CLI arg. Change the declaration to:
```dart
static const String model =
    String.fromEnvironment('AI_MODEL', defaultValue: 'claude-opus-5');
```
This `model` field is unchanged in purpose from rev 4 — it drives `ask()`
and `generateInsight()` only, and nothing about Ask/insight behavior
changes in this revision. ADD a second, separate field for extraction:
```dart
static const String extractionModel =
    String.fromEnvironment('AI_EXTRACTION_MODEL',
                           defaultValue: 'claude-haiku-4-5-20251001');
```
`model` and `extractionModel` are two INDEPENDENT dart-defines: setting
`AI_EXTRACTION_MODEL` never changes what `ask()`/`generateInsight()` send,
and setting `AI_MODEL` never changes what `extractStructured` sends.
- Expect: `grep -n "AI_MODEL\|AI_EXTRACTION_MODEL" lib/core/ai/ai_config.dart`
  shows both `String.fromEnvironment` forms; with both defines ABSENT,
  `AiConfig.model` resolves to `claude-opus-5` (byte-for-byte today's
  behavior — invisible to every existing test) and `AiConfig.extractionModel`
  resolves to `claude-haiku-4-5-20251001` — the new shipping default for
  extraction; a run with `--dart-define=AI_EXTRACTION_MODEL=claude-opus-5`
  moves only the extraction field to Opus while `AiConfig.model` is
  untouched, proving the two are independent.
- Failure: some call site needs `AiConfig.model` or `AiConfig.extractionModel`
  in a `const`-context position (e.g. a `switch` case or another `const`
  declaration) → `String.fromEnvironment` IS still a compile-time constant,
  so this should not occur; if a genuine non-const usage surfaces, the
  cause is unrelated to this change → counter: fix that call site, do not
  revert either define.

**M3 — Extend the seam (typed, validation INSIDE the boundary).** In
`lib/core/ai/ai_gateway.dart`:
```dart
class ExtractionSpec<T> {
  const ExtractionSpec({required this.toolName, required this.description,
    required this.inputSchema, required this.parse});
  final String toolName; final String description;
  final Map<String, Object?> inputSchema;
  final T Function(Map<String, Object?> input) parse;
}
abstract class AiGateway {
  ... // existing ask(), generateInsight() unchanged
  Future<T> extractStructured<T>({
    required String instruction,
    required List<AiImage> images,
    required ExtractionSpec<T> spec,
  });
}
```
Doc-comment contract: single turn, forced tool call, `spec.parse` runs INSIDE
the gateway; parse throwing anything ⇒ `AiUnavailableError(error)` — a typed
`T` or an `AiUnavailableError` are the only possible outcomes. This contract
binds EVERY implementor, not just `AnthropicGateway` — including test
fakes (see M4's F1 fix below).
- Expect: `flutter analyze` reports missing-implementation errors in EXACTLY
  the five implementors listed in settled facts.
- Failure: a sixth site appears → cause: an implementor recon missed →
  counter: `grep -rn "implements AiGateway\|extends AiGateway\|extends FakeAiGateway" lib test`,
  patch every hit per M4.

**M4 — Update ALL implementors.**
- `FakeAiGateway`: add `Map<String, Object?> extractInput = const {};`,
  `AiUnavailableError? extractError;` (typed the same as the existing
  `error` field — NOT `Object?`), `final List<({String toolName, int
  imageCount})> extractCalls = [];` and an override that records the call,
  then wraps parsing EXACTLY like the real gateway: throw `extractError` if
  set, else `try { return spec.parse(extractInput); } catch (_) { throw
  const AiUnavailableError(AiFailureKind.error); }`. The fake enforces the
  SAME A6.3 boundary as `AnthropicGateway.extractStructured` — a malformed
  `extractInput` must never leak a raw `FormatException`/`TypeError` into a
  widget/controller test (Codex round-2 F1: the prior draft called
  `spec.parse` unguarded and typed the error field `Object?`, so the fake
  did not exercise the real contract).
- The three private test gateways: add the override mirroring each one's
  existing behavior (`_ThrowingAiGateway` throws its error; recorder-style
  ones `throw UnimplementedError()` — they are never called with extract).
- Expect: analyze clean repo-wide; `flutter test` green with zero edits to
  existing test ASSERTIONS (only the added overrides); plus a new required
  test: `FakeAiGateway` configured with a malformed `extractInput` (e.g.
  `items` set to a String instead of a List) → the caller observes
  `AiUnavailableError`, never a `FormatException`/`TypeError`.
- Failure: an existing test constructed a const FakeAiGateway → cause: new
  mutable fields → counter: keep fields non-final-initialized (no const
  constructor existed per settled read — if it did, drop const at the call
  sites, assertions untouched).

**M5 — Implement in `AnthropicGateway`.**
Constructor gains `this.extractionTimeout = _defaultExtractionTimeout`
(`static const _defaultExtractionTimeout = Duration(seconds: 60)`) —
injectable like the existing `timeout` (A6.4 discipline) — AND
`this.extractionModel = AiConfig.extractionModel` — injectable, exactly the
same discipline as `extractionTimeout` and the existing `model` field.
`_post` gains an optional named `{Duration? timeout}` using `timeout ??
this.timeout`; `ask`/`generateInsight` call sites untouched — they keep
sending the instance `model` field, unchanged from rev 4.
`extractStructured<T>` body:
- Re-assert every image ≤ `AiImage.maxRawBytes` (defense in depth — throw
  `AiUnavailableError(error)`, not ArgumentError, at this boundary).
- Body: `model: extractionModel` (the INSTANCE field, defaulting to
  `AiConfig.extractionModel` — i.e. Haiku — NEVER the `model`/Ask field),
  `max_tokens: 4096`, short system string ("You extract structured data
  from photos for a Kenyan duka bookkeeping app. Money values are integer
  cents. Omit lines you cannot read — never invent data."), messages = one
  user turn: image blocks (`{'type':'image','source':{'type':'base64',
  'media_type':img.mediaType,'data': base64Encode(img.bytes)}}`) then
  `{'type':'text','text':instruction}`, `tools: [{name: spec.toolName,
  description: spec.description, input_schema: spec.inputSchema}]`,
  `tool_choice: {'type':'tool','name': spec.toolName}`.
- `_post(body, timeout: extractionTimeout)`.
- Response, A6.1-exhaustive switch on `stop_reason`:
  - `'refusal'` → throw `AiUnavailableError(error)` (checked FIRST, before
    touching content — same ordering as `ask()`).
  - `'tool_use'` → via `_contentBlocks`, collect every block with
    `type=='tool_use'`. EXACTLY ONE such block is acceptable, and it must
    have `name==spec.toolName` AND `input is Map` →
    `final input = Map<String, Object?>.from(block['input'] as Map)`. Zero
    blocks, more than one block, a block whose name doesn't match, or a
    non-map `input` → `AiUnavailableError(error)` (Codex round-2 F3: a
    response containing two `record_receipt` blocks, or the requested block
    plus an unexpected extra tool block, must fail loudly rather than
    silently take "the first matching block" and drop the rest).
  - `'end_turn'`, `'max_tokens'`, `'stop_sequence'`, null, ANY other value →
    `AiUnavailableError(error)`. (tool_choice is forced; anything but
    tool_use is a protocol violation — never "best-effort" parse it.)
- `try { return spec.parse(input); } catch (_) { throw const
  AiUnavailableError(AiFailureKind.error); }` — A6.3: no FormatException/
  TypeError ever escapes.
- Expect: M8's gateway tests pass, including one asserting the extraction
  wire body carries `extractionModel` (not `model`); existing ask/insight
  tests untouched and still assert `model`.
- Failure: fake HTTP client helper can't express a delayed response for the
  timeout test → cause: helper too rigid → counter: extend the helper
  additively (new constructor/callback), never edit existing assertions. A
  real response ever contains more than one `tool_use` block despite
  `tool_choice` forcing a single named tool → cause: this should be
  impossible per the API contract → counter: none needed — exactly-one
  enforcement rejecting it is correct behavior, not a bug to route around.

**M6 — Extraction specs + strict parsers.** New
`lib/core/ai/extraction_schemas.dart` (pure Dart; exposes
`ReceiptExtraction.spec` and `NotebookPage.spec` as `ExtractionSpec<T>`):
- Receipt tool `record_receipt`: top-level `required: ['items']`;
  `items[]` properties `{name: string, quantity: integer, unit: string?,
  unit_price_cents: integer?, line_total_cents: integer?}` with item-level
  `required: ['name','quantity']`; plus `receipt_total_cents: integer?`,
  `supplier_name: string?`, `date: string?` (description: YYYY-MM-DD).
- Notebook tool `record_notebook_page`: `products[]` properties `{name:
  string, unit: enum[piece,packet,bottle,kilogram,litre,crate,carton,tray,
  other]?, selling_price_cents: integer?, buying_price_cents: integer?}`,
  item-level `required: ['name']`, top-level `required: ['products']`.
- Field-by-field accept/drop/fail behavior (Codex round-2 F2b — every field
  now has a stated rule, not just item rows):
  - `items` / `products` missing or not a `List` → throw `FormatException`
    (the gateway maps it to `AiUnavailableError`). This is the ONLY
    whole-extraction failure; every other rule below degrades gracefully
    instead of failing the extraction.
  - One rule governs every field, split only by required-vs-optional
    (Codex round-3, ACCEPTED — replaces the round-2 wording that
    contradicted itself on optional money fields):
    - REQUIRED fields (receipt item `name` + `quantity`; notebook item
      `name`) invalid for ANY reason (missing, blank, wrong type,
      non-integral/negative on `quantity`) → the ROW is dropped and
      counted in `skippedRows`. Unchanged from rev 3.
    - EVERY OPTIONAL numeric or string field — receipt item
      `unit_price_cents`, `line_total_cents`, `unit`; notebook item
      `selling_price_cents`, `buying_price_cents`; top-level
      `receipt_total_cents`, `supplier_name`, `date` — invalid for ANY
      reason (wrong type, a string, a non-integral double, a negative
      number) → that FIELD alone becomes `null` and the ROW SURVIVES,
      provided the row's required fields are still valid.
    - Integral doubles remain ACCEPTED and coerced via `.toInt()`
      (`1200.0` → `1200`) on both required and optional numeric fields —
      this is the logged orchestrator divergence below, unchanged.
  - Receipt `quantity` must be `> 0` (zero ⇒ dropped — `StockDao.receiveStock`
    requires qty > 0 and a zero-qty prefill would dead-end the owner).
  - `date` must round-trip strict `YYYY-MM-DD` (`DateTime.parse` + re-format
    equality, the R7 rule) else `null`.
  - Unknown `unit` string → `null`.
  - Unknown/unexpected top-level keys → ignored silently.
  - Caps: 50 items/receipt, 60 products/page — truncate + set `truncated`.
  Results carry `skippedRows` and `truncated` for feature-level messaging.

  > **Orchestrator divergence from Codex round-2 advice (F2a):** Codex asked
  > to accept ONLY `int` for integer schema fields and reject integral
  > doubles outright. We KEEP the integral-double coercion (`1200.0` →
  > `1200` via `.toInt()`). Reason: models genuinely emit integral doubles
  > for integer schema fields; the coercion is lossless; and dropping such a
  > row would cost the owner a manual re-type for no safety gain.
  > Non-integral doubles (`1200.5`) are still rejected — this divergence
  > only widens what counts as an integer, it never weakens the money-value
  > correctness rule.

- Expect: parser unit tests (M8) pass including one hostile-shape test per
  bullet above (missing/non-list top-level key, non-integral/negative/wrong
  -type `receipt_total_cents`, non-string/blank `supplier_name`, unknown
  top-level key ignored, wrong-type optional item field), plus the existing
  float coercion / zero-qty / bad-date / caps tests.
- Failure: model emits money as strings ("1,200") → cause: schema drift →
  counter is BY DESIGN: money fields are always OPTIONAL, so per the
  unified rule above that field alone becomes `null` and the row SURVIVES;
  do NOT add string parsing, and do NOT drop the row (Codex round-3 fix —
  rev 3 contradicted itself here by implying the row is dropped).

**M7 — Capture pipeline (deterministic, we own it, testable boundary).**
New `lib/core/capture/image_capture_service.dart` + provider in the same
file (core/providers.dart is frozen D9; `ai_providers.dart` precedent):
```dart
sealed class CaptureResult;
class CaptureSuccess extends CaptureResult { final AiImage image; }
class CaptureCancelled extends CaptureResult {}
class CaptureFailed extends CaptureResult { final CaptureFailure reason; }
enum CaptureFailure { tooLarge, undecodable }

/// Top-level and injectable so tests can force each outcome directly,
/// instead of faking package:image internals (Codex round-2 F4).
class PreparedImage {
  const PreparedImage({required this.bytes, required this.width, required this.height});
  final Uint8List bytes; final int width; final int height;
}
PreparedImage prepareImage(Uint8List raw, {int maxLongEdge = 1568, int quality = 80});

class ImageCaptureService {
  ImageCaptureService({
    Future<XFile?> Function(ImageSource)? pick,
    PreparedImage Function(Uint8List)? prepare,
  });
  Future<CaptureResult> capture(ImageSource source);
}
```
Pipeline (every platform, no trust in picker params):
1. `pick(source)` — default impl calls `ImagePicker().pickImage(source:,
   maxWidth: 1568, maxHeight: 1568, imageQuality: 80)` (best-effort fast
   path only). null → `CaptureCancelled`.
2. `await xfile.readAsBytes()` (web-safe; no dart:io). Throws →
   `undecodable`.
3. `compute(prepareImage, bytes)` on the default path (isolate on Android;
   main thread on web — accepted for the demo target), or the injected
   `prepare` callback when the test supplies one: `img.decodeImage`
   (package:image) — null → `undecodable`; `prepareImage`/`prepare` throwing
   for any other reason → `undecodable`. If long edge > `maxLongEdge` →
   `img.copyResize` (long edge `maxLongEdge`, `interpolation: linear`).
   ALWAYS `img.encodeJpg(image, quality: quality)`. Return
   `PreparedImage(bytes, width, height)`.
4. `bytes.length > AiImage.maxRawBytes` → `tooLarge` (post-encode 1568px q80
   is typically 300–600KB; only pathological inputs hit this naturally,
   which is exactly why tests use the injected `prepare` to force it rather
   than generating a giant real image). Else `CaptureSuccess(AiImage.jpeg(...))`.
- Expect: unit tests (M8) pass for all four outcomes, including `tooLarge`
  and `undecodable` exercised directly via the injected `prepare` callback
  rather than declared untestable.
- Failure: `compute` with a top-level function complains about closure
  capture → cause: non-static callback → counter: `prepareImage` is already
  a top-level function taking/returning plain records of bytes+ints, so
  this should not recur; if it does, check for an accidental closure in the
  default `prepare` wiring.

**M8 — Tests.** New files:
- `test/core/ai/ai_image_test.dart` — cap boundary (at/above), mediaType.
- `test/core/ai/extraction_schemas_test.dart` — golden parse, float
  coercion, zero-qty dropped, bad date → null, caps/truncated, top-level
  garbage throws FormatException, plus one hostile-shape test per M6 field
  rule: non-integral/negative/wrong-type `receipt_total_cents` → null,
  non-string/blank `supplier_name` → null, unknown top-level key ignored,
  wrong-type optional item field → that field null while the row survives
  (Codex round-2 F2b). Plus, per schema (receipt AND notebook), three
  item-level optional-price tests: a negative optional price (e.g.
  `unit_price_cents: -100` / `selling_price_cents: -100`), a non-integral
  optional price (e.g. `150.5`), and a string optional price (e.g.
  `"150"`) — each asserting that field alone is `null` and the row
  survives (Codex round-3, ACCEPTED).
- `test/core/ai/anthropic_gateway_extract_test.dart` — fake HTTP client:
  tool_use success (asserts wire body: instance `extractionModel` — NOT
  `model` — tool_choice forced, base64 present, max_tokens 4096); refusal;
  end_turn; max_tokens; stop_sequence; unknown stop; zero tool_use blocks;
  two tool_use blocks both named `spec.toolName`; one tool_use block with
  the wrong name; non-map input; parse-throw inside spec →
  AiUnavailableError; 429→busy; malformed JSON→error; `fakeAsync` timeout
  test: gateway with `timeout: 15s, extractionTimeout: 60s` + client delayed
  20s → extract SUCCEEDS, `ask` times out (Codex round-2 F3 adds the
  zero/multiple/wrong-name block cases — a malformed `extractInput` test on
  `FakeAiGateway` for the F1 fix lives alongside M4's expect bullet). Plus
  one new test (Ian rev 5 per-feature model split): construct the gateway
  with distinct `model`/`extractionModel` values and assert `ask()`'s wire
  body carries `model` while `extractStructured`'s wire body carries
  `extractionModel` — proving the two never collide.
- `test/core/capture/image_capture_service_test.dart` — fixture built IN the
  test via package:image (`img.Image(width: 2400, height: 1600)` filled,
  `encodePng` it to also prove cross-format): assert result is JPEG magic
  (FF D8), long edge == 1568, dims returned, under cap; cancel path;
  `readAsBytes` throwing → `undecodable`; injected `prepare` returning
  oversized bytes → `tooLarge`; injected `prepare` throwing → `undecodable`
  (Codex round-2 F4 — these two directly replace the prior "untestable,
  substitute an `AiImage` constructor test" wording, which is removed).
- Golden seam test: generated image → capture service (real pipeline) →
  `FakeAiGateway` with `extractInput` = receipt fixture → typed
  `ReceiptExtraction` — proves prepared-image → gateway → typed object
  end to end without network.
- Expect: `flutter test` fully green; count strictly greater than baseline.
- Failure: package:image API names differ in the solved 4.x → cause: minor
  API drift → counter: check `flutter pub deps` version, read that version's
  copyResize/encodeJpg signatures in `~/.pub-cache`, adapt names only.

**M9 — README + final battery.** README AI section, privacy wording
(EXACT claim, factually safe): "When you snap a receipt or notebook page,
the photo is sent to Anthropic for extraction. DukaSmart does not retain the
photo and never stores it in the database; the system photo picker may keep
a temporary copy in the OS cache." Then, in order, each with its pass bar:
1. `flutter analyze` → "No issues found". Failure → fix the named lint; a
   lint you cannot fix without touching frozen files → ABORT A2.
2. `flutter test` → all green, count > baseline. A red test you wrote → fix
   it; a red test you did NOT write → ABORT A1 semantics (you broke v1) —
   diagnose via the failing assertion before any further move.
3. `grep -rn "dart:io" lib/core/ai/ lib/core/capture/` → zero hits. A hit →
   remove the import; if a dependency forces it → ABORT A4.
4. `flutter build web` → completes. Failure names a web-incompatible import
   → counter: it can only be M7's compute/image path — re-check step 3's
   surfaces and the package:image import graph
   (`dart pub deps`), fix, rerun.
Final summary MUST quote: baseline and final test counts, the grep output,
and "build web: OK".

**M10 — EXIT GATE: real-sample extraction spike (Ian-owned, BLOCKS missions
02 and 03). STATUS: RECON NEEDED — not yet run.** Every test in all three
missions fakes the extraction result — correct for CI, but it means nothing
here proves the model can actually read a faded thermal receipt or a
handwritten Swahili/Sheng notebook page. Two features are built on that
assumption, so it gets checked BEFORE they are dispatched (Fable advisor
blind-spot 1). The executor's job is only to leave this runnable; Ian runs
it with a real key. Missions 02 and 03 gate their OWN M0 on the existence
and content of `.wargames/GATE-01-extraction-spike.md` (below) — neither
may be dispatched until that file exists and ends in a `GATE: GO` line
covering its feature.

Deliverables from the executor (Codex round-2 F5 replaces the prior
"temporary debug entry point or test harness" / "large majority" wording
with an exact artifact and numeric thresholds):
- `tool/extraction_spike.dart` — a standalone harness (not a test) whose
  `main()` picks an image via the real `ImageCaptureService`, constructs
  `AnthropicGateway(extractionModel: AiConfig.extractionModel, ...)`
  EXPLICITLY passing `AiConfig.extractionModel` — never a hardcoded model
  string, and never `AiConfig.model` (that field drives Ask/insight only,
  not this spike) — so the `--dart-define=AI_EXTRACTION_MODEL=...` flag
  (consumed by M2's `AiConfig.extractionModel`) actually reaches the API
  call; a run with no define set genuinely calls Haiku — the shipping
  default — and a run with `AI_EXTRACTION_MODEL=claude-opus-5` genuinely
  calls Opus for the comparison cell.
  Schema selection is via a **minimal two-button UI**, NOT a command-line
  argument (Codex round-4: `flutter run` entrypoint args are desktop-only,
  so on the `-d chrome` target a `receipt`/`notebook` arg can never reach
  `main()` — and the web file picker additionally REQUIRES a user gesture,
  which a headless `main()` cannot supply). The harness therefore renders a
  bare `MaterialApp` with exactly two ≥48dp buttons — **"Read receipt"** and
  **"Read notebook page"** — each of which picks an image and calls
  `extractStructured` with that schema's `ExtractionSpec`, satisfying the
  gesture requirement and making both gate cells runnable from one build.
  Results (parsed object, `skippedRows`, `truncated`) print to stdout via
  `debugPrint` AND render on screen, so Ian can read them without the
  console.
- Expect: `flutter run -d chrome tool/extraction_spike.dart --dart-define=...`
  opens a page with two buttons; tapping one opens the OS/browser picker.
- Failure: the picker never opens on Chrome → cause: the call was not made
  inside a user-gesture call stack → counter: invoke the picker directly in
  the button's `onPressed` (no `await` before it, no post-frame callback).
- `tool/spike_samples/README.md` — tells Ian where to drop photos (e.g.
  `tool/spike_samples/receipts/*.jpg`, `tool/spike_samples/notebook/*.jpg`)
  and states the EXACT run command, matching whatever the executor actually
  wires up, in this shape:
  `flutter run -d chrome tool/extraction_spike.dart --dart-define=ANTHROPIC_API_KEY=sk-ant-... --dart-define=AI_EXTRACTION_MODEL=<model-id>`

Numeric pass bar Ian applies (deterministic — no "usable"/"large majority"
judgment calls):
- At least **5 printed-receipt photos** and **5 handwritten-notebook
  photos**.
- A photo PASSES when **≥80% of the lines visible on the paper** are
  extracted AND **every extracted money figure matches the paper** (a
  partial line or a wrong money figure fails that photo — no partial
  credit).
- **GO for a feature requires ≥4 of its 5 photos passing.**
- Each photo is run **twice** — once with `--dart-define=
  AI_EXTRACTION_MODEL=claude-haiku-4-5-20251001` (the PRIMARY run — Haiku
  is the shipping extraction model, already chosen by Ian) and once with
  `--dart-define=AI_EXTRACTION_MODEL=claude-opus-5` (a COMPARISON run only,
  so the quality gap is measured, not guessed) — both flow through M2's
  `AiConfig.extractionModel` fix into the harness — giving 4 numbers total:
  haiku×receipts, haiku×notebook, opus×receipts, opus×notebook hit rates
  (Fable blind-spot 3; Codex round-3, ACCEPTED; reframed rev 5, see below).
- **Validation rule, not a selection rule (Ian, rev 5 — replaces the
  round-3 automatic "cheapest model clearing every feature" rule now that
  Ian has already made the model choice this spike used to make):** Haiku
  is the chosen extraction model; this spike VALIDATES it, it does not
  choose between models. Its per-feature hit rate is what the ≥4-of-5 bar
  is applied to.
  - Haiku clears the bar for a feature → that feature is **GO on Haiku**.
  - Haiku MISSES the bar for a feature → the gate records **NO-GO** for
    that feature and reports Opus's hit rate for the SAME photos alongside
    it. Whether to spend Opus money on that feature is Ian's call, made
    AFTER seeing both numbers — the executor/gate-filler must NOT silently
    switch that feature to Opus, and must NOT mark it GO on Opus's number.

Durable artifact Ian fills in: `.wargames/GATE-01-extraction-spike.md`,
containing the results table and ending with EXACTLY one line of this exact
form (`YES`/`NO` independently per feature — a `NO` on one feature does not
block the other's mission):
```
GATE: GO receipts=YES notebook=YES model=<validated-model-id>
```
`model=<validated-model-id>` names the model the numbers above actually
validate — normally `claude-haiku-4-5-20251001`, since Haiku is the chosen
extraction model this gate validates (per the validation rule above, a
feature that misses the bar on Haiku is recorded NO-GO, not silently
re-validated on Opus). Missions 02 and 03 MUST verify at their own M0 that
this file's `model=` value equals the model they will actually run — i.e.
the effective `AiConfig.extractionModel` (`String.fromEnvironment(
'AI_EXTRACTION_MODEL', defaultValue: 'claude-haiku-4-5-20251001')` per M2)
— before proceeding; a mismatch means the mission would ship on a model
this gate never validated → ABORT and re-run the gate on the correct
model.
Full template the executor leaves in place for Ian to fill in:
```markdown
# Gate 01 — Extraction Spike Results

Run date: <YYYY-MM-DD>

## Receipts (printed)
| # | file | lines on paper | lines extracted | money correct? | model | pass? |
|---|------|-----------------|------------------|-----------------|-------|-------|
| 1 |      |                 |                  |                 | haiku |       |
| 1 |      |                 |                  |                 | opus  |       |
| 2 |      |                 |                  |                 | haiku |       |
| 2 |      |                 |                  |                 | opus  |       |
| 3 |      |                 |                  |                 | haiku |       |
| 3 |      |                 |                  |                 | opus  |       |
| 4 |      |                 |                  |                 | haiku |       |
| 4 |      |                 |                  |                 | opus  |       |
| 5 |      |                 |                  |                 | haiku |       |
| 5 |      |                 |                  |                 | opus  |       |

Receipts hit rate: haiku <n>/5, opus <n>/5

## Notebook pages (handwritten)
| # | file | lines on paper | lines extracted | money correct? | model | pass? |
|---|------|-----------------|------------------|-----------------|-------|-------|
| 1 |      |                 |                  |                 | haiku |       |
| 1 |      |                 |                  |                 | opus  |       |
| 2 |      |                 |                  |                 | haiku |       |
| 2 |      |                 |                  |                 | opus  |       |
| 3 |      |                 |                  |                 | haiku |       |
| 3 |      |                 |                  |                 | opus  |       |
| 4 |      |                 |                  |                 | haiku |       |
| 4 |      |                 |                  |                 | opus  |       |
| 5 |      |                 |                  |                 | haiku |       |
| 5 |      |                 |                  |                 | opus  |       |

Notebook hit rate: haiku <n>/5, opus <n>/5

## Hit-rate summary (all 4 cells required — haiku is PRIMARY, opus is COMPARISON)
| model | receipts | notebook |
|-------|----------|----------|
| haiku | <n>/5    | <n>/5    |
| opus  | <n>/5    | <n>/5    |

GATE: GO receipts=<YES|NO> notebook=<YES|NO> model=<validated-model-id>
```
- Expect: a filled table for both features and both models, the 4-cell
  hit-rate summary filled in, and the exact `GATE:` line above present as
  the last line of the file, with `model=` normally
  `claude-haiku-4-5-20251001` — the model this gate validates — per the
  validation rule above.
- Failure: hit rate poor on handwriting → cause: the hard half of the
  problem is real → counter: mission 03 (notebook) is the one at risk;
  mission 02 (printed receipts) may still proceed independently — the
  per-feature `YES`/`NO` on the `GATE:` line is what encodes this, so
  missions 02/03 read their own flag rather than a single shared verdict.
  Haiku misses the bar on one feature → NOT a gate failure — that's the
  validation rule doing its job; record NO-GO for that feature, log
  Opus's rate for the same photos, and stop — the model-vs-money decision
  for that feature belongs to Ian, not the executor.

## Forks
- **F1 (package:image performance on web).** Trigger: chrome dev-target
  manual run shows multi-second freeze on a 12MP photo → route B: keep
  the picker's best-effort resize as the input (already in M7 step 1), and
  ACCEPT the latency for the demo target — document in README known-gaps.
  No new dependency, no platform fork.
- **F2 (implementor fan-out).** Trigger: M3's analyze error list ≠ the five
  expected files → run the M3 counter-grep and patch every hit before
  proceeding.

## Abort conditions
- A1: baseline red / modified tracked files at M0, or a v1 test broken at M9.
- A2: reality contradicts a SETTLED fact above, or a fix would require
  editing frozen surfaces (router table structure, core/providers.dart
  registrations) beyond adding the planned method/files.
- A3: pub cannot solve `image ^4.x` alongside existing pins.
- A4: anything would require `dart:io` in shared paths or storing image
  bytes to disk/DB (the picker's own OS cache is outside our code and
  documented in M9's wording).

## Verification
M0 baseline battery; M8 suite; M9 final battery (the four commands with pass
bars above); M10 gate file (`.wargames/GATE-01-extraction-spike.md`) checked
for a trailing `GATE: GO ...` line before missions 02/03 are dispatched —
STATUS: RECON NEEDED until Ian runs it. Every claim in the executor's final
summary must cite a command run or file read in-session.

## Red-team record (Phase B + Codex round 1 + Codex round 2)
**Attack 1 (held from Phase B):** 15s instance timeout misclassifies slow
vision calls as "offline" — patched: injectable `extractionTimeout` (60s
default) + per-call `_post` timeout + fakeAsync test.
**Attack 2 (Codex 01.4, upheld):** picker resize params are silently
best-effort (verified in image_picker_for_web 3.1.1 source) — an oversized
non-JPEG sails past a magic-byte check. Patched: deterministic
decode→resize→encodeJpg pipeline owned by us; `AiImage` is always JPEG with
verified dimensions; cap enforced at construction AND at the gateway.
**Attack 3 (Codex 01.1/01.2, upheld):** raw-map API let parser exceptions
escape the A6.3 boundary; non-exhaustive stop_reason accepted protocol
violations. Patched: `ExtractionSpec<T>.parse` runs inside the gateway with
catch-all mapping; exhaustive switch, tool_use only.
**Round 2 (Codex plan review — F1/F3/F4 upheld, F2 partially accepted, F5
upheld):**
- Attack 4 (F1): `FakeAiGateway` called `spec.parse` directly with an
  `Object?`-typed error field — a malformed `extractInput` could leak a raw
  `FormatException`/`TypeError` past the A6.3 boundary in controller/widget
  tests, meaning those tests never exercised the real contract. Patched:
  the fake wraps parsing in the same try/catch as `AnthropicGateway` and
  types its error field `AiUnavailableError?`.
- Attack 5 (F3): "first matching `tool_use` block" silently dropped data
  when a response contained two `record_receipt` blocks, or the requested
  block plus an unexpected extra tool block. Patched: the gateway now
  requires EXACTLY ONE `tool_use` block matching `spec.toolName` with a
  `Map` input; zero, multiple, wrong-name, or non-map → `AiUnavailableError
  (error)`.
- Attack 6 (F4): the `tooLarge` branch was declared untestable, and M8
  substituted an `AiImage` constructor test that never touches the
  service — meaning the SERVICE's oversized-output mapping to
  `CaptureFailed(tooLarge)` was never actually proven. Patched: factored a
  top-level `prepareImage`/`PreparedImage` boundary and an injectable
  `prepare` callback on `ImageCaptureService` so `tooLarge` and
  `undecodable` are exercised directly.
- Logged divergence (F2a): Codex asked to accept ONLY `int` for integer
  schema fields and reject integral doubles. We KEEP integral-double
  coercion (`1200.0` → `1200`) — models genuinely emit integral doubles for
  integer schema fields, the coercion is lossless, and rejecting it would
  cost the owner a manual re-type for no safety gain. Non-integral doubles
  (`1200.5`) are still rejected.
