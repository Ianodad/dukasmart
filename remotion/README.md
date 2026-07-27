# DukaSmart promo

The promo video linked from the repo-root README, built in
[Remotion](https://remotion.dev). An intro, one beat per app screen, an outro.

The rendered result is committed at `docs/dukasmart-promo.mp4` (and its `.gif`
preview) because the README links to it. `out/` is gitignored.

## Commands

```
npm i               # once
npm run dev         # Remotion Studio, live preview
npx remotion render DukaPromo ../docs/dukasmart-promo.mp4
npm run lint        # eslint + tsc
```

## Adding a beat

Beats are data. `src/DukaPromo.tsx` holds a `BEATS` array — one entry per screen:

```ts
{ img: "13-dashboard-live.png", title: "Today at a glance", line: "Sales, cash vs M-PESA, and what needs attention." }
```

Append an entry and the video gets longer automatically — `PROMO_DURATION_FRAMES`
is derived from `BEATS.length`. Keep `line` to one sentence; it is set at 40px
and wraps badly beyond about 70 characters.

## Screenshots — read this before adding one

`img` refers to a file in `public/screens/`, which is a **byte-identical copy of
`docs/screenshots/`**. Both must be updated together.

Every screenshot is **860 × 1864** — 430 × 932 CSS pixels at DPR 2. This is not
cosmetic: the phone frame is `phoneW = 430`, and the slow pan assumes the scaled
image is ~888px tall inside an 840px window. A different aspect ratio crops or
letterboxes inside the frame.

The full capture recipe, including how to reach the AI screens, is in
[`docs/screenshots/CAPTURE.md`](../docs/screenshots/CAPTURE.md).

Beats reference files by exact filename. Renaming an existing screenshot breaks
the video silently — add new numbers instead of renumbering old ones.

## Keeping it honest

The promo shows real screenshots of a real build. Do not stage a beat for a
feature that is not shipped, and do not illustrate one with a mock-up drawn in
React — inside a phone frame beside eight real captures, an illustration reads
as a screenshot.
