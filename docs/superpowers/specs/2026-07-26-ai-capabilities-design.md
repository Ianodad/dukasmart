# DukaSmart AI Capabilities — Design (v1)

**Date:** 2026-07-26
**Branch:** `feature/ai-capabilities`
**Status:** Approved by Ian (2026-07-26)

## Context

DukaSmart is a local-first Android inventory/sales/daily-close app for a single
Kenyan kiosk owner. All data lives in a local Drift/SQLite database (Products,
Sales, SaleItems, Expenses, StockMovements, DailyCloses). The app currently has
no network layer at all. Product principle: "trust in the money math is the
product" — the biggest number on screen is the one the owner came for, and it
must be correct.

This design adds **online-only AI capabilities** that layer on top of the
offline core without weakening it. When the device is offline or no API key is
configured, the app behaves exactly as today.

## Decisions (locked)

| Decision | Choice | Why |
|---|---|---|
| Scope | (1) "Ask your duka" natural-language Q&A, (2) AI daily-close insights, (3) projections with AI narration | Coherent trio sharing one AI layer. Quick-capture and voice deferred. |
| Deployment reality | Demo / portfolio first | Dev API key via `--dart-define`; no backend, no Firebase. APK is not publicly distributed with a key. |
| UX surface | Ask bar on dashboard → focused `/home/ask` Q&A screen; insight cards on existing screens | Discoverable without competing with money numbers; fits "serious merchant tool" brand. |
| Data access | **Hybrid**: tool-use loop for Q&A; one-shot snapshot prompt for daily-close insights & projection narration | Tool-use gives precision + follow-ups; snapshot gives one cheap round-trip for a fixed query set. NL→SQL rejected (untrustworthy). |
| Provider/model | Anthropic Messages API over raw HTTPS, `claude-opus-5` (single const) | No official Dart SDK; raw HTTP is documented and simple. Opus 5 is the recommended default; Haiku 4.5 is the cost fallback if ever needed. |

## Architecture

```
lib/core/ai/
  ai_gateway.dart        # abstract interface — the ONLY seam to the network
  anthropic_gateway.dart # Messages API impl (http package, raw JSON)
  duka_tools.dart        # 6 read-only tool defs + dispatcher → DAOs
  snapshot_builder.dart  # ShopSnapshot JSON for one-shot insight calls
  projection_service.dart# pure-Dart math: stock run-out, cash-flow projection
  ai_config.dart         # model const, key from String.fromEnvironment

lib/features/assistant/
  ask_screen.dart        # Q&A thread UI
  ask_controller.dart    # Riverpod controller (messages, loading, errors)
```

### AiGateway (provider-agnostic seam)

```dart
abstract class AiGateway {
  /// Multi-turn Q&A with tool use. Returns the final assistant text.
  Future<String> ask(List<AiMessage> thread, {required ToolDispatcher tools});

  /// One-shot insight from a precomputed snapshot.
  Future<String> generateInsight(ShopSnapshot snapshot);
}
```

Swapping to a backend proxy or another provider later = one new implementation
class. Nothing in features/ imports `anthropic_gateway.dart` directly; Riverpod
provides the gateway.

### API key & availability gating

- Key read at build time: `--dart-define=ANTHROPIC_API_KEY=sk-...` via
  `const String.fromEnvironment('ANTHROPIC_API_KEY')`.
- `aiAvailableProvider` = key non-empty. When false: ask bar not rendered,
  AI insight card not rendered, no network code paths reachable.
- No key is ever committed to the repo. Release builds without the define are
  identical to today's app.

### Tools (all read-only)

The model can never write to the database. Each tool result includes both raw
cents and pre-formatted KSh strings (via existing `formatCents`); the system
prompt instructs the model to quote provided formatted values and never do its
own arithmetic on money.

| Tool | Inputs | Backed by |
|---|---|---|
| `get_sales_summary` | `from`, `to` (ISO dates) | SalesDao aggregate: total, cash vs M-PESA, sale count |
| `get_top_products` | `from`, `to`, `limit` | SaleItems join Products: qty + revenue per product |
| `get_expenses` | `from`, `to` | Aggregated totals + counts by category and by reason — no raw expense rows |
| `get_stock_levels` | `low_only` (bool) | ProductsDao/StockDao: current qty, low-stock flags |
| `get_daily_closes` | `from`, `to` | DailyCloseDao: totals, cash difference per closed day |
| `get_projections` | — | ProjectionService output (see below) |

