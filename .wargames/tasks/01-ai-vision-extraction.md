WARGAME ORDER. You are not executing this mission, you are wargaming it. A cheaper
executor runs the brief below later. Your job is the route it will follow.

Recon first, read-only: the repo structure, the existing patterns for similar
features, and anything the new feature must integrate with or match.

Then fight the mission on paper, move by move, and write it to
wargames/01-ai-vision-extraction.md.

=== THE MISSION BRIEF (the executor's orders, not yours) ===

Here is my repo: /data/Documents/Flutter/dukasmart. I want to add **vision +
structured extraction plumbing** to the existing AI core, as the shared
foundation for two v2 features (snap-to-restock, notebook import):

1. **Image input in the gateway.** The Anthropic gateway (lib/core/ai/) gains
   the ability to send one request containing image content blocks (base64 JPEG)
   alongside text. Single-turn call — NOT the multi-round tool loop used by
   Ask-your-duka.
2. **Structured extraction call.** A new gateway method that sends image(s) +
   an extraction instruction + one "extraction tool" whose input schema IS the
   desired output shape, with `tool_choice` forced to that tool. Returns the
   validated tool_use input as a typed Dart object. Strict validation, same
   spirit as the existing strict tool-input validation retrofit (R7).
3. **Image capture + preparation utility.** A small service OUTSIDE
   lib/core/ai/ (it needs platform plugins): pick from camera or gallery,
   downscale so the long edge ≤ 1568px, re-encode JPEG (~80 quality), return
   bytes + dimensions. Must work on Android AND web (kIsWeb-safe — no dart:io
   in any code path shared with web).
4. **Extraction schemas for both consumers**, defined once: receipt line-items
   (supplier receipt → items: name, quantity, unit, unit_price_cents,
   line_total_cents; plus receipt_total_cents, supplier_name?, date?) and
   notebook catalog page (page → products: name, unit?, selling_price_cents?,
   buying_price_cents?). Cents are integers — never floats.

It needs to integrate with the existing AI seam on branch feature/ai-capabilities:
the Anthropic gateway class, AiConfig, the aiAvailableProvider gating, and the
existing error taxonomy (offline / auth / rate-limit / server mapped to
user-facing states). Follow the existing patterns in lib/core/ai/ and its tests
for style and structure — do not introduce a new pattern where one already
exists.

Constraints:
- No dart:io anywhere under lib/core/ai/ or other AI feature code (web is a
  real target; the CORS `anthropic-dangerous-direct-browser-access` header
  path must keep working).
- The AI layer NEVER writes to the database. Extraction returns data only.
- Money values in schemas are integer cents; display elsewhere uses
  formatCents().
- Keep the existing 217-test suite green; add tests with the same fake/mock
  approach the gateway tests already use (MockClient-style, no live API).
- Request size discipline: images downscaled/compressed BEFORE base64; reject
  (with a typed error) any prepared image still over ~4.5MB base64.
- No new gating: reuse aiAvailableProvider; if AI is unavailable the new
  capabilities simply don't surface.

Do the simplest thing that works well. No speculative abstractions, no
configuration options nobody asked for.

When you believe you are done, verify before reporting: run `flutter analyze`
and `flutter test` (export PATH="$HOME/flutter/bin:$PATH"), and manually
exercise the golden path with a fixture image in a widget/unit test (fake
gateway response → typed extraction object). Audit each claim in your final
summary against something you actually ran or read in this session.

=== ASSUMPTIONS MADE WHILE DRAFTING (flagged, not asked) ===
- image_picker is the capture dependency (add if absent) — camera capture via
  OS intent needs no CAMERA manifest permission on Android.
- Downscale target 1568px long edge follows Anthropic vision sizing guidance.
- One image per extraction call (notebook import loops pages client-side).
