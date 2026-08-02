#!/usr/bin/env node
// Screenshot rig for docs/screenshots/ — drives headless Chrome over CDP.
//
// Why this exists: docs/screenshots/CAPTURE.md describes a manual DevTools
// recipe (device toolbar, 430x932, DPR 2, Capture screenshot). That is fine
// once and error-prone every time after — the 860x1864 geometry is load-
// bearing for the promo's phone frame, and an off-by-one aspect ratio
// letterboxes inside it. This does the same thing reproducibly.
//
// Chrome's plain `--screenshot` flag cannot be used: it needs
// `--virtual-time-budget` to wait for the app, and virtual time freezes real
// timers while Drift's sqlite3 worker runs off-thread and never advances. The
// app stays on the splash screen forever. So we wait in real time over CDP.
//
// No dependencies — Node 22+ ships a global WebSocket.
//
// Usage:
//   node tool/capture_screens.mjs <base-url> <out-dir> [name:route ...]
//
// Example:
//   node tool/capture_screens.mjs http://localhost:8771 /tmp/shots \
//     15-ask-answer:/home/ask 16-daily-report-ai:/home/report

import { spawn } from 'node:child_process';
import { writeFileSync, mkdirSync } from 'node:fs';
import { setTimeout as sleep } from 'node:timers/promises';

const WIDTH = 430;   // CSS px — matches phoneW in remotion/src/DukaPromo.tsx
const HEIGHT = 932;
const DPR = 2;       // => 860 x 1864 PNG
const PORT = 9333;

const [baseUrl, outDir, ...targets] = process.argv.slice(2);
if (!baseUrl || !outDir || targets.length === 0) {
  console.error('usage: capture_screens.mjs <base-url> <out-dir> <name:route> [...]');
  process.exit(2);
}
mkdirSync(outDir, { recursive: true });

const chrome = spawn('google-chrome', [
  '--headless=new', '--disable-gpu', '--no-sandbox', '--hide-scrollbars',
  `--remote-debugging-port=${PORT}`,
  `--window-size=${WIDTH},${HEIGHT}`,
  '--user-data-dir=/tmp/dukasmart-capture-profile',
  'about:blank',
], { stdio: 'ignore' });

const cleanup = () => { try { chrome.kill(); } catch {} };
process.on('exit', cleanup);
process.on('SIGINT', () => { cleanup(); process.exit(130); });

// --- wait for the debugging endpoint, then open a websocket to the page ---
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
// DPR here, not --force-device-scale-factor: the flag also scales the browser
// UI and is ignored by captureScreenshot in some Chrome builds.
await cdp('Emulation.setDeviceMetricsOverride', {
  width: WIDTH, height: HEIGHT, deviceScaleFactor: DPR, mobile: true,
});

// Page.navigate resolves with errorText when the load actually failed. Without
// this check a dead server is invisible: Chrome renders its own "This site
// can't be reached" page, the rig screenshots THAT at a perfect 860x1864, and
// every downstream check (geometry, docs/remotion sync) still passes. Broken
// captures have been committed this way — fail loudly instead.
async function navigate(url) {
  const res = await cdp('Page.navigate', { url });
  if (res?.errorText) {
    throw new Error(`navigation to ${url} failed: ${res.errorText} — is the server up?`);
  }
}

// Boot once and let the Drift worker + service worker settle. The splash
// screen awaits databaseReadyProvider; the service worker alone has been
// observed taking >4s on a cold profile.
await navigate(baseUrl);
await sleep(15000);

for (const target of targets) {
  const idx = target.indexOf(':');
  const name = target.slice(0, idx);
  const route = target.slice(idx + 1);

  await navigate(`${baseUrl}/#${route}`);
  await sleep(6000); // route transition + any async card resolving

  const { data } = await cdp('Page.captureScreenshot', { format: 'png' });
  const file = `${outDir}/${name}.png`;
  writeFileSync(file, Buffer.from(data, 'base64'));
  console.log(`wrote ${file}`);
}

ws.close();
cleanup();
