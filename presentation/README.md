# DukaSmart deck

The 10-slide DukaSmart presentation, built in [Remotion](https://remotion.dev) so
the deck is code — same brand tokens as the app, no copy drifting inside a
proprietary slide file.

Output lands in `out/` and is **gitignored**: 6MB+ of binaries that rebuild from
source in one command.

## Commands

```
npm i               # once
npm run dev         # Remotion Studio, live preview
npx remotion render DukaSmartDeck out/dukasmart-deck.mp4
npx tsc --noEmit -p tsconfig.json   # typecheck before committing
```

Render a single slide while iterating — much faster than the full deck:

```
npx remotion still DukaSmartDeck out/slide.png --frame=920
```

## Structure

| File | What it holds |
|---|---|
| `src/slides.tsx` | Every slide component, plus the shared `HeaderBand` / `LightSlide` / `Card` / `Dot` chrome |
| `src/Deck.tsx` | Slide order, timing, transitions, `DECK_DURATION` |
| `src/tokens.ts` | Brand tokens — mirrors the app's DESIGN.md "Slate + Emerald Pro" exactly |
| `src/ui.tsx` | `Reveal`, `Overline`, the Lexend font handle, money formatting |

## Editing rules that will bite you

- **The slide count is hardcoded.** `HeaderBand` renders `DukaSmart · {index}/9`.
  Adding a slide means updating that denominator *and* passing the right `index`
  to every slide after the insertion point. An off-by-one here is silent — it
  typechecks and it renders, it is simply wrong.
- **Timing is derived, not written.** `DECK_DURATION` comes from `SLIDES.length`.
  Never hardcode a duration.
- Slide *n* starts near frame `(n-1) * (SLIDE_FRAMES - TRANSITION_FRAMES)`. Add
  ~70 frames to clear the `Reveal` stagger before capturing a still.
- Body text is left-aligned, never centred. Emerald is an accent, not a
  background. Both rules come from the app's design system.

## Keeping it honest

This deck describes a real product to real people. Every claim on it — test
counts, what ships versus what is only planned — is checked against the codebase
before it goes in. If you change a number here, verify it with `flutter test`
first, and check the repo-root `README.md` for the same claim.
