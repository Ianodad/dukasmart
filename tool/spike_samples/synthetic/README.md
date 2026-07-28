# Synthetic spike samples — SMOKE TEST ONLY

**These images are AI-generated (gpt-image-2). They do NOT count toward the M10
exit gate.** Do not score them into `.wargames/GATE-01-extraction-spike.md`.

## What these are for

Proving the *plumbing* works end to end against the real Anthropic API, without
waiting on a photo-gathering trip:

- the two-button harness renders and the Chrome file picker actually opens
- `ImageCaptureService` decodes → resizes → re-encodes a real photo
- the wire body reaches the API and comes back as a forced `tool_use` block
- `ReceiptExtraction` / `NotebookPage` parse it into typed Dart
- money lands as integer cents and the on-screen result is readable

If any of that is broken, these images will show it in five minutes.

## What these CANNOT tell you

A pass here is **not** evidence that Haiku can read a real receipt or real
handwriting. Generated images are cleaner than reality: even the "faded" and
"messy" ones have consistent stroke weight, even lighting, no thermal-print
dropout, no ballpoint skips, no bleed-through from the previous page, no
genuine Swahili/Sheng shorthand from a person who writes fast because a
customer is waiting.

**The M10 gate still requires ≥5 real printed receipts and ≥5 real handwritten
notebook pages.** Handwriting is the half most likely to fail, and it is
exactly the half these fixtures flatter.

Treat a pass here as "the pipe is connected", and a *failure* here as genuinely
bad news — if the model misses on clean synthetic input, real paper will be
worse.

## Ground truth

Scored against what was requested from the image model. Verify against the
actual rendered image before trusting a cell — generation is not always exact,
and the image on disk is the truth, not this table.

### receipts/receipt-01-clean.jpg — VERIFIED exact against the rendered image
Supplier `MWANGI WHOLESALERS LTD`, date `2026-07-21`, total `KES 4,870.00`

| item | qty | unit price | line total |
|---|---|---|---|
| Maize Flour 2kg | 4 | 180.00 | 720.00 |
| Cooking Oil 1L | 3 | 310.00 | 930.00 |
| Sugar 1kg | 6 | 145.00 | 870.00 |
| Rice 5kg | 2 | 850.00 | 1700.00 |
| Bar Soap | 10 | 65.00 | 650.00 |

Note: `4 × 180 = 720`, `3 × 310 = 930`, `2 × 850 = 1700`, `10 × 65 = 650` all
tie out, but `6 × 145 = 870` ✓ — and the five line totals sum to `4,870`. Good
arithmetic makes this a clean correctness check.

### receipts/receipt-02-thermal.jpg — faded thermal, 4 lines — VERIFIED against the rendered image
Supplier `KAMAU STORES SUPPLY`, date `2026-07-19`, printed total `3,090.00`

| item | qty | unit price |
|---|---|---|
| Tea Leaves 500g | 2 | 240.00 |
| Wheat Flour 2kg | 5 | 210.00 |
| Salt 1kg | 8 | 40.00 |
| Milk 500ml | 12 | 60.00 |

> **The printed total on this one is WRONG on purpose-by-accident.**
> `2×240 + 5×210 + 8×40 + 12×60 = 2,570`, not the `3,090.00` printed on the
> paper. I did not plan that, but keep it — it is a genuinely useful test.
> The correct behavior is to report `receipt_total_cents: 309000` because
> that is **what the paper says**. If the model instead "helpfully" returns
> 257000, or silently adjusts a line to make the arithmetic work, that is a
> real finding: the model is reconciling instead of transcribing, and on a
> real receipt that would quietly rewrite a supplier's figures.

### receipts/receipt-03-dense.jpg — 9 lines, skewed handheld shot — VERIFIED exact against the rendered image
Arithmetic ties out: the nine amounts sum to exactly `23,434.00`, and every
`qty × rate` matches its amount. This is the strongest correctness check of
the three receipts — any wrong figure breaks a sum you can verify by hand.

Supplier `RIFT VALLEY DISTRIBUTORS`, date `2026-07-23`, total `KES 23,434.00`

| item | qty | rate | amount |
|---|---|---|---|
| Maize Flour 2kg | 12 | 178.00 | 2136.00 |
| Cooking Oil 5L | 4 | 1450.00 | 5800.00 |
| Sugar 2kg | 9 | 290.00 | 2610.00 |
| Rice 10kg | 3 | 1620.00 | 4860.00 |
| Detergent 1kg | 7 | 195.00 | 1365.00 |
| Bar Soap | 24 | 62.00 | 1488.00 |
| Tea Leaves 250g | 15 | 135.00 | 2025.00 |
| Cocoa Drink 400g | 5 | 480.00 | 2400.00 |
| Matchbox Pack | 30 | 25.00 | 750.00 |

### notebook/notebook-01-neat.jpg — neat blue biro, 7 products — VERIFIED exact against the rendered image
Heading `STOCK LIST`. Clean ruled page, even daylight. This is the easy case —
if Haiku misses here, it will not survive a real notebook.

| product | price |
|---|---|
| Maize Flour 2kg | 190 |
| Cooking Oil 1L | 320 |
| Sugar 1kg | 150 |
| Rice 5kg | 880 |
| Bar Soap | 70 |
| Tea Leaves 500g | 250 |
| Salt 1kg | 45 |

### notebook/notebook-02-messy.jpg — hurried mixed-language writing, 8 products — VERIFIED against the rendered image
Angled handheld shot on a shop counter, creased and grubby page, Swahili
product names, one line in black ink among the blue.

> **Two prices carry a struck-through correction** — `Sukari 1kg` and
> `Chai 500g` both show a crossed-out first digit with the corrected value
> beside it (`155` and `245`). That is the most interesting cell in this whole
> set. The correct read is the CORRECTED number. If the model returns the
> struck-out value, or blends the two into a third number, that is a genuine
> money-correctness failure — and shopkeepers correct prices in their books
> constantly, so it will happen on real pages too.

| product | price |
|---|---|
| Unga 2kg | 190 |
| Mafuta 1L | 315 |
| Sukari 1kg | 155 |
| Mchele 5kg | 890 |
| Sabuni | 70 |
| Chai 500g | 245 |
| Chumvi | 45 |
| Maziwa 500ml | 65 |

## Watch for this specifically

Money is **integer cents** in DukaSmart. A receipt printing `180.00` shillings
must come back as `18000` cents. If the model returns `180`, extraction is
100× under and the review screen will show `KES 1.80`. That single failure mode
is worth more attention than the line-count hit rate — it is silent, plausible,
and lands straight in a money field.

## Running

```
flutter run -d chrome tool/extraction_spike.dart \
  --dart-define=ANTHROPIC_API_KEY=sk-ant-... \
  --dart-define=AI_EXTRACTION_MODEL=claude-haiku-4-5-20251001
```

Tap **Read receipt** or **Read notebook page**, pick a file from the folders
here, and compare the on-screen result with the table above.

## Where the images are

Not in git. `.gitignore` drops every image under `tool/spike_samples/` — the real
gate photos are a live shop's supplier prices, and this set is 12MB of generated
JPEGs. This file is tracked instead, so the ground-truth tables and the two
deliberate traps survive even though the pixels don't. A fresh clone will find
these folders empty; regenerate the images from the descriptions above, or ask
for the originals.