New aggregate queries live in a single `AiQueryService` class in
`lib/core/ai/` that composes the existing DAOs/database — existing DAOs are
not modified, and there are no schema changes.

Tool-use loop: manual loop per Anthropic docs — send request; while
`stop_reason == "tool_use"`, execute each `tool_use` block locally, append the
full assistant `content` plus one user message containing all `tool_result`
blocks (matching `tool_use_id`s); re-send. Cap: 5 executed tool rounds.
`max_tokens`: 2048 for Q&A, 1024 for the one-shot insight (headroom so a
`max_tokens` stop is an explicit failure, never silently-truncated text).
`stop_reason == "refusal"`, `max_tokens`, and unknown stop reasons are handled
before reading content — only `end_turn` returns text.

### ShopSnapshot (one-shot insight input)

Computed locally in Dart, deterministic, unit-tested:

- Today's close: totals, cash vs M-PESA, cash difference, best seller.
- Comparisons: vs. same weekday last week, vs. 7-day and 30-day daily averages.
- Expense trend: today + 7/30-day totals by category.
- Projections (from ProjectionService).

Serialized as compact JSON; single Messages API call (no tools); returns one
short insight paragraph.

### ProjectionService (pure math, no AI)

- **Stock run-out:** per product, average daily quantity sold over the last 14
  days (only days since first sale of that product); `daysRemaining =
  currentQty / avgDailyQty`. Products with no sales in window → "no estimate".
- **Cash-flow:** average daily net (sales − expenses) over last 30 days,
  projected 7 days forward.
- Works offline; values shown by AI features are narrations of these numbers.

## UX

### Ask your duka
- Dashboard gets a quiet "Ask about your duka…" field (slate, not emerald —
  not a money action). Tapping opens `/home/ask` (new GoRouter route).
- `/home/ask` screen: message thread, input bar, send button; 3 suggested chips on
  empty state ("What did I sell today?", "Nimetumia pesa ngapi kwa transport
  wiki hii?", "What's running low?"). Loading indicator between send and reply.
- Thread is session-only (in-memory); cleared on leaving the screen. No chat
  persistence in v1.
- English and Swahili both supported natively by the model; it mirrors the
  user's language.

### Daily close insight
- `daily_report_screen.dart` keeps the existing rule-based `buildInsight()`
  text exactly as-is (instant, offline).
- When AI is available and online, an additional "AI insight" card loads
  underneath (async). On any failure the card simply does not appear — no
  error state on this screen.

### Projections
- Surfaced through (a) the AI insight card and (b) `get_projections` in chat.
  No new dedicated screen in v1.

## Error handling

- Network errors (`http.ClientException`, timeout ~15s) → in chat: friendly bubble
  "You're offline — asking needs internet." On the insight card: card hidden.
- API errors: 429/5xx → "AI is busy, try again shortly"; 4xx → generic failure
  message (and debug log). No retries in v1 beyond the user tapping again.
- No `connectivity_plus` dependency — attempting the call and catching the
  exception is the offline check.

## Privacy & cost

- What leaves the phone: the user's typed questions, the in-session
  conversation thread, aggregated query results, and the snapshot. Raw
  database rows never leave the device, and the schema holds no customer PII.
  Demo keys should be scoped/expiring and revoked after the demo.
- Cost estimate at Opus 5 rates ($5/$25 per MTok): ~2–4k input + ~300 output
  tokens per question ≈ ~US$0.02; one insight call per day-close. Demo-scale
  negligible. Model is a single const if a cheaper model is preferred later.

## Testing

- Unit: ProjectionService math (fixed seed data, edge cases: new product, zero
  sales, zero stock); SnapshotBuilder against in-memory Drift DB (existing test
  pattern); tool dispatcher (tool name → correct DAO call → JSON shape).
- Gateway: request-building and response-parsing tests with a mocked
  `http.Client` (tool_use loop, refusal, error mapping). No live API calls.
- Widget: ask screen renders states (empty/loading/reply/offline); dashboard
  hides ask bar when key absent.

## Out of scope (v1)

Voice input, receipt OCR / quick expense capture, streaming responses, chat
persistence, backend proxy / Firebase, per-user keys, write-capable tools.

## Dependency changes

- Add `http` to pubspec dependencies. Nothing else.
