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
  15-ask-answer:/home/ask 16-daily-report-ai:/home/report
```

No dependencies — it uses the `WebSocket` global built into Node 22+.

Two things it deliberately does NOT do:

- **It cannot seed data.** It photographs whatever state the browser profile is
  already in. A fresh profile shows `KES 0` and the demo seed products, which
  reads as fake. Put real sales and expenses in first (step 4 below), then run it.
- **It cannot conjure the AI screens.** `AiConfig.isConfigured` is
  `apiKey.isNotEmpty`, and `aiAvailableProvider` gates every AI surface — build
  without the dart-define and the Ask bar and insight card are not in the widget
  tree at all. There is nothing to photograph.

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

Two screens only render with a key present at build time:

| Screen | How to reach it | Notes |
|---|---|---|
| Ask your duka | Dashboard → the "Ask about your duka…" bar (route `/home/ask`) | Capture *after* an answer has rendered, not the empty suggestion-chip state |
| AI insight card | Daily Report (`/home/report`) — card sits below the ledger | Needs a closed day with real figures behind it |

Use a scoped or expiring key for capture work and revoke it afterwards. The key
is baked into that build; do not distribute an APK or web build made with it.
