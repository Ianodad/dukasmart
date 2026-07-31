#!/usr/bin/env node
// UI driver for the DukaSmart web build — taps, types, and screenshots over CDP.
//
// Why this exists: capture_screens.mjs can only navigate and photograph, so
// CAPTURE.md had to tell you to seed the shop by hand before every capture
// run. A screenshot of a fresh profile shows `KES 0` and the demo seed
// products, which reads as fake. This drives the real UI instead, so a
// realistic day can be recorded reproducibly.
//
// Flutter web renders to a canvas — there is no DOM to query and no
// stable selector to target. So actions are CSS-pixel coordinates, read off
// a screenshot (screenshot px / DPR = CSS px). Coordinates are therefore
// layout-dependent: if a screen changes, re-shoot it and re-measure.
//
// Everything must happen in ONE run: each invocation spawns a fresh Chrome on
// about:blank. Committed data survives in the profile's IndexedDB, so seeding
// accumulates across runs, but on-screen state does not.
//
// No dependencies — Node 22+ ships a global WebSocket.
//
// Usage:
//   node tool/drive_ui.mjs <base-url> <out-dir> <script.json>
//
// Actions (one JSON object per step, executed in order):
//   {"boot": true}          navigate to the app root (do this first)
//   {"nav": "/home/ask"}    navigate to a route
//   {"tap": [x, y]}         tap at CSS coordinates
//   {"scroll": [x, y, dy]}  wheel-scroll by dy at CSS coordinates
//   {"type": "text"}        insert text into the focused field
//   {"key": "Enter"}        send a key
//   {"shot": "name"}        write <out-dir>/name.png at 860x1864
//   {"wait": 1200}          ms to settle after this step (default 700)
//
// Boot needs a long wait (~16000) — the splash screen awaits the Drift
// sqlite3 worker, and a cold profile also warms the service worker.

import { spawn } from 'node:child_process';
import { writeFileSync, mkdirSync, readFileSync } from 'node:fs';
import { setTimeout as sleep } from 'node:timers/promises';

const WIDTH = 430;   // CSS px — matches phoneW in remotion/src/DukaPromo.tsx
const HEIGHT = 932;
const DPR = 2;       // => 860 x 1864 PNG, same geometry as capture_screens.mjs
const PORT = 9334;   // not 9333 — so this can run alongside capture_screens.mjs
const PROFILE = '/tmp/dukasmart-drive-profile';

const [baseUrl, outDir, scriptFile] = process.argv.slice(2);
if (!baseUrl || !outDir || !scriptFile) {
  console.error('usage: drive_ui.mjs <base-url> <out-dir> <script.json>');
  process.exit(2);
}
mkdirSync(outDir, { recursive: true });
const actions = JSON.parse(readFileSync(scriptFile, 'utf8'));

const chrome = spawn('google-chrome', [
  '--headless=new', '--disable-gpu', '--no-sandbox', '--hide-scrollbars',
  `--remote-debugging-port=${PORT}`,
  `--window-size=${WIDTH},${HEIGHT}`,
  `--user-data-dir=${PROFILE}`,
  'about:blank',
], { stdio: 'ignore' });

const cleanup = () => { try { chrome.kill(); } catch {} };
process.on('exit', cleanup);
process.on('SIGINT', () => { cleanup(); process.exit(130); });

let wsUrl;
for (let i = 0; i < 40; i++) {
  await sleep(250);
  try {
    const r = await fetch(`http://127.0.0.1:${PORT}/json/list`);
    const page = (await r.json()).find((t) => t.type === 'page');
    if (page?.webSocketDebuggerUrl) { wsUrl = page.webSocketDebuggerUrl; break; }
  } catch { /* not up yet */ }
}
if (!wsUrl) { console.error('chrome devtools endpoint never came up'); process.exit(1); }

const ws = new WebSocket(wsUrl);
await new Promise((res, rej) => { ws.onopen = res; ws.onerror = rej; });

let msgId = 0;
const pending = new Map();
ws.onmessage = (ev) => {
  const m = JSON.parse(ev.data);
  if (m.id && pending.has(m.id)) {
    const { resolve, reject } = pending.get(m.id);
    pending.delete(m.id);
    m.error ? reject(new Error(JSON.stringify(m.error))) : resolve(m.result);
  }
};
const cdp = (method, params = {}) =>
  new Promise((resolve, reject) => {
    const id = ++msgId;
    pending.set(id, { resolve, reject });
    ws.send(JSON.stringify({ id, method, params }));
  });

await cdp('Page.enable');
await cdp('Emulation.setDeviceMetricsOverride', {
  width: WIDTH, height: HEIGHT, deviceScaleFactor: DPR, mobile: true,
});

// A real press/release pair — Flutter's pointer binding ignores a bare click.
async function tap(x, y) {
  const base = { x, y, button: 'left', clickCount: 1, pointerType: 'mouse' };
  await cdp('Input.dispatchMouseEvent', { type: 'mouseMoved', ...base, buttons: 0 });
  await sleep(60);
  await cdp('Input.dispatchMouseEvent', { type: 'mousePressed', ...base, buttons: 1 });
  await sleep(90);
  await cdp('Input.dispatchMouseEvent', { type: 'mouseReleased', ...base, buttons: 0 });
}

for (const a of actions) {
  if (a.boot) {
    await cdp('Page.navigate', { url: baseUrl });
  } else if (a.nav !== undefined) {
    await cdp('Page.navigate', { url: `${baseUrl}/#${a.nav}` });
  } else if (a.tap) {
    await tap(a.tap[0], a.tap[1]);
  } else if (a.scroll) {
    const [x, y, dy] = a.scroll;
    await cdp('Input.dispatchMouseEvent', {
      type: 'mouseWheel', x, y, deltaX: 0, deltaY: dy,
    });
  } else if (a.type !== undefined) {
    // insertText goes through Flutter's hidden IME input; per-key events do not.
    await cdp('Input.insertText', { text: a.type });
  } else if (a.key) {
    const vk = a.key === 'Enter' ? 13 : 0;
    await cdp('Input.dispatchKeyEvent', { type: 'keyDown', key: a.key, code: a.key, windowsVirtualKeyCode: vk });
    await cdp('Input.dispatchKeyEvent', { type: 'keyUp', key: a.key, code: a.key });
  } else if (a.shot) {
    const { data } = await cdp('Page.captureScreenshot', { format: 'png' });
    const file = `${outDir}/${a.shot}.png`;
    writeFileSync(file, Buffer.from(data, 'base64'));
    console.log(`wrote ${file}`);
  }
  await sleep(a.wait ?? 700);
}

ws.close();
cleanup();
