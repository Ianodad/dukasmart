# How to capture DukaSmart screenshots

Every screenshot in this folder is **860 × 1864** — 430 × 932 CSS pixels at 2×
device pixel ratio. That is not arbitrary: the promo video's phone frame is
`phoneW = 430` (`remotion/src/DukaPromo.tsx`), and its slow pan assumes the
scaled image is ~888px tall inside an 840px window. **A screenshot at a
different aspect ratio will letterbox or crop inside the phone frame.**

Two folders hold byte-identical copies. **Both must be updated together:**

- `docs/screenshots/` — what the README links to
- `remotion/public/screens/` — what the promo video loads via `staticFile()`

## Scripted capture (preferred)

`tool/capture_screens.mjs` drives headless Chrome over CDP and emits the exact
860 x 1864 geometry, so the numbers below cannot be fat-fingered:

```
export PATH="$HOME/flutter/bin:$PATH"
flutter build web --dart-define=ANTHROPIC_API_KEY=sk-ant-...   # key only for AI screens
python3 -m http.server 8771 --directory build/web &
node tool/capture_screens.mjs http://localhost:8771 docs/screenshots \
  17-ask-answer:/home/ask 18-daily-report-ai:/home/report
```

No dependencies — it uses the `WebSocket` global built into Node 22+.

One thing it deliberately does NOT do:

- **It cannot conjure the AI screens.** `AiConfig.isConfigured` is
  `apiKey.isNotEmpty`, and `aiAvailableProvider` gates every AI surface — build
  without the dart-define and the Ask bar and insight card are not in the widget
  tree at all. There is nothing to photograph.

It also cannot seed data — it photographs whatever state the browser profile is
already in, and a fresh profile shows `KES 0` and the demo seed products, which
reads as fake. Use the UI driver below for that instead of seeding by hand.

## Seeding a realistic shop (`tool/drive_ui.mjs`)

`capture_screens.mjs` can only navigate and photograph. `tool/drive_ui.mjs`
also taps and types, so a realistic trading day can be recorded reproducibly
instead of clicked in by hand before every capture run:

```
node tool/drive_ui.mjs http://localhost:8771 docs/screenshots tool/seed_demo_day.json
```

`tool/seed_demo_day.json` records three sales (two cash, one M-PESA with a
transaction code), one stock-transport expense, and then captures
`15-dashboard-ai` and `16-ask-suggestions`. From a clean profile it produces
`KES 680` — cash 340, M-PESA 340. Wipe `/tmp/dukasmart-drive-profile` first for
a repeatable run; leave it to accumulate more data on top.

Because Flutter renders to a canvas there are no selectors — steps are CSS
coordinates measured off a screenshot (screenshot px ÷ 2). **If a screen's
layout changes, the coordinates go stale silently:** the tap lands on nothing
and the run continues. Always eyeball the output rather than trusting the exit
code. Everything must happen in one invocation; committed data survives in the
profile's IndexedDB, but on-screen state does not.

Do not reach for Chrome's plain `--screenshot` flag instead. It needs
`--virtual-time-budget` to wait for the app, and virtual time freezes real
timers while Drift's `sqlite3` worker runs off-thread — the app sits on the
splash screen forever and you get a screenshot of the logo.

## Manual recipe (fallback)

1. Start the app on Chrome:

   ```
   export PATH="$HOME/flutter/bin:$PATH"
   flutter run -d chrome --web-port=8770
   ```

   Add `--dart-define=ANTHROPIC_API_KEY=sk-ant-...` if you are capturing an AI
   screen — without it the AI surfaces do not render at all.

2. Open Chrome DevTools → toggle device toolbar (`Ctrl+Shift+M`).

3. Set **Responsive**, dimensions **430 × 932**, DPR **2**.

4. Put real data on screen first. An empty state photographs badly and a seeded
   demo shop reads as fake — record a couple of sales and an expense before
   capturing anything with numbers in it.

5. Capture: DevTools command menu (`Ctrl+Shift+P`) → **Capture screenshot**.
   Use *Capture screenshot*, not *Capture full size screenshot* — the latter
   extends past the viewport and breaks the 1864px height.

6. Verify before committing:

   ```
   file docs/screenshots/<new>.png    # must report 860 x 1864
   ```

7. Copy into both folders and keep the `NN-name.png` numbering contiguous.

## Naming

Files sort by their numeric prefix and the promo references them by exact
filename in the `BEATS` array. Renaming an existing file silently breaks the
video — add new numbers rather than renumbering old ones.

## AI screens

Every AI surface needs a key at build time. But there are two different bars
here, and confusing them wastes a key:

- **Rendering** needs only a *non-empty* key — `AiConfig.isConfigured` is just
  `apiKey.isNotEmpty`. Any string makes the ask bar and the Ask screen appear.
- **Content** needs a *valid* key. With a bogus one the request goes out and
  comes back 401, and the thread shows "Something went wrong — please try
  again."

So `15-dashboard-ai` and `16-ask-suggestions` are capturable with a dummy key
(that is how they were taken). These two are not:

| Screen | Capture as | How to reach it | Notes |
|---|---|---|---|
| Ask your duka, answered | `17-ask-answer` | Dashboard → the "Ask about your duka…" bar (route `/home/ask`) | Capture *after* an answer has rendered, not the empty suggestion-chip state — that is already `16` |
| AI insight card | `18-daily-report-ai` | Daily Report (`/home/report`) — card sits below the ledger | Needs a closed day with real figures behind it |

Ask one question in Swahili during the same session — that claim ships in the
UI and the deck but has never been checked against a real key.

### One command

`tool/capture_ai_screens.sh` does the whole run — build, serve, seed, close the
day, ask, capture, and mirror into `remotion/public/screens/`:

```
tool/capture_ai_screens.sh
```

It prompts for the key with echo off. Do not pass the key as an argument:
argv is visible to any process via `ps` and lands in your shell history.
`ANTHROPIC_API_KEY=... tool/capture_ai_screens.sh` also works.

It preflights the key against the API before spending a build on it. That
guard matters more than it looks: because `isConfigured` is just
`apiKey.isNotEmpty`, a dead key still renders every AI surface, so a run
would otherwise produce four plausible-looking PNGs — `17` holding an error
bubble, `18` silently missing its card — mirror them into
`remotion/public/screens/`, and exit 0.

Every coordinate in it has been dry-run against a build with a dummy key, so
the taps are known-good — only the AI *content* was unverifiable that way. Two
traps it already accounts for, both of which failed silently the first time:

- **Complete Day opens a confirmation dialog.** Tapping the button alone
  leaves the day open, and the report then renders "Day not closed yet"
  instead of the AI card.
- **The insight sits below the fold.** The report must be scrolled to the
  bottom or the capture is all ledger and no insight.

The script still cannot tell you whether the *answer* rendered — check by eye.

Use a scoped or expiring key for capture work and revoke it afterwards. The key
is baked into that build; do not distribute an APK or web build made with it.
