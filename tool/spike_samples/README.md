# Extraction spike sample photos

Drop real photos here for the M10 exit-gate spike
(`.wargames/wargames/01-ai-vision-extraction.md`, `.wargames/GATE-01-extraction-spike.md`):

- `tool/spike_samples/receipts/*.jpg` — at least 5 printed supplier
  receipt photos.
- `tool/spike_samples/notebook/*.jpg` — at least 5 handwritten notebook
  catalog page photos.

## Running the spike

```
flutter run -d chrome tool/extraction_spike.dart \
  --dart-define=ANTHROPIC_API_KEY=sk-ant-... \
  --dart-define=AI_EXTRACTION_MODEL=claude-haiku-4-5-20251001
```

This opens a page with two buttons — **Read receipt** and **Read
notebook page**. Tapping one opens the browser's file picker; pick a
photo from the folders above. The parsed result (items/products,
`skippedRows`, `truncated`) prints to the browser devtools console via
`debugPrint` and also renders on screen.

Run every photo **twice** — once with `AI_EXTRACTION_MODEL=claude-haiku-4-5-20251001`
(the shipping model) and once with `AI_EXTRACTION_MODEL=claude-opus-5`
(the comparison run) — and record both in
`.wargames/GATE-01-extraction-spike.md`.
